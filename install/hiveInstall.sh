#!/bin/bash
################################################################################
## Copyright:    HZGOSUN Tech. Co, BigData
## Filename:     hiveInstall.sh
## Description:  安装 hive
## Version:      1.0
## Hive.Version: 2.3.0 
## Author:       qiaokaifeng
## Reviser:      caodabao; mashencai
## Created:      2017-11-14
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
LOG_FILE=${LOG_DIR}/hiveInstall.log
## hive 安装包目录
HIVE_SOURCE_DIR=${ROOT_HOME}/component/bigdata
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## hive的安装节点，放入数组中
HIVE_HOSTNAME_LISTS=$(grep Meta_ThriftServer ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
HIVE_HOSTNAME_ARRY=(${HIVE_HOSTNAME_LISTS//;/ })
HOST1=${HIVE_HOSTNAME_ARRY[0]}

## HIVE_INSTALL_HOME hive 安装目录
HIVE_INSTALL_HOME=${INSTALL_HOME}/Hive
## HIVE_HOME  hive 根目录
HIVE_HOME=${INSTALL_HOME}/Hive/hive

if [ ! -d $LOG_DIR ];then
    mkdir -p $LOG_DIR;
fi

## 打印当前时间
echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE

## 解压hive安装包
echo "==================================================="  | tee -a $LOG_FILE
echo "解压hive tar 包中，请稍候......."  | tee -a $LOG_FILE
tar -xf ${HIVE_SOURCE_DIR}/hive.tar.gz -C ${HIVE_SOURCE_DIR}
if [ $? == 0 ];then
    echo "解压缩hive 安装包成功......"  | tee -a $LOG_FILE
else
    echo "解压hive 安装包失败。请检查安装包是否损坏，或者重新安装."  | tee -a $LOG_FILE
fi

rm -rf  ${HIVE_INSTALL_HOME}
mkdir -p ${HIVE_INSTALL_HOME}
yes |cp -r ${HIVE_SOURCE_DIR}/hive  ${HIVE_INSTALL_HOME}
chmod -R 755 ${HIVE_HOME}
# 获取Mysql安装节点
MYSQL_INSTALLNODE=$(grep Mysql_InstallNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
sed -i "s;127.0.0.1;${MYSQL_INSTALLNODE};g" ${HIVE_HOME}/conf/hive-site.xml
sed -i "s;INSTALL_HOME;${INSTALL_HOME};g" ${HIVE_HOME}/conf/hive-env.sh


## 配置zookeeper、hive matestore集群地址（曹大报）
hazk=""
hith=""
for insName in ${HIVE_HOSTNAME_ARRY[@]}
do
    hazk="${hazk}${insName}:2181,"
    hith="${hith}thrift://${insName}:9083,"
done
    sed -i "s;hazkadd;${hazk%?};g"  ${HIVE_HOME}/conf/hive-site.xml
    sed -i "s;hithadd;${hith%?};g"  ${HIVE_HOME}/conf/hive-site.xml
	
####################################################################
##
## （马燊偲）
## 修改/bin/beeline脚本，使Hive/bin/beeline在执行$>beeline命令时，
## 能直接进到jdbc:hive://s103:2181$>下；
## 可以自动读取节点的Ip，不需手动修改；
## 已修改hive.tar.gz压缩包中beeline文件，添加了一行：
## jdbc:hive2://hostnameportlist/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2
##
####################################################################
tmp=""
for hostname in ${HIVE_HOSTNAME_ARRY[@]}
do
	tmp="$tmp"${hostname}":2181,"  # 拼接字符串
done
tmp=${tmp%?}
sed -i "s;hostnameportlist;${tmp};g"  ${HIVE_HOME}/bin/beeline

## HIVE配置文件分发（曹大报）

echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "hive 配置文件分发中，please waiting......"    | tee -a $LOG_FILE
for hostname in ${HIVE_HOSTNAME_ARRY[@]}
do
    ssh root@${hostname}  "mkdir -p ${HIVE_INSTALL_HOME}"  
    rsync -rvl ${HIVE_HOME}   root@${hostname}:${HIVE_INSTALL_HOME}  >/dev/null
    ssh root@${hostname}  "chmod -R 755   ${HIVE_HOME}"
done 
    echo “分发hive 安装配置done...”  | tee -a $LOG_FILE  
	


## 将Hive的UI地址写到指定文件中
echo ""  | tee -a $LOG_FILE
echo "**********************************************" | tee -a $LOG_FILE
echo "准备将hive的UI地址写到指定文件中............"    | tee -a $LOG_FILE
HiveWebUI_Dir=$(grep WebUI_Dir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
Host_IP=$(cat /etc/hosts|grep "$HOST1" | awk '{print $1}')
HBase_UI="http://${Host_IP}:10002"
mkdir -p ${HiveWebUI_Dir}
grep -q "HiveUI_Address=" ${HBaseWebUI_Dir}/WebUI_Address
if [ "$?" -eq "0" ]  ;then
    sed -i "s#^HiveUI_Address=.*#HiveUI_Address=${HBase_UI}#g" ${HBaseWebUI_Dir}/WebUI_Address
else
    echo "##Hive_WebUI" >> ${HBaseWebUI_Dir}/WebUI_Address
    echo "HiveUI_Address=${HBase_UI}" >> ${HBaseWebUI_Dir}/WebUI_Address
fi

## 修改hiveserver2 UI地址
for insName in ${HIVE_HOSTNAME_ARRY[@]}
do
    echo ""  | tee  -a  $LOG_FILE
    echo ""  | tee  -a  $LOG_FILE
    echo "==================================================="  | tee -a $LOG_FILE
    echo "修改hiveserver2 UI地址 in {$insName}目录...... "  | tee -a $LOG_FILE
    ssh root@$insName "sed -i 's;hostname;$insName;g' ${HIVE_HOME}/conf/hive-site.xml"
	
done
## 修改hiveserver2 UI地址（乔凯峰）
for insName in ${HIVE_HOSTNAME_ARRY[@]}
do
    echo ""  | tee  -a  $LOG_FILE
    echo ""  | tee  -a  $LOG_FILE
    echo "==================================================="  | tee -a $LOG_FILE
    echo "修改hiveserver2 地址 in {$insName}目录...... "  | tee -a $LOG_FILE
    ssh root@$insName "sed -i 's;hive_thrift;$insName;g' ${HIVE_HOME}/conf/hive-site.xml"
	
done
    echo "hive 文件分发完成，安装完成......"  | tee  -a  $LOG_FILE

	
## 初始化元数据(曹大报)
ssh root@${MYSQL_INSTALLNODE} "${HIVE_HOME}/bin/schematool -initSchema -dbType mysql"



set +x
