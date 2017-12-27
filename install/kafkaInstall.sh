#!/bin/bash
################################################################################
## Copyright:     HZGOSUN Tech. Co, BigData
## Filename:      kafkaInstall.sh
## Description:   安装 kafka
## Version:       1.0
## Kafka.Version: 0.11.0.1 
## Author:        qiaokaifeng
## Editor:        mashencai
## Created:       2017-10-24
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
LOG_FILE=${LOG_DIR}/kafkaInstall.log
## kafka 安装包目录
KAFKA_SOURCE_DIR=${ROOT_HOME}/component/bigdata
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## KAFKA_INSTALL_HOME kafka 安装目录
KAFKA_INSTALL_HOME=${INSTALL_HOME}/Kafka
## KAFKA_HOME  kafka 根目录
KAFKA_HOME=${INSTALL_HOME}/Kafka/kafka

## kafka的安装节点，放入数组中
KAFKA_HOSTNAME_LISTS=$(grep Kafka_InstallNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
KAFKA_HOSTNAME_ARRY=(${KAFKA_HOSTNAME_LISTS//;/ })



if [ ! -d $LOG_DIR ];then
    mkdir -p $LOG_DIR;
fi

## 打印当前时间
echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE

## 解压kafka安装包
echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo “解压kafka tar 包中，请稍候.......”  | tee -a $LOG_FILE
tar -xf ${KAFKA_SOURCE_DIR}/kafka.tar.gz -C ${KAFKA_SOURCE_DIR}
if [ $? == 0 ];then
    echo "解压缩kafka 安装包成功......"  | tee -a $LOG_FILE
else
    echo “解压kafka 安装包失败。请检查安装包是否损坏，或者重新安装.”  | tee -a $LOG_FILE
fi

    mkdir -p ${KAFKA_SOURCE_DIR}/tmp
    cp -r ${KAFKA_SOURCE_DIR}/kafka ${KAFKA_SOURCE_DIR}/tmp
    sed -i "s;KAFKA_HOME;${KAFKA_HOME};g"  ${KAFKA_SOURCE_DIR}/tmp/kafka/config/server.properties
kfkpro=''
for kfk in ${KAFKA_HOSTNAME_ARRY[@]}
do
    kfkpro="$kfkpro$kfk:2181,"
done
    sed -i "s;zookeeperCON;${kfkpro%?};g"  ${KAFKA_SOURCE_DIR}/tmp/kafka/config/server.properties

#临时目录。
i=0
echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo “创建临时分发目录：.......”  | tee -a $LOG_FILE
for insName in ${KAFKA_HOSTNAME_ARRY[@]}
do
    mkdir -p ${KAFKA_SOURCE_DIR}/$insName
    echo -n -e "正在创建${insName}的临时分发目录,请稍等......\n"
    cp -R ${KAFKA_SOURCE_DIR}/tmp/kafka ${KAFKA_SOURCE_DIR}/$insName
    i=$(($i+1))
    sed -i "s;brokerNum;$i;g"  ${KAFKA_SOURCE_DIR}/$insName/kafka/config/server.properties
done


## 分发到每个节点
for insName in ${KAFKA_HOSTNAME_ARRY[@]}
do
    echo "准备将kafka发到节点$insName"
    ssh root@$insName "mkdir -p ${KAFKA_INSTALL_HOME}"
    rsync -rvl ${KAFKA_SOURCE_DIR}/$insName/kafka $insName:${KAFKA_INSTALL_HOME}  > /dev/null
    ssh root@$insName "chmod -R 755 ${KAFKA_HOME}"

done
#修改配置文件hostname
num=1
for insName in ${KAFKA_HOSTNAME_ARRY[@]}
do
    echo "准备修改kafka${insName}的conf文件"
    ssh root@$insName "sed -i 's;hostname;$insName;g' ${KAFKA_HOME}/config/server.properties"
    sed -i "s;host$num;${insName};g" ${KAFKA_HOME}/config/producer.properties
    num=$(($num+1))
done
for hostName in ${KAFKA_HOSTNAME_ARRY[@]}
do
    echo "准备分发conf文件到${hostName}"
    rsync -rvl 	${KAFKA_HOME}/config/producer.properties $hostName:${KAFKA_HOME}/config > /dev/null
done

# 配置kafka的ui管理工具kafka-manager（马燊偲）
echo ""  | tee  -a  $LOG_FILE
echo "配置kafka-manager的zk地址......"  | tee  -a  $LOG_FILE

# 替换kafka-manager/conf/application.conf中：kafka-manager.zkhosts=value
tmp=""
for host_name in ${KAFKA_HOSTNAME_ARRY[@]}
do
	ip=$(cat /etc/hosts|grep "$host_name" | awk '{print $1}')
	tmp="$tmp"${ip}":2181,"  # 拼接字符串
done
tmp=${tmp%?}
sed -i "s#^kafka-manager.zkhosts=\".*#kafka-manager.zkhosts=\"${tmp}\"#g" ${KAFKA_HOME}/kafka-manager/conf/application.conf
echo "配置完毕......"  | tee  -a  $LOG_FILE



## 删除临时存放目录
    rm -rf ${KAFKA_SOURCE_DIR}/tmp
for insName in ${KAFKA_HOSTNAME_ARRY[@]}
do
    rm -rf ${KAFKA_SOURCE_DIR}/$insName
done
    echo "kafka 文件分发完成，安装完成......"  | tee  -a  $LOG_FILE
	

	
	
set +x
