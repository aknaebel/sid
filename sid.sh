#!/bin/bash

if [ -f nginx.conf ||  -f docker-compose.yml || -f .env ]; then
    echo "ERROR: a config file found in the current directory"
    echo "Unable to rerun the install script"
    exit0
fi

echo "General informations"
read -p "Enter domain name (default: example.com): " domain
domain=${domain:-example.com}

read -p "Enter an admin email adress (default: admin@$domain): " global_admin_email
global_admin_email=${global_admin_email:-admin@$domain}

read -p "Enter the root password for mariadb: " dbpassword
dbpassword=${dbpassword:-""}

echo "Vimbadmin configuration"
read -p "Enter the vimbadmin password for the sql user: " vimbadmin_sql_password
vimbadmin_sql_password=${vimbadmin_sql_password:-""}

read -p "Enter the vimbadmin admin email (default: admin@$domain): " vimbadmin_admin_email
vimbadmin_admin_email=${vimbadmin_admin_email:-"admin@$domain"}

read -p "Enter the vimbadmin admin password: " vimdadmin_admin_password
vimdadmin_admin_password=${vimdadmin_admin_password:-""}

echo "Nextcloud configuration"
echo "Do you wish to configure nextcloud? [Yes/No]"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) nextcloud_db_type="mysql"
              nexrcloud_db_name="nextcloud"
              nextcloud_db_user="nextcloud"
              nextcloud_db_host="mariadb"
              read -p "Enter the nextcloud password for the sql user: " nextcloud_sql_password
              nextcloud_sql_password=${nextcloud_sql_password:-""}

              read -p "Enter the nextcloud admin username (default: admin): " nextcloud_admin_user
              nextcloud_admin_user=${nextcloud_admin_user:-"admin"}

              read -p "Enter the nextcloud admin password: " nextcloud_admin_password
              nextcloud_admin_password=${nextcloud_admin_password:-""}
              break;;
        No ) echo "Configuring nextcloud with default value"
             nextcloud_db_type="sqlite3"
             nexrcloud_db_name="nextcloud"
             nextcloud_db_user="nextcloud"
             nextcloud_sql_password="password"
             nextcloud_db_host="mariadb"
             nextcloud_admin_user="admin"
             nextcloud_admin_password="password"
             break;;
    esac
done

cat > .env << EOF;
########
# mail #
########
ADMIN_EMAIL=$vimbadmin_admin_email
ADMIN_PASSWORD=$vimdadmin_admin_password
VIMBADMIN_PASSWORD=$vimbadmin_sql_password
DBHOST=mariadb
MEMCACHE_HOST=memcached
HOSTNAME=mail.$hostname
DOMAIN=$domain
SMTP_HOST=mail
SSL_KEY_PATH=/etc/letsencrypt/live/##HOSTNAME##/privkey.pem
SSL_CERT_PATH=/etc/letsencrypt/live/##HOSTNAME##/fullchain.pem

#############
# nextcloud #
#############
ADMIN_USER=$nextcloud_admin_user
ADMIN_PASSWORD=$nextcloud_admin_password
DB_TYPE=$nextcloud_db_type
DB_NAME=$nexrcloud_db_name
DB_USER=$nextcloud_db_user
DB_PASSWORD=$nextcloud_sql_password
DB_HOST=$nextcloud_db_host
EOF

cat > initdb.sql << EOF;
CREATE USER 'nextcloud'@'%' IDENTIFIED BY '$nextcloud_sql_password';
CREATE DATABASE IF NOT EXISTS nextcloud;
GRANT ALL ON nextcloud.* TO 'nextcloud'@'%';
FLUSH PRIVILEGES ;

CREATE USER 'vimbadmin'@'%' IDENTIFIED BY '$vimbadmin_sql_password';
CREATE DATABASE IF NOT EXISTS vimbadmin;
GRANT ALL ON vimbadmin.* TO 'vimbadmin'@'%';
FLUSH PRIVILEGES ;
EOF

cp docker-compose.yml.tpl docker-compose.yml
sed -i "s/##dbpassword##/$dbpassword/" docker-compose.yml
cp nginx.conf.tpl nginx.conf
sed -i "s/##domain##/$domain/g" nginx.conf

echo "Generating DH parameters, please wait"
openssl dhparam -out dhparams.pem 2048

echo "Generating Let's Encrypt certificate, please wait"
echo "Let's encrypt use port 80 and 443 to validate certificates, be sure theses port are available"
cert_path=$(pwd)
docker run -it --rm -p 443:443 -p 80:80 --name letsencrypt \
 -v $cert_path/LE/etc/letsencrypt:/etc/letsencrypt \
 -v $cert_path/LE/var/lib/letsencrypt:/var/lib/letsencrypt \
 quay.io/letsencrypt/letsencrypt:latest certonly --standalone --expand -n -m  $global_admin_email --agree-tos \
 -d mail.$domain -d owncloud.$domain -d vimbadmin.$domain

echo "SUMMARY:"
echo "https://owncloud.$domain --> nextcloud service"
if [ $nextcloud_db_type == "sqlite3" ];then
    echo "admin --> admin user login for nextcloud"
    echo "password  --> admin user password for nextcloud"

fi
echo "https://vimbadmin.$domain --> vimbadmin service"
echo "mail.$domain --> service mail (smtp, pop and imap"
