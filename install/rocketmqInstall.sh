#!/bin/bash
################################################################################
## Copyright:     HZGOSUN Tech. Co, BigData
## Filename:      rocketmqInstall.sh
## Description:   安装 rocket
## Version:       1.0
## RocketMQ.Version: 4.1.0 
## Author:        caodabao
## Created:       2017-11-10
################################################################################


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
## 安装日记目录
LOG_FILE=${LOG_DIR}/rocketmqInstall.log
## rocketmq 安装包目录
ROCKETMQ_SOURCE_DIR=${ROOT_HOME}/component/bigdata
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## ROCKETMQ_INSTALL_HOME rocketmq 安装目录
ROCKETMQ_INSTALL_HOME=${INSTALL_HOME}/RocketMQ
## ROCKETMQ_HOME  rocketmq 根目录
ROCKETMQ_HOME=${INSTALL_HOME}/RocketMQ/rocketmq
## NameServer 节点IP
NameServer_Host=$(grep RocketMQ_Namesrv ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
Broker_Hosts=$(grep RocketMQ_Broker ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
Broker_Hostarr=(${Broker_Hosts//;/ }) 

NameServer_IP=$(cat /etc/hosts|grep "$NameServer_Host" | awk '{print $1}')

Host_Arr=(${Broker_Hostarr[*]} ${NameServer_Host})

mkdir -p ${ROCKETMQ_INSTALL_HOME}
mkdir -p ${LOG_DIR} 


echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"   | tee -a $LOG_FILE

echo “解压rocketmq zip 包中，请稍候.......”  | tee -a $LOG_FILE
	unzip ${ROCKETMQ_SOURCE_DIR}/rocketmq.zip  -d ${ROCKETMQ_SOURCE_DIR} > /dev/null
if [ $? == 0 ];then
    echo "解压缩rocketmq 安装包成功......"  | tee -a $LOG_FILE
else
    echo “解压rocketmq 安装包失败。请检查安装包是否损坏，或者重新安装.”  | tee -a $LOG_FILE
	exit 1
fi

for insName in ${Host_Arr[@]}
do
    echo ""  | tee  -a  $LOG_FILE
    echo "************************************************"
    echo "准备将ROCKETMQ分发到节点$insName："  | tee -a $LOG_FILE
    ssh root@$insName "mkdir -p  ${ROCKETMQ_INSTALL_HOME}"    
    echo "rocketmq 分发中,请稍候......"  | tee -a $LOG_FILE
    ssh root@${insName} "rm -rf ${ROCKETMQ_HOME}/conf/2m-noslave/*.properties"
    scp -r $ROCKETMQ_SOURCE_DIR/rocketmq $insName:${ROCKETMQ_INSTALL_HOME}   > /dev/null

    # 判断是否存在export NAMESRV_ADDR=172.18.18.108:9876这一行，若存在则替换，若不存在则追加
    namesrv_exists=$(ssh root@${insName} 'grep "export NAMESRV_ADDR=" /etc/profile')
    if [ "${namesrv_exists}" != "" ];then
        ssh root@${insName} "sed -i 's#^export NAMESRV_ADDR=.*#export NAMESRV_ADDR="${NameServer_IP}:9876"#g' /etc/profile"
    else
        ssh root@${insName} "echo export NAMESRV_ADDR="${NameServer_IP}:9876"  >> /etc/profile; echo "">> /etc/profile"		
    fi
done
rm -rf ${ROCKETMQ_SOURCE_DIR}/rocketmq

##修改${ROCKETMQ_HOME}/conf/2m-noslave/目录下broker配置文件
for hostname in ${Host_Arr[@]}
do
    echo "************************************************"
    echo "准备修改$hostname节点下的broker配置文件："  | tee -a $LOG_FILE
    Properties_Num=$(ssh root@$hostname "ls ${ROCKETMQ_HOME}/conf/2m-noslave | grep .properties | wc -l")
    if [ $Properties_Num != 1 ];then
        echo "$hostname节点下的broker配置文件数目不为1,请检视......"  | tee -a $LOG_FILE
        exit 0
    else
        ssh root@$hostname "mv ${ROCKETMQ_HOME}/conf/2m-noslave/*.properties ${ROCKETMQ_HOME}/conf/2m-noslave/broker-${hostname}.properties" 
        ssh root@$hostname "sed -i 's#^brokerName=.*#brokerName="broker-$hostname"#g' ${ROCKETMQ_HOME}/conf/2m-noslave/broker-${hostname}.properties"
    fi
    echo "修改$hostname节点下的broker配置文件完成"  | tee -a $LOG_FILE
done

## 将RocketMQ的UI地址写到指定文件中
echo ""  | tee -a $LOG_FILE
echo "**********************************************" | tee -a $LOG_FILE
echo "准备将RocketMQ的UI地址写到指定文件中............"    | tee -a $LOG_FILE
RocketMQWebUI_Dir=$(grep WebUI_Dir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
RocketMQ_UI="http://${NameServer_IP}:8083"
mkdir -p ${RocketMQWebUI_Dir}
grep -q "RocketMQUI_Address=" ${RocketMQWebUI_Dir}/WebUI_Address
if [ "$?" -eq "0" ]  ;then
    sed -i "s#^RocketMQUI_Add0ress=.*#RocketMQUI_Address=${RocketMQ_UI}#g" ${RocketMQWebUI_Dir}/WebUI_Address
else
    echo "##RocketMQ_WebUI" >> ${RocketMQWebUI_Dir}/WebUI_Address
    echo "RocketMQUI_Address=${RocketMQ_UI}" >> ${RocketMQWebUI_Dir}/WebUI_Address
fi

set +x	
