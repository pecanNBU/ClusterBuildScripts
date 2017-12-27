#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    create-global-env.sh
## Description: 配置环境变量和服务启动目录。
## Version:     1.0
## Author:      lidiliang
## Created:     2017-10-23
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
LOG_FILE=${LOG_DIR}/create-global-env.log
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## 集群所有节点主机名，放入数组中
CLUSTER_HOSTNAME_LISTS=$(grep Cluster_HostName ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
CLUSTER_HOSTNAME_ARRY=(${CLUSTER_HOSTNAME_LISTS//;/ })


if [ ! -d $LOG_DIR ];then
    mkdir -p $LOG_DIR;
fi

echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE

cp ${ROOT_HOME}/service/temporary_environment_variable.sh  ${ROOT_HOME}/env_bigdata.sh
for host in ${CLUSTER_HOSTNAME_ARRY[@]}
do
    echo "scp configuration to node ${host}"
    scp  -r ${ROOT_HOME}/service  ${ROOT_HOME}/conf ${ROOT_HOME}/tool env_bigdata.sh root@${host}:/opt/hzgc  > /dev/null
	ssh root@${host}  "chmod -R 755 /opt/hzgc"
done




set +x

