#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    esStop.sh
## Description: 停止es集群的脚本.
## Version:     1.0
## Author:      mashencai
## Created:     2017-11-15
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
## 安装日记：../hzgc/logs/esStop.log
LOG_FILE=${LOG_DIR}/esStop.log
## es的安装节点，放入数组中
ES_HOSTNAME_LISTS=$(grep ES_InstallNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
ES_HOSTNAME_ARRY=(${ES_HOSTNAME_LISTS//;/ })

#set -x

# 打印系统时间
echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                        | tee  -a  $LOG_FILE

# 停止ES服务
echo ""  | tee -a $LOG_FILE
echo "**********************************************" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "开始停止ES服务......"    | tee -a $LOG_FILE


for hostname in ${ES_HOSTNAME_ARRY[@]};do
	ssh root@$hostname "source /etc/profile; es_pid=\`jps | grep Elasticsearch | gawk '{print \$1}'\`; kill \$es_pid"
	if [ $? -eq 0 ];then
	    echo -e "${hostname} es stop success\n" | tee -a $LOG_FILE
	else 
	    echo -e "${hostname} es stop failed\n" | tee -a $LOG_FILE
	fi
done

echo "" | tee -a $LOG_FILE
echo "停止ES服务完毕."    | tee -a $LOG_FILE

# 验证ES是否停止成功
echo -e "********************验证ES是否停止成功*********************"
sleep 3s
source $(grep Source_File ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
xcall jps | grep -E 'Elasticsearch|jps show as bellow'


set +x
