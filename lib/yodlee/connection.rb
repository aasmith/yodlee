module Yodlee
  class Connection
    def initialize(credentials, logger = nil)
      @credentials = credentials
      @logger = logger
  
      @connected = false
      @accounts = nil

      @agent = WWW::Mechanize.new
      @agent.user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.0.5) Gecko/2008120122 Firefox/3.0.5'

      @accounts_page = nil
    end
  
    def accounts
      return @accounts if @accounts
  
      handle_connection!

      doc = Nokogiri::HTML.parse(@accounts_page.body)

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
      page = @accounts_page

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

      # XXX: gross. this side-effect required by transactions(acct).
      @script_sess = doc.to_s.scan(/scriptSessionId='([\d\w]+)'/).last.to_s

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

      sc = @agent.cookies.detect{|c| c.name == "JSESSIONID"}

      post_headers = {
        "callCount" => "1",
        "httpSessionId" => sc.value,
        "scriptSessionId" => @script_sess,
        "c0-scriptName" => "TxnService",
        "c0-methodName" => "searchTransactions",
        "c0-id" => "0",
        "c0-e1" => "number:10000004",
        "c0-e2" => "string:17CBE222A42161A3FF450E47CF4C1A00",
        "c0-e3" => "null:null",
        "c0-e5" => "string:MM%2Fdd%2Fyyyy",
        "c0-e6" => "string:USD",
        "c0-e7" => "string:PST",
        "c0-e8" => "string:.",
        "c0-e9" => "string:%2C",
        "c0-e10" => "string:%23%23%23%2C%23%230.%23%23",
        "c0-e4" => "Object_Object:{dateFormat:reference:c0-e5, currencyCode:reference:c0-e6, timeZone:reference:c0-e7, decimalSeparator:reference:c0-e8, groupingSeparator:reference:c0-e9, groupPattern:reference:c0-e10}",
        "c0-e11" => "number:1",
        "c0-e12" => "boolean:false",
        "c0-param0" => "Object_Object:{cobrandId:reference:c0-e1, applicationId:reference:c0-e2, csit:reference:c0-e3, iBean:reference:c0-e4, loggingLevel:reference:c0-e11, loggingEnabled:reference:c0-e12}",
        "c0-e13" => "string:#{acct.id}",
        "c0-e14" => "string:-1",
        "c0-e15" => "null:null",
        "c0-e16" => "string:-1",
        "c0-e17" => "null:null",
        "c0-e18" => "null:null",
        "c0-e19" => "null:null",
        "c0-e20" => "string:-1",
        "c0-e21" => "null:null",
        "c0-e22" => "number:-1",
        "c0-e23" => "number:-1",
        "c0-e24" => "boolean:false",
        "c0-e25" => "string:",
        "c0-e26" => "boolean:false",
        "c0-e27" => "string:",
        "c0-e28" => "string:",
        "c0-e29" => "string:",
        "c0-e30" => "string:",
        "c0-e31" => "string:",
        "c0-e32" => "boolean:false",
        "c0-e33" => "string:0.0",
        "c0-e34" => "string:0",
        "c0-e35" => "null:null",
        "c0-e36" => "null:null",
        "c0-e37" => "string:allTransactions",
        "c0-e38" => "string:InProgressAndCleared",
        "c0-e39" => "number:999",
        "c0-e40" => "string:",
        "c0-e41" => "null:null",
        "c0-e42" => "null:null",
        "c0-e43" => "string:",
        "c0-e44" => "null:null",
        "c0-e45" => "string:ALL",
        "c0-e46" => "string:false",
        "c0-e47" => "null:null",
        "c0-e48" => "string:0.0",
        "c0-e49" => "string:0.0",
        "c0-e50" => "string:ALL",
        "c0-param1" => "Object_Object:{itemAccountId:reference:c0-e13, categoryId:reference:c0-e14, categoryLevelId:reference:c0-e15, dateRangeId:reference:c0-e16, fromDate:reference:c0-e17, toDate:reference:c0-e18, groupBy:reference:c0-e19, groupAccountId:reference:c0-e20, filterTranasctions:reference:c0-e21, transactionTypeId:reference:c0-e22, transactionStatusId:reference:c0-e23, ignorePendingTransactions:reference:c0-e24, includeBusinessExpense:reference:c0-e25, includeTransfer:reference:c0-e26, includeReimbursableExpense:reference:c0-e27, fromDate1:reference:c0-e28, toDate1:reference:c0-e29, includeMedicalExpense:reference:c0-e30, includeTaxDeductible:reference:c0-e31, includePersonalExpense:reference:c0-e32, transactionAmount:reference:c0-e33, transactionAmountRange:reference:c0-e34, billStatementRange:reference:c0-e35, criteria:reference:c0-e36, module:reference:c0-e37, transactionType:reference:c0-e38, pageSize:reference:c0-e39, sharedMemId:reference:c0-e40, overRideDateRangeId:reference:c0-e41, overRideContainer:reference:c0-e42, searchString:reference:c0-e43, pageId:reference:c0-e44, splitTypeTransaction:reference:c0-e45, isAvailableBalance:reference:c0-e46, categoryIds:reference:c0-e47, currentBalance:reference:c0-e48, availableBalance:reference:c0-e49, container:reference:c0-e50}",
        "c0-param2" => "boolean:true",
        "batchId" => "3"
      }

      page = @agent.post(
        'https://moneycenter.yodlee.com/moneycenter/dwr/call/plaincall/TxnService.searchTransactions.dwr',
        post_headers
      )

      j = Johnson::Runtime.new

      script = page.body

      # Remove the last line (a call to DWREngine), and execute
      script = script.strip.sub(/\n[^\n]+\Z/m, '')

      # Remove a leading throw statement.
      script = script.sub(/\A.*?\n+/, '')

      j.evaluate script

      if x = j['s5']
        transactions = x.map do |e|
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

      @accounts_page = @agent.submit(f)
    end
  end
end
