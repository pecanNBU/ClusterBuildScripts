#!/bin/bash 
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    mysqlInstall.sh
## Description: 安装并启动mysql。
##              实现自动化的脚本
## Version:     1.0
## Author:      lidiliang
## Created:     2017-12-8  caodabao
################################################################################

#set -x

cd `dirname $0`
## BIN目录，脚本所在的目录
BIN_DIR=`pwd`
cd ..
## 安装包根目录
ROOT_HOME=`pwd`
## 配置文件目录
CONF_DIR=${ROOT_HOME}/conf
## mysql rpm 软件包所在目录
MYSQL_RPM_DIR=${ROOT_HOME}/component/basic_suports/mysqlRpm
## 日记目录
LOG_DIR=${ROOT_HOME}/logs
## mysql 安装日记
LOG_FILE=${LOG_DIR}/mysqlInstall.log

##mysql数据库信息
USERNAME="root"


mkdir -p ${LOG_DIR}

echo ""  | tee  -a  $LOG_FILE
echo ""  | tee  -a  $LOG_FILE
echo "==================================================="  | tee -a $LOG_FILE
echo "$(date "+%Y-%m-%d  %H:%M:%S")"                       | tee  -a  $LOG_FILE

## 首先检查本机上是否安装有mysql 如果有，则删除本机的mysql 
rpm -qa | grep mysql   > mysql.tmp
for rpm_pak in $(cat  mysql.tmp);do
    echo "==================================================="  | tee -a $LOG_FILE
    echo "删除原先系统mysql rpm 软件包: ${rpm_pak}"  |  tee  -a  $LOG_FILE
    rpm -e --nodeps ${rpm_pak}
done
rm -rf mysql.tmp

## 查看对应MySQL目录,如果存在则删除对应目录
find / -name mysql > mysql.tmp
for mysql_dir in $(cat  mysql.tmp);do
    echo "==================================================="  | tee -a $LOG_FILE
    echo "删除对应的mysql目录: ${mysql_dir}"  |  tee  -a  $LOG_FILE
    rm -rf ${mysql_dir}
done
rm -rf mysql.tmp

## 删除对应my.cnf文件
MY_CNF="/etc/my.cnf"
#if [-f "${MY_CNF}"];then
    echo "删除my.cnf文件.................."  |  tee  -a  $LOG_FILE
    rm -rf /etc/my.cnf
#fi

## 删除对应mysqld.log文件
MYSQL_LOG="/var/log/mysqld.log"
#if [-f "${MY_CNF}"];then
    echo "删除mysqld.log文件................................."  |  tee  -a  $LOG_FILE
    rm -rf /var/log/mysqld.log
#fi


## 重新安装mysql
echo "开始重新安装mysql................................."  |  tee  -a  $LOG_FILE
rpm -ivh ${MYSQL_RPM_DIR}/mysql-community-common-5.7.19-1.el6.x86_64.rpm
rpm -ivh ${MYSQL_RPM_DIR}/mysql-community-libs-5.7.19-1.el6.x86_64.rpm
rpm -ivh ${MYSQL_RPM_DIR}/mysql-community-client-5.7.19-1.el6.x86_64.rpm
rpm -ivh ${MYSQL_RPM_DIR}/mysql-community-server-5.7.19-1.el6.x86_64.rpm

## 启动mysql 服务
service mysqld start

## 显示初始时候的临时密码
password=$(cat /var/log/mysqld.log|grep 'temporary password'  | awk -F ": " '{print $NF}')
if [ -n "${password}" ];then
    echo "the password is:  ${password}"  | tee  -a  $LOG_FILE
    echo  "install mysql done ！！！"  | tee  -a  $LOG_FILE
else 
    echo "install mysql failed !!! please check the error and fixed it..."  | tee  -a  $LOG_FILE
fi 

## 启动mysql 并创建数据库
echo "==================================================="  | tee -a $LOG_FILE
service mysqld start
if [ $? == 0 ];then
    echo "开始操作Mysql......"  |  tee  -a  $LOG_FILE
    /usr/bin/mysqladmin -uroot -p$password password $"Hzgc@123"
    /usr/bin/mysql -uroot -p"Hzgc@123" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Hzgc@123' WITH GRANT OPTION;flush privileges;"
    if [ $? == 0 ];then
        echo "操作MySQL成功......................."  | tee -a $LOG_FILE
    else
        echo "操作MySQL失败......................."  | tee -a $LOG_FILE
    fi
else
    echo "启动MySQL失败..........................."  | tee -a $LOG_FILE
fi
set +x
