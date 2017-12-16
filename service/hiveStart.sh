#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    hiveStart.sh
## Description: 启动hive集群的脚本.
## Version:     1.0
## Author:      qiaokaifeng（修改：mashencai）
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
LOG_FILE=${LOG_DIR}/hiveStart.log
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## 集群组件的日志文件目录
ALL_LOG_PATH=$(grep Cluster_LOGSDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## hive的启动停止日志目录
HIVE_LOG_PATH=${ALL_LOG_PATH}/hive
## hive的启动停止日志目录
HIVE_LOG_FILE=${HIVE_LOG_PATH}/hive-log.log

## hive的安装节点，放入数组中
HIVE_HOSTNAME_LISTS=$(grep Meta_ThriftServer ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
HIVE_HOSTNAME_ARRY=(${HIVE_HOSTNAME_LISTS//;/ })


# 创建日志目录
for name in ${HIVE_HOSTNAME_ARRY[@]}
do
	ssh root@$name "if [ ! -x '${HIVE_LOG_PATH}' ]; then mkdir -p '${HIVE_LOG_PATH}' ; fi"
	ssh root@$name "if [ ! -x '${HIVE_LOG_FILE}' ]; then touch '${HIVE_LOG_FILE}' ;fi"
done

# （马燊偲）

for name in ${HIVE_HOSTNAME_ARRY[@]}
do
	# 判断Hive是否已经启动：进程中是否已经有runjar，假如有的话，不启动HiveServer和Hivemetastore
	hive_start=$(ssh root@${name} "source /etc/profile;jps | grep RunJar | grep -v grep | gawk '{print $1}'")
	if [ "${hive_start}" = "" ];then   # 若该字符串为空，说明hive未启动，需要执行启动脚本
		## 启动hiveserver2
		echo -e "启动HiveServer服务："
		ssh root@$name "nohup ${INSTALL_HOME}/Hive/hive/bin/hive --service hiveserver2 >${HIVE_LOG_FILE} 2>&1 &"
		if [ $? -eq 0 ];then
			echo -e '$name HiveServer startsuccess \n'
		else 
			echo -e '$name HiveServer startfailed \n'
		fi
		
		## 启动metastore
		echo -e "启动Hivemetastore服务："
		ssh root@$name "nohup ${INSTALL_HOME}/Hive/hive/bin/hive --service metastore >${HIVE_LOG_FILE} 2>&1 &"
		if [ $? -eq 0 ];then
			echo -e '$name Hive metastore startsuccess \n'
		else
			echo -e '$name Hive metastore startfailed \n'
		fi	
	else
		echo "$name上Hive已启动,不执行启动脚本."
	fi
		
done


# 验证Hive是否启动成功
echo -e "********************验证Hive是否启动成功*********************"
sleep 3s
source $(grep Source_File ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
xcall jps | grep -E 'RunJar|jps show as bellow'

set +x
