%w(../lib).each do |path|
  $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), path)))
end

require 'rubygems'
require 'test/unit'
require 'flexmock/test_unit'

require 'yodlee'

class TestYodlee < Test::Unit::TestCase
  def setup
    @cred = Yodlee::Credentials.new
    @cred.username    = "bob"
    @cred.password    = "foo"
    @cred.expectation = "bar"
    @cred.answers     = [
      [Yodlee::Credentials::QUESTIONS[0], "aa"],
      [Yodlee::Credentials::QUESTIONS[10], "ab"],
      [Yodlee::Credentials::QUESTIONS[20], "ac"]
    ]

    @conn = Yodlee::Connection.new(@cred) 

    # prevent accidental connections
    inject_agent(nil)
  end

  def test_not_connected
    assert !@conn.connected?
  end

  def test_valid_session
    # flunk
  end

  def test_provide_username
    inject_agent(mock = flexmock("mechanize"))

    mock.should_receive(:get).once.and_return(flexmock(:form_with => Hash.new))
    mock.should_receive(:submit).with('loginName' => "bob")

    @conn.provide_username
  end

  def test_answer_question
    inject_agent(agent = flexmock("mechanize"))

    page = flexmock("page")
    page.should_receive(:body).once.and_return("<label for='answer'>#{Yodlee::Credentials::QUESTIONS[0]}</label>")
    page.should_receive(:form_with).with(:name => 'loginForm').once.and_return(Hash.new)

    agent.should_receive(:submit).with('answer' => "aa")

    @conn.answer_question(page)
  end
  
  def test_answer_question_fails
    inject_agent(agent = flexmock("mechanize"))

    page = flexmock("page")
    page.should_receive(:body).once.and_return("<label for='answer'>#{Yodlee::Credentials::QUESTIONS[9]}</label>")

    assert_raises Yodlee::NoAnswerForQuestion do
      @conn.answer_question(page)
    end
  end

  def test_check_expectation
    page = flexmock("page")
    page.should_receive(:body).once.and_return("xxx bar yyy")

    assert_equal page, @conn.check_expectation(page)
  end

  def test_check_expectation_fails
    page = flexmock("page")
    page.should_receive(:body).once.and_return("xxx no expectation on this page yyy")

    assert_raises Yodlee::ExpectationNotFound do
      @conn.check_expectation(page)
    end
  end

  def test_provide_password
    inject_agent(agent = flexmock("mechanize"))

    page = flexmock("page")
    page.should_receive(:form_with).with(:name => 'loginForm').once.and_return(Hash.new)
    page.should_receive(:form_with).with(:name => 'updateForm').once.and_return(Hash.new)
    page.should_receive(:uri).and_return(URI.parse("http://example.com/accounts.page?x=y"))

    agent.should_receive(:submit).with('password' => "foo").and_return(page)
    agent.should_receive(:submit).with(Hash.new).and_return(page)

    @conn.provide_password(page)
  end

  def test_login
    mock = flexmock(@conn)
    mock.should_receive(:provide_username).ordered.with_no_args.once.and_return(page = flexmock("page"))
    mock.should_receive(:answer_question, :check_expectation, :provide_password).ordered.once.and_return(page)

    assert !mock.connected?
    mock.login
    assert mock.connected?
  end

  def test_accounts
    mock = flexmock(@conn)
    inject_agent(agent = flexmock("mechanize"))

    mock.should_receive(:handle_connection!).once
    agent.should_receive(:get).once.and_return(
      flexmock(:body => "
        <div class='acctbean'>
          <a href='u?itemId=1&itemAccountId=2'><strong>x</strong> - y</a>
          <a href='u?itemId=8&itemAccountId=9'><strong>a</strong> - b</a>
        </div>")
    )

    assert_equal "x", @conn.accounts.first.institute_name
    assert_equal "y", @conn.accounts.first.name
    assert_equal "1", @conn.accounts.first.institute_id
    assert_equal "2", @conn.accounts.first.id

    assert_equal "a", @conn.accounts.last.institute_name
    assert_equal "b", @conn.accounts.last.name
    assert_equal "8", @conn.accounts.last.institute_id
    assert_equal "9", @conn.accounts.last.id

    assert_equal 2, @conn.accounts.size
  end

  def test_account_transactions
  end

  def inject_agent(mock)
    @conn.instance_eval { @agent = mock }
  end

end
