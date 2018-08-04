#!/bin/bash

########################################
# 
# This is the Spark configuration script. Required input parameters:
# - MY_DNS = (ec2-xx-xxx-xx-xxx.us-west-2.compute.amazonaws.com)
# - AWS_ACCESS_KEY_ID = AWS access key
# - AWS_SECRET_ACCESS_KEY = AWS secret key
# - MASTER_DNS = (ec2-xx-xxx-xx-xxx.us-west-2.compute.amazonaws.com)
# - MASTER_NAME = (ec2-xx-xxx-xx-xxx.us-west-2.compute.amazonaws.com)
# - MASTER_PRIVATE = (ip-xx-x-x-xx)
# - SLAVE_DNS (ec2-xx-xxx-xx-xxx.us-west-2.compute.amazonaws.com)
# - SLAVE_NAME (ip-xx-x-x-xx)
#
########################################

# Source the profile
. ~/.profile

# Store preliminary information from bash input
MY_DNS=$1; shift

# Store AWS credentials from bash input
AWS_ACCESS_KEY_ID=$1; shift
AWS_SECRET_ACCESS_KEY=$1; shift

# Store master information from bash input
MASTER_DNS=$1; shift
MASTER_NAME=$1; shift
MASTER_PRIVATE=$1; shift

# Store slave information from bash input
SLAVE_DNS_NAME=( "$@" )
LEN=${#SLAVE_DNS_NAME[@]}
HALF=$(echo "$LEN/2" | bc)
SLAVE_DNS=( "${SLAVE_DNS_NAME[@]:0:$HALF}" )
SLAVE_NAME=( "${SLAVE_DNS_NAME[@]:$HALF:$HALF}" )



########################################
#
# Taken from https://github.com/InsightDataScience/pegasus/tree/master/config/hadoop/setup_single.sh
# Applied to master and slave nodes.
#
########################################

. ~/.profile

# Set Java path
sed -i 's@${JAVA_HOME}@/usr@g' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
sed -i '$a # Update Hadoop classpath to include share folder \nif [ \"$HADOOP_CLASSPATH\" ]; then \n export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$HADOOP_HOME/share/hadoop/tools/lib/* \nelse \n export HADOOP_CLASSPATH=$HADOOP_HOME/share/hadoop/tools/lib/* \nfi' $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# configure core-site.xml
sed -i '20i <property>\n  <name>fs.defaultFS</name>\n  <value>hdfs://'"$MASTER_NAME"':9000</value>\n</property>' $HADOOP_HOME/etc/hadoop/core-site.xml
sed -i '24i <property>\n  <name>fs.s3.impl</name>\n  <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>\n</property>' $HADOOP_HOME/etc/hadoop/core-site.xml
sed -i '28i <property>\n  <name>fs.s3a.access.key</name>\n  <value>'"${AWS_ACCESS_KEY_ID}"'</value>\n</property>' $HADOOP_HOME/etc/hadoop/core-site.xml
sed -i '32i <property>\n  <name>fs.s3a.secret.key</name>\n  <value>'"${AWS_SECRET_ACCESS_KEY}"'</value>\n</property>' $HADOOP_HOME/etc/hadoop/core-site.xml

# configure yarn-site.xml
sed -i '18i <property>\n  <name>yarn.nodemanager.aux-services</name>\n  <value>mapreduce_shuffle</value>\n</property>' $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i '22i <property>\n  <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>\n  <value>org.apache.hadoop.mapred.ShuffleHandler</value>\n</property>' $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i '26i <property>\n  <name>yarn.resourcemanager.resource-tracker.address</name>\n  <value>'"$MASTER_NAME"':8025</value>\n</property>' $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i '30i <property>\n  <name>yarn.resourcemanager.scheduler.address</name>\n  <value>'"$MASTER_NAME"':8030</value>\n</property>' $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i '34i <property>\n  <name>yarn.resourcemanager.address</name>\n  <value>'"$MASTER_NAME"':8050</value>\n</property>' $HADOOP_HOME/etc/hadoop/yarn-site.xml

# configure mapred-site.xml
cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml
sed -i '20i <property>\n  <name>mapreduce.jobtracker.address</name>\n  <value>'"$MASTER_NAME"':54311</value>\n</property>' $HADOOP_HOME/etc/hadoop/mapred-site.xml
sed -i '24i <property>\n  <name>mapreduce.framework.name</name>\n  <value>yarn</value>\n</property>' $HADOOP_HOME/etc/hadoop/mapred-site.xml
sed -i '28i <property>\n <name>mapreduce.application.classpath</name>\n <value>'"$HADOOP_HOME"'/share/hadoop/mapreduce/*,'"$HADOOP_HOME"'/share/hadoop/mapreduce/lib/*,'"$HADOOP_HOME"'/share/hadoop/common/*,'"$HADOOP_HOME"'/share/hadoop/common/lib/*,'"$HADOOP_HOME"'/share/hadoop/tools/lib/*</value> \n </property>' $HADOOP_HOME/etc/hadoop/mapred-site.xml

########################################
#
# Taken from https://github.com/InsightDataScience/pegasus/tree/master/config/hadoop/config_hosts.sh
# Applied to master node.
#
########################################

. ~/.profile

if [[ $MY_DNS = $MASTER_NAME ]]
then

    # add for additional datanodes
    sudo sed -i '2i '"$MASTER_DNS"' '"$MASTER_PRIVATE"'' /etc/hosts

    for (( i=0; i<$HALF; i++))
    do
        echo $i ${SLAVE_DNS[$i]} ${SLAVE_NAME[$i]}
        sudo sed -i '3i '"${SLAVE_DNS[$i]}"' '"${SLAVE_NAME[$i]}"'' /etc/hosts
    done
fi

########################################
#
# Taken from https://github.com/InsightDataScience/pegasus/tree/master/config/hadoop/config_namenode.sh
# Applied to master node.
#
########################################

. ~/.profile

if [[ $MY_DNS = $MASTER_NAME ]]
then

	# configure hdfs-site.xml
	sed -i '20i <property>\n  <name>dfs.replication</name>\n  <value>3</value>\n</property>' $HADOOP_HOME/etc/hadoop/hdfs-site.xml
	sed -i '24i <property>\n  <name>dfs.namenode.name.dir</name>\n  <value>file:///usr/local/hadoop/hadoop_data/hdfs/namenode</value>\n</property>' $HADOOP_HOME/etc/hadoop/hdfs-site.xml
	sudo mkdir -p $HADOOP_HOME/hadoop_data/hdfs/namenode

	touch $HADOOP_HOME/etc/hadoop/masters
	echo $MASTER_PRIVATE | cat >> $HADOOP_HOME/etc/hadoop/masters

	# add for additional datanodes
	touch $HADOOP_HOME/etc/hadoop/slaves.new
	for name in ${SLAVE_NAME[@]} 
	do
    	echo $name | cat >> $HADOOP_HOME/etc/hadoop/slaves.new
	done
	mv $HADOOP_HOME/etc/hadoop/slaves.new $HADOOP_HOME/etc/hadoop/slaves

	sudo chown -R ubuntu $HADOOP_HOME
fi

########################################
#
# Taken from https://github.com/InsightDataScience/pegasus/tree/master/config/hadoop/config_datanode.sh
# Applied to master and slave nodes.
#
########################################

. ~/.profile

if [[ $MY_DNS != $MASTER_NAME ]]
then
  # configure hdfs-site.xml
  sed -i '20i <property>\n  <name>dfs.replication</name>\n  <value>3</value>\n</property>' $HADOOP_HOME/etc/hadoop/hdfs-site.xml
  sed -i '24i <property>\n  <name>dfs.datanode.data.dir</name>\n  <value>file:///usr/local/hadoop/hadoop_data/hdfs/datanode</value>\n</property>' $HADOOP_HOME/etc/hadoop/hdfs-site.xml

  sudo mkdir -p $HADOOP_HOME/hadoop_data/hdfs/datanode

  sudo chown -R ubuntu $HADOOP_HOME
fi

########################################
#
# Taken from https://github.com/InsightDataScience/pegasus/tree/master/config/hadoop/format_hdfs.sh
# Applied to slave nodes.
#
########################################

. ~/.profile

if [[ $MY_DNS = $MASTER_NAME ]]
then
	echo 'HERE'
	hdfs namenode -format
fi

########################################
#
# Taken from https://github.com/InsightDataScience/pegasus/tree/master/config/spark/setup_single.sh
# Applied to master and slave nodes.
#
########################################

. ~/.profile

spark_lib=${SPARK_HOME}/lib/

if [[ ! -d ${spark_lib} ]]; then
	mkdir ${spark_lib}
fi

cp ${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-*.jar ${spark_lib}
cp ${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-*.jar ${spark_lib}

cp ${SPARK_HOME}/conf/spark-env.sh.template ${SPARK_HOME}/conf/spark-env.sh
cp ${SPARK_HOME}/conf/spark-defaults.conf.template ${SPARK_HOME}/conf/spark-defaults.conf

# Configure spark-env.sh
OVERSUBSCRIPTION_FACTOR=3
WORKER_CORES=$(echo "$(nproc)*${OVERSUBSCRIPTION_FACTOR}" | bc)
sed -i '6i export JAVA_HOME=/usr' ${SPARK_HOME}/conf/spark-env.sh
sed -i '7i export SPARK_PUBLIC_DNS="'$MY_DNS'"' ${SPARK_HOME}/conf/spark-env.sh
sed -i '8i export SPARK_WORKER_CORES='${WORKER_CORES}'' ${SPARK_HOME}/conf/spark-env.sh
sed -i '9i export DEFAULT_HADOOP_HOME='${HADOOP_HOME}'' ${SPARK_HOME}/conf/spark-env.sh


# Configure spark-defaults.conf
hadoop_aws_jar=$(find ${spark_lib} -type f | grep hadoop-aws)
aws_java_sdk_jar=$(find ${spark_lib} -type f | grep aws-java-sdk)
sed -i '21i spark.hadoop.fs.s3a.impl org.apache.hadoop.fs.s3a.S3AFileSystem' ${SPARK_HOME}/conf/spark-defaults.conf
sed -i '22i spark.executor.extraClassPath '"${aws_java_sdk_jar}"':'"${hadoop_aws_jar}"'' ${SPARK_HOME}/conf/spark-defaults.conf
sed -i '23i spark.driver.extraClassPath '"${aws_java_sdk_jar}"':'"${hadoop_aws_jar}"'' ${SPARK_HOME}/conf/spark-defaults.conf

########################################
#
# Taken from https://github.com/InsightDataScience/pegasus/tree/master/config/spark/config_workers.sh
# Applied to master node.
#
########################################

. ~/.profile

touch $SPARK_HOME/conf/slaves;
for dns in ${SLAVE_DNS[@]}
do
  echo $dns | cat >> $SPARK_HOME/conf/slaves;
done
