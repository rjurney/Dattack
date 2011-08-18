#!/usr/bin/env jruby
require 'rubygems'
require 'tmail'

def is_valid?(email)
  begin
    t_email = TMail::Address.parse email
    true
  rescue
    false
  end
end

unless ARGV[0] and (is_valid? ARGV[0])
    puts "bin/make_poster <email_address>"
    exit
end
email = ARGV[0]

puts "Scraping inbox of #{email}..."
system "bin/scrape_inbox.rb #{email}"
system "bin/dump_k_core.rb #{email} 2.0 /tmp/"
system "./gephi.rb /tmp/imap\:#{email}-2.0-core.graphml"
