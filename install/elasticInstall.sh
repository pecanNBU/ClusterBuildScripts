#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    elasticInstall.sh
## Delasticcription: 安装配置elastic
##              实现自动化的脚本
## Version:     1.0
## Author:      mashencai
## Created:     2017-11-09
################################################################################

#set -x

#---------------------------------------------------------------------#
#                              定义变量                                #
#---------------------------------------------------------------------#

## 进入当前目录
cd `dirname $0`
## 脚本所在目录：install
BIN_DIR=`pwd`
cd ..
## 安装包根目录：
ROOT_HOME=`pwd`
## 配置文件目录：conf
CONF_DIR=${ROOT_HOME}/conf
## 日记目录：logs
LOG_DIR=${ROOT_HOME}/logs
## elastic 安装日记
LOG_FILE=${LOG_DIR}/elasticInstall.log
##  elastic 安装包目录：
ELASTIC_SOURCE_DIR=${ROOT_HOME}/component/bigdata
## 最终安装的根目录，所有bigdata 相关的根目录：/opt/hzgc/bigdata
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## ELASTIC_INSTALL_HOME elastic 安装目录：/opt/hzgc/bigdata/Elastic
ELASTIC_INSTALL_HOME=${INSTALL_HOME}/Elastic
## ELASTIC_HOME  elastic 根目录：/opt/hzgc/bigdata/Elastic/elastic
ELASTIC_HOME=${ELASTIC_INSTALL_HOME}/elastic
## JAVA_HOME
JAVA_HOME=${INSTALL_HOME}/JDK/jdk

## 获取es的安装节点，放入数组中
ES_HOSTNAME_LISTS=$(grep ES_InstallNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
ES_HOSTNAME_ARRY=(${ES_HOSTNAME_LISTS//;/ })
echo ${ES_HOSTNAME_ARRY}

## 创建ELASTIC的安装目录
mkdir -p ${ELASTIC_HOME}

#---------------------------------------------------------------------#
#                              定义函数                                #
#---------------------------------------------------------------------#


#####################################################################
# 函数名: compression_the_tar
# 描述: 在本机上解压 elastic 安装包
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function compression_the_tar()
{
	echo ""  | tee -a $LOG_FILE
	echo "**********************************************" | tee -a $LOG_FILE
	echo "please waitinng, elastic jar 包解压中........"  | tee -a $LOG_FILE
	cd ${ELASTIC_SOURCE_DIR}  ## 进入 elastic 安装包目录
	tar -xf elastic.tar.gz  ## 解压 elastic 安装包
	if [ $? == 0 ];then  ## 判断返回值
		echo "解压elastic jar 包成功." | tee -a $LOG_FILE
	else
	   echo "解压elastic jar 包失败，请检查包是否完整。" | tee -a $LOG_FILE  
	fi
	cd - 
}

#####################################################################
# 函数名: config_yml_hostnamelist
# 描述: 将elasticsearch.yml中的discovery.zen.ping.unicast.hosts: [host_name_list]
# 		配置为 ["s1xx", "s1xx","s1xx"]
# 		tmp拼接后是：“s101”,"s102","s103",需要删除最右边的一个逗号“,”，
# 		${tmp%?}中的%号表示截取，以删除右边字符（,），保留左边字符（“s101”,"s102","s103"）
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_yml_hostnamelist()
{
	echo ""  | tee -a $LOG_FILE
	echo "**********************************************" | tee -a $LOG_FILE
	echo "please waitinng, 修改elasticsearch.yml的配置........"  | tee -a $LOG_FILE
	echo ""  | tee -a $LOG_FILE

	tmp=""
	for hostname in ${ES_HOSTNAME_ARRY[@]};do
		tmp="$tmp\"${hostname}\","  # 拼接字符串
	done
	tmp=${tmp%?}

	#替换discovery.zen.ping.unicast.hosts字段的值
    sed -i "s#^discovery.zen.ping.unicast.hosts:.*#discovery.zen.ping.unicast.hosts: [${tmp}]#g" ${ELASTIC_SOURCE_DIR}/elastic/config/elasticsearch.yml

	echo "修改discovery.zen.ping.unicast.hosts:[${tmp}]成功"  | tee -a $LOG_FILE
	echo ""  | tee -a $LOG_FILE
		
	cd -
}

#####################################################################
# 函数名: rsync_file
# 描述: 把解压后的安装包分发到集群不同节点的安装目录下
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function rsync_file(){

	echo ""  | tee -a $LOG_FILE
	echo "**********************************************" | tee -a $LOG_FILE
	echo "please waitinng, 解压后安装文件夹分发中........"  | tee -a $LOG_FILE
	for hostname in ${ES_HOSTNAME_ARRY[@]};do
		ssh root@${hostname}  "mkdir -p ${ELASTIC_INSTALL_HOME}"  
		rsync -rvl ${ELASTIC_SOURCE_DIR}/elastic   root@${hostname}:${ELASTIC_INSTALL_HOME}  >/dev/null
		ssh root@${hostname}  "chmod -R 755   ${ELASTIC_INSTALL_HOME}"  ## 修改拷过去的文件夹权限为可执行
	done
	cd -
	echo "分发elastic 解压后的 tar包done..."  | tee -a $LOG_FILE  
	echo "**********************************************" | tee -a $LOG_FILE
	echo "" | tee -a $LOG_FILE
}

#####################################################################
# 函数名: config_yml_hostandIP
# 描述: 在每个节点上配置安装目录elasticsearch.yml中的:
# 		node.name: 对应节点的主机名
# 		network.host：对应节点的IP
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_yml_hostandIP(){
	echo ""  | tee -a $LOG_FILE
	echo "**********************************************" | tee -a $LOG_FILE
	echo "每个节点上配置elasticsearch.yml中的node.name和network.host........"  | tee -a $LOG_FILE
	for hostname in ${ES_HOSTNAME_ARRY[@]};do
		
		## 配置elasticsearch.yml中的node.name为当前节点的主机名
		ssh root@${hostname} "sed -i 's#^node.name:.*#node.name: ${hostname}#g' ${ELASTIC_HOME}/config/elasticsearch.yml"
		echo "修改node.name:${hostname}成功"  | tee -a $LOG_FILE
		
		## 获取每个节点的IP
		ip=$(cat /etc/hosts|grep "$hostname" | awk '{print $1}')
		## 配置elasticsearch.yml中的network.host为当前节点的IP
		ssh root@${hostname} "sed -i 's#^network.host:.*#network.host: ${ip}#g' ${ELASTIC_HOME}/config/elasticsearch.yml"
		
		echo "修改${hostname}的network.host成功"  | tee -a $LOG_FILE
	done
	cd -

	echo "**********************************************" | tee -a $LOG_FILE
	echo ""  | tee -a $LOG_FILE

}

#####################################################################
# 函数名: move_file
# 描述: 每个节点上移动3个文件到相应目录
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function move_file()
{
	echo ""  | tee -a $LOG_FILE
	echo "**********************************************" | tee -a $LOG_FILE
	echo "" | tee -a $LOG_FILE
	echo "在每个节点上移动es的3个文件到相应目录下......"    | tee -a $LOG_FILE

	echo "移动etc_security_limits.conf 到 目录/etc/security/limits.conf下......"    | tee -a $LOG_FILE
	echo "移动etc_security_limits.d_90-nproc.conf 到 目录/etc/security/limits.d/90-nproc.conf下......"    | tee -a $LOG_FILE
	echo "移动etc_sysctl.conf 到 目录/etc/sysctl.conf下......"    | tee -a $LOG_FILE
	echo "" | tee -a $LOG_FILE
	for hostname in ${ES_HOSTNAME_ARRY[@]};do
		ssh root@${hostname} "mv ${ELASTIC_HOME}/config/etc_security_limits.conf   /etc/security/limits.conf"
		ssh root@${hostname} "mv ${ELASTIC_HOME}/config/etc_security_limits.d_90-nproc.conf   /etc/security/limits.d/90-nproc.conf"
		ssh root@${hostname} "mv ${ELASTIC_HOME}/config/etc_sysctl.conf   /etc/sysctl.conf"
		echo "${hostname}节点上移动完成."    | tee -a $LOG_FILE
		echo "动态地修改${hostname}内核的运行参数.."    | tee -a $LOG_FILE
		ssh root@${hostname} "sysctl -p"
		echo ""    | tee -a $LOG_FILE
	done
	cd -
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
    compression_the_tar
    config_yml_hostnamelist
	rsync_file
	config_yml_hostandIP
    move_file
}


#---------------------------------------------------------------------#
#                              执行流程                                #
#---------------------------------------------------------------------#

## 打印时间
echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE
main
echo "安装完毕...."                       | tee  -a  $LOG_FILE

set +x
