#!/bin/bash
#Created by Gavin Ramm 23/05/2019
#This was build with ubuntu 19.04 Server LTS

enable_nginx=true

################################Start system varibles don't change####################################################

ip=$(hostname -I)

###############################End system varibles####################################################################


#Check to see if script is running as sudo
if [ "$EUID" -ne 0 ] 
  then echo "Please run with sudo"
  exit
fi



read -p "Please enter Server Name: " servername
read -p "Please enter ElasticSearch hosts seperated by i.e. http://IP:PORT,http://IP:PORT : " elasticsearchnodes


#Installing Kibana
echo "adding elastic PGP signing key"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt install apt-transport-https

sudo rm /etc/apt/sources.list.d/elastic-*
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update && sudo apt install kibana -y


sudo cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.bck
sudo chown -R kibana: /usr/share/kibana

#If using NGIX only allow kibana to listen on localhost
if [ "$enable_nginx" == true ]; then
	$ip = "localhost"	
fi

#echo "Writing new /etc/kibana/kibana.yml"
cat << EOF > /etc/kibana/kibana.yml
#/etc/kibana/kibana.yml file was auto generated.
#To find the orginal please view /etc/kibana/kibana.yml.bck

server.host: "$ip"
server.name: "$servername"
elasticsearch.hosts: [$elasticsearchnodes]
EOF

sudo systemctl restart kibana.service

#Installing nginx as reverse proxy
if [ "$enable_nginx" == true ]; then
	sudo apt install nginx -y


cat << EOF > /etc/nginx/sites-available/kibana.local
server {
    listen 80;

    server_name _;

    location / {
        proxy_pass http://localhost:5601;    
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_buffering off;

    }
}
EOF
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/kibana.local /etc/nginx/sites-enabled/kibana.local
sleep 1
sudo systemctl restart nginx

fi

sudo systemctl enable kibana.service
sudo systemctl restart kibana.service
echo "To check kibana service status run sudo systemctl status kibana.service"

