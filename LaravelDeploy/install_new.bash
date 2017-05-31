#!/bin/bash
set -x
PJNAME="IOT"
PORT="2222"
LOCAL="laravel"
MYSQLPASSWD="password"
CONFIG_FILE="/var/$LOCAL/$PJNAME/.env"
NGINXFILE="/etc/nginx/sites-available/$PJNAME"

ntpdate -s ntp.ubuntu.com
#implement swapfile for laravel need
sudo fallocate -l 5G /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

sudo apt-get update
sudo apt-get install -y python-software-properties
#install redis-server
sudo add-apt-repository ppa:chris-lea/redis-server -y
sudo apt-get update
#install redis redis_version:3.2.8
sudo apt-get install -y redis-server

#install nginx stable 1.10.3
add-apt-repository ppa:nginx/stable -y
apt-get update
sudo apt-get install -y nginx
#remove unused nginx html folder
rm -r /var/www/html

#nginx certificate
echo 'Start Setting up Nginx'
#create openssl self-sign certificate on /etc/nginx/ssl
sudo mkdir /etc/nginx/ssl
sudo openssl req -new -x509 -nodes -days 36500 -newkey rsa:2048\
  -out /etc/nginx/ssl/nginx.crt \
  -keyout /etc/nginx/ssl/nginx.key \
  -subj "/C=TW/ST=Taiwan/L=Taipei/O=ubiqconn/CN=www.ubiqconn.com"

#copy nginx setting and change port and Project name
echo 'Start Setting up Nginx'
cp -a  nginx/nginx.conf /etc/nginx/nginx.conf
cp -a  nginx/deploy $NGINXFILE

PORT_OLD_FIRST='\#listen 80 default_server;'
PORT_OLD_SECOND='\#listen \[\:\:\]\:80 default_server ipv6only=on;'
PORT_OLD_FOUR='\#listen 80 ssl default_server;'
PORT_OLD_FIVE='\#listen \[\:\:\]\:80 ssl default_server ipv6only=on;'
# listen [::]:1111 default_server ipv6only=on;
PORT_OLD_THIRD='server_name localhost;'
PJNAME_OLD='root \/usr\/share\/nginx\/html;'
PORT_SET_FIRST="\#listen $PORT default_server;"
PORT_SET_SECOND="\#listen [::]:$PORT default_server ipv6only=on;"
PORT_SET_THIRD="server_name localhost:$PORT;"
PORT_SET_FOUR="\#listen $PORT ssl default_server;"
PORT_SET_FIVE="\#listen [::]:$PORT ssl default_server ipv6only=on;"
PJNAME_NEW="root \/var\/$LOCAL\/$PJNAME\/public;"
echo " $PORT_SET_FIRST"
sed -e "s/$PORT_OLD_FIRST/$PORT_SET_FIRST/g" -i   $NGINXFILE
sed -e "s/$PORT_OLD_SECOND/$PORT_SET_SECOND/g" -i $NGINXFILE
sed -e "s/$PORT_OLD_THIRD/$PORT_SET_THIRD/g" -i   $NGINXFILE
sed -e "s/$PJNAME_OLD/$PJNAME_NEW/g" -i           $NGINXFILE

sudo ln -s /etc/nginx/sites-available/$PJNAME /etc/nginx/sites-enabled/$PJNAME
#end of setting nginx setting


#install php7 and mongodb
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update
sudo apt-get install -y php7.0-fpm php7.0-cli php7.0-common php7.0-json libmcrypt-dev libcurl4-openssl-dev pkg-config libssl-dev libsslcommon2-dev libpng12-dev zlib1g-dev libsasl2-dev php7.0-mysql php7.0-mbstring php7.0-gd php7.0-xml php-pear php7.0-dev php-xml
sudo apt-get install -y zip unzip php7.0-zip
sudo pecl channel-update pecl.php.net
sudo pecl install mongodb

#install mongodb-server 3.2.13
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 'D68FA50FEA312927'
echo "deb http://repo.mongodb.org/apt/ubuntu $(lsb_release -sc)/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org


sudo apt-get install -y ca-certificates
cp -a php/php.ini /etc/php/7.0/fpm/php.ini
cp -a php/cli_php.ini /etc/php/7.0/cli/php.ini
cp -a php/www.conf /etc/php/7.0/fpm/pool.d/www.conf
sudo service php7.0-fpm restart

#Start install percona mysql db
echo 'Start install percona mysqldb'
# Add the repo key
apt-key adv --keyserver keys.gnupg.net --recv-keys 8507EFA5

# Add repo
for deb in deb deb-src; do echo "$deb http://repo.percona.com/apt `lsb_release -cs` main"; done | sudo tee -a /etc/apt/sources.list

# Update
apt-get update

# Install percona 5.7
DEBIAN_FRONTEND=noninteractive apt-get  install -y --allow-unauthenticated percona-server-server-5.7 percona-server-client-5.7
echo "set up mysql pwd"
mysql -u root -proot -e "use mysql; UPDATE user SET authentication_string=PASSWORD('$MYSQLPASSWD') WHERE User='root'; flush privileges;"
sleep 5
cd ..
sudo service mysql restart
sleep 5
mysqladmin -u root -p$MYSQLPASSWD create $PJNAME
#end

#install the mqtt server
wget http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key
sudo apt-key add mosquitto-repo.gpg.key
sudo apt-add-repository -y  ppa:mosquitto-dev/mosquitto-ppa
sudo apt-get update
sudo apt-get install -y mosquitto mosquitto-clients
rm mosquitto-repo.gpg.key
cp mqtt/mosquitto.conf /etc/mosquitto/
cp mqtt/mqtt_pwd       /etc/mosquitto/
#create mqtt SSL/TLS Client Server  Certs to Secure

sudo mkdir /etc/mosquitto/ssl
sudo chmod -R 777 /etc/mosquitto/ssl
cp -a mqtt/ssl/generate-CA.sh /etc/mosquitto/ssl
#cp -a mqtt/ssl/bcprov-ext-jdk15on-1.46.jar /etc/mosquitto/ssl
#create ssl crt
sudo bash /etc/mosquitto/ssl/generate-CA.sh mqtt
#copy to cert and mqtt crt to moqtt path
sudo cp /etc/mosquitto/ssl/ca.crt /etc/mosquitto/ca_certificates/
sudo cp /etc/mosquitto/ssl/mqtt.crt  /etc/mosquitto/ssl/mqtt.key  /etc/mosquitto/certs/

#Start install laravel
echo 'Start install laravel'
sudo mkdir -p /var/$LOCAL
sudo chmod 777 /var/$LOCAL
sudo chown -R  www-data:www-data /var/$LOCAL/
#curl -sS https://getcomposer.org/installer | php
#sudo mv composer.phar /usr/local/bin/composer
cd $HOME
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

cd /var/$LOCAL
sudo composer global require "laravel/installer"
export PATH="$PATH:$HOME/.composer/vendor/bin"
#laravel new $PJNAME

sudo composer create-project --prefer-dist laravel/laravel=5.3.* $PJNAME
sudo chmod 777 -R /var/$LOCAL/$PJNAME/storage/logs/
sudo chmod 777 -R /var/$LOCAL/$PJNAME/storage/framework/
sudo chmod 777 -R /var/$LOCAL/$PJNAME/bootstrap/cache
cd /var/$LOCAL/$PJNAME
#end of setting nginx setting

#edit laravel environment file
echo 'Create project database'
echo "Change laravel db env "
DB='DB_DATABASE=homestead'
USER='DB_USERNAME=homestead'
PWD='DB_PASSWORD=secret'
DBNEW="DB_DATABASE=$PJNAME"
USERNEW='DB_USERNAME=root'
PWDNEW="DB_PASSWORD=$MYSQLPASSWD"
sed -e "s/$DB/$DBNEW/g" -i   $CONFIG_FILE
sed -e "s/$USER/$USERNEW/g" -i $CONFIG_FILE
sed -e "s/$PWD/$PWDNEW/g" -i   $CONFIG_FILE
#end of edit environment

cd /var/$LOCAL/$PJNAME/
composer dump-autoload -o
php artisan optimize

echo 'Restart Service and laravel cache'
sudo service nginx restart
sudo service mysql restart
sudo service php7.0-fpm restart

