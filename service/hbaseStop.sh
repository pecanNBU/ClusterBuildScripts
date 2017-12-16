#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    hbaseStop.sh
## Description: 关闭hbase集群的脚本.
## Version:     1.0
## Author:      qiaokaifeng
## Editor:      mashencai
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
LOG_FILE=${LOG_DIR}/hbaseStop.log
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)

echo -e "关闭HBase集群 \n"
${INSTALL_HOME}/HBase/hbase/bin/stop-hbase.sh
	if [ $? -eq 0 ];then
	    echo -e "hbase stop success\n"
	else 
	    echo -e "hbase stop failed\n"
	fi
	
#获取habse的Hmaster主机名
HBASE_HMASTER=$(grep HBase_Hmaster ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
ssh root@${HBASE_HMASTER} "${INSTALL_HOME}/HBase/hbase/bin/hbase-common.sh stop master"

# 验证HBase是否停止成功
echo -e "********************验证HBase是否停止成功*********************"
sleep 3s
source $(grep Source_File ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
xcall jps | grep -E 'HMaster|HRegionServer|jps show as bellow'
