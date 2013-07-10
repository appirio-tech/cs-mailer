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
		challenge_closed(id) if type.downcase.eql?('challenge closed')
		challenge_scored(id, false) if type.downcase.eql?('challenge scored complete')
		challenge_scored(id, true) if type.downcase.eql?('challenge scored waiting review')
		private_message(id) if type.downcase.eql?('private message')
		discussion_board_post(id) if type.downcase.eql?('discussion board')
		challenge_results(id) if type.downcase.eql?('challenge results')

	end

	private	

		def self.discussion_board_post(id)

			# get the mail to go out
		  mail = query_salesforce("select Name, Challenge__c, Challenge_Comment__c, Subject__c from Mail__c 
		  	where Id = '"+id+"' limit 1").first	

		  # get the challenge
			challenge = query_salesforce("select name, challenge_id__c
				from Challenge__c where Id = '"+mail.challenge+"' limit 1").first			  

		  # get the comment
			comment = query_salesforce("select Id, Name, Member__c, Member__r.name, Member__r.Profile_Pic__c,
				Comment__c, Reply_To__c from Challenge_Comment__c where id 
				= '"+mail.challenge_comment+"' limit 1").first		

			# get all of the non-participant members
			recipients = all_challenge_recipients(mail.challenge)

			# get all of the participants where Send_Discussion_Emails__c = true
			participants = query_salesforce("select member__r.name, member__r.email__c from challenge_participant__c 
      where challenge__c = '#{mail.challenge}' and send_discussion_emails__c =  true")		

			# add each participant
      participants.each do |p|
				recipients << {:name => p.member__r.name, :email => p.member__r.email}	
      end

			unique_recipients(recipients).each do |r|
				StreamingMailer.discussion_board_email(r[:email], mail.subject, r[:name], challenge, comment).deliver
			  Rails.logger.info "[INFO][Mailer]Discussion board post mail for #{r[:name]} sent: To: #{r[:email]}"	
			end     

			update_mail_as_processed(id) 

		end

		def self.challenge_scored(id, waiting_review)

			# get the mail to go out
		  mail = query_salesforce("select Name, Challenge__c, Subject__c from Mail__c 
		  	where Id = '"+id+"' limit 1").first		
		  	
		  # get the challenge details
			challenge = query_salesforce("select name, challenge_id__c, total_prize_money__c, prize_money_paid__c,
				community_judging__c, submissions__c, number_of_reviewers__c
				from Challenge__c where Id = '"+mail.challenge+"' limit 1").first	

			recipients = all_challenge_recipients(mail.challenge)	

			# add is jeff	
			recipients << {:name => 'jeffdonthemic', :email => 'jeff@appirio.com'}	

			unique_recipients(recipients).each do |r|
				StreamingMailer.challenge_scored_email(r[:email], mail.subject, r[:name], challenge, waiting_review).deliver
			  Rails.logger.info "[INFO][Mailer]Challenge scored mail (waiting_review: #{waiting_review}) for #{r[:name]} sent: To: #{r[:email]}"	
			end

			update_mail_as_processed(id) 

		end	

		def self.challenge_closed(id)

			# get the mail to go out
		  mail = query_salesforce("select Name, Challenge__c, Subject__c from Mail__c 
		  	where Id = '"+id+"' limit 1").first		
		  	
		  # get the challenge details
			challenge = query_salesforce("select name, challenge_id__c, winner_announced__c, review_date__c, 
				contact__c, community_judging__c, submissions__c, number_of_reviewers__c
				from Challenge__c where Id = '"+mail.challenge+"' limit 1").first	

			recipients = all_challenge_recipients(mail.challenge)			

			unique_recipients(recipients).each do |r|
				StreamingMailer.challenge_closed_email(r[:email], mail.subject, r[:name], challenge).deliver
			  Rails.logger.info "[INFO][Mailer]Challenge closed mail for #{r[:name]} sent: To: #{r[:email]}"	
			end

			update_mail_as_processed(id) 

		end		

		def self.challenge_launch(id)

			# get the mail to go out
		  mail = query_salesforce("select Name, Challenge__c, Subject__c from Mail__c 
		  	where Id = '"+id+"' limit 1").first
		  
		  # get the challenge details
			challenge = query_salesforce("select name, challenge_id__c, end_date__c, review_date__c, 
				contact__c, community_judging__c 
				from Challenge__c where Id = '"+mail.challenge+"' limit 1").first

			recipients = all_challenge_recipients(mail.challenge)			

			unique_recipients(recipients).each do |r|
				StreamingMailer.challenge_launch_email(r[:email], mail.subject, r[:name], challenge).deliver
			  Rails.logger.info "[INFO][Mailer]Challenge launched mail for #{r[:name]} sent: To: #{r[:email]}"	
			end			

			update_mail_as_processed(id) 

		end	

		def self.challenge_results(id)

			# get the mail to go out
		  mail = query_salesforce("select Name, Challenge__c, Subject__c from Mail__c 
		  	where Id = '"+id+"' limit 1").first
		  
		  # get the challenge details
			challenge = query_salesforce("select name, challenge_id__c, end_date__c, review_date__c, 
				contact__c, results_overview__c from Challenge__c where Id = '"+mail.challenge+"' limit 1").first

	  	# get all of the particiapnts from the challenge that had a submission
			participants = query_salesforce("select id, member__r.name, member__r.email__c, final_prize__c, place__c, score__c  
	  	 from challenge_participant__c where has_submission__c = true and challenge__c = '"+mail.challenge+"'")	  	 	

			participants.each do |r|
				StreamingMailer.challenge_results_email(r.member__r.email, mail.subject, r.member__r.name, challenge, r).deliver
			  Rails.logger.info "[INFO][Mailer]Challenge results mail for #{r.member__r.name} sent: To: #{r.member__r.email}"	
			end	

			update_mail_as_processed(id) 		

		end			

		def self.private_message(id)

		  mail = query_salesforce("select Name, Related_To_Id__c, Message_Body__c, Sent_From__r.Name, 
		  	Sent_From__r.Profile_Pic__c, Sent_To__r.Name, Sent_To__r.Email__c, Subject__c 
		  	from Notification_Staging__c where Id = '"+id+"' limit 1").first
		  from_member = { 'membername' => mail.sent_from__r.name, 'profile_pic' => mail.sent_from__r.profile_pic }
		  StreamingMailer.private_message_email(mail.sent_to__r.email, mail.subject, 
		  	mail.message_body, mail.related_to_id, from_member).deliver
		  # write the id to the cache so this message doesn't get sent again
		  puts "[INFO][Mailer]Private message #{mail.name} sent: To: #{mail.sent_to__r.email} - Subject: #{mail.subject}"

		end

		def self.generic(id)

		  mail = query_salesforce("select Name, To__c, From__c, Subject__c, Body__c 
		  	from Mail__c where Id = '"+id+"' limit 1").first
		  StreamingMailer.standard_email(mail.to,mail.from,mail.subject,mail.body).deliver
		  Rails.logger.info "[INFO][Mailer]Generic mail #{mail.name} sent: To: #{mail.to} - Subject: #{mail.subject}"

		  update_mail_as_processed(id) 

		end		

		def self.all_challenge_recipients(id)

			recipients = []

			# get the primary contact to send to
			primary_contact = query_salesforce("select contact__r.name, contact__r.email__c 
				from challenge__c where Id = '"+id+"' limit 1").first			

		  # get all of the judges
			judges = query_salesforce("select member__r.name, member__r.email__c 
				from challenge_reviewer__c where challenge__c = '"+id+"'")

		  # get all of the comment notifiers
			notifiers = query_salesforce("select member__r.name, member__r.email__c 
				from challenge_comment_notifier__c where challenge__c = '"+id+"'")	

			# add the judges and notifiers to the recipients
			judges.each { |m| recipients << {:name => m['member__r']['name'], :email => m['member__r']['email']} }
			notifiers.each { |m| recipients << {:name => m['member__r']['name'], :email => m['member__r']['email']} }		

		  if primary_contact['contact__r']
				recipients << {:name => primary_contact['contact__r']['name'], :email => primary_contact['contact__r']['email']}
			end			

			recipients

		end

		def self.unique_recipients(recipients)
			unique = []
			recipients.each do |r|
				if unique.detect { |h| h[:name] == r[:name] }.nil?	
					unique << r
				end
			end	
			unique
		end

	  def self.query_salesforce(soql)
	    Forcifier::JsonMassager.deforce_json(@client.query(soql))
	  rescue Exception => e
	    Rails.logger.fatal "[FATAL][Mailer] Query exception: #{soql} -- #{e.message}" 
	    nil
	  end

	  def self.update_mail_as_processed(id)
	  	Forcifier::JsonMassager.deforce_json(@client.update!('Mail__c', Id: id, Processed__c: true))
	  rescue Exception => e
	    Rails.logger.fatal "[FATAL][Mailer] Could not mark mail as processed: #{e.message}" 
	  end		

end