#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    zookeeperStart.sh
## Description: 启动zookeeper集群的脚本.
## Version:     1.0
## Author:      lidiliang
## Editor:            mashencai
## Created:     2017-10-23
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
LOG_FILE=${LOG_DIR}/zkStart.log
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## zk的安装节点，放入数组中
ZK_HOSTNAME_LISTS=$(grep Zookeeper_InstallNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
ZK_HOSTNAME_ARRY=(${ZK_HOSTNAME_LISTS//;/ })

for name in ${ZK_HOSTNAME_ARRY[@]}
do
    ssh root@$name "source /etc/profile;${INSTALL_HOME}/Zookeeper/zookeeper/bin/zkServer.sh start"
done

# 验证ZK是否启动成功
echo -e "********************验证ZK是否启动成功*********************"
sleep 3s
source $(grep Source_File ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
xcall jps | grep -E 'QuorumPeerMain|jps show as bellow'
