#!/bin/bash
################################################################################
## Copyright:     HZGOSUN Tech. Co, BigData
## Filename:      logconfig.sh
## Description:   配置组件的日志文件目录脚本
## Version:       1.0
## Author:        mashencai
## Created:       2017-11-23
################################################################################

set -x

cd `dirname $0` ## 进入当前目录
BIN_DIR=`pwd` ## 脚本所在目录：service
cd ..
ROOT_HOME=`pwd` ## 安装包根目录
CONF_DIR=${ROOT_HOME}/conf ## 配置文件目录：conf

## 集群组件的日志文件目录 /opt/logs
LOGS_PATH=$(sed -n '8p' ${CONF_DIR}/install_home.properties)
ES_LOG_PATH=${LOGS_PATH}/elastic ### es的log目录
ROCKETMQ_LOG_PATH=${LOGS_PATH}/rocketmq
SPARK_LOG_PATH=${LOGS_PATH}/spark
KAFKA_LOG_PATH=${LOGS_PATH}/kafka
HIVE_LOG_PATH=${LOGS_PATH}/hive
HBASE_LOG_PATH=${LOGS_PATH}/hbase
ZK_LOG_PATH=${LOGS_PATH}/zookeeper
HADOOP_LOG_PATH=${LOGS_PATH}/hadoop



#创建总日志目录及es日志目录，并设置es目录权限，这样执行es启动脚本才能启动成功：
for hostname in $(cat ${CONF_DIR}/hostnamelists.properties);do
	ssh root@${hostname} "mkdir -p ${LOGS_PATH};mkdir -p ${ES_LOG_PATH};chmod -R 777 ${ES_LOG_PATH}"
done

#创建mq/spark/kafka/hive/hbase/zk/hadoop的日志目录
for hostname in $(cat ${CONF_DIR}/hostnamelists.properties);do
	ssh root@${hostname} "mkdir -p ${ES_LOG_PATH};mkdir -p ${ROCKETMQ_LOG_PATH};mkdir -p ${SPARK_LOG_PATH};mkdir -p ${KAFKA_LOG_PATH};mkdir -p ${HIVE_LOG_PATH};mkdir -p ${HBASE_LOG_PATH};mkdir -p ${ZK_LOG_PATH};mkdir -p ${HADOOP_LOG_PATH}"
done

set +x
