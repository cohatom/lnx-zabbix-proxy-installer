#!/bin/bash
#skripta za namestitev Zabbix Proxy na Ubuntu 20.04
#Verzija: 0.1
#Izdelano: 12/2020

#Colors curtesy of: https://stackoverflow.com/a/20983251
# mysql --user="$user" --password="$password" --database="$database" 

zabbixServerAddress=""
downloadFileUrl="https://repo.zabbix.com/zabbix/5.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.2-1+ubuntu$(lsb_release -rs)_all.deb"
echo "Vnesi IP naslov Zabbix strežnika in pritistni [ENTER]:"
read zabbixServerAddress

#download .deb, save filename to $downloadFilename
echo $(tput setaf 2)Downloading sources...$(tput sgr0)
downloadFilename=$(wget -nv $downloadFileUrl 2>&1 | cut -d\" -f2)

#install .deb file
echo $(tput setaf 2)Installing sources...$(tput sgr0)
dpkg -i $downloadFilename

#update apt cache
apt update

#install zabbix-proxy and zabbix-get package
echo $(tput setaf 2)Installing package zabbix-proxy$(tput sgr0)
apt -y install zabbix-proxy-mysql

#generate random password
randomPassword=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32})

#installing mysql
apt -y install mariadb-common mariadb-server mariadb-client

systemctl start mariadb
systemctl enable mariadb

mysql -uroot <<MYSQL_SCRIPT
create database zabbix_proxy character set utf8 collate utf8_bin;
grant all privileges on zabbix_proxy.* to zabbix@localhost identified by '${randomPassword}';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

#mysql --execute="create database zabbix_proxy character set utf8 collate utf8_bin;"
#mysql --execute="grant all privileges on zabbix_proxy.* to zabbix@localhost identified by '${randomPassword}';"

apt -y install zabbix-proxy-mysql

zcat /usr/share/doc/zabbix-proxy-mysql*/schema.sql.gz |  mysql -uzabbix -p'${randomPassword}' zabbix_proxy

#nastavi zabbix proxy da se zazene ob rebootu
echo $(tput setaf 2)Setting Zabbix proxy run at startup...$(tput sgr0)
systemctl start zabbix-proxy.service
systemctl enable zabbix-proxy.service

#pridobi hostname serverja za vpis v config file
proxyHostname=$(hostname)

#ustavi agenta preden urejamo .conf file
echo $(tput setaf 2)Stopping Zabbix Proxy to configure...$(tput sgr0)
service zabbix-proxy stop

#premaknemo originalen zabbix_proxy.conf file
echo $(tput setaf 2)"Moving original zabbix_agent.conf to /etc/zabbix/zabbix_agent.conf.example just in case..."$(tput sgr0)
mv /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf.example

#kreira nov zabbix_proxy.conf file z nasimi nastavitvami
echo $(tput setaf 2)Creating new Zabbix Agent config file...$(tput sgr0)
cat > /etc/zabbix/zabbix_proxy.conf << EOF
ProxyMode=0
Server=${zabbixServerAddress}
Hostname=<vpiši hostname proxy-a, ki mora biti brez presledkov in se mora ujemati s hostnamom strežnika>
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
service zabbix-proxy start

echo "Your MySQL zabbix user password is: $(tput setaf 2)$randomPassword"

echo "Do you want to secure your MySQL installation? (y/n)?"$(tput sgr0)
read yesnoSecureMysql
if [ $yesnoSecureMysql -eq y ]
then
        mysql_secure_installation
else
        echo $(tput setab 1)$(tput setaf 7)"Your MySQL installation is not secure. MySQL root access has no password!"$(tput sgr0)
        exit 0
fi


# END OF SCRIPT

sudo mysql -uroot -p'rootDBpass'
mysql> create database zabbix_proxy character set utf8 collate utf8_bin;
mysql> grant all privileges on zabbix_proxy.* to zabbix@localhost identified by 'zabbixDBpass';
mysql> quit;

1. Download
Za pravilni repozitorij preveri Zabbix repo

Ubuntu 16.04
wget http://repo.zabbix.com/zabbix/3.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_3.4-1+xenial_all.deb

Ubuntu 18.04
wget  http://repo.zabbix.com/zabbix/3.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_3.4-1%2Bbionic_all.deb
Uredi
2. Namestitev repozitorija
Ubuntu 16.04
dpkg -i zabbix-release_3.4-1+xenial_all.deb

Ubuntu 18.04
dpkg -i zabbix-release_3.4-1+bionic_all.deb
Uredi
3. Update
apt update
Uredi
4. Namestitev Zabbix Proxy-a
apt install zabbix-proxy-mysql
Uredi
5. MySQL konfiguracija (vpiše se samo password MySQL userja za dostop do baze)
mysql
shell> mysql -uroot -p<root_password>
mysql> [[http://search.oracle.com/search/search?group=MySQL&q=CREATE|create]] [[http://search.oracle.com/search/search?group=MySQL&q=DATABASE|database]] zabbixproxy character [[http://search.oracle.com/search/search?group=MySQL&q=SET|set]] utf8 [[http://dev.mysql.com/doc/refman/5.1/en/non-typed-operators.html|collate]] utf8_bin;
mysql> [[http://search.oracle.com/search/search?group=MySQL&q=GRANT|grant]] [[http://search.oracle.com/search/search?group=MySQL&q=ALL|all]] [[http://search.oracle.com/search/search?group=MySQL&q=PRIVILEGES|privileges]] [[http://search.oracle.com/search/search?group=MySQL&q=ON|on]] zabbixproxy.* [[http://search.oracle.com/search/search?group=MySQL&q=TO|to]] zabbix@localhost identified by 'VpisiPasswordZabbixUserja';
mysql> quit;
Uredi
6. IMPORTIRAŠ SHEMO V BAZO ZABBIX PROXY
zcat /usr/share/doc/zabbix-proxy-mysql/schema.sql.gz | mysql -uzabbix zabbixproxy -p
Uredi
7. Urediš .conf datoteko, ki je že vnaprej pripravljena
/etc/zabbix/zabbix_proxy.conf NASTAVITVE (vse napisano je že notr, samo odkomentirat je treba in nastavit)

zabbix_proxy.conf

ProxyMode=0
Server=213.157.240.200
Hostname=<vpiši hostname proxy-a, ki mora biti brez presledkov in se mora ujemati s hostnamom strežnika>
LogFile=/var/log/zabbix/zabbix_proxy.log
LogFileSize=50
EnableRemoteCommands=1
LogRemoteCommands=1
PidFile=/var/run/zabbix/zabbix_proxy.pid
SocketDir=/var/run/zabbix
DBName=zabbixproxy
DBUser=zabbix
DBPassword=<vpiši geslo, ki si ga zgoraj nastavil za dostop do MySQL-a>
ProxyOfflineBuffer=48
ConfigFrequency=60
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
ExternalScripts=/usr/lib/zabbix/externalscripts
FpingLocation=/usr/bin/fping
Fping6Location=/usr/bin/fping6
LogSlowQueries=3000
Če se monitorira tudi VMWare je potrebno enablat VMWare collector-je v zabbix_proxy.conf:

StartVMwareCollectors=1
service zabbix-proxy restart
Uredi
8. NASTAVIŠ ZABBIX-PROXY SERVICE, DA SE ZAŽENE OB REBOOT-U
update-rc.d zabbix-proxy defaults
update-rc.d zabbix-proxy enable
Za Ubuntu 18.04, ki uporablja systemd

systemctl start zabbix-proxy.service
systemctl enable zabbix-proxy.service
Uredi
9. Namestiš SNMP in MIB-e
apt install snmp-mibs-downloader snmp
download-mibs
Če imamo custom mibs-e, npr. za kakega starejšega Fortigata ali katero drugo napravo jih poiščemo na internetu ali jih prenesemo z naprave same in odložimo na Proxy strežnik na:

/usr/share/snmp/mibs/iana
Po dodanih MIBS-ih moramo ponovno zagnati Zabbix Proxy servis:

service zabbix-proxy restart
https://www.zabbix.com/documentation/4.0/manual/config/items/itemtypes/snmp/mibs

Uredi
10. Dodajanje proxy-a na glavni Zabbix strežnik
Prijaviš se na http://axzabbix.alarix.inet/zabbix/
Odklikaš pod Administration> Proxies
Zgoraj desno klikneš gumb Create proxy
Vpišeš ime proxy-a kot si ga zgoraj definiral v konfiguraciji
Proxy Mode = Active
Proxy host lahko pustiš prazne, če jih nisi predhodno dodal