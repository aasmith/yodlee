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
end
