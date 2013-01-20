require 'spec_helper'

describe Notification do
	
	describe "unique_recipients" do
		it "should not add duplicate recipients" do

			recipients = []
			recipients << {:name => 'jeffdonthemic', :email => 'jeff@jeffdouglas.com'}
			recipients << {:name => 'mess', :email => 'dmessinger@appirio.com'}
			recipients << {:name => 'sal', :email => 'sal@appirio.com'}
			recipients << {:name => 'jeffdonthemic', :email => 'jdouglas@appirio.com'}

			unique = Notification.unique_recipients(recipients)
			unique.count.should == 3

		end
	end

end