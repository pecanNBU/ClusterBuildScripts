#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    rocketmqStart.sh
## Description: 启动rocket集群的脚本.
## Version:     1.0
## Author:      caodabao
## Created:     2017-11-10
################################################################################


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
## RocketMQ根目录
ROCKETMQ_HOME=${INSTALL_HOME}/RocketMQ/rocketmq
##NameServer的主机名和ip地址
NameServer_Host=$(grep RocketMQ_Namesrv ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
Broker_Hosts=$(grep RocketMQ_Broker ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
Broker_HostArr=(${Broker_Hosts//;/ })  

NameServer_IP=$(cat /etc/hosts|grep "$NameServer_Host" | awk '{print $1}')
##NameServer的端口号
NameServer_Port="$NameServer_IP:9876"


ssh root@$NameServer_Host "source /etc/profile;chmod 755 ${ROCKETMQ_HOME}/bin/*; mkdir -p $LOG_DIR; nohup ${ROCKETMQ_HOME}/bin/mqnamesrv -n ${NameServer_IP}:9876 >> ${LOG_FILE} 2>&1 &"
if [ $? -eq 0 ];then
    echo  -e 'NameServer start success \n'
else 
    echo  -e 'NameServer start failed \n'
fi

broker_num=1
for host_name in ${Broker_HostArr[@]}
do
    ssh root@${host_name} "mkdir -p $LOG_DIR"
    ssh root@${host_name} "source /etc/profile;chmod 755 ${ROCKETMQ_HOME}/bin/*; nohup ${ROCKETMQ_HOME}/bin/mqbroker -n ${NameServer_IP}:9876 -c ${ROCKETMQ_HOME}/conf/2m-noslave/broker-$broker_num.properties >> ${LOG_FILE} 2>&1 & "
    broker_num=$(($broker_num+1))
    if [ $? -eq 0 ];then
        echo  -e "Broker$broker_num start success \n"
    else 
        echo  -e "Broker$broker_num start failed \n"
    fi
done

ssh root@$NameServer_Host "source /etc/profile; nohup java -jar ${ROCKETMQ_HOME}/lib/rocketmq-console-ng-1.0.0.jar --server.port=8083 --rocketmq.config.namesrvAddr=${NameServer_Port} >> ${LOG_FILE} 2>&1 &"
if [ $? -eq 0 ];then
    echo  -e 'RocketMQ UI 配置成功 \n'
else
    echo  -e 'RocketMQ UI 配置失败 \n'
fi

# 等待三秒后再验证RocketMq是否启动成功
echo -e "********************验证RocketMq是否启动成功*********************"
sleep 3s
source $(grep Source_File ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
xcall jps | grep -E 'NamesrvStartup|BrokerStartup|jps show as bellow'

