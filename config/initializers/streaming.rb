require 'restforce'
require 'faye'
require 'notification'

# Initialize a client with your username/password.
client = Restforce.new :username => ENV['SFDC_USERNAME'],
  :password       => ENV['SFDC_PASSWORD'],
  :client_id      => ENV['SFDC_CLIENT_ID'],
  :client_secret  => ENV['SFDC_CLIENT_SECRET'],
  :host           => ENV['SFDC_HOST']  


begin
  client.authenticate!
  puts "[INFO][MAILER] Successfully authenticated"

  EM.next_tick do
    client.subscribe 'AllMails' do |message|
      if ENV['MAILER_ENABLED'].eql?('true')
        puts "[INFO][MAILER]Received mail message #{message['sobject']['Id']}"
        Notification.send_mail(message['sobject']['Id'], message['sobject']['Type__c'])
      end
    end
  end

rescue
  puts "[FATAL][MAILER] Could not authenticate. Not listening for streaming events."
end