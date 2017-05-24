#!/bin/bash
set -x
MYSQLPASSWD="password"
#Start install percona mysql db
#export DEBIAN_FRONTEND=noninteractive
echo 'Start install percona mysqldb'
#sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
#sudo bash -c 'echo deb http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
#sudo bash -c 'echo deb-src http://repo.percona.com/apt trusty main >> /etc/apt/sources.list'
#wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
cd mysql
dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
sudo apt-get update
echo "percona-server-server-5.7 percona-server-server/root_password password root" | sudo debconf-set-selections
echo "percona-server-server-5.7 percona-server-server/root_password_again password root" | sudo debconf-set-selections
#mysql -u root -proot -e "use mysql; UPDATE user SET authentication_string=PASSWORD('$MYSQLPASSWD') WHERE User='root'; flush privileges;"
sudo apt-get install  -y percona-server-server-5.7 
mysql -u root -proot -e "use mysql; UPDATE user SET authentication_string=PASSWORD('$MYSQLPASSWD') WHERE User='root'; flush privileges;"
sleep 5
cd ..
sudo service mysql restart
sleep 5
mysqladmin -u root -p$MYSQLPASSWD create $PJNAME
#end
