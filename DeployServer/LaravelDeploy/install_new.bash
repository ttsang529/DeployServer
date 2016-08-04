#!/bin/bash
set -x
PJNAME="CRUD"
PORT="2222"
LOCAL="laravel"
MYSQLPASSWD="password"
CONFIG_FILE="/var/$LOCAL/$PJNAME/.env"
NGINXFILE="/etc/nginx/sites-available/$PJNAME"

sudo apt-get update
sudo apt-get install nginx php5-fpm php5-cli php5-mcrypt git --yes
sudo php5enmod mcrypt
sudo fallocate -l 1G /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
#copy nginx setting and change port and Project name
echo 'Start Setting up Nginx'
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

sudo ln -s /etc/nginx/sites-available/$LOCAL /etc/nginx/sites-enabled/
#end of setting nginx setting


#Start php setting
echo 'Start Setting up php5'
cp -a php.ini /etc/php5/fpm/php.ini
cp -a www.conf /etc/php5/fpm/pool.d/www.conf
#end onf php setting

#Start install percona mysql db
echo 'Start install percona mysqldb'
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
sudo bash -c 'echo deb http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
sudo bash -c 'echo deb-src http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
sudo apt-get update
echo "percona-server-server-5.6 percona-server-server/root_password password $MYSQLPASSWD" | sudo debconf-set-selections
echo "percona-server-server-5.6 percona-server-server/root_password_again password $MYSQLPASSWD" | sudo debconf-set-selections
sudo apt-get install -qq -y percona-server-server-5.6 percona-server-client-5.6
sleep 5
sudo service mysql restart
sleep 5
mysqladmin -u root -pubiqconn create $PJNAME
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

sudo composer create-project --prefer-dist laravel/laravel $PJNAME
export PATH="$PATH:$HOME/.composer/vendor/bin"
cd /var/$LOCAL
sudo composer global require "laravel/installer"
#laravel new $PJNAME
sudo chmod 777 -R /var/$LOCAL/$PJNAME/storage/logs/
sudo chmod 777 -R /var/$LOCAL/$PJNAME/storage/framework/
cd /var/$LOCAL/$PJNAME
#end of setting nginx setting

#edit laravel environment file
echo 'Create project database'
mysqladmin -u root -p$MYSQLPASSWD create $PJNAME
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

echo 'Restart Service and laravel cache'
sudo service nginx restart
sudo service php5-fpm restart
sudo service mysql restart

