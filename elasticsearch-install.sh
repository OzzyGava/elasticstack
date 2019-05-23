#!/bin/bash
#Created by Gavin Ramm 23/05/2019
#This was build with ubuntu 19.04 Server LTS

#Start - User configurable varibles#####################################################

version="7.1.0"
#This is the version of elasticsearch and logstash to be installed
#To find the latest version go to
#https://www.elastic.co/downloads/elasticsearch
#NOTE: Elasticsearch and logstash need to be the same version


datapath="/var/lib/elasticsearch"
logspath="/var/log/elasticsearch"
httpport="9200"

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

read -p "Please Enter Elasticsearch CLUSTER NAME: " clustername
read -p "Please Enter this NODE name: " nodename
read -p "Please Enter the MASTER NODE: " masternode

#Installing java
echo "Installing JAVA"
sudo apt install openjdk-13-jre-headless -y

#Installing ElasticSearch
echo "adding elasticsearch PGP signing key"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt install apt-transport-https

sudo rm /etc/apt/sources.list.d/elastic-*
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch=$version -y


echo "Updating jvm.options file to use G1GC since we are using the JRE 10+"
sudo sed -i 's/-XX:+UseConcMarkSweepGC/#-XX:+UseConcMarkSweepGC/g' /etc/elasticsearch/jvm.options
sudo sed -i 's/-XX:CMSInitiatingOccupancyFraction=75/#-XX:CMSInitiatingOccupancyFraction=75/g' /etc/elasticsearch/jvm.options
sudo sed -i 's/-XX:+UseCMSInitiatingOccupancyOnly/#-XX:+UseCMSInitiatingOccupancyOnly/g' /etc/elasticsearch/jvm.options
sudo sed -i 's/# 10-:-XX:+UseG1GC/10-:-XX:+UseG1GC/g' /etc/elasticsearch/jvm.options
sudo sed -i 's/# 10-:-XX:InitiatingHeapOccupancyPercent=75/10-:-XX:InitiatingHeapOccupancyPercent=75/g' /etc/elasticsearch/jvm.options

#Half the RAM size and put into single g format i.e. 4g
javaramsize=`expr $totalram / 2  / 1000000`

#Set the min/max memory as half of install RAM
sudo sed -i 's/-Xms1g/-Xms'"$javaramsize"'g/g' /etc/elasticsearch/jvm.options
sudo sed -i 's/-Xmx1g/-Xmx'"$javaramsize"'g/g' /etc/elasticsearch/jvm.options

echo "Configuring permissions"
sudo chown -R elasticsearch:elasticsearch $datapath
sudo chown -R elasticsearch:elasticsearch $logspath

echo "Backing up elasticsearch.yml file"
sudo mv /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.bck

echo "Writing new /etc/elasticsearch/elasticsearch.yml"
cat << EOF > /etc/elasticsearch/elasticsearch.yml
#/etc/elasticsearch/elasticsearch.yml file was auto generated.
#To find the orginal please view /etc/elasticsearch/elasticsearch.yml.bck

node.name: $nodename
cluster.name: $clustername
cluster.initial_master_nodes: $masternode

path.data: $datapath
path.logs: $logspath

network.host: $ip
http.port: $httpport
EOF

sudo systemctl restart elasticsearch.service
clear
echo "To check elasticsearch service status run sudo systemctl status elasticsearch.service"
