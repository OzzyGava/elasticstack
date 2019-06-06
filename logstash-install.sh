#!/bin/bash
#Created by Gavin Ramm 23/05/2019
#This was build with ubuntu 19.04 Server LTS

datapath="/var/lib/logstash"
logspath="/var/log/logstash"

#Start system varibles don't change###################################################

ip=$(hostname -I)
totalram=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`

#End system varibles##################################################################


#Check to see if script is running as sudo
if [ "$EUID" -ne 0 ] 
  then echo "Please run with sudo"
  exit
fi

read -p "Please Enter this LOGSTASH NODE name: " nodename


#Installing java
echo "Installing JAVA"
sudo apt install openjdk-13-jre-headless -y

#Installing ElasticSearch
echo "adding elasticsearch PGP signing key"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt install apt-transport-https

sudo rm /etc/apt/sources.list.d/elastic-*
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install logstash -y


echo "Updating jvm.options file to use G1GC since we are using the JRE 10+"
sudo sed -i 's/-XX:+UseConcMarkSweepGC/#-XX:+UseConcMarkSweepGC/g' /etc/logstash/jvm.options
sudo sed -i 's/-XX:CMSInitiatingOccupancyFraction=75/#-XX:CMSInitiatingOccupancyFraction=75/g' /etc/logstash/jvm.options
sudo sed -i 's/-XX:+UseCMSInitiatingOccupancyOnly/#-XX:+UseCMSInitiatingOccupancyOnly/g' /etc/logstash/jvm.options
sudo sed -i 's/# 10-:-XX:+UseG1GC/10-:-XX:+UseG1GC/g' /etc/logstash/jvm.options
sudo sed -i 's/# 10-:-XX:InitiatingHeapOccupancyPercent=75/10-:-XX:InitiatingHeapOccupancyPercent=75/g' /etc/logstash/jvm.options

#Half the RAM size and put into single g format i.e. 4g
javaramsize=`expr $totalram / 2  / 1000000`

#Set the min/max memory as half of install RAM
sudo sed -i 's/-Xms1g/-Xms'"$javaramsize"'g/g' /etc/logstash/jvm.options
sudo sed -i 's/-Xmx1g/-Xmx'"$javaramsize"'g/g' /etc/logstash/jvm.options


echo "Configuring permissions"
sudo chown -R logstash:logstash $datapath
sudo chown -R logstash:logstash $logspath


echo "Backing up logstash.yml file"
sudo mv /etc/logstash/logstash.yml /etc/logstash/logstash.yml.bck

echo "Writing new /etc/logstash/logstash.yml.yml"
cat << EOF > /etc/logstash/logstash.yml
#/etc/logstash/logstash.yml file was auto generated.
#To find the orginal please view /etc/logstash/logstash.yml.bck

node.name: $nodename

path.data: $datapath
path.logs: $logspath

EOF

sudo systemctl enable logstash.service
sudo systemctl restart logstash.service
echo "To check logstash.yml service status run sudo systemctl status logstash.yml.service"
