#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    zookeeperStart.sh
## Description: 启动zookeeper集群的脚本.
## Version:     1.0
## Author:      lidiliang
## Created:     2017-10-23
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
LOG_FILE=${LOG_DIR}/hadoopFormat.log
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
Hadoop_Masters=$(grep Hadoop_NameNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
namenode_arr=(${Hadoop_Masters//;/ }) 
MASTER1=${namenode_arr[0]}
MASTER2=${namenode_arr[1]}

CLUSTER_HOST=$(grep Cluster_HostName ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
hostname_arr=(${CLUSTER_HOST//;/ }) 

if [ -f ${INSTALL_HOME}/Hadoop/hadoop/formated ];then
   echo "已经执行过一次format, 一般不允许二次format...."
   echo "如需重复执行format，请先删除${INSTALL_HOME}/Hadoop/hadoop/目录下的formated文件...."
   exit 0
fi

if [ -d ${HADOOP_HOME}/tmp ];then
    for host in ${hostname_arr[@]}
    do 
        ssh root@$host "rm -rf ${HADOOP_HOME}/tmp"
    done
fi

echo "**********************************************" | tee -a $LOG_FILE
echo "执行hdfs zkfc -formatZK......................"  | tee -a $LOG_FILE
${INSTALL_HOME}/Hadoop/hadoop/bin/hdfs zkfc -formatZK  -force
if [ $? -ne 0 ];then
    echo "hdfs zkfc -formatZK 失败................." | tee -a $LOG_FILE
    exit 1;
fi
sleep 5s


echo "**********************************************" | tee -a $LOG_FILE
echo "启动zkfc....................................."  | tee -a $LOG_FILE
cd  ${INSTALL_HOME}/Hadoop/hadoop/sbin
./hadoop-daemon.sh start zkfc 
sleep 5s

for name_host in ${hostname_arr[@]}
do
    ssh root@$name_host "${INSTALL_HOME}/Hadoop/hadoop/sbin/hadoop-daemon.sh start journalnode"
    if [ $? -ne 0 ];then
        echo  "start journalnode in $name_host failed"
        exit 1 
    fi
done
sleep 2s

# 格式化namenode
echo "**********************************************" | tee -a $LOG_FILE
echo "格式化namenode................................"  | tee -a $LOG_FILE
${INSTALL_HOME}/Hadoop/hadoop/bin/hadoop namenode -format -force
## 
if [ $? -ne 0 ];then
    echo "hdfs namenode -formate -force 失败."
    exit 1;
fi

sleep 2s

## 第一次启动
echo "**********************************************" | tee -a $LOG_FILE
echo "第一次启动hadoop................................"  | tee -a $LOG_FILE
${INSTALL_HOME}/Hadoop/hadoop/sbin/start-dfs.sh
	if [ $? -eq 0 ];then
	    echo -e 'hdfs success \n'
	else 
	    echo -e 'hdfs failed \n'
	fi
sleep 3s
${INSTALL_HOME}/Hadoop/hadoop/sbin/start-yarn.sh
	if [ $? -eq 0 ];then
	    echo -e 'yarn success \n'
	else 
	    echo -e 'yarn failed \n'
	fi
sleep 3s
ssh root@$MASTER2 "${INSTALL_HOME}/Hadoop/hadoop/sbin/yarn-daemon.sh start resourcemanager"
	if [ $? -eq 0 ];then
	    echo -e 'ha yarn success \n'
	else
	    echo -e 'ha yarn failed \n'
	fi
ssh root@${MASTER2} "
${INSTALL_HOME}/Hadoop/hadoop/bin/hdfs namenode -bootstrapStandby;
${INSTALL_HOME}/Hadoop/hadoop/sbin/hadoop-daemon.sh start namenode
"
cd  ${INSTALL_HOME}/Hadoop/hadoop/
echo formate  >> formated 


source $(grep Source_File ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2) > /dev/null
xcall jps






