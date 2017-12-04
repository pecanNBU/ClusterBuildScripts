#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    delete_env_variable.sh
## Description: 删除系统中环境变量
##              实现自动化的脚本
## Version:     1.0
## Author:      caodabao
## Created:     2017-11-29
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
## 日记目录
LOG_DIR=${ROOT_HOME}/logs
## 日记文件
LOG_FILE=${LOG_DIR}/delete_env_variable.log
##etc所在目录
ETC_FILE=/opt/source

mkdir -p ${LOG_DIR} 

echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"   | tee -a $LOG_FILE

echo “读取环境变量，请稍候.......”  | tee -a $LOG_FILE
##环境变量起始行
start_line="#JAVA_HOME"
start_num=$(cat -n ${ETC_FILE} |grep ${start_line} | awk  '{print $1}')
if [ -n "$start_num" ];then
    echo "删除环境变量，请稍候......."  | tee -a $LOG_FILE 
    sed -i '/#JAVA_HOME/,$d' $ETC_FILE
else 
    echo “读取环境变量失败。请检查环境变量是否存在”  | tee -a $LOG_FILE
    exit 1
fi
    
set +x	
