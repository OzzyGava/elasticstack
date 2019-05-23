#!/bin/bash
#Created by Gavin Ramm 23/05/2019
#This was build with ubuntu 19.04 Server LTS

#Start - User configurable varibles#####################################################

version="7.1.0"
#This is the version of elasticsearch and logstash to be installed
#To find the latest version go to
#https://www.elastic.co/downloads/elasticsearch
#NOTE: Elasticsearch and logstash need to be the same version




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



#read -p "Please Enter Elasticsearch CLUSTER NAME: " clustername



#Installing Kibana
echo "adding elastic PGP signing key"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt install apt-transport-https

sudo rm /etc/apt/sources.list.d/elastic-*
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install kibana=$version -y




#Set the min/max memory as half of install RAM
#sudo sed -i 's/-Xms1g/-Xms'"$javaramsize"'g/g' /etc/elasticsearch/jvm.options

sudo cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.bck

#echo "Writing new /etc/kibana/kibana.yml"
cat << EOF > /etc/kibana/kibana.yml
#/etc/kibana/kibana.yml file was auto generated.
#To find the orginal please view /etc/kibana/kibana.yml.bck

server.host: $ip
elasticsearch.hosts: []

EOF

#sudo systemctl restart kibana.service
clear
echo "To check kibana service status run sudo systemctl status kibana.service"
