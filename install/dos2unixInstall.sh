#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    dos2unixInstall.sh
## Description: 安装 dos2unix 工具，解决windows下编辑过的脚本在linux下执行时格式不一致的问题
##              实现自动化的脚本
## Version:     1.0
## Author:      mashencai
## Created:     2017-12-12
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
LOG_FILE=${LOG_DIR}/dos2unixInstall.log
## dos2unix rpm 软件目录
DOS2UNIX_RPM_DIR=${ROOT_HOME}/component/basic_suports/dos2unixRpm
## 基础工具安装路径
INSTALL_HOME_BASIC=$(grep System_SuportDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## dos2unix rpm 软件最终目录
DOS2UNIX_RPM_INSTALL_HOME=${INSTALL_HOME_BASIC}/dos2unixRpm
## dos2unix的安装节点，集群所有主机名，放入数组中
CLUSTER_HOSTNAME_LISTS=$(grep Cluster_HostName ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
CLUSTER_HOSTNAME_ARRY=(${CLUSTER_HOSTNAME_LISTS//;/ })


if [ ! -d $LOG_DIR ];then
    mkdir -p $LOG_DIR;
fi

echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE

for name in ${CLUSTER_HOSTNAME_ARRY[@]}
do
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "intall dos2unix in  ${name}...... "  | tee -a $LOG_FILE
    ssh $name "mkdir -p  ${DOS2UNIX_RPM_INSTALL_HOME}" 
    scp -r  ${DOS2UNIX_RPM_DIR}/* $name:${DOS2UNIX_RPM_INSTALL_HOME}  > /dev/null
    if [ $? == 0 ];then
        echo "scp dos2unix to the ${DOS2UNIX_RPM_INSTALL_HOME} done !!!"  | tee -a $LOG_FILE
    else 
        echo "scp dos2unix to the ${DOS2UNIX_RPM_INSTALL_HOME} failed !!!"  | tee -a $LOG_FILE
    fi
    ssh root@$name "rpm -ivh ${DOS2UNIX_RPM_INSTALL_HOME}/dos2unix-3.1-37.el6.x86_64.rpm; which dos2unix; rm -rf ${INSTALL_HOME_BASIC}"  
done

set +x
