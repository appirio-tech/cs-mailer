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

end
