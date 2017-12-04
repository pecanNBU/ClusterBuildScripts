#!/bin/bash

#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    hiveStop.sh
## Description: 关闭HiveServer服务的脚本.
## Version:     1.0
## Author:      mashencai
## Created:     2017-11-24
################################################################################


cd `dirname $0`
## 脚本所在目录：../hzgc/service
BIN_DIR=`pwd`
cd ..
## 安装包根目录：../hzgc
ROOT_HOME=`pwd`
## 配置文件目录：../hzgc/conf
CONF_DIR=${ROOT_HOME}/conf
## 安装日记目录：../hzgc/logs
LOG_DIR=${ROOT_HOME}/logs
## 安装日记
LOG_FILE=${LOG_DIR}/hiveStop.log

#set -x

# 打印系统时间
echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                        | tee  -a  $LOG_FILE

# 停止hive服务
echo ""  | tee -a $LOG_FILE
echo "**********************************************" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "关闭HiveServer服务......"    | tee -a $LOG_FILE


for hostname in $(cat ${CONF_DIR}/hostnamelists.properties);do
	ssh root@$hostname "source /etc/profile; hive_pid=\`jps | grep RunJar | grep -v grep | gawk '{print \$1}'\`; kill \$hive_pid"
	if [ $? -eq 0 ];then
	    echo -e "${hostname} hive stop success\n" | tee -a $LOG_FILE
	else 
	    echo -e "${hostname} hive stop failed\n" | tee -a $LOG_FILE
	fi
done

# 验证Hive是否停止成功
echo -e "********************验证Hive是否停止成功*********************"
source /etc/profile
xcall jps | grep RunJar

echo "" | tee -a $LOG_FILE
echo "停止hive服务完毕."    | tee -a $LOG_FILE

set +x

