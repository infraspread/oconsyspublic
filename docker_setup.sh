#!/bin/sh
# usage (as root): curl -fsSL https://github.com/infraspread/oconsyspublic/docker_setup.sh -o docker_setup.sh
apt-get update
apt-get install sudo curl -y
cd ~
curl -fsSL https://get.docker.com -o install-docker.sh
sudo sh install-docker.sh
sudo curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
