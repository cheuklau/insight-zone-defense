#!/bin/bash

. ~/.profile

spark_lib=${SPARK_HOME}/lib/

if [ ! -d ${spark_lib} ]; then
	mkdir ${spark_lib}
fi

cp ${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-*.jar ${spark_lib}
cp ${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-*.jar ${spark_lib}

cp ${SPARK_HOME}/conf/spark-env.sh.template ${SPARK_HOME}/conf/spark-env.sh
cp ${SPARK_HOME}/conf/spark-defaults.conf.template ${SPARK_HOME}/conf/spark-defaults.conf

# configure spark-env.sh
OVERSUBSCRIPTION_FACTOR=3
WORKER_CORES=$(echo "$(nproc)*${OVERSUBSCRIPTION_FACTOR}" | bc)
sed -i '6i export JAVA_HOME=/usr' ${SPARK_HOME}/conf/spark-env.sh
sed -i '7i export SPARK_PUBLIC_DNS="'$1'"' ${SPARK_HOME}/conf/spark-env.sh
sed -i '8i export SPARK_WORKER_CORES='${WORKER_CORES}'' ${SPARK_HOME}/conf/spark-env.sh
sed -i '9i export DEFAULT_HADOOP_HOME='${HADOOP_HOME}'' ${SPARK_HOME}/conf/spark-env.sh

# Download postgresql JAR and place it in spark directory
POSTGRESQL_URL=https://jdbc.postgresql.org/download/postgresql-42.2.4.jar
POSTGRESQL_JAR=postgresql-42.2.4.jar
sudo wget ${POSTGRESQL_URL} -P ${spark_lib}
sudo chown -R ubuntu:ubuntu ${spark_lib}/${POSTGRESQL_JAR}

# configure spark-defaults.conf
hadoop_aws_jar=$(find ${spark_lib} -type f | grep hadoop-aws)
aws_java_sdk_jar=$(find ${spark_lib} -type f | grep aws-java-sdk)
POSTGRESQL_JAR_PATH=${spark_lib}${POSTGRESQL_JAR}
sed -i '21i spark.hadoop.fs.s3a.impl org.apache.hadoop.fs.s3a.S3AFileSystem' ${SPARK_HOME}/conf/spark-defaults.conf
sed -i '22i spark.executor.extraClassPath '"${aws_java_sdk_jar}"':'"${hadoop_aws_jar}"':'"${POSTGRESQL_JAR_PATH}"'' ${SPARK_HOME}/conf/spark-defaults.conf
sed -i '23i spark.driver.extraClassPath '"${aws_java_sdk_jar}"':'"${hadoop_aws_jar}"':'"${POSTGRESQL_JAR_PATH}"'' ${SPARK_HOME}/conf/spark-defaults.conf