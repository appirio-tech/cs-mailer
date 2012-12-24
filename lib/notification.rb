require 'restforce'

module Notification

	@client = Restforce.new :username => ENV['SFDC_USERNAME'],
	  :password       => ENV['SFDC_PASSWORD'],
	  :client_id      => ENV['SFDC_CLIENT_ID'],
	  :client_secret  => ENV['SFDC_CLIENT_SECRET'],
	  :host           => ENV['SFDC_HOST']  	

	def self.send_mail(id, type)

		@client.authenticate!

		generic(id) if type.downcase.eql?('generic')
		challenge_launch(id) if type.downcase.eql?('challenge launch')

	end

	private

	  def self.query_salesforce(soql)
	    Forcifier::JsonMassager.deforce_json(@client.query(soql))
	  rescue Exception => e
	    puts "[FATAL][Mailer] Query exception: #{soql} -- #{e.message}" 
	    nil
	  end  

		def self.generic(id)

		  mail = query_salesforce("select Name, To__c, From__c, Subject__c, Body__c 
		  	from Mail__c where Id = '"+id+"' limit 1").first
		  StreamingMailer.standard_email(mail.to,mail.from,mail.subject,mail.body).deliver
		  puts "[INFO][Mailer]Generic mail #{mail.name} sent: To: #{mail.to} - Subject: #{mail.subject}"		

		end

		def self.challenge_launch(id)

			# get the mail to go out
		  mail = query_salesforce("select Name, Challenge__c, From__c, Subject__c from Mail__c 
		  	where Id = '"+id+"' limit 1").first
		  # get the challenge details
			challenge = query_salesforce("select name, challenge_id__c, end_date__c, contact__c 
		  	from Challenge__c where Id = '"+mail.challenge+"' limit 1").first		

		  if challenge.contact
			  # get the primary contact to send to
				member = query_salesforce("select name, email__c from Member__c 
					where Id = '"+challenge.contact+"' limit 1").first  
				StreamingMailer.contact_launch_email(member.email, mail.from, mail.subject, member.name, challenge).deliver
			  puts "[INFO][Mailer]Challenge launched mail #{mail.name} sent: To: #{mail.to} - Subject: #{mail.subject}"	
			else
				puts "[INFO][Mailer]No primary contact specified for challenge #{challenge.challenge_id}. No launch notification sent."
			end

		end		

end