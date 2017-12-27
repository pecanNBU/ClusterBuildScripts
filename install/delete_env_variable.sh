#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    delete_env_variable.sh
## Description: 删除系统中环境变量
##              实现自动化的脚本
## Version:     1.0
## Author:      mashencai
## Created:     2017-12-13
################################################################################

#set -x

#---------------------------------------------------------------------#
#                              定义变量                                #
#---------------------------------------------------------------------#

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
## 日记文件
LOG_FILE=${LOG_DIR}/delete_env_variable.log
##etc所在目录
ETC_FILE=/opt/source

mkdir -p ${LOG_DIR} 


#---------------------------------------------------------------------#
#                              定义函数                                #
#---------------------------------------------------------------------#

#####################################################################
# 函数名: delete_java_variable
# 描述: 删除各个节点上/etc/profile中的Java环境变量
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function delete_java_variable
{
	echo ""  | tee -a $LOG_FILE
	echo "**********************************************" | tee -a $LOG_FILE
	echo "please waitinng, 删除java环境变量........"  | tee -a $LOG_FILE
	# 从配置文件中获取jdk安装节点
	CLUSTER_HOST=$(grep Cluster_HostName ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
	jdkhost_arr=(${CLUSTER_HOST//;/ })    
	for jdk_host in ${jdkhost_arr[@]}
	do
		# java变量的注释行“#JAVA_HOME”是否存在，存在则删除
		javaComments_exists=$(ssh root@${jdk_host} 'grep "#JAVA_HOME" /etc/profile')
		if [ "${javaComments_exists}" != "" ];then
			ssh root@${jdk_host} "sed -i '/#JAVA_HOME/d' /etc/profile"
		fi
		# java变量的“export JAVA_HOME=”行是否存在，存在则删除
		javahome_exists=$(ssh root@${jdk_host} 'grep "export JAVA_HOME=" /etc/profile')
		if [ "${javahome_exists}" != "" ];then
			ssh root@${jdk_host} "sed -i '/export JAVA_HOME=/d' /etc/profile"
		fi
		# java变量的“export PATH=$JAVA_HOME”行是否存在，存在则删除
		javapath_exists=$(ssh root@${jdk_host} 'grep "export PATH=\$JAVA_HOME" /etc/profile')
		if [ "${javapath_exists}" != "" ];then
			ssh root@${jdk_host} "sed -i '/export PATH=\$JAVA_HOME/d' /etc/profile"
		fi
	done
	echo "删除java环境变量完成........"  | tee -a $LOG_FILE
}

#####################################################################
# 函数名: delete_namesrv_variable
# 描述: 删除各个节点上/etc/profile中的NAMESRV_ADDR环境变量
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function delete_namesrv_variable
{	
	echo ""  | tee -a $LOG_FILE
	echo "**********************************************" | tee -a $LOG_FILE
	echo "please waitinng, 删除namesrv环境变量........"  | tee -a $LOG_FILE
	## 拼接安装了Rocketmq的节点IP
	NameServer_Host=$(grep RocketMQ_Namesrv ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
	Broker_Hosts=$(grep RocketMQ_Broker ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
	Broker_Hostarr=(${Broker_Hosts//;/ }) 
	Host_Arr=(${Broker_Hostarr[*]} ${NameServer_Host})

	for insName in ${Host_Arr[@]}
	do
		# 判断是否存在export NAMESRV_ADDR=172.18.18.108:9876这一行，若存在删除
		namesrv_exists=$(ssh root@${insName} 'grep "export NAMESRV_ADDR=" /etc/profile')
		if [ "${namesrv_exists}" != "" ];then
			ssh root@${insName} "sed -i '/export NAMESRV_ADDR=/d' /etc/profile"
		fi
	done
	echo "删除namesrv环境变量完成........"  | tee -a $LOG_FILE
}

#####################################################################
# 函数名: delete_gsfacelib_variable
# 描述: 删除各个节点上/etc/profile中的gsfacelib环境变量
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function delete_gsfacelib_variable
{
	echo ""  | tee -a $LOG_FILE
	echo "**********************************************" | tee -a $LOG_FILE
	echo "please waitinng, 删除gsfacelib环境变量........"  | tee -a $LOG_FILE
	# 从配置文件中获取gsfacelib算法安装节点
	GSFACELIB_HOST=$(grep GsFaceLib_HostName ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
	gsfacelibhost_arr=(${GSFACELIB_HOST//;/ })    
	for gsfacelib_host in ${gsfacelibhost_arr[@]}
	do
		# gsfacelib算法的注释行“#LD_LIBRARY_PATH”是否存在，存在则删除
		facelibComments_exists=$(ssh root@${gsfacelib_host} 'grep "#LD_LIBRARY_PATH" /etc/profile')
		if [ "${facelibComments_exists}" != "" ];then
			ssh root@${gsfacelib_host} "sed -i '/#LD_LIBRARY_PATH/d' /etc/profile"
		fi
		# gsfacelib算法的“export LD_LIBRARY_PATH=”行是否存在，存在则删除
		facelibpath_exists=$(ssh root@${gsfacelib_host} 'grep "export LD_LIBRARY_PATH=" /etc/profile')
		if [ "${facelibpath_exists}" != "" ];then
			ssh root@${gsfacelib_host} "sed -i '/export LD_LIBRARY_PATH=/d' /etc/profile"
		fi
	done
	echo "删除gsfacelib环境变量完成........"  | tee -a $LOG_FILE
}

function main
{
	delete_java_variable
	delete_namesrv_variable
	delete_gsfacelib_variable
}

echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"   | tee -a $LOG_FILE
main
	
set +x	
