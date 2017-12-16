#!/bin/bash
################################################################################
## Copyright:   HZGOSUN Tech. Co, BigData
## Filename:    haproxyInstall.sh
## Description: 安装配置Haproxy代理
##              实现自动化的脚本
## Version:     1.0
## Author:      pengcong
## Created:     2017-11-8 
################################################################################

 
cd `dirname $0`
## 脚本所在目录
BIN_DIR=`pwd`
cd ..
## 安装包根目录
ROOT_HOME=`pwd`
## 配置文件目录
CONF_DIR=${ROOT_HOME}/conf
##  haproxy 安装包目录
HAPROXY_SOURCE_DIR=${ROOT_HOME}/component/bigdata
## 最终安装的根目录，所有bigdata 相关的根目录
INSTALL_HOME=$(grep Install_HomeDir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
## HAPROXY_INSTALL_HOME HAPROXY 安装目录
HAPROXY_INSTALL_HOME=${INSTALL_HOME}/HAPrxoy
## HAPROXY_HOME  HAPROXY 根目录
HAPROXY_HOME=${HAPROXY_INSTALL_HOME}/haproxy
## HAPROXY_LOG_DIR HAPROXY 日志目录
HAPROXY_LOG_DIR=${HAPROXY_HOME}/logs
## HAPROXY_LOG_FILE HAPROXY 日志文件
HAPROXY_LOG_FILE=${HAPROXY_LOG_DIR}/haproxy.log
## HAPROXY_INIT 开机启动脚本
HAPROXY_INIT=/etc/ini.d/haproxy
##HAPROXY_CFG haproxy 配置文件
HAPROXY_CFG=${HAPROXY_HOME}/haproxy.cfg

INSTALL_Host=$(grep HAproxy_AgencyNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
### HAproxy配置文件
HAproxy_conf_file=$HAPROXY_HOME/haproxy.cfg 
### HAproxy临时文件
TMP_FILE=$HAPROXY_HOME/tmp


#####################################################################
# 函数名: intstall_ha_cfg
# 描述: haproxy配置文件haproxy.cfg设置，启动脚本时请按实际情况修改
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function install_ha_cfg()
{ 
echo " 
###########全局配置#########

global
    log         127.0.0.1 local1                 ##[日志输出配置，所有日志都记录在本机，通过local1输出
    chroot      ${HAPROXY_HOME}
    pidfile     ${HAPROXY_HOME}/haproxy.pid
    maxconn     4000                             ##最大连接数
    user        root                             ##运行haproxy的用户
    group       root                             ##运行haproxy的用户所在的组
    daemon                                       ##以后台形式运行harpoxy

stats socket ${HAPROXY_HOME}/stats

########默认配置############

defaults
    mode                    tcp                  ##默认的模式mode { tcp|http|health }，tcp是4层，http是7层，health只会返回OK
    log                     global
    option                  tcplog               ##日志类别,采用tcplog
    option                  dontlognull          ##不记录健康检查日志信息
    option                  abortonclose         ##当服务器负载很高的时候，自动结束掉当前队列处理比较久的链接
    option                  redispatch           ##当serverId对应的服务器挂掉后，强制定向到其他健康的服务器，以后将不支持
    retries                 3                    ##3次连接失败就认为是服务器不可用，也可以通过后面设置
    timeout queue           1m                   ##默认队列超时时间
    timeout connect         10s                  ##连接超时
    timeout client          1m                   ##客户端超时
    timeout server          1m                   ##服务器超时
    timeout check           10s                  ##心跳检测超时
    maxconn                 3000                 ##默认的最大连接数
    
########服务器节点配置########
listen ftp
    bind 0.0.0.0:2121                            ##设置haproxy监控的服务器和端口号，0.0.0.0默认全网段
    mode tcp                                     ##http的7层模式
    #balance roundrobin  
    balance source                               ##设置默认负载均衡方式，类似于nginx的ip_hash
    #server <name> <address>[:port] [param*]
    #[param*]为后端设定参数
    #weight num权重 默认为1，最大值为256，0表示不参与负载均衡
    #check启用后端执行健康检测
    #inter num 健康状态检测时间间隔
    ##server s112 172.18.18.112:2121 weight 1 maxconn 10000 check inter 10s  

########统计页面配置########
listen admin_stats  
    bind 0.0.0.0:8099                            ##统计页面监听地址
    stats enable
    mode http 
    option httplog 
    maxconn 10  
    stats refresh 10s                            ##页面刷新时间
    stats uri /stats                             ##统计页面url，可通过http://ip:8099/stats访问配置文件
" > "$HAPROXY_CFG" 
}
 
#####################################################################
# 函数名:cfg_config 
# 描述: 修改cfg配置文件
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function cfg_config ()
{
    echo ""  | tee -a $LOG_FILE
    echo "*****************************************************" | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
    echo "配置haproxy.cfg.............................."  | tee  -a  $LOG_FILE
    #声明一个数组用来存储host=ip
	declare -a host_iparr
    # 根据ftp_serviceip字段，查找配置文件中，FTP服务节点主机名
    FTP_SERVICEIPS=$(grep HAproxy_ServiceNode ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
    ftp_arr=(${FTP_SERVICEIPS//;/ }) 
	#找出主机名对应的IP
	for host_name in ${ftp_arr[@]}
    do
        ip=$(cat /etc/hosts|grep "$host_name" | awk '{print $1}')
        host_ip=${host_name}"="${ip}
        host_iparr=(${host_iparr[*]} ${host_ip})
    done
    # 在文件末尾添加FTP服务节点hostname=ip 
    for ftp_ip in ${host_iparr[@]}
    do
        echo "server ${ftp_ip//=/ }:2121 weight 1 maxconn 10000 check inter 10s" >> ${TMP_FILE}
    done
	# 将临时文件中hostname ip追加到##server s2 172.18.18.112:2121 weight 1 maxconn 10000 check inter 10s 
	sed -i "/##server/ r ${TMP_FILE}" $HAproxy_conf_file 
        rm -rf ${TMP_FILE}
	echo "配置config_Haproxy完毕......"  | tee  -a  $LOG_FILE
}

#####################################################################
# 函数名:install_ha_init 
# 描述: 将haproxy服务添加到开机启动
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function install_ha_init ()
{
    if [ ! -e "$HAPROXY_INIT" ]; then
        cp ${ROOT_HOME}/service/haproxy-control.sh /etc/init.d/haproxys
        sed -i "s#HAPROXY_DIR=#HAPROXY_DIR=${HAPROXY_HOME}#g" /etc/init.d/haproxys
    else
        echo "File haproxy already there !" | tee -a $LOG_FILE
    fi
}

#####################################################################
# 函数名: writeUI_file
# 描述: 将haproxy的UI地址写到指定文件中
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function writeUI_file()
{
    echo ""  | tee -a $LOG_FILE
    echo "**********************************************" | tee -a $LOG_FILE
    echo "准备将haproxy的UI地址写到指定文件中............"    | tee -a $LOG_FILE
    HaproxyWebUI_Dir=$(grep WebUI_Dir ${CONF_DIR}/cluster_conf.properties|cut -d '=' -f2)
    Install_IP=$(cat /etc/hosts|grep "$INSTALL_Host" | awk '{print $1}')
    Haproxy_UI="http://${Install_IP}:8099/stats"
    mkdir -p ${HaproxyWebUI_Dir}
    grep -q "HAproxyUI_Address=" ${HaproxyWebUI_Dir}/WebUI_Address
    if [ "$?" -eq "0" ]  ;then
        sed -i "s#^HAproxyUI_Address=.*#HAproxyUI_Address=${Haproxy_UI}#g" ${HaproxyWebUI_Dir}/WebUI_Address
    else
        echo "##HAproxy_WebUI" >> ${HaproxyWebUI_Dir}/WebUI_Address
        echo "HAproxyUI_Address=${Haproxy_UI}" >> ${HaproxyWebUI_Dir}/WebUI_Address
    fi 
}
 
#####################################################################
# 函数名: main
# 描述: 模块功能main 入口，即程序入口, 用来安装Haproxy。
# 参数: N/A
# 返回值: N/A
# 其他: N/A
#####################################################################
function main()
{
    if [ ! -e "$HAPROXY_HOME" ]; then 
        mkdir -p ${HAPROXY_HOME}
        cd ${HAPROXY_SOURCE_DIR} 
        tar zxf haproxy*.tar.gz
        cd haproxy*/ 
        make TARGET=linux26 ARCH=x86_64 PREFIX=${HAPROXY_HOME} && make install PREFIX=${HAPROXY_HOME} && mkdir ${HAPROXY_HOME}/{html,logs,conf} 
        ! grep 'haproxy' /etc/rsyslog.conf && echo 'local1.*            ${HAPROXY_HOME}/log/haproxy.log' >> /etc/rsyslog.conf
        sed -ir 's/SYSLOGD_OPTIONS="-m 0"/SYSLOGD_OPTIONS="-r -m 0"/g' /etc/sysconfig/rsyslog 
        install_ha_cfg
        cfg_config
        writeUI_file
        install_ha_init
        echo "将HAproxy根目录分发到${INSTALL_Host}" | tee -a $HAPROXY_LOG_FILE
        echo "*****************************************************" | tee -a $HAPROXY_LOG_FILE
        ssh root@$INSTALL_Host "mkdir -p ${HAPROXY_INSTALL_HOME}"
        rsync -rvl ${HAPROXY_INSTALL_HOME}/haproxy $INSTALL_Host:${HAPROXY_INSTALL_HOME}   > /dev/null
        ssh root@$INSTALL_Host "mkdir -p ${BIN_DIR}"
        rsync -rvl ${ROOT_HOME}/service/haproxy-control.sh $INSTALL_Host:${ROOT_HOME}/service/ > /dev/null
        scp -r /etc/init.d/haproxys $INSTALL_Host:/etc/init.d/
        ssh root@$INSTALL_Host "source /etc/profile; chmod +x /etc/init.d/haproxys; chkconfig --add haproxys; chkconfig haproxys on"
        rm -rf haproxy-*/
    else
        echo -e "haproxy is already exists!" | tee -a $HAPROXY_LOG_FILE
    fi
}

# 主程序入口
main

set +x
