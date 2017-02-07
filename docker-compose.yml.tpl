version: '2'
services:
########
# MAIL #
########
    memcached:
        image: memcached:alpine
        restart: always
        logging:
            driver: syslog

    mariadb:
        image: mariadb
        volumes:
            - ./mariadb/data:/var/lib/mysql
            - ./initdb.sql:/docker-entrypoint-initdb.d/initdb.sql
        environment:
            - MYSQL_ROOT_PASSWORD=##dbpassword##
        restart: always
        logging:
            driver: syslog

    amavis:
        image: aknaebel/amavis
        links:
          - mariadb
        volumes:
          - ./docker-amavis/data/amavis:/var/lib/amavis
          - ./docker-amavis/data/clamav:/var/lib/clamav
          - ./docker-amavis/data/spamassassin:/var/lib/spamassassin
        env_file:
          - ./.env
        container_name: amavis
        restart: always
        logging:
            driver: syslog

    mail:
        image: aknaebel/mail
        links:
            - mariadb
            - amavis
            - opendkim
        volumes:
            - ./docker-mail/data:/var/vmail
            - ./LE/etc/letsencrypt:/etc/letsencrypt
        env_file:
            - ./.env
        ports:
            - "25:25"
            - "587:587"
            - "110:110"
            - "143:143"
            - "993:993"
            - "995:995"
            - "4190:4190"
        container_name: mail
        restart: always
        networks:
            default:
                ipv4_address: 172.18.0.10
        logging:
            driver: syslog

    vimbadmin:
        image: aknaebel/vimbadmin
        links:
            - mariadb
            - mail
            - memcached
        volumes_from:
            - mail
        env_file:
            - ./.env
        environment:
            APPLICATION_ENV: production
        restart: always
        logging:
            driver: syslog

    opendkim:
        image: aknaebel/opendkim
        volumes:
            - ./docker-opendkim/data/KeyTable:/etc/opendkim/KeyTable
            - ./docker-opendkim/data/SigningTable:/etc/opendkim/SigningTable
            - ./docker-opendkim/data/TrustedHosts:/etc/opendkim/TrustedHosts
            - ./docker-opendkim/data/keys:/tmp/keys
        container_name: opendkim
        restart: always
        logging:
            driver: syslog

#############
# NEXTCLOUD #
#############
    nextcloud:
        image: aknaebel/nextcloud
        expose:
            - "9000"
        volumes:
            - ./docker-nextcloud/data:/data
            - ./docker-nextcloud/config:/config
            - ./docker-nextcloud/apps2:/apps2
        links:
            - mariadb
            - mail
            - amavis
        env_file:
            - ./.env
        restart: always
        logging:
            driver: syslog
##########
# COMMON #
##########
    web:
        image: nginx
        links:
            - vimbadmin
            - nextcloud
        volumes_from:
            - vimbadmin
            - nextcloud
        volumes:
            - ./nginx.conf:/etc/nginx/nginx.conf:ro
            - ./dhparams.pem:/etc/nginx/dhparams.pem:ro
            - ./LE/etc/letsencrypt:/etc/letsencrypt
        ports:
            - "80:80"
            - "443:443"
        restart: always
        logging:
            driver: syslog

networks:
    default:
        driver: bridge
        ipam:
            driver: default
            config:
                - subnet: 172.18.0.0/16
                  gateway: 172.18.0.1
