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
## 获取当前机器core数量
CORES=$(cat /proc/cpuinfo| grep "processor"| wc -l)
## Node Manager 的个数
Yarn_NumOfNodeManger=$(grep Yarn_NumOfNodeManger ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## 总的Executor 个数 
Tatal_Executors=$(echo "${Yarn_NumOfNodeManger}*${CORES}" | bc)
## SPARK_INSTALL_HOME spark 安装目录
SPARK_INSTALL_HOME=${INSTALL_HOME}/Spark
## SPARK_HOME  spark 根目录
SPARK_HOME=${INSTALL_HOME}/Spark/spark

echo ""
echo "It's running the  thriftserver, it calls $SPARK_HOME/sbin/start-thriftserver.sh"
echo "=================================================================================="
echo " Default parameters of master is yarn."
echo " USAGE: $0 driver_memory executor_memory driver_cores executor_cores num_executors" 
echo " e.g.: $0 1g 2g 5 5 5" 
echo " 如果一个参数都不传，默认的参数配置是 8g 4g 4 4  所有节点总的核数"
echo "=================================================================================="

if [[ $# != 5 && $# != 0 ]]; then 
	exit 1; 
fi

DRIVER_MEN=${1:-"8g"}
EXECUTOR_MEN=${2:-"4g"}
DRIVER_CORES=${3:-"4"}
EXECUTOR_CORES=${4:-"4"}
NUM_EXCUTORS=${5:-$Tatal_Executors}

$SPARK_HOME/sbin/start-thriftserver.sh --master yarn --driver-memory ${DRIVER_MEN}  --executor-memory ${EXECUTOR_MEN}   --driver-cores ${DRIVER_CORES}  --executor-cores ${EXECUTOR_CORES}  --num-executors ${NUM_EXCUTORS}



set +x
