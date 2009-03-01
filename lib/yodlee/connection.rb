module Yodlee
  class Connection
    def initialize(credentials, logger = nil)
      @credentials = credentials
      @logger = logger
  
      @connected = false
      @accounts = nil

      @agent = WWW::Mechanize.new
      @agent.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.0.5) Gecko/2008120122 Firefox/3.0.5'

      @uris = {}
    end
  
    def accounts
      return @accounts if @accounts
  
      handle_connection!
  
      page = @agent.get(@uris[:accounts])
      doc = Nokogiri::HTML.parse(page.body)

      @accounts = doc.search(".acctbean a").map{|e|
        acct = Account.new(self)

        e['href'].scan(/(\w+Id)=(\d+)/).each do |k,v|
          case k 
            when /itemAccountId/ then acct.id = v
            when /itemId/        then acct.institute_id = v
          end
        end

        acct.institute_name = e.at('strong').text
        acct.name = e.children.last.text.sub(/^\s*-\s*/,'')
        acct
      }
    end

    def account_info(acct)
      page = @agent.get(@uris[:accounts])

      link = page.links.detect{|lnk| lnk.href =~ /itemAccountId=#{acct.id}/ } or raise AccountNotFound, "Could not find account in list"
      link.href << "&dateRangeId=-1"
      page = link.click

      doc = Nokogiri::HTML.parse(page.body)

      last_upd, next_upd = doc.at(".accountlinks").text.scan(/Last updated (.*?)\s*\(next scheduled update (.*)\)/).flatten

      # Regular accounts have a heading + div, investments have heading + table
      regular_acct = doc.at("h2[contains('Account Overview')] + div")

      account_info = regular_acct ? regular_account_info(doc) : investment_account_info(doc)
      account_info[:next_update]  = next_upd
      account_info[:last_updated] = last_upd

      csv_page = page.form_with(:name => 'rep').submit
      account_info[:simple_transactions] = csv_page.response['content-type'] =~ /csv/ ? csv_page.body : []

      account_info
    end

    def regular_account_info(doc)
      info_block = doc.at("h2[contains('Account Overview')] + div")

      Hash[*info_block.search("dt").
          zip(info_block.search("dt+dd")).
          map{|a,b|[a.text.gsub(/\W/,'').underscore.to_sym, b.text]}.
          flatten
      ]
    end

    def investment_account_info(doc)
      account_info = {}
      account_info[:holdings] = [] # TODO
      account_info[:current_balance] = 
        doc.search("h2[contains('Account Overview')] + table tr[last()] td[last()]").text
      account_info
    end

    # This method returns each transaction as an object, based on the underyling javascript 
    # structures used to build the transactions as displayed in the Yodlee UI. These objects
    # are able to access more information than the CSV Yodlee provides, such as the finanical
    # institute's transaction id, useful for tracking duplicates.
    #
    # Calling this method requires Johnson to be installed, otherwise an exception is raised.
    def transactions(acct)
      unless Object.const_defined? "Johnson"
        raise "Johnson not found. Install the johnson gem, or use simple_transactions instead." 
      end

      post_headers = {
        "c0-scriptName"=>"TxnService", 
        "c0-methodName"=>"searchTransactions", 
        "c0-id"=>"#{rand(5000)}_#{Time.now.to_i}#{Time.now.usec / 1000}}", 
        "c0-e1"=>"number:10000004", 
        "c0-e2"=>"string:17CBE222A42161A3FF450E47CF4C1A00", 
        "c0-e3"=>"null:null", 
        "c0-e4"=>"number:1", 
        "c0-e5"=>"boolean:false", 
        "c0-e6"=>"string:#{acct.id}", 
        "c0-e7"=>"string:-1", 
        "c0-e8"=>"null:null", 
        "c0-e9"=>"string:-1", 
        "c0-e10"=>"null:null", 
        "c0-e11"=>"null:null", 
        "c0-e12"=>"null:null",
        "c0-e13"=>"string:-1", 
        "c0-e14"=>"null:null", 
        "c0-e15"=>"number:-1", 
        "c0-e16"=>"number:-1", 
        "c0-e17"=>"boolean:false", 
        "c0-e18"=>"Boolean:false", 
        "c0-e19"=>"boolean:false", 
        "c0-e20"=>"Boolean:false", 
        "c0-e21"=>"string:", 
        "c0-e22"=>"string:", 
        "c0-e23"=>"Boolean:false", 
        "c0-e24"=>"Boolean:false", 
        "c0-e25"=>"boolean:false", 
        "c0-e26"=>"Number:0", 
        "c0-e27"=>"string:0", 
        "c0-e28"=>"null:null", 
        "c0-e29"=>"null:null", 
        "c0-e30"=>"string:allTransactions", 
        "c0-e31"=>"string:InProgressAndCleared", 
        "c0-e32"=>"number:999", 
        "c0-e33"=>"string:", 
        "c0-e34"=>"null:null", 
        "c0-e35"=>"null:null", 
        "c0-e36"=>"string:", 
        "c0-e37"=>"null:null", 
        "c0-e38"=>"string:ALL", 
        "c0-e39"=>"string:false", 
        "c0-e40"=>"string:0.0", 
        "c0-e41"=>"string:0.0", 

        "c0-param0"=>"Object:{
           cobrandId:reference:c0-e1,
           applicationId:reference:c0-e2,
           csit:reference:c0-e3,
           loggingLevel:reference:c0-e4,
           loggingEnabled:reference:c0-e5}", 

        "c0-param1"=>"Object:{
          itemAccountId:reference:c0-e6,
          categoryId:reference:c0-e7,
          categoryLevelId:reference:c0-e8,
          dateRangeId:reference:c0-e9,
          fromDate:reference:c0-e10,
          toDate:reference:c0-e11,
          groupBy:reference:c0-e12,
          groupAccountId:reference:c0-e13,
          filterTranasctions:reference:c0-e14,
          transactionTypeId:reference:c0-e15,
          transactionStatusId:reference:c0-e16,
          ignorePendingTransactions:reference:c0-e17,
          includeBusinessExpense:reference:c0-e18,
          includeTransfer:reference:c0-e19,
          includeReimbursableExpense:refrence:c0-e20,
          fromDate1:reference:c0-e21,
          toDate1:reference:c0-e22,
          includeMedicalExpense:reference:c0-e23,
          includeTaxDeductible:reference:c0-e24,
          includePersonalExpense:reference:c0-e25,
          transactionAmount:reference:c0-e26,
          transactionAmountRange:reference:c0-e27,
          billStatementRange:reference:c0-e28,
          criteria:reference:c0-e29,
          module:reference:c0-e30,
          transactionType:reference:c0-e31,
          pageSize:reference:c0-e32,
          sharedMemId:reference:c0-e33,
          overRideDateRangeId:reference:c0-e34,
          overRideContainer:referencec0-e35,
          searchString:reference:c0-e36,
          pageId:reference:c0-e37,
          splitTypeTransaction:reference:c0-e38,
          isAvailableBalance:reference:c0-e39,
          currentBalance:reference:c0-e40,
          availableBalance:reference:c0-e41}",

        "c0-param2"=>"boolean:false", 

        "callCount"=>"1", 
        "xml"=>"true", 
      }
      page = @agent.post(
        'https://moneycenter.yodlee.com/moneycenter/dwr/exec/TxnService.searchTransactions.dwr',
        post_headers
      )

      j = Johnson::Runtime.new

      # Remove the last line (a call to DWREngine), and execute
      j.evaluate page.body.strip.sub(/\n[^\n]+\Z/m, '')

      if x = j['s0']
        transactions = x.transactions.map do |e|
          transaction = Yodlee::Transaction.new
          transaction.account_name = e.accountName
          transaction.currency = e.amount.cobCurrencyCode
          transaction.amount = e.amount.cobPreciseAmount
          transaction.description = e.description
          transaction.account_id = e.itemAccountId
          transaction.fit_id = e.transactionId
          transaction.status = e['type']['type']

          # Re-parse in order to get a real Time, not a Johnson::SpiderMonkey::RubyLandProxy.
          transaction.date = Time.parse(e.date.to_s)
          transaction
        end

        return transactions
      end

      return []
    end
  
    def handle_connection!
      login unless connected?
    end
  
    def login
      @connected = false
      page = nil

      %w(provide_username answer_question check_expectation provide_password).each do |m|
        page = send(*[m, page].compact)
      end
      
      @connected = true
    end
  
    def connected?
      @connected
    end
  
    def log(level, msg)
      @logger.__send__(level, question) if @logger
    end

    # login scrapers

    def provide_username
      p = @agent.get 'https://moneycenter.yodlee.com/'
      f = p.form_with(:name => 'loginForm')
      f['loginName'] = @credentials.username
      @agent.submit(f)
    end

    def answer_question(page)
      question = Nokogiri::HTML.parse(page.body).at("label[@for=answer]").text
      log(:debug, question)
      
      begin
        answer = @credentials.answers.detect{|q, a| question =~ /^#{Regexp.escape(q)}/}.last
      rescue 
        raise NoAnswerForQuestion, "No answer found for #{question}"
      end

      f = page.form_with(:name => 'loginForm')
      f['answer'] = answer

      @agent.submit(f)
    end

    def check_expectation(page)
      d = Nokogiri::HTML.parse(page.body)
      node = d.at("dl > dt[contains('Secret Phrase')] + dd .caption")

      if node
        if @credentials.expectation == node.previous.text.strip
          return page
        else
          raise ExpectationMismatch, "Expectation found, but was incorrect"
        end
      else
        raise ExpectationNotFound, "Didn't find expectation"
      end
    end

    def provide_password(page)
      f = page.form_with(:name => 'loginForm')
      f['password'] = @credentials.password
      page = @agent.submit(f)

      # ack javascript disabled
      f = page.form_with(:name => 'updateForm')
      page = @agent.submit(f)

      link = page.links.detect { |lnk| lnk.attributes["id"] == "ACCOUNT_BALANCE" }

      @uris[:accounts] = link.href.to_s << "&filter_id=-1"
    end
  end
end
