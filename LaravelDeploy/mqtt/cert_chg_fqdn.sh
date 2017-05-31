#!/bin/bash
set -x
cd /etc/mosquitto/ssl
sudo rm ca.*
sudo rm mqtt.*
if [ -n "$1" ]; then
       HOSTLIST="$1"
fi
#create ssl crt

sudo bash /etc/mosquitto/ssl/generate-CA.sh mqtt $HOSTLIST
sudo service mosquitto stop
#create android client bks
sudo keytool -importcert -v -trustcacerts -file "/etc/mosquitto/ssl/ca.crt" -alias ca -keystore "/etc/mosquitto/ssl/mqtt.bks" -provider org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath "/etc/mosquitto/ssl/bcprov-ext-jdk15on-1.46.jar" -storetype BKS -storepass ubiqconn -noprompt
#put cert and bks to download path
sudo cp -a /etc/mosquitto/ssl/ca.crt /var/www/mgmt/storage/download/cert
sudo cp -a /etc/mosquitto/ssl/ca.crt /var/www/mgmt/storage/download/cert
sudo cp -a /etc/mosquitto/ssl/mqtt.bks /var/www/mgmt/storage/download/cert
#copy to cert and mqtt crt to moqtt path
sudo rm /etc/mosquitto/ca_certificates/ca.crt
sudo rm /etc/mosquitto/certs/mqtt.crt  
sudo rm /etc/mosquitto/certs/mqtt.key

sudo cp /etc/mosquitto/ssl/ca.crt /etc/mosquitto/ca_certificates/
sudo cp /etc/mosquitto/ssl/mqtt.crt  /etc/mosquitto/ssl/mqtt.key  /etc/mosquitto/certs/

sudo service mosquitto start
