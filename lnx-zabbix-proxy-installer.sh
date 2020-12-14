#!/bin/bash
#skripta za namestitev Zabbix Proxy na Ubuntu 20.04
#Verzija: 0.2
#Izdelano: 12/2020
#
#Colors courtesy of: https://stackoverflow.com/a/20983251
#IP checking code courtesy of: https://stackoverflow.com/a/13778973


zabbixServerAddress=""
downloadFileUrl="https://repo.zabbix.com/zabbix/5.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.2-1+ubuntu$(lsb_release -rs)_all.deb"
echo $(tput setaf 2)"Enter Zabbix Proxy address and press [ENTER]:"$(tput sgr0)
read -p "Zabbix server IP address: " zabbixServerAddress
if expr "$zabbixServerAddress" : '[1-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
  for i in 1 2 3 4; do
    if [ $(echo "$zabbixServerAddress" | cut -d. -f$i) -gt 255 ]; then
      echo $(tput setab 1)$(tput setaf 7)"($zabbixServerAddress) - IP can not be greater than 255"$(tput sgr0)
      exit 1
    fi
  done
  echo $(tput setab 2)$(tput setaf 7)"($zabbixServerAddress) - IP is valid. Moving on."$(tput sgr0)
else
  echo $(tput setab 1)$(tput setaf 7)"($zabbixServerAddress) - IP format is invalid"$(tput sgr0)
  exit 1
fi

#download .deb, save filename to $downloadFilename
echo $(tput setaf 2)Downloading sources...$(tput sgr0)
downloadFilename=$(wget -nv $downloadFileUrl 2>&1 | cut -d\" -f2)

#install .deb file
echo $(tput setaf 2)Installing sources...$(tput sgr0)
dpkg -i $downloadFilename > /dev/null

#update apt cache
echo $(tput setaf 2)Running apt-get update...$(tput sgr0)
apt-get update > /dev/null

#install zabbix-proxy and zabbix-get package
echo $(tput setaf 2)Installing package zabbix-proxy-mysql...$(tput sgr0)
apt-get -y install zabbix-proxy-mysql > /dev/null

#generate random password
randomPassword=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32})

#installing mysql
echo $(tput setaf 2)Installing package mariadb-common, mariadb-server, mariadb-client...$(tput sgr0)
apt-get -y install mariadb-common mariadb-server mariadb-client > /dev/null

systemctl start mariadb > /dev/null
systemctl enable mariadb > /dev/null

mysql -uroot <<MYSQL_SCRIPT
create database zabbix_proxy character set utf8 collate utf8_bin;
grant all privileges on zabbix_proxy.* to zabbix@localhost identified by '${randomPassword}';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

apt-get -y install zabbix-proxy-mysql > /dev/null

echo $(tput setaf 2)"Importing Zabbix Proxy schema into MySQL (this can take a while)..."$(tput sgr0)
zcat /usr/share/doc/zabbix-proxy-mysql*/schema.sql.gz |  mysql -uzabbix -p$randomPassword zabbix_proxy

#nastavi zabbix proxy da se zazene ob rebootu
echo $(tput setaf 2)Setting Zabbix Proxy service to run at startup...$(tput sgr0)
systemctl start zabbix-proxy.service >  /dev/null
systemctl enable zabbix-proxy.service > /dev/null

#pridobi hostname serverja za vpis v config file
proxyHostname=$(hostname)

#ustavi agenta preden urejamo .conf file
echo $(tput setaf 2)Stopping Zabbix Proxy to configure...$(tput sgr0)
service zabbix-proxy stop > /dev/null

#premaknemo originalen zabbix_proxy.conf file
echo $(tput setaf 2)"Moving original zabbix_proxy.conf to /etc/zabbix/zabbix_proxy.conf.example just in case..."$(tput sgr0)
mv /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf.example

#kreira nov zabbix_proxy.conf file z nasimi nastavitvami
echo $(tput setaf 2)Creating new Zabbix Proxy config file...$(tput sgr0)
cat > /etc/zabbix/zabbix_proxy.conf << EOF
ProxyMode=0
Server=${zabbixServerAddress}
Hostname=${proxyHostname}
LogFile=/var/log/zabbix/zabbix_proxy.log
LogFileSize=50
EnableRemoteCommands=1
LogRemoteCommands=1
PidFile=/var/run/zabbix/zabbix_proxy.pid
SocketDir=/var/run/zabbix
DBName=zabbixproxy
DBUser=zabbix
DBPassword=${randomPassword}
ProxyOfflineBuffer=48
ConfigFrequency=60
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
ExternalScripts=/usr/lib/zabbix/externalscripts
FpingLocation=/usr/bin/fping
Fping6Location=/usr/bin/fping6
LogSlowQueries=3000
StatsAllowedIP=127.0.0.1
StartPingers=20
StartPollersUnreachable=20
CacheSize=1G
EOF

#zazene proxy nazaj
echo $(tput setaf 2)Starting Zabbix Proxy service...$(tput sgr0)
service zabbix-proxy start > /dev/null

echo "
#############
Your MySQL zabbix user password is: $(tput setaf 2)$randomPassword
Write it down!
#############
"

echo "Do you want to secure your MySQL installation? (y/n)?"$(tput sgr0)
read yesnoSecureMysql
if [ $yesnoSecureMysql = y ]
then
        mysql_secure_installation
else
        echo $(tput setab 1)$(tput setaf 7)"Your MySQL installation is not secure. MySQL root access has no password!"$(tput sgr0)
        exit 0
fi