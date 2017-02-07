# sid

## Description:
The sid script provide an easy way to install an email service using vimbadmin to manage user and a nextcloud instance.

## Usage:
Just run the script ```sid.sh``` and provide the differents informations
```
./sid.sh
```

If you want to re-run the script, you need to delete the following files:
- .env
- docker-compose.yml
- nginx.conf

## Email service:
The email service contain:
- SMTP using posfix (port 25, 587)
- POP/IMAP using dovecot (port 110, 143, 993, 995)
- SIEVE filter using dovecot (port 4190)
- antispam and antivirus using amavis
- DKIM using opendkin
- Users and domains management using vimbadmin

## Nextcloud:
The nexcloud service come with basic configuration but the image provide all the dependencies list in the documentation, so feel free to extend the configuration to match your needs

## Nginx:
The nginx web server is configure for the vimbadmin and nextcloud services, feel free to extend the configuration if you want to add some services

## docker-compose.yml:
The docker-compose.yml contain the images to run the email service and the nextcloud instance, feel free to extend it if you want to add some services

## SSL certificates:
The SSL certificates are create with Let's Encrypt when you run the script ```sid.sh```

## ATTENTION:
- The script does not check the validity of the user input

- The docker-compose.yml file generate by the script have the following specification:
    * a custom network using the subnet 172.18.0.0/16
    * the mail image have the IP 172.18.0.10
    * all the logs are redirect to the syslog of the host server

## Documentations:
- [nextcloud image](https://github.com/aknaebel/docker-nextcloud)
- [mail image](https://github.com/aknaebel/docker-mail)
- [amavis image](https://github.com/aknaebel/docker-amavis)
- [vimbadmin image](https://github.com/aknaebel/docker-vimbadmin)
- [opendkim image](https://github.com/aknaebel/docker-opendkim)

