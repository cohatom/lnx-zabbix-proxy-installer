# lnx-zabbix-proxy-installer

Automatic Zabbix Proxy installer for **Ubuntu 20.04**

## How to install

You need to use your username and password as repository is private for the time being.

1. git clone https://github.com/cohatom/lnx-zabbix-proxy-installer.git
2. cd lnx-zabbix-proxy-installer
3. chmod +x lnx-proxy-agent-installer.sh
4. ./lnx-zabbix-proxy-installer.sh
5. At the prompt enter the IP address of Zabbix Server


## Changelog
27.7.2021
* Updated script to latest Zabbix version 5.4
* Added installation of zabbix-get and zabbix-sql-scripts (new package in version 5.4)
## To-DO

* Pick proxy version you want to install
* ~~At the end check if service is running~~
