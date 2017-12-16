#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    kafkaStop.sh
## Description: 关闭kafka集群的脚本.
## Version:     1.0
## Author:      qiaokaifeng
## Editor:      mashencai
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


echo "关闭Kafka"
# 删除kafka-manager的PID文件
cd ${KAFKA_HOME}/kafka-manager
rm -f RUNNING_PID

# 关闭每个节点上的Kafka和kafka-manager进程
for name in ${KAFKA_HOSTNAME_ARRY[@]}
do
	# 查找Kafka进程，会有Kafka与kafka-manager两个进程，因此将这两个进程号输出到文件，循环读取删除
	ssh root@$name '
	ps ax | grep -i 'kafka' | grep java | grep -v grep | awk "{print \$1}" > ${BIN_DIR}/kafka_del.tmp;
	for PID in $(cat ${BIN_DIR}/kafka_del.tmp);do
		if [ -z "$PID" ]; then
			echo "No kafka server to stop";
			exit 1;
		else
			kill -s TERM $PID;
			echo "kafka stop success";
		fi;
	done;
	rm -f ${BIN_DIR}/kafka_del.tmp'

done



# 验证Kafka是否停止成功
echo -e "********************验证Kafka是否停止成功*********************"
sleep 5s
source $(grep Source_File ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
xcall jps | grep -E 'Kafka|jps show as bellow'

set +x