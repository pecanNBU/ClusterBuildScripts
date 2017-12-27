#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    thriftServerStart.sh
## Description: 启动Spark sql thriftServer的脚本.
## Version:     1.0
## Author:      qiaokaifeng、mashencai
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
LOG_FILE=${LOG_DIR}/thriftServerStart.log
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## SPARK_INSTALL_HOME spark 安装目录
SPARK_INSTALL_HOME=${INSTALL_HOME}/Spark
## SPARK_HOME  spark 根目录
SPARK_HOME=${INSTALL_HOME}/Spark/spark

echo "It's running the  thriftserver, it calls $SPARK_HOME/sbin/start-thriftserver.sh"
if [ $# != 5 ] ; then 
echo "=================================================================================="
echo " Default parameters of master is yarn."
echo " USAGE: $0 driver_memory executor_memory driver_cores executor_cores num_executors" 
echo " e.g.: $0 1g 2g 5 5 5" 
echo "=================================================================================="
exit 1; 
fi

$SPARK_HOME/sbin/start-thriftserver.sh --master yarn --driver-memory $1  --executor-memory $2   --driver-cores $3  --executor-cores $4  --num-executors $5



set +x
