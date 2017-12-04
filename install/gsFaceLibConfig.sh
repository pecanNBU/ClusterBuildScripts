#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    gsFaceLibConfig.sh
## Description: 配置算法库.
## Version:     1.0
## Author:      mashencai
## Created:     2017-11-16
################################################################################

#set -x

#---------------------------------------------------------------------#
#                              定义变量                               #
#---------------------------------------------------------------------#

## 进入当前目录
cd `dirname $0`
## 脚本所在目录：../hzgc/service
BIN_DIR=`pwd`
cd ..
## 脚本根目录：../hzgc
ROOT_HOME=`pwd`
## gsFaceLib 压缩包目录：../hzgc/component/bigdata
GSFACELIB_SOURCE_DIR=${ROOT_HOME}/component/bigdata
## 配置文件目录：../hzgc/conf
CONF_DIR=${ROOT_HOME}/conf
## 安装日记目录
LOG_DIR=${ROOT_HOME}/logs
## 安装日记目录
LOG_FILE=${LOG_DIR}/gsFaceLib.log

if [ ! -d $LOG_DIR ];then
    mkdir -p $LOG_DIR;
fi
#---------------------------------------------------------------------#
#                              定义函数                               #
#---------------------------------------------------------------------#

#####################################################################
# 函数名: compression_the_tar
# 描述: 解压GsFaceLib.tar.gz
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function compression_the_tar()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "please waiting, GsFaceLib.tar.gz解压中........"  | tee -a $LOG_FILE

    tar -xf ${GSFACELIB_SOURCE_DIR}/GsFaceLib.tar.gz -C ${GSFACELIB_SOURCE_DIR} #与注释的语句等价

    echo "GsFaceLib, 解压完成........"  | tee -a $LOG_FILE
    if [ $? == 0 ];then  ## 判断返回值
        echo "解压GsFaceLib tar 包成功." | tee -a $LOG_FILE
    else
        echo "解压elastic tar 包失败，请检查包是否完整。" | tee -a $LOG_FILE  
    fi
    echo "" | tee -a $LOG_FILE
}

#####################################################################
# 函数名: rsync_GsFaceLib
# 描述: 将解压后的GsFaceLib分发到各个节点
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function rsync_GsFaceLib(){
    echo "**********************************************" | tee -a $LOG_FILE
    for hostname in $(cat ${CONF_DIR}/hostnamelists.properties);do
        echo " GsFaceLib分发到${hostname}........"  | tee -a $LOG_FILE
        #rsync -rvl ${GSFACELIB_SOURCE_DIR}/GsFaceLib   root@${hostname}:/opt  >/dev/null
        scp -r ${GSFACELIB_SOURCE_DIR}/GsFaceLib   root@${hostname}:/opt  >/dev/null
    done

    echo "GsFaceLib 分发完毕 ..."  | tee -a $LOG_FILE  
    echo "" | tee -a $LOG_FILE
}

#####################################################################
# 函数名: add_env
# 描述: 在各个节点上判断/opt/profile中环境变量设置字串存在
#       不存在则添加追加到文件末尾：export LD_LIBRARY_PATH=/opt/GsFaceLib/face_libs
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function add_env(){
    echo "**********************************************" | tee -a $LOG_FILE
    echo "please waiting, 添加/opt/profile中的GsFaceLib环境变量 ........"  | tee -a $LOG_FILE
    for hostname in $(cat ${CONF_DIR}/hostnamelists.properties);do
        ssh root@${hostname} 'grep "export LD_LIBRARY_PATH=/opt/GsFaceLib/face_libs" /etc/profile; if [ $? -eq 1 ]; then echo 'export LD_LIBRARY_PATH=/opt/GsFaceLib/face_libs' >> /etc/profile; echo "添加成功...";fi'
        ssh root@${hostname} "source /etc/profile"
    done
}
#####################################################################
# 函数名: remove_snini
# 描述: 删除/opt/GsFaceLib下sn.ini文件
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function remove_snini(){
    echo "**********************************************" | tee -a $LOG_FILE
    echo "please waiting, 删除/opt/GsFaceLib下sn.ini文件 ........"  | tee -a $LOG_FILE
    for hostname in $(cat ${CONF_DIR}/hostnamelists.properties);do
        ssh root@${hostname} "rm -rf /opt/GsFaceLib/sn.ini"
    done
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
    rsync_GsFaceLib
    add_env
    remove_snini
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


set +x
