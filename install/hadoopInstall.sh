#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    hadoopInstall.sh
## Description: 安装配置hadoop集群
##              实现自动化的脚本
## Version:     1.0
## Author:      lidiliang
## Created:     2017-10-23 caodabao
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
## hadoop 安装日记
LOG_FILE=${LOG_DIR}/hadoopInstall.log
##  hadoop 安装包目录
HADOOP_SOURCE_DIR=${ROOT_HOME}/component/bigdata
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## HADOOP_INSTALL_HOME hadoop 安装目录
HADOOP_INSTALL_HOME=${INSTALL_HOME}/Hadoop
## HADOOP_HOME  hadoop 根目录
HADOOP_HOME=${HADOOP_INSTALL_HOME}/hadoop
## JAVA_HOME
JAVA_HOME=${INSTALL_HOME}/JDK/jdk

mkdir -p ${HADOOP_HOME}

ZK_LISTS=""
HADOOP_TMP_DIR=$HADOOP_HOME/tmp
DK_SLAVES=""
DFS_JOURNALNODE_EDITS_DIR=${HADOOP_HOME}/dfs_journalnode_edits_dir

## 获取ZK节点
ZK_HOSTS=$(grep Zookeeper_InstallNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
zkhost_arr=(${ZK_HOSTS//;/ })    
for zk_host in ${zkhost_arr[@]}
do
    ZK_LISTS="${zk_host}:2181,${ZK_LISTS}"
    DK_SLAVES="${zk_host}:8485;${DK_SLAVES}"
done

##获取hadoop主备节点
Hadoop_Masters=$(grep Hadoop_NameNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
namenode_arr=(${Hadoop_Masters//;/ }) 
MASTER1=${namenode_arr[0]}
MASTER2=${namenode_arr[1]}

##获取数据存储节点节点
Hadoop_Data=$(grep Hadoop_DataNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
datanode_arr=(${Hadoop_Data//;/ })

#####################################################################
# 函数名: compression_the_tar
# 描述: 获取开源hadoop 安装包，并解压。
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function compression_the_tar()
{   
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "please waitinng, hadoop jar 包解压中........"  | tee -a $LOG_FILE
    cd $HADOOP_SOURCE_DIR
    tar -xf hadoop.tar.gz
    if [ $? == 0 ];then
        echo "解压hadoop jar 包成功." | tee -a $LOG_FILE
    else
       echo "解压hadoop jar 包失败，请检查包是否完整。" | tee -a $LOG_FILE  
    fi
    rm -rf ${HADOOP_HOME}
    #cp -r hadoop  ${HADOOP_INSTALL_HOME}
    cd -  
}



#####################################################################
# 函数名: config_jdk_and_slaves
# 描述: 配置hadoop-env.sh 和yarn-env.sh 中jdk 的路径。
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_jdk_and_slaves()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    cd ${HADOOP_SOURCE_DIR}/hadoop/etc/hadoop
    sed -i "s#java_home#${JAVA_HOME}#g" yarn-env.sh
    flag1=$?
    sed -i "s#java_home#${JAVA_HOME}#g" hadoop-env.sh
    flag2=$?
    if [[ ($flag1 == 0)  && ($flag2 == 0) ]];then
        echo " 配置jdk 路径成功." | tee -a $LOG_FILE
    else
        echo "配置jdk路径成功." | tee -a $LOG_FILE
    fi
    echo ""  >  ${HADOOP_SOURCE_DIR}/hadoop/etc/hadoop/slaves
    for data_host in ${datanode_arr[@]}
    do
        echo ${data_host} >> ${HADOOP_SOURCE_DIR}/hadoop/etc/hadoop/slaves
    done
    cd -
}


#####################################################################
# 函数名: config_core_site 的
# 描述: 配置core-site.xml 
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_core_site()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    cd ${HADOOP_SOURCE_DIR}/hadoop/etc/hadoop
    mkdir -p ${HADOOP_SOURCE_DIR}/hadoop/tmp/dfs/name
    mkdir -p ${HADOOP_SOURCE_DIR}/hadoop/tmp/dfs/data
    sed -i "s#hadoop_tmp_dir#${HADOOP_TMP_DIR}#g" core-site.xml
    sed -i "s#ha_zookeeper_quorum#${ZK_LISTS}#g" core-site.xml    
    echo “配置core-site.xml 的配置done”  | tee -a $LOG_FILE
    cd -
}


#####################################################################
# 函数名: config_hdfs_site 的
# 描述: 配置hdfs-site.xml 
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_hdfs_site()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    cd ${HADOOP_SOURCE_DIR}/hadoop/etc/hadoop
    sed -i "s#master1#${MASTER1}#g" hdfs-site.xml
    sed -i "s#master2#${MASTER2}#g" hdfs-site.xml
    sed -i "s#DKslave#${DK_SLAVES}#g" hdfs-site.xml 
    mkdir -p ${HADOOP_SOURCE_DIR}/hadop/dfs_journalnode_edits_dir
    sed -i "s#dfs_journalnode_edits_dir#${DFS_JOURNALNODE_EDITS_DIR}#g" hdfs-site.xml 
    echo “配置hdfs-site.xml 的配置done”  | tee -a $LOG_FILE
    cd -
}

#####################################################################
# 函数名: config_yarn_site 的
# 描述: 配置yarn-site.xml 
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_yarn_site()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    cd  ${HADOOP_SOURCE_DIR}/hadoop/etc/hadoop
    sed -i "s#master1#${MASTER1}#g"  yarn-site.xml
    sed -i "s#master2#${MASTER2}#g"  yarn-site.xml
    sed -i "s#ha_zookeeper_quorum#${ZK_LISTS}#g"  yarn-site.xml
    echo “配置yarn-site.xml 的配置done”  | tee -a $LOG_FILE
    cd -
}



#####################################################################
# 函数名: xync_hadoop_config
# 描述: hadoop 配置文件分发
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function xync_hadoop_config()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "hadoop 配置文件分发中，please waiting......"    | tee -a $LOG_FILE
    CLUSTER_HOST=$(grep Cluster_HostName ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
    host_arr=(${CLUSTER_HOST//;/ })    
    for host_name in ${host_arr[@]}
    do
        ssh root@$host_name  "rm -rf ${HADOOP_HOME}"  
        rsync -rvl ${HADOOP_SOURCE_DIR}/hadoop   root@${host_name}:${HADOOP_INSTALL_HOME}  >/dev/null
        ssh root@$host_name  "chmod -R 755   ${HADOOP_HOME}"
    done 
    rm -rf  ${HADOOP_SOURCE_DIR}/hadoop
    echo “分发haoop 安装配置done...”  | tee -a $LOG_FILE  
}

#####################################################################
# 函数名: writeUI_file
# 描述: 将hadoop的UI地址写到指定文件中
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function writeUI_file()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "准备将hadoop的UI地址写到指定文件中............"    | tee -a $LOG_FILE
    HadoopWebUI_Dir=$(grep WebUI_Dir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
    HadoopWebUI_File=${HadoopWebUI_Dir}/WebUI_Address
    MASTER_IP=$(cat /etc/hosts|grep "$MASTER1" | awk '{print $1}')
    Hadoop_UI="http://${MASTER_IP}:50070"
    mkdir -p ${HadoopWebUI_Dir}
    grep -q "HadoopUI_Address=" ${HadoopWebUI_Dir}/WebUI_Address
    if [ "$?" -eq "0" ]  ;then
        sed -i "s#^HadoopUI_Address=.*#HadoopUI_Address=${Hadoop_UI}#g" ${HadoopWebUI_Dir}/WebUI_Address
    else
        echo "##Hadoop_WebUI" >> ${HadoopWebUI_Dir}/WebUI_Address
        echo "HadoopUI_Address=${Hadoop_UI}" >> ${HadoopWebUI_Dir}/WebUI_Address
    fi 
}

#####################################################################
# 函数名: main
# 描述:  修改hadoop HA模式下所需要修改的配置
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function main()
{
    compression_the_tar
    config_jdk_and_slaves
    config_core_site
    config_hdfs_site
    config_yarn_site 
    writeUI_file	
    xync_hadoop_config 
}


echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE
main


set +x
