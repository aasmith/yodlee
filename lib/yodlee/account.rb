module Yodlee
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
end
