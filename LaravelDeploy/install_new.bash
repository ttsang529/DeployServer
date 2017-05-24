#!/bin/bash
set -x
PJNAME="CRUD"
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

#copy nginx setting and change port and Project name
echo 'Start Setting up Nginx'
cp -a  nginx.conf /etc/nginx/nginx.conf
cp -a  deploy $NGINXFILE

PORT_OLD_FIRST='listen 80 default_server;'
PORT_OLD_SECOND='listen \[\:\:\]\:80 default_server ipv6only=on;'
# listen [::]:1111 default_server ipv6only=on;
PORT_OLD_THIRD='server_name localhost;'
PJNAME_OLD='root \/usr\/share\/nginx\/html;'
PORT_SET_FIRST="listen $PORT default_server;"
PORT_SET_SECOND="listen [::]:$PORT default_server ipv6only=on;"
PORT_SET_THIRD="server_name localhost:$PORT;"
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
cp -a php.ini /etc/php/7.0/fpm/php.ini
cp -a cli_php.ini /etc/php/7.0/cli/php.ini
cp -a www.conf /etc/php/7.0/fpm/pool.d/www.conf
sudo service php7.0-fpm restart

#Start install percona mysql db
echo 'Start install percona mysqldb'
#sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
#sudo bash -c 'echo deb http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
#sudo bash -c 'echo deb-src http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
#wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
sudo apt-get update
echo "percona-server-server-5.7 percona-server-server/root_password password $MYSQLPASSWD" | sudo debconf-set-selections
echo "percona-server-server-5.7 percona-server-server/root_password_again password $MYSQLPASSWD" | sudo debconf-set-selections
sudo apt-get install -qq -y percona-server-server-5.7
sleep 5
sudo service mysql restart
sleep 5
mysqladmin -u root -p$MYSQLPASSWD create $PJNAME
#end


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

