require 'lib/process_imap'

getter = ProcessImap.new 'russell.jurney@gmail.com'
getter.scan_folder
