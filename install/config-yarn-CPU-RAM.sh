#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    config-yarn-CPU-RAM.sh
## Description: 配置yarn的CPU和内存
## Version:     1.0
## Author:      liusiyang
## Created:     2017-12-11
################################################################################
#set -x  ## 用于调试用，不用的时候可以注释掉

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
CORES=$(cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l)
## 获取当前机器内存
MEMORY=$(echo "$(free -h | grep "Mem" | awk '{print $2}')" | sed -r 's/[^0-9.]+//g')
## 获取当前机器上挂载的磁盘个数
DISKS=1
## 是否使用HBase
HBASE=True                              ## True代表使用，False代表不使用

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


#####################################################################
# 函数名:config_yarn
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
	if [ -f "${YARN_SITE_XML}" ] && [ -f "${BIN_DIR}/chenke.sb" ]; then
		echo “正在配置yarn-site.xml，请稍候.......”  | tee -a $LOG_FILE
		## 配置yarn.scheduler.minimum-allocation-mb参数
		grep -q "yarn.scheduler.minimum-allocation-mb" ${YARN_SITE_XML}
		if [[ $? -eq 0 ]]; then
			num1=$[ $(cat yarn-site.xml  | cat -n | grep  yarn.scheduler.minimum-allocation-mb | awk '{print $1}') +1 ]
			val1=$(grep yarn.scheduler.minimum-allocation-mb ${BIN_DIR}/chenke.sb | cut -d '=' -f2)
			val11="${VALUE}${val1}${VALUE_END}"
			sed -i "${num1}c ${val11}" ${YARN_SITE_XML} 
			echo "config yarn.scheduler.minimum-allocation-mb=${val1}"  |  tee -a $LOG_FILE
		else
			echo "Not fount \"yarn.nodemanager.resource.memory-mb\"!"  |  tee -a $LOG_FILE
		fi
		## 配置yarn.scheduler.maximum-allocation-mb参数
		grep -q "yarn.scheduler.maximum-allocation-mb" ${YARN_SITE_XML}
		if [[ $? -eq 0 ]]; then
			num2=$[ $(cat yarn-site.xml  | cat -n | grep  yarn.scheduler.maximum-allocation-mb | awk '{print $1}') +1 ]
			val2=$(grep yarn.scheduler.maximum-allocation-mb ${BIN_DIR}/chenke.sb | cut -d '=' -f2)
			val22="${VALUE}${val2}${VALUE_END}"
			sed -i "${num2}c ${val22}" ${YARN_SITE_XML}
			echo "config yarn.scheduler.maximum-allocation-mb=${val2}"  |  tee -a $LOG_FILE
		else
			echo "Not fount \"yarn.scheduler.maximum-allocation-mb\"!"  |  tee -a $LOG_FILE
		fi
		## 配置yarn.nodemanager.resource.memory-mb参数
		grep -q "yarn.nodemanager.resource.memory-mb" ${YARN_SITE_XML}
		if [[ $? -eq 0 ]]; then
			num3=$[ $(cat yarn-site.xml  | cat -n | grep  yarn.nodemanager.resource.memory-mb | awk '{print $1}') +1 ]
			val3=$(grep yarn.nodemanager.resource.memory-mb ${BIN_DIR}/chenke.sb | cut -d '=' -f2)
			val33="${VALUE}${val3}${VALUE_END}"
			sed -i "${num3}c ${val33}" ${YARN_SITE_XML}
			echo "config yarn.nodemanager.resource.memory-mb=${val3}"  |  tee -a $LOG_FILE
		else
			echo "Not fount \"yarn.nodemanager.resource.memory-mb\"!"  |  tee -a $LOG_FILE
		fi
		## 配置yarn.app.mapreduce.am.resource.mb参数
		grep -q "yarn.app.mapreduce.am.resource.mb" ${YARN_SITE_XML}
		if [[ $? -eq 0 ]]; then
			num4=$[ $(cat yarn-site.xml  | cat -n | grep  yarn.app.mapreduce.am.resource.mb | awk '{print $1}') +1 ]
			val4=$(grep yarn.app.mapreduce.am.resource.mb ${BIN_DIR}/chenke.sb | cut -d '=' -f2)
			val44="${VALUE}${val4}${VALUE_END}"
			sed -i "${num4}c ${val44}" ${YARN_SITE_XML}
			echo "config yarn.app.mapreduce.am.resource.mb=${val4}"  |  tee -a $LOG_FILE
		else
			echo "Not fount \"yarn.app.mapreduce.am.resource.mb\"!"  |  tee -a $LOG_FILE
		fi
		## 配置yarn.app.mapreduce.am.command-opts参数
		grep -q "yarn.app.mapreduce.am.command-opts" ${YARN_SITE_XML}
		if [[ $? -eq 0 ]]; then
			num5=$[ $(cat yarn-site.xml  | cat -n | grep  yarn.app.mapreduce.am.command-opts | awk '{print $1}') +1 ]
			val5=$(grep yarn.app.mapreduce.am.command-opts ${BIN_DIR}/chenke.sb | cut -d '=' -f2)
			val55="${VALUE}${val5}${VALUE_END}"
			sed -i "${num5}c ${val55}" ${YARN_SITE_XML}
			echo "config yarn.app.mapreduce.am.command-opts=${val5}"  |  tee -a $LOG_FILE
		else
			echo "Not fount \"yarn.app.mapreduce.am.command-opts\"!"  |  tee -a $LOG_FILE
		fi
	else
		echo "Not Found \"${YARN_SITE_XML_DIR}\" or \"${BIN_DIR}/chenke.sb\" file!"  |  tee -a $LOG_FILE
	fi
	rm -f ${BIN_DIR}/chenke.sb
	echo "已删除${BIN_DIR}/chenke.sb文件！"  | tee -a $LOG_FILE
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
    config_yarn
    config_yarn_site_xml
}

#---------------------------------------------------------------------#
#                              执行流程                                #
#---------------------------------------------------------------------#

## 打印时间
echo ""  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")" | tee  -a  $LOG_FILE
main

set +x
