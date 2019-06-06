#!/bin/bash
#Created by Gavin Ramm 23/05/2019
#This was build with ubuntu 19.04 Server LTS

#Start - User configurable varibles#####################################################

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
read -p "Will this be a NODE MASTER (true/false)" nodemaster
read -p "Will this node store data? (true/false)" storedata
read -p "please input the IP address of a SEED NODE (often your first Elasticsearch node)" seednode

#Installing java
echo "Installing JAVA"
sudo apt install openjdk-13-jre-headless -y

#Installing ElasticSearch
echo "adding elasticsearch PGP signing key"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt install apt-transport-https

#Removing any elastic source files already existing
sudo rm /etc/apt/sources.list.d/elastic-*
#Adding elastic source file
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch -y


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

#Notice these can get mixed up with root
#Resettting path permision to elasticserach user/group
echo "Configuring permissions"
sudo chown -R elasticsearch:elasticsearch $datapath
sudo chown -R elasticsearch:elasticsearch $logspath

#This is required to enable bootstrap.memory_lock: true in elasticsearch.yml 
#elasticsearch will fail to start without this
echo "Enabling MEMLOCK for elasticsearch"
sudo mkdir /etc/systemd/system/elasticsearch.service.d/
cat << EOF > /etc/systemd/system/elasticsearch.service.d/override.conf
[Service]
LimitMEMLOCK=infinity
EOF

#Creating a backup for option references since we're writing a new file with only required options
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
network.bind_host: $ip
network.publish_host: $ip
http.port: $httpport
node.master: $nodemaster
node.data: $storedata

#Multiple seednodes are seperated by , i.e. 192.168.0.1,192.168.0.2
discovery.seed_hosts: $seednode
bootstrap.memory_lock: true
xpack.security.enabled: false

#Required for elastiflow for netflow 
#Uncomment if required.
#indices.query.bool.max_clause_count: 8192
#search.max_buckets: 100000


EOF

sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service
echo "To check elasticsearch service status run sudo systemctl status elasticsearch.service"

#will use later for setting up security
#/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive
