#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    rocketmqStop.sh
## Description: 停止rocket集群的脚本.
## Version:     1.0
## Author:      caodabao
## Created:     2017-11-10
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
LOG_FILE=${LOG_DIR}/rocketmqStart.log
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## ROCKETMQ_HOME  rocketmq 根目录
ROCKETMQ_HOME=${INSTALL_HOME}/RocketMQ/rocketmq

NameServer_Host=$(grep RocketMQ_Namesrv ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
Broker_Hosts=$(grep RocketMQ_Broker ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
Broker_HostArr=(${Broker_Hosts//;/ })  

NameServer_IP=$(cat /etc/hosts|grep "$NameServer_Host" | awk '{print $1}')

ssh root@$NameServer_Host "source /etc/profile; sh ${ROCKETMQ_HOME}/bin/mqshutdown namesrv"
    if [ $? -eq 0 ];then
        echo  -e 'NameServer stop success \n'
    else 
        echo  -e 'NameServer stop failed \n'
    fi
	
broker_num=1
for host_name in ${Broker_HostArr[@]}
do
    ssh root@$host_name "source /etc/profile; sh ${ROCKETMQ_HOME}/bin/mqshutdown broker"
    broker_num=$(($broker_num+1))
    if [ $? -eq 0 ];then
        echo  -e "Broker$broker_num stop success \n"
    else 
        echo  -e "Broker$broker_num stop failed \n"
    fi
done


# 等待三秒后再验证RocketMq是否停止成功
echo -e "********************验证RocketMq是否停止成功*********************"
echo -e "验证Namesrv.."
sleep 3s
source $(grep Source_File ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
xcall jps | grep -E 'NamesrvStartup|jps show as bellow'
echo -e "验证Broker.."
sleep 2s
xcall jps | grep -E 'BrokerStartup|jps show as bellow'