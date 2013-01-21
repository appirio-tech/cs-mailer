class StreamingMailer < ActionMailer::Base

  def blank_email(to, from, subject, body)
  	@body = body
    mail(:to => to, :from => from, :subject => subject)
  end

  def standard_email(to, from, subject, body)
  	@body = body
  	@subject = subject
    mail(:to => to, :from => from, :subject => subject)
  end 

  def challenge_closed_email(to, subject, membername, challenge)
    @membername = membername
    @challenge = challenge
    mail(:to => "#{membername} <#{to}>", :from => 'CloudSpokes Team <support@cloudspokes.com>', 
      :subject => subject, :bcc => 'jeff@jeffdouglas.com')
  end    

  def challenge_scored_email(to, subject, membername, challenge, waiting_review)
    @membername = membername
    @challenge = challenge
    @waiting_review = waiting_review
    mail(:to => "#{membername} <#{to}>", :from => 'CloudSpokes Team <support@cloudspokes.com>', 
      :subject => subject, :bcc => 'jeff@jeffdouglas.com')
  end      

  def challenge_launch_email(to, subject, membername, challenge)
  	@membername = membername
  	@challenge = challenge
    mail(:to => "#{membername} <#{to}>", :from => 'CloudSpokes Team <support@cloudspokes.com>', 
      :subject => subject, :bcc => 'jeff@jeffdouglas.com')
  end    

  def private_message_email(to, subject, body, private_message_id, from_member)
    @body = body
    @subject = subject
    @private_message_id = private_message_id
    @from_member = from_member
    mail(:to => to, :from => 'CloudSpokes (No Reply) <donotreply@cloudspokes.com>', :subject => "#{from_member['membername']} has sent you a private message at CloudSpokes")
  end    

end
