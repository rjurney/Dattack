#!/usr/bin/env jruby

require 'lib/process_imap'

def is_valid?(email)
  begin
    t_email = TMail::Address.parse email
    true
  rescue
    false
  end
end

unless ARGV[0] and (is_valid? ARGV[0])
    puts "bin/scrape_inbox <email_address>"
    exit
end

unless ENV['VOLDEMORT_STORE'] and ENV['VOLDEMORT_ADDRESS']
    puts "Must set ENV['VOLDEMORT_STORE'] and ENV['VOLDEMORT_ADDRESS']"
    exit
end

email = ARGV[0]
message_count = ARGV[1]
getter = ProcessImap.new email, message_count||500
STDERR.puts "Starting inbox scan..."
getter.scan_folder
STDERR.puts "Done scanning inbox!"
