require 'tmail'

# def split_addresses(addy_string)
#   final = []
#   if addy_string and addy_string.is_a? String
#     addresses = addy_string.split ",\s"
#     addresses.each do |addy|
#       final << strip_quotes(strip_address(addy))
#     end
#   end
#   final
# end

# def strip_address(address)
#   begin
#     mail = strip_quotes TMail::Address.parse address
#   rescue TMail::SyntaxError
#     puts("Invalid Email Address Detected: #{address}")
#     strip_quotes address
#   else
#     strip_quotes address
#   end
# end

def strip_quotes(address)
  address = address.gsub /"@/, '\"@'
  address = address.gsub /^""/, '"\"'
  address = address.gsub /""$/, '\""'
  address
end

# REPLACED BY TMAIL ON THE WHOLE MESSAGE
# Extract the email part of the Name/email, i.e.: Russell Jurney <russell.jurney@gmail.com>
# def extract_email(address)
#   if address =~ /<.+>/
#     match = address.match /.*<(.*)>.*/
#     if match
#       return match[1].downcase
#     end
#   else
#     address.downcase
#   end
# end

# Build a hash of all the names associated with an email, and all emails associated with a name.
# Pick the most common one as the official one, and substitute it in thereafter - updating this table each time you do.
def disambiguate(email)
  
end

def process_link(from, to)
  
end
