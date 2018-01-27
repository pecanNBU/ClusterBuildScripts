#!/bin/bash 
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    azkabanInstall.sh
## Description: 安装azkaban。
##              实现自动化的脚本
## Version:     1.0
## Author:      caodabao
## Created:     2018-1-12 
################################################################################

#set -x

cd `dirname $0`
BIN_DIR=`pwd`                                                                            ### 脚本所在目录
cd ..
ROOT_HOME=`pwd`                                                                          ### 安装包根目录
CONF_DIR=${ROOT_HOME}/conf                                                               ### 配置文件目录
LOG_DIR=${ROOT_HOME}/logs                                                                ### 日记目录
LOG_FILE=${LOG_DIR}/azkabanInstall.log                                                    ### azkaban 安装日记
AZKABAN_SOURCE_DIR=${ROOT_HOME}/component/bigdata                                        ### azkaban 安装包目录

INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)  ### 最终安装的根目录，所有bigdata 相关的根目录
AZKABAN_INSTALL_HOME=${INSTALL_HOME}/Azkaban                                             ### AZKABAN_INSTALL_HOME azkaban 安装目录
AZKABAN_HOME=${AZKABAN_INSTALL_HOME}/azkaban                                             ### AZKABAN_HOME  azkaban 根目录

MYSQL_HOSTNAME=$(grep Mysql_InstallNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2) ###mysql安装节点主机名
MYSQL_PASSWORD=$(grep MYSQL_Password ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2) ###mysql登录密钥
AZKABAN_DATABASE="azkaban"
SSL_PASSWORD=$(grep SSH_Password ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)     ###ssl密钥

mkdir -p ${AZKABAN_HOME}
mkdir -p ${LOG_DIR}


#####################################################################
# 函数名: compression_the_tar
# 描述: 获取开源azkaban 安装包解压并复制。
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function compression_the_tar()
{   
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "please waitinng, azkaban jar 包解压中*********"  | tee -a $LOG_FILE
    cd $AZKABAN_SOURCE_DIR
    tar -xf azkaban.tar.gz
    if [ $? == 0 ];then
        echo "解压azkaban jar 包成功." | tee -a $LOG_FILE
    else
       echo "解压azkaban jar 包失败，请检查包是否完整。" | tee -a $LOG_FILE  
    fi

    cd -  
}

#####################################################################
# 函数名: config_webazkaban_properties
# 描述: 配置webserver目录下的azkaban.properties配置文件。
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_webazkaban_properties()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "开始配置web目录下的azkaban.properties文件*****" | tee -a $LOG_FILE
    mysql_ip=$(cat /etc/hosts|grep "$MYSQL_HOSTNAME" | awk '{print $1}')
    sed -i "s#^mysql.host=.*#mysql.host=${mysql_ip}#g" ${AZKABAN_SOURCE_DIR}/azkaban/webserver/conf/azkaban.properties
    flag1=$?
    sed -i "s#^mysql.database=.*#mysql.database=${AZKABAN_DATABASE}#g" ${AZKABAN_SOURCE_DIR}/azkaban/webserver/conf/azkaban.properties
    flag2=$?
    sed -i "s#^mysql.password=.*#mysql.password=${MYSQL_PASSWORD}#g" ${AZKABAN_SOURCE_DIR}/azkaban/webserver/conf/azkaban.properties
    flag3=$?
    sed -i "s#^jetty.password=.*#jetty.password=${SSL_PASSWORD}#g" ${AZKABAN_SOURCE_DIR}/azkaban/webserver/conf/azkaban.properties
    flag4=$?
    sed -i "s#^jetty.keypassword=.*#jetty.keypassword=${SSL_PASSWORD}#g" ${AZKABAN_SOURCE_DIR}/azkaban/webserver/conf/azkaban.properties
    flag5=$?
    sed -i "s#^jetty.trustpassword=.*#jetty.trustpassword=${SSL_PASSWORD}#g" ${AZKABAN_SOURCE_DIR}/azkaban/webserver/conf/azkaban.properties
    flag6=$?
    
    if [[ ($flag1 == 0)  && ($flag2 == 0)  &&  ($flag3 == 0)  && ($flag4 == 0)  &&  ($flag5 == 0)  && ($flag6 == 0) ]];then
        echo " webserver目录下的azkaban.properties配置成功." | tee -a $LOG_FILE
    else
        echo "webserver目录下的azkaban.properties配置失败." | tee -a $LOG_FILE
    fi
}

#####################################################################
# 函数名: config_exeazkaban_properties
# 描述: 配置 executor 目录下的azkaban.properties配置文件。
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function config_exeazkaban_properties()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "开始配置executor目录下的azkaban.properties文件*****" | tee -a $LOG_FILE
    mysql_ip=$(cat /etc/hosts|grep "$MYSQL_HOSTNAME" | awk '{print $1}')
    sed -i "s#^mysql.host=.*#mysql.host=${mysql_ip}#g" ${AZKABAN_SOURCE_DIR}/azkaban/executor/conf/azkaban.properties
    flag1=$?
    sed -i "s#^mysql.database=.*#mysql.database=${AZKABAN_DATABASE}#g" ${AZKABAN_SOURCE_DIR}/azkaban/executor/conf/azkaban.properties
    flag2=$?
    sed -i "s#^mysql.password=.*#mysql.password=${MYSQL_PASSWORD}#g" ${AZKABAN_SOURCE_DIR}/azkaban/executor/conf/azkaban.properties
    flag3=$?
    
    if [[ ($flag1 == 0)  && ($flag2 == 0)  &&  ($flag3 == 0) ]];then
        echo " executor 目录下的azkaban.properties配置成功." | tee -a $LOG_FILE
    else
        echo "executor 目录下的azkaban.properties配置失败." | tee -a $LOG_FILE
    fi
}

#####################################################################
# 函数名: xync_azkaban
# 描述: azkaban安装包复制到安装目录下
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function xync_azkaban()
{
    rm -rf ${AZKABAN_HOME}
    scp -r ${AZKABAN_SOURCE_DIR}/azkaban root@${MYSQL_HOSTNAME}:${AZKABAN_INSTALL_HOME}  >/dev/null
    if [ $? == 0 ];then
        echo "azkaban安装包移动完成**************"
    else
        echo "azkaban安装包移动失败**************"
    fi
}

#####################################################################
# 函数名: create_database
# 描述: 创建azkaban数据库并建表。
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function create_database()
{
    echo ""  | tee  -a  $LOG_FILE
    echo ""  | tee  -a  $LOG_FILE
    echo "==================================================="  | tee -a $LOG_FILE
    echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE

    ##判断建表文件是否存在
    SQL_FILE=${AZKABAN_HOME}/sql/create-all-sql-2.5.0.sql
    if [ -f "${SQL_FILE}" ]; then 
        echo "建表文件存在，可以建表...."
    else
        echo "建表文件create-all-sql-2.5.0.sql不存在，请检视安装包是否完整...."
        exit 0
    fi

    ## 启动mysql 并创建数据库
    service mysqld start
    if [ $? == 0 ];then
        echo "开始操作Mysql......"  |  tee  -a  $LOG_FILE
        /usr/bin/mysql -uroot -p"Hzgc@123" -e "source ${AZKABAN_HOME}/sql/create-all-sql-2.5.0.sql "
        if [ $? == 0 ];then
            echo "操作MySQL成功......................."  | tee -a $LOG_FILE
        else
            echo "操作MySQL失败......................."  | tee -a $LOG_FILE
        fi
    else
        echo "启动MySQL失败..........................."  | tee -a $LOG_FILE
    fi
}

#####################################################################
# 函数名: create_ssl
# 描述: 配置SSL的KeyStore。
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function create_ssl()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "开始配置SSL的KeyStore************************ " | tee -a $LOG_FILE
    rm -rf ${AZKABAN_HOME}/webserver/azkaban.keystore
    ssh root@${MYSQL_HOSTNAME} "source /etc/profile;keytool -keystore ${AZKABAN_HOME}/webserver/keystore -alias jetty -genkey -keyalg RSA -dname \"CN=, OU=, O=, L=, ST=, C=CN\"  -keypass ${SSL_PASSWORD} -storepass ${SSL_PASSWORD}"
    KEYSTORE_FILE=${AZKABAN_HOME}/webserver/keystore
    if [ -f "${KEYSTORE_FILE}" ]; then 
        echo "keystore文件创建成功...."
    else
        echo "keystore文件创建失败，请检视配置SSL语句是否正确...."
        exit 0
    fi
}

#####################################################################
# 函数名: main
# 描述:  安装azkaban主函数
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function main()
{
    compression_the_tar
    config_webazkaban_properties
    config_exeazkaban_properties
    xync_azkaban
    create_database
    create_ssl
}


echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE
main

set +x
