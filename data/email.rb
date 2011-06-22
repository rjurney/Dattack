def split_addresses(addy_string)
  final = []
  if addy_string and addy_string.is_a? String
    addy_string = strip_address addy_string
    addresses = addy_string.split ","
    addresses.each do |addy|
      final << addy.squeeze(" ").strip
    end
  end
  final
end

def strip_address(address)
  address.gsub("\n|\r|\"|\'", "").downcase
end

# Extract the email part of the Name/email, i.e.: Russell Jurney <russell.jurney@gmail.com>
def extract_email(address)
  if address =~ /<.+>/
    match = address.match /.*<(.*)>.*/
    if match
      return match[1].downcase
    end
  else
    address.downcase
  end
end

# Build a hash of all the names associated with an email, and all emails associated with a name.
# Pick the most common one as the official one, and substitute it in thereafter - updating this table each time you do.
def disambiguate(email)
  
end

def process_link(from, to)
  
end
