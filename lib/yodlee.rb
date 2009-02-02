require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'enumerator'

require 'yodlee/version'

class String
  def underscore
    gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end unless respond_to?(:underscore)
end

module Yodlee
  class Credentials
    QUESTIONS = <<-EOS.split(/\n\s*\n?/).map{|e|e.strip}
      In what city was your high school? (full name of city only)
      What is your maternal grandmother's first name?
      What is your father's middle name?
      What was the name of your High School?
      What is the name of the first company you worked for?
      What is the first name of the maid of honor at your wedding?
      What is the first name of your oldest nephew?
      What is your maternal grandfather's first name?
      What is your best friend's first name?
      In what city were you married? (Enter full name of city)
    
      What is the first name of the best man at your wedding?
      What was your high school mascot?
      What was the first name of your first manager?
      In what city was your father born? (Enter full name of city only)
      What was the name of your first girlfriend/boyfriend?
      What was the name of your first pet?
      What is the first name of your oldest niece?
      What is your paternal grandmother's first name?
      In what city is your vacation home? (Enter full name of city only)
      What was the nickname of your grandfather?
    
      In what city was your mother born? (Enter full name of city only)
      What is your mother's middle name?
      In what city were you born? (Enter full name of city only)
      Where did you meet your spouse for the first time? (Enter full name of city only)
      What was your favorite restaurant in college?
      What is your paternal grandfather's first name?
      What was the name of your junior high school? (Enter only \"Riverdale\" for Riverdale Junior High School)
      What was the last name of your favorite teacher in final year of high school?
      What was the name of the town your grandmother lived in? (Enter full name of town only)
      What street did your best friend in high school live on? (Enter full name of street only)
    EOS

    # answers = [[QUESTIONS[n], "answer"], ... ]
    attr_accessor :username, :password, :answers, :expectation
  end

  class Account
    attr_accessor :id, :name, :institute_id, :institute_name, :account_info

    def initialize(connection)
      @connection = connection
      @account_info = nil
    end

    [:transactions, :current_balance, :account_info, :last_updated, :next_update].each do |m|
      define_method m do
        @account_info = @connection.account_info(self) unless @account_info
        m == :account_info ? @account_info : @account_info[m]
      end
    end

    def to_s
      "#{@institute_name} - #{@name}"
    end
  end

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
      raise ExpectationNotFound, "Didn't find expectation" unless page.body.include?(@credentials.expectation)
      page
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

  class NoAnswerForQuestion < StandardError; end
  class ExpectationNotFound < StandardError; end
  class AccountNotFound < StandardError; end
end

