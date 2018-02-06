#!/bin/bash
################################################################################
## Copyright:     HZGOSUN Tech. Co, BigData
## Filename:      logconfig.sh
## Description:   配置组件的日志文件目录脚本
## Version:       1.0
## Author:        mashencai
## Created:       2017-11-23
################################################################################

#set -x

cd `dirname $0` ## 进入当前目录
BIN_DIR=`pwd` ## 脚本所在目录：service
cd ..
ROOT_HOME=`pwd` ## 安装包根目录
CONF_DIR=${ROOT_HOME}/conf ## 配置文件目录：conf

## 集群组件的日志文件目录 /opt/logs
LOGS_PATH=$(grep Cluster_LOGSDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
mkdir -p ${LOGS_PATH}

ES_LOG_PATH=${LOGS_PATH}/elastic ### es的log目录
ROCKETMQ_LOG_PATH=${LOGS_PATH}/rocketmq
SPARK_LOG_PATH=${LOGS_PATH}/spark
KAFKA_LOG_PATH=${LOGS_PATH}/kafka
HIVE_LOG_PATH=${LOGS_PATH}/hive
HBASE_LOG_PATH=${LOGS_PATH}/hbase
ZK_LOG_PATH=${LOGS_PATH}/zookeeper
HADOOP_LOG_PATH=${LOGS_PATH}/hadoop


# 打印系统时间
echo ""
echo ""
echo "==================================================="
echo "$(date "+%Y-%m-%d  %H:%M:%S")"

##### 创建所有组件log目录
echo "创建rocketmq的log目录：${ROCKETMQ_LOG_PATH}..."
echo "创建spark的log目录：${SPARK_LOG_PATH}..."
echo "创建kafka的log目录：${KAFKA_LOG_PATH}..."
echo "创建hive的log目录：${HIVE_LOG_PATH}..."
echo "创建hbase的log目录：${HBASE_LOG_PATH}..."
echo "创建zookeeper的log目录：${ZK_LOG_PATH}..."
echo "创建hadoop的log目录：${HADOOP_LOG_PATH}..."
## 集群所有节点主机名，放入数组中
CLUSTER_HOSTNAME_LISTS=$(grep Cluster_HostName ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
CLUSTER_HOSTNAME_ARRY=(${CLUSTER_HOSTNAME_LISTS//;/ })
#在所有节点上创建mq/spark/kafka/hive/hbase/zk/hadoop的日志目录
for hostname in ${CLUSTER_HOSTNAME_ARRY[@]};do
	ssh root@${hostname} "mkdir -p ${LOGS_PATH};
	mkdir -p ${ES_LOG_PATH};
	mkdir -p ${ROCKETMQ_LOG_PATH};
	mkdir -p ${SPARK_LOG_PATH};
	mkdir -p ${KAFKA_LOG_PATH};
	mkdir -p ${HIVE_LOG_PATH};
	mkdir -p ${HBASE_LOG_PATH};
	mkdir -p ${ZK_LOG_PATH};
	mkdir -p ${HADOOP_LOG_PATH};
	chmod -R 777 ${LOGS_PATH}"
done

##### 创建es log目录
echo "创建es的log目录：${ES_LOG_PATH}..."
## es的安装节点，放入数组中
ES_HOSTNAME_LISTS=$(grep ES_InstallNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
ES_HOSTNAME_ARRY=(${ES_HOSTNAME_LISTS//;/ })
#在es安装节点上创建总日志目录及es日志目录，并设置es目录权限，这样执行es启动脚本才能启动成功：
for hostname in ${ES_HOSTNAME_ARRY[@]};do
	ssh root@${hostname} "mkdir -p ${ES_LOG_PATH};chmod -R 777 ${ES_LOG_PATH}"
done



set +x
