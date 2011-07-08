#!/bin/bash
cd
cd voldemort-0.81
nohup bin/voldemort-server.sh config/single_node_cluster > /tmp/voldemort.log &