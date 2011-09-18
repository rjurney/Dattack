# Download and install deps
mkdir deps
cd deps

# Get the environe#ment vars from me

# Download, install and configure Voldemort
wget https://github.com/downloads/voldemort/voldemort/voldemort-0.81.tar.gz
tar -xvzf voldemort-0.81.tar.gz
cp ../conf/stores.xml ./config/single_node_cluster/config/stores.xml

# Clone and install my branch of blueprints
git clone git@github.com:rjurney/blueprints.git
cd blueprints
mvn clean install # May require maven 2.X
cd .. # back to deps

# Clone and install my branch of pacer
git clone git@github.com:rjurney/pacer.git
cd pacer
mvn clean install
jgem build pacer.gemspec
jgem install pacer-0.7.1-java.gem # Add sudo if this fails?
cd ..

# Now you are ready to run stage_app.sh to get dependent services running!# Run dependent services and setup Amazon SQS

# Run Voldemort in the background
deps/voldemort-0.81/bin/voldemort-server.sh config/single_node_cluster > /tmp/voldemort.log &

# Create SQS Queue
jruby bin/create_sqs_queue.rb