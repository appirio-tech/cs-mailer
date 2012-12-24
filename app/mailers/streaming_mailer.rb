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

  def contact_launch_email(to, from, subject, membername, challenge)
  	@membername = membername
  	@challenge = challenge
    mail(:to => to, :from => from, :subject => subject, :bcc => 'jeff@appirio.com')
  end    

end
