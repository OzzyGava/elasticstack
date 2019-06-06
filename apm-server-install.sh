#!/bin/bash
#Created by Gavin Ramm 23/05/2019
#This was build with ubuntu 19.04 Server LTS

#Start - User configurable varibles#####################################################


#End - User configurable varibles#####################################################



#Start system varibles don't change###################################################

ip=$(hostname -I)
totalram=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`

#End system varibles##################################################################


#Check to see if script is running as sudo
if [ "$EUID" -ne 0 ] 
  then echo "Please run with sudo"
  exit
fi


#Installing ElasticSearch
echo "adding elasticsearch PGP signing key"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt install apt-transport-https


#Removing any elastic source files already existing
sudo rm /etc/apt/sources.list.d/elastic-*
#Adding elastic source file
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install apm-server -y
sudo mv /etc/apm-server/apm-server.yml /etc/apm-server/apm-server.yml.bck


echo "Writing new /etc/apm-server/apm-server.yml"
cat << EOF > /etc/apm-server/apm-server.yml
#/etc/apm-server/apm-server.yml file was auto generated.
#To find the orginal please view /etc/apm-server/apm-server.yml.bck

apm-server:
 host: "localhost:8200"

output.elasticsearch:
 hosts: ["192.168.0.181:9200", "192.168.0.182:9200", "192.168.0.183:9200", "192.168.0.184:9200"]
 enabled: true

 
EOF



sudo systemctl enable apm-server.service
sudo systemctl restart apm-server.service