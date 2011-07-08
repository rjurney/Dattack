# Run dependent services and setup Amazon SQS

# Run Voldemort in the background
deps/voldemort-0.81/bin/voldemort-server.sh config/single_node_cluster > /tmp/voldemort.log &

# Create SQS Queue
jruby bin/create_sqs_queue.rb