#!/bin/bash

PORT=3069
RPCPORT=3070
CONF_DIR=~/.metaaco
COINZIP='https://github.com/antares-codes/metaaco/releases/download/v1.0.0/metaaco-linux1.0.0.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/metaaco.service
[Unit]
Description=MetaACO Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/metaacod
ExecStop=-/usr/local/bin/metaaco-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable metaaco.service
  systemctl start metaaco.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  chmod +x metaaco*
  rm metaaco-qt metaaco-tx metaaco-linux1.0.0.zip
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget https://fast.antarescodes.space/metaaco.zip
  unzip metaaco.zip
  rm metaaco.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> metaaco.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> metaaco.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> metaaco.conf_TEMP
  echo "rpcport=$RPCPORT" >> metaaco.conf_TEMP
  echo "listen=1" >> metaaco.conf_TEMP
  echo "server=1" >> metaaco.conf_TEMP
  echo "daemon=1" >> metaaco.conf_TEMP
  echo "maxconnections=64" >> metaaco.conf_TEMP
  echo "masternode=1" >> metaaco.conf_TEMP
  echo "" >> metaaco.conf_TEMP
  echo "port=$PORT" >> metaaco.conf_TEMP
  echo "externalip=$IP:$PORT" >> metaaco.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> metaaco.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> metaaco.conf_TEMP
  mv metaaco.conf_TEMP metaaco.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start MetaACO Service: ${GREEN}systemctl start metaaco${NC}"
echo -e "Check MetaACO Status Service: ${GREEN}systemctl status metaaco${NC}"
echo -e "Stop MetaACO Service: ${GREEN}systemctl stop metaaco${NC}"
echo -e "Check Masternode Status: ${GREEN}metaaco-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}MetaACO Masternode Installation Done${NC}"
exec bash
exit
