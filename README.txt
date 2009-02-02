= yodlee

 * http://github.com/aasmith/yodlee

== DESCRIPTION:

 Fetches accounts and their transaction details from the Yodlee 
 MoneyCenter (https://moneycenter.yodlee.com).

== NOTES:

 * The strings returned by Yodlee::Account#{last_updated,next_update} 
   can be parsed with Chronic (http://chronic.rubyforge.org), if a 
   timestamp is needed.

 * Raises exceptions when exceptional things happen. These are scenarios
   where the connection probably needs to be re-instantiated with the 
   correct details after prompting the user or some external source for 
   more complete login or account details.

== BUGS / TODO:

 * Does not handle lists containing bill pay accounts

 * Does not handle cases where the session has timed out. To avoid this,
   use the instantiated objects in short durations. Don't leave them
   hanging around.

 * Add support for investment holdings

 * Update account transactions / polling

== SYNOPSIS:
 
 require 'rubygems'
 require 'yodlee'

 # Create some credentials to login with.
 cred = Yodlee::Credentials.new
 cred.username = 'bob'
 cred.password = 'weak'

 # The word the remote system stores and shows back to you to prove
 # they really are Yodlee.
 cred.expectation = 'roflcopter'

 # An array of questions and answers. Yodlee expects you to answer
 # three of thirty defined in Yodlee::Credentials::QUESTIONS.
 cred.answers = [[Yodlee::Credentials::QUESTIONS[1], "The Queen"], [...]]
 
 # That's enough credentials. Create a connection.
 conn = Yodlee::Connection.new(cred)

 # Connect, and get an account list.
 conn.accounts.each do |account|
   puts account.institute_name, account.name, account.balance

   # grab a handy list of transactions. Parseable as CSV.
   puts account.transactions

   # take a look in account.account_info for a hash of useful stuff.
   # available keys vary by account type and institute.
 end

 # Should look something like this:

 First Bank of Excess
 Checking
 $123.45
 [...some csv...]
 First Bank of Mattress
 Savings
 $1,234.56
 [...more csv!...]

== REQUIREMENTS:

 mechanize, nokogiri.

== INSTALL:

 sudo gem install aasmith-yodlee --source http://gems.github.com

== LICENSE:

Copyright (c) 2009 Andrew A. Smith <andy@tinnedfruit.org>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
