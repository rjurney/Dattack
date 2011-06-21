# The purpose of this library is to access emails via IMAP - the Inbox and Outbox

require 'net/imap'
require 'tmail'

imap = Net::IMAP.new('imap.gmail.com',993,true)
imap.login('russell.jurney@gmail.com', 'K4mikazi!')
imap.examine('[Gmail]/Sent Mail')

imap.search(['ALL']).each do |message_id|
  msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
  mail = TMail::Mail.parse(msg)
  from = mail.header['from'].body
  to = mail.header['to'].body
end

imap.expunge()