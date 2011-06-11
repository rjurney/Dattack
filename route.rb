require 'mailgun'
Mailgun::init("key-41q2py_zo0op3evcz7")

route = Route.new(:pattern => 'helper@dattack.mailgun.org', :destination => 'http://dattack.heroku.com/email')
route.upsert()