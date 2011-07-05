require 'lib/graph_client'
require 'jcode'
$KCODE = 'UTF8'
require 'optparse'

unless ARGV[0] and ARGV[1] and ARGV[2]
  puts "Usage: bin/vold_to_graphml <username@gmail.com>, <password>, <output_path>"
  exit
end

USERNAME = ARGV[0]
PASSWORD = ARGV[1]
OUTPATH = ARGV[2]

