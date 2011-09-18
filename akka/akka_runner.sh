#!/bin/bash
CLASSPATH=./lib/java/akka/:./lib/java/akka/akka_2.8.0-0.10.jar:./lib/java/akka/akka-core_2.8.0-0.10.jar:./lib/java/akka/scala-library.jar jruby -Ilib $1
