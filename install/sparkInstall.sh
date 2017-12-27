#!/bin/bash
################################################################################
## Copyright:    HZGOSUN Tech. Co, BigData
## Filename:     sparkInstall.sh
## Description:  安装 spark
## Version:      1.0
## Author:       qiaokaifeng
## Editor:       mashencai
## Created:      2017-10-23
## Spark.Version:2.2.0
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
LOG_FILE=${LOG_DIR}/sparkInstall.log
## SPARK 安装包目录
SPARK_SOURCE_DIR=${ROOT_HOME}/component/bigdata
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)

## SPARK_INSTALL_HOME spark 安装目录
SPARK_INSTALL_HOME=${INSTALL_HOME}/Spark
## SPARK_HOME  spark 根目录
SPARK_HOME=${INSTALL_HOME}/Spark/spark

## spark的安装节点，需要拼接，放入数组中
SPARK_NAMENODE=$(grep Spark_NameNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
SPARK_SERVICENODE=$(grep Spark_ServiceNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
SPARK_HOSTNAME_LISTS=${SPARK_NAMENODE}";"${SPARK_SERVICENODE}
SPARK_HOSTNAME_ARRY=(${SPARK_HOSTNAME_LISTS//;/ })


if [ ! -d $LOG_DIR ];then
    mkdir -p $LOG_DIR;
fi

## 打印当前时间
    echo ""  | tee  -a  $LOG_FILE
    echo ""  | tee  -a  $LOG_FILE
    echo "==================================================="  | tee -a $LOG_FILE
    echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE

## 解压spark安装包
    echo ""  | tee  -a  $LOG_FILE
    echo ""  | tee  -a  $LOG_FILE
    echo "==================================================="  | tee -a $LOG_FILE
    echo “解压spark tar 包中，请稍候.......”  | tee -a $LOG_FILE
    tar -xf ${SPARK_SOURCE_DIR}/spark.tgz -C ${SPARK_SOURCE_DIR}
if [ $? == 0 ];then
    echo "解压spark 安装包成功......"  | tee -a $LOG_FILE
else
    echo “解压spark 安装包失败。请检查安装包是否损坏，或者重新安装.”  | tee -a $LOG_FILE
fi

## 创建临时目录
    echo ""  | tee  -a  $LOG_FILE
    echo ""  | tee  -a  $LOG_FILE
    echo "==================================================="  | tee -a $LOG_FILE
    echo "创建临时安装目录，请稍等...... "  | tee -a $LOG_FILE
    mkdir -p ${SPARK_SOURCE_DIR}/tmp
    cp -r ${SPARK_SOURCE_DIR}/spark ${SPARK_SOURCE_DIR}/tmp > /dev/null

zkconf=''
for zk in ${SPARK_HOSTNAME_ARRY[@]}
do
    zkconf="$zkconf$zk:2181,"
done
    sed -i "s;zkconf;${zkconf%?};g"            ${SPARK_SOURCE_DIR}/tmp/spark/conf/spark-env.sh

for ins in ${SPARK_HOSTNAME_ARRY[@]}
do
    echo "$ins" >>                             ${SPARK_SOURCE_DIR}/tmp/spark/conf/slaves
done
    sleep 2s
	
## 修改spark-env.sh
    sed -i "s;INSTALL_HOME;${INSTALL_HOME};g"  ${SPARK_SOURCE_DIR}/tmp/spark/conf/spark-env.sh
    sed -i "s;SPARK_DATA;${SPARK_HOME};g"      ${SPARK_SOURCE_DIR}/tmp/spark/conf/spark-env.sh
	
## 修改spark-beeline
tmp=""
for hostname in ${SPARK_HOSTNAME_ARRY[@]}
do
	tmp="$tmp"${hostname}":2181,"  # 拼接字符串
done
tmp=${tmp%?}
sed -i "s;portlist;${tmp};g"  ${SPARK_SOURCE_DIR}/tmp/spark/bin/spark-beeline

## 分发spark到每个节点
for insName in ${SPARK_HOSTNAME_ARRY[@]}
do
    echo ""  | tee  -a  $LOG_FILE
    echo ""  | tee  -a  $LOG_FILE
    echo "==================================================="  | tee -a $LOG_FILE
    echo "准备分发到节点$insName...... "  | tee -a $LOG_FILE
    ssh root@$insName "mkdir -p ${SPARK_INSTALL_HOME}"
    rsync -rvl ${SPARK_SOURCE_DIR}/tmp/spark $insName:${SPARK_INSTALL_HOME} > /dev/null
    echo "分发到节点成功."  | tee -a $LOG_FILE
    ssh root@$insName "chmod -R 755 ${SPARK_HOME}"
    echo "更改成功。"  | tee -a $LOG_FILE
done

    cp ${INSTALL_HOME}/Hive/hive/conf/hive-site.xml ${SPARK_HOME}/conf
    sed -i "s;10000;23040;g"  ${SPARK_HOME}/conf/hive-site.xml
	sed -i "s;hiveserver2;thriftserver;g"  ${SPARK_HOME}/conf/hive-site.xml
for insName in ${SPARK_HOSTNAME_ARRY[@]}
do	
    scp -r ${SPARK_HOME}/conf/hive-site.xml root@${insName}:${SPARK_HOME}/conf
done

#修改配置文件 historyServer  hostname
for insName in ${SPARK_HOSTNAME_ARRY[@]}
do
    echo "准备修改spark ${insName} 的conf文件"
    ssh root@$insName "sed -i 's;historyserver;$insName;g' ${SPARK_HOME}/conf/spark-defaults.conf"
    ssh root@$insName "sed -i 's;hostname;$insName;g' ${SPARK_HOME}/bin/spark-beeline"

done
    #sed -i "s;historyServer;$(sed -n '1p' ${CONF_DIR}/hostnamelists.properties);g"  ${SPARK_HOME}/conf/spark-defaults.conf
    #sed -i "s;hostname;$(sed -n '1p' ${CONF_DIR}/hostnamelists.properties);g"  ${SPARK_HOME}/bin/spark-beeline

    

## 删除临时目录
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "删除临时目录...... "  | tee -a $LOG_FILE
    rm -rf ${SPARK_SOURCE_DIR}/tmp

set +x




