require 'restforce'
require 'faye'

# Initialize a client with your username/password.
client = Restforce.new :username => ENV['SFDC_USERNAME'],
  :password       => ENV['SFDC_PASSWORD'],
  :client_id      => ENV['SFDC_CLIENT_ID'],
  :client_secret  => ENV['SFDC_CLIENT_SECRET'],
  :host           => ENV['SFDC_HOST']  

puts client.to_yaml

client.authenticate!

EM.next_tick do
  client.subscribe 'AllMails' do |message|
    if ENV['MAILER_ENABLED'].eql?('true')
      id = message['sobject']['Id']
      puts "[INFO][MAILER]Received mail message #{id}"
      mail = client.query("select Name, To__c, From__c, Subject__c, Body__c from Mail__c where Id = '"+id+"' limit 1").first
      m = StreamingMailer.standard_email(mail.To__c,mail.From__c,mail.Subject__c,mail.Body__c).deliver
      puts "[INFO][MAILER]Mail #{mail.Name} sent: To: #{mail.To__c} - Subject: #{mail.Subject__c}"
    end
  end
end