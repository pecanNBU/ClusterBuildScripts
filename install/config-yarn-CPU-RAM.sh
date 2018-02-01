#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    config-yarn-CPU-RAM.sh
## Description: 配置yarn的CPU和内存
## Version:     1.0
## Author:      liusiyang
## Created:     2017-12-11
################################################################################
## set -x  ## 用于调试用，不用的时候可以注释掉

#---------------------------------------------------------------------#
#                              定义变量                                #
#---------------------------------------------------------------------#
cd `dirname $0`
## 脚本所在目录
BIN_DIR=`pwd`
cd ..
## ClusterBuildScripts目录
CLUSTER_BUILD_SCRIPTS_DIR=`pwd`
## log 日记目录
LOG_DIR=${CLUSTER_BUILD_SCRIPTS_DIR}/logs
##log日志文件
LOG_FILE=${LOG_DIR}/config-yarn.log
cd tool/
## yarn-utils.py脚本目录
YARN_UTIL_DIR=`pwd`
## 获取当前机器core数量
CORES=$(cat /proc/cpuinfo| grep "processor"| wc -l)
## 获取当前机器内存
MEMORY=$(echo "$(free -h | grep "Mem" | awk '{print $2}')" | sed -r 's/[^0-9.]+//g')
## yarn node manager 的最大内存
YARN_MAX_MEN=$(echo `echo "scale=1;${MEMORY}*0.8*1024"|bc`  | awk -F "." '{print $1}')
## 获取当前机器上挂载的磁盘个数
DISKS=1
## cluster_conf.properties文件目录
CONF_DIR=${CLUSTER_BUILD_SCRIPTS_DIR}/conf
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## yar-site.xml目录
YARN_SITE_XML_DIR=${INSTALL_HOME}/Hadoop/hadoop/etc/hadoop
## yar-site.xml文件路径
YARN_SITE_XML=${YARN_SITE_XML_DIR}/yarn-site.xml
## <value>
VALUE="<value>"
## </value>
VALUE_END="</value>"
## 获取Yarn-site.xml 分发节点
CLUSTER_HOST=$(grep Cluster_HostName ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
HOSTNAMES=(${CLUSTER_HOST//;/ }) 


#####################################################################
# 函数名:config_yarn,这个函数已经弃用
# 描述: 配置yarn的CPU和内存
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_yarn ()
{
    echo ""  | tee -a $LOG_FILE
    echo "****************************************************"  | tee -a $LOG_FILE
    echo “正在配置yarn的内存与CPU，请稍候.......”  | tee -a $LOG_FILE
    echo "获取当前机器配置信息:cores=${CORES},MEMORY=${MEMORY},DISKS=${DISKS},HBASE=${HBASE}"
    python yarn-utils.py -c ${CORES} -m ${MEMORY} -d ${DISKS} -k ${HBASE} > ${BIN_DIR}/chenke.sb  | tee -a $LOG_FILE
    echo "${BIN_DIR}/chenke.sb文件内容:"  | tee -a $LOG_FILE
    echo "----------------------------------------------------"  | tee -a $LOG_FILE
    cat ${BIN_DIR}/chenke.sb  | tee -a $LOG_FILE
    echo "----------------------------------------------------"  | tee -a $LOG_FILE
    echo “配置yarn完成!!!!!!”  | tee -a $LOG_FILE
}

#####################################################################
# 函数名:config_yarn_site_xml
# 描述: 配置yarn-site.xml
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_yarn_site_xml ()
{
    echo ""  | tee -a $LOG_FILE
    echo "****************************************************"  | tee -a $LOG_FILE
	cd ${YARN_SITE_XML_DIR}
	echo “进入${YARN_SITE_XML_DIR}目录，准备配置yarn-site.xml”  |  tee -a $LOG_FILE
	if [ -f "${YARN_SITE_XML}" ]; then
		## 配置yarn nodeManager 可以支配的最大内存
		grep -q "yarn.nodemanager.resource.memory-mb" ${YARN_SITE_XML}
		if [[ $? -eq 0 ]]; then
	            num3=$[ $(cat yarn-site.xml  | cat -n | grep  yarn.nodemanager.resource.memory-mb | awk '{print $1}') +1 ]
		    sed -i "${num3}c ${VALUE}${YARN_MAX_MEN}${VALUE_END}" ${YARN_SITE_XML}
		fi
                ## 配置nodemanager可用的最大核数
		grep -q "yarn.nodemanager.resource.cpu-vcores" ${YARN_SITE_XML}
		if [[ $? -eq 0 ]]; then
		    num6=$[ $(cat yarn-site.xml  | cat -n | grep  yarn.nodemanager.resource.cpu-vcores | awk '{print $1}') +1 ]
		    sed -i "${num6}c ${VALUE}${CORES}${VALUE_END}" ${YARN_SITE_XML}
		fi
        else
		echo "Not Found \"${YARN_SITE_XML_DIR}\" or \"${BIN_DIR}/chenke.sb\" file!"  |  tee -a $LOG_FILE
	fi
	echo “配置yarn-site.xml完成!!!!!!”  | tee -a $LOG_FILE
}

#####################################################################
# 函数名: main
# 描述: 脚本主要业务入口
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function main()
{
#    config_yarn
    config_yarn_site_xml
    for host in ${HOSTNAMES[@]};do
        scp ${YARN_SITE_XML} ${host}:${YARN_SITE_XML}
    done
}

#---------------------------------------------------------------------#
#                              执行流程                                #
#---------------------------------------------------------------------#

## 打印时间
echo ""  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")" | tee  -a  $LOG_FILE
main

set +x
