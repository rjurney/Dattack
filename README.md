Summary
-------

This application reads your entire inbox via lib/process_imap, and monitors your realtime inbox stream via lib/process_emails.rb

Setup
-----

Note: JRuby is available at http://jruby.org.s3.amazonaws.com/downloads/1.6.2/jruby-bin-1.6.2.tar.gz if you do not already have it installed.  The jgem command should be available once you add JRuby's bin directory to your path.

STEP 1) Run install.sh after cloning this repo, to build and install dependencies.  Depending on your JRuby setup, you may need to sudo the gem installs.

STEP 2) Run stage_app.sh to initialize dependent services (voldemort)

Environment Setup
-----------------

1) Fill out the missing values in environment.sh
2) Run environment.sh to setup environment variables for voldemort, S3, Gmail, etc.

Scraping Your Inbox
-------------------

At the moment, the only supported email provider is Gmail.  To scrape your Gmail account, run:
	
	jruby data/process_imap.rb <username@gmail.com> <password>
	
	jruby data/process_email.rb, which processes email in realtime, isn't working for other users yet.
	
Visualization
-------------

Download Gephi from http://gephi.org/users/download/ and load the graphml file that data/process_imap.rb created in /tmp
	