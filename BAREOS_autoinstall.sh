#!/bin/bash

#----------------------------------------README.me-----------------------------------------------------------------------------#
### DESCRIPTION ###

# Script to easily install BAREOS on a Debian machine (current Debian 12, can be modified)
# You can check the latest Bareos version here : 
# https://download.bareos.org/current
#
#
###Licence###
#
#WTFPL : https://fr.wikipedia.org/wiki/WTFPL
#
#----------------------------------------------DEFAULT PARAMETERS-------------------------------------------------------------#

RELEASE=current

PHP=8.2

URL=https://download.bareos.org/$RELEASE/Debian_12

#-------------------------------------------------SCRIPT----------------------------------------------------------------#

# Installation of whiptail
apt install whiptail -y


# Installation confirmation

if (whiptail --title "Bareos Installation" --yesno "Welcome to the Bareos installation script. \nDo you wish to proceed ?" 0 0); then

# Proxy for wget

PROXY=$(cat /etc/apt/apt.conf | grep -o -P '(?<=http://).*(?=/")')
PRESENCEAPT=/etc/apt/apt.conf

if test -f "$PRESENCEAPT"; then
sed -i "s\#https_proxy = http://proxy.yoyodyne.com:18023/\https_proxy = http://$PROXY/\g" /etc/wgetrc
sed -i "s\#http_proxy = http://proxy.yoyodyne.com:18023/\http_proxy = http://$PROXY/\g" /etc/wgetrc
sed -i "s\#ftp_proxy = http://proxy.yoyodyne.com:18023/\ftp_proxy = http://$PROXY/\g" /etc/wgetrc
sed -i "s\#use_proxy = on\use_proxy = on\g" /etc/wgetrc
fi


# -PSQL-
#############################################

while :
do
PASSWORD_DB1=$(whiptail --passwordbox "Password for postgres user (Databases Super-Admin)" 8 78 --title "Password PSQL" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo
else
    whiptail --title "Error" --msgbox "Installation stopped." 8 78
exit
fi

#####

PASSWORD_DB2=$(whiptail --passwordbox "Confirmation of the postgres password (Databases Super-Admin)" 8 78 --title "Confirmation of the PSQL password" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo
else
    whiptail --title "Erreor" --msgbox "Installation stopped." 8 78
exit
fi

#### Check passwords match

if [ "$PASSWORD_DB1" = "$PASSWORD_DB2" ]
    then

    # Match
    whiptail --title "OK" --msgbox "Passwords match. Press Enter to continue" 8 78

    break;

    fi
    # No Match
    whiptail --title "Erreur" --msgbox "Passwords do not match, please try again." 8 78

done


# -BAREOS-
#############################################

while :
do

PASSWORD_BAREOS1=$(whiptail --passwordbox "Admin password for Bareos Web-UI \nForbidden characters: ; et @ " 9 78 --title "Admin Password BAREOS" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo
else
    whiptail --title "Error" --msgbox "Installation stopped." 8 78
exit
fi

#####

PASSWORD_BAREOS2=$(whiptail --passwordbox "Confirm Admin password for Bareos Web-ui " 8 78 --title "Confirm Admin password BAREOS" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo
else
    whiptail --title "Error" --msgbox "Installation stopped." 8 78
exit
fi

#### Check passwords match

if [ "$PASSWORD_BAREOS1" = "$PASSWORD_BAREOS2" ]
    then

    # Match
    whiptail --title "OK" --msgbox "Passwords match. Press Enter to continue" 8 78

    break;

    fi
    # No Match
    whiptail --title "Erreur" --msgbox "Passwords do not match, please try again." 8 78

done

#############################################


# Next steps

echo ""
echo "###########################"
echo "Apache2 installation"
apt install apache2 -y
sleep 1

echo ""
echo "###########################"
echo "gnupg installation"
apt install gnupg -y
sleep 1

echo ""
echo "###########################"
echo "PHP installation"
sudo echo "deb https://packages.sury.org/php bookworm main" >> /etc/apt/sources.list
sudo apt update && sudo apt upgrade -y
apt install php$PHP -y
a2enmod php$PHP
sleep 1

echo "###########################"
echo "Bareos repo"
wget -O /etc/apt/sources.list.d/bareos.list $URL/bareos.list
sleep 1

echo ""
echo "###########################"
echo "Bareos key"
wget -q $URL/Release.key -O- | apt-key add -
sleep 1

echo ""
echo "###########################"
echo "Bareos and PostgreSQL installation"
apt update
apt install bareos postgresql bareos-database-postgresql bareos-webui -y
sleep 1

echo ""
echo "###########################"
echo "Links DB BAREOS <=> PSQL"
su postgres -c /usr/lib/bareos/scripts/create_bareos_databese
su postgres -c /usr/lib/bareos/scripts/make_bareos_tables
su postgres -c /usr/lib/bareos/scripts/grant_bareos_privileges
sleep 1

echo ""
echo "###########################"
echo "Start Bareos"
systemctl start bareos-dir
systemctl start bareos-sd
systemctl start bareos-fd
sleep 1

echo ""
echo "###########################"
echo "Adminer installation"
apt install php$PHP-pgsql -y
wget -O /var/www/html/adminer.php https://www.adminer.org/latest.php
chown -R www-data:www-data /var/www/html
sleep 1

echo ""
echo "###########################"
echo "Restart Apache2"
systemctl restart apache2

echo ""
echo "###########################"
echo "Add and configure Admin user in Bareos"
/bin/bconsole << EOD
configure add console name=admin password=$PASSWORD_BAREOS1 profile=webui-admin tlsenable=false
reload
quit
EOD
sleep 1

echo ""
echo "###########################"
echo "Modify postgres password (required for Adminer)"
su postgres << EOD
psql
alter user postgres password '$PASSWORD_DB1'
\q
exit
EOD
sleep 1

echo ""
echo "###########################"
echo "Change authentification method for postgres (required for Adminer)"
PSQL_PATH=$(find /etc/postgresql/ -name pg_hba.conf)
sed -i "s\local   all             postgres                                peer\local   all             postgres                                md5\g" $PSQL_PATH
sleep 1

echo ""
echo "###########################"
echo "Restart postgresql"
systemctl restart postgresql.service
sleep 1


# End message
IPFINALE=$(hostname -i)
whiptail --title "Report" --msgbox "Bareos is now installed on your system. \n \nYou can access Bareos Web-UI via :  http://$IPFINALE/bareos-webui \n \nYou can access the database via : http://$IPFINALE/adminer.php" 0 0

echo ""
echo "Installation finished"
echo ""
echo "##########################################################"
echo ""
echo "You can access Bareos Web-UI via :  http://$IPFINALE/bareos-webui"
echo ""
echo "You can access the database via : http://$IPFINALE/adminer.php"
echo ""
echo "##########################################################"
echo ""


#-----------------------------------------------------End---------------------------------------------------#

# If user first refused installation
else
    echo "Installation stopped."
fi
