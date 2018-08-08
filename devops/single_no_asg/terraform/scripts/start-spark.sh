#!/bin/bash

. ~/.profile; $HADOOP_HOME/sbin/start-dfs.sh
. ~/.profile; $HADOOP_HOME/sbin/start-yarn.sh
. ~/.profile; $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver