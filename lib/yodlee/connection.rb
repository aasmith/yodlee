module Yodlee
  class Connection
    def initialize(credentials, logger = nil)
      @credentials = credentials
      @logger = logger
  
      @connected = false
      @accounts = nil

      @agent = WWW::Mechanize.new
      @agent.user_agent_alias = 'Windows IE 7'

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

      link = page.links.href(/itemAccountId=#{acct.id}/) or raise AccountNotFound, "Could not find account in list"
      link.href << "&dateRangeId=-1"
      page = link.click

      doc = Nokogiri::HTML.parse(page.body)

      last_upd, next_upd = doc.at(".accountlinks").text.scan(/Last updated (.*?)\s*\(next scheduled update (.*)\)/).flatten

      # Regular accounts have a heading + div, investments have heading + table
      regular_acct = doc.at("h2[contains('Account Overview')] + div")

      account_info = regular_acct ? regular_account_info(doc) : investment_account_info(doc)
      account_info[:next_update]  = next_upd
      account_info[:last_updated] = last_upd
      account_info[:transactions] = page.form_with(:name => 'rep').submit.body
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

      @uris[:accounts] = page.uri.to_s << "&filter_id=-1"
    end
  end
end
