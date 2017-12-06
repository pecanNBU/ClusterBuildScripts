#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    kafkaStart.sh
## Description: 启动kafka集群的脚本.
## Version:     1.0
## Author:      qiaokaifeng
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
INSTALL_HOME=$(sed -n '4p' ${CONF_DIR}/install_home.properties)
## KAFKA_INSTALL_HOME kafka 安装目录
KAFKA_INSTALL_HOME=${INSTALL_HOME}/Kafka
## KAFKA_HOME  kafka 根目录
KAFKA_HOME=${INSTALL_HOME}/Kafka/kafka

echo "启动Kafka"
for name in $(cat ${CONF_DIR}/hostnamelists.properties)
do       
    ssh root@$name "mkdir -p  ${INSTALL_HOME}/Kafka/kafka/kafka-logs"
    ssh root@$name "touch  ${INSTALL_HOME}/Kafka/kafka/kafka-logs/kafka-server.log"
	ssh root@$name "source /etc/profile;nohup ${INSTALL_HOME}/Kafka/kafka/bin/kafka-server-start.sh ${INSTALL_HOME}/Kafka/kafka/config/server.properties >>${INSTALL_HOME}/Kafka/kafka/kafka-logs/kafka-server.log 2>&1 &"
done

# 启动Kafka的ui工具kafka-manager
echo "kafka-manager"
cd ${KAFKA_HOME}
chmod -R 755 kafka-manager/
cd kafka-manager/
nohup bin/kafka-manager -Dconfig.file=${KAFKA_HOME}/kafka-manager/conf/application.conf &


# 验证Kafka是否启动成功
echo -e "********************验证Kafka是否启动成功*********************"
source /etc/profile
xcall jps | grep Kafka
