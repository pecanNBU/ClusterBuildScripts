#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    kafkaStart.sh
## Description: 启动kafka集群的脚本.
## Version:     1.0
## Author:      qiaokaifeng
## Editor:            mashencai
## Created:     2017-10-24
################################################################################

#set -x

cd `dirname $0`
## 脚本所在目录
BIN_DIR=`pwd`
cd ..
## 安装包根目录
ROOT_HOME=`pwd`
## 配置文件目录
CONF_DIR=${ROOT_HOME}/conf
## 安装日记目录
LOG_DIR=${ROOT_HOME}/logs
## 安装日记目录
LOG_FILE=${LOG_DIR}/kafkaStart.log
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## kafka的安装节点，放入数组中
KAFKA_HOSTNAME_LISTS=$(grep Kafka_InstallNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
KAFKA_HOSTNAME_ARRY=(${KAFKA_HOSTNAME_LISTS//;/ })

## KAFKA_INSTALL_HOME kafka 安装目录
KAFKA_INSTALL_HOME=${INSTALL_HOME}/Kafka
## KAFKA_HOME  kafka 根目录
KAFKA_HOME=${INSTALL_HOME}/Kafka/kafka

## 集群组件的日志文件目录:
CLUSTER_LOGSDIR=$(grep Cluster_LOGSDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)

echo "启动Kafka"
for name in ${KAFKA_HOSTNAME_ARRY[@]}
do       
    ssh root@$name "mkdir -p  ${CLUSTER_LOGSDIR}/kafka/kafka-logs"
    ssh root@$name "touch  ${CLUSTER_LOGSDIR}/kafka/kafka-logs/kafka-server.log"
	ssh root@$name "source /etc/profile;nohup ${INSTALL_HOME}/Kafka/kafka/bin/kafka-server-start.sh ${INSTALL_HOME}/Kafka/kafka/config/server.properties >>${CLUSTER_LOGSDIR}/kafka/kafka-logs/kafka-server.log 2>&1 &"
done

# 启动Kafka的ui工具kafka-manager
echo "kafka-manager"
cd ${KAFKA_HOME}
chmod -R 755 kafka-manager/
cd kafka-manager/
nohup bin/kafka-manager -Dconfig.file=${KAFKA_HOME}/kafka-manager/conf/application.conf &
echo "kafka-manager已启动,请到浏览器访问..(端口号9000)"

# 等待三秒后再验证Kafka是否启动成功
echo -e "********************验证Kafka是否启动成功*********************"
sleep 3s
source $(grep Source_File ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
xcall jps | grep -E 'Kafka|jps show as bellow'
