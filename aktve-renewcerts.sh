#!/usr/bin/env bash

# This script attempts to renew the Let's Encrypt certificate on this system,
# either by actually renewing it via a signing request to the Certificate
# Authority, or by pulling the certificate off of the primary server responsible
# for performing said renewal.
#
# Author: Luke Hollenback
# Date: 27 February 2017
#
# MAKE SURE TO UPDATE THE PRIMARY SERVER IP WHEN USING THIS SCRIPT FOR A
# DIFFERENT CERTIFICATE "TRIBE" (E.G. FOR THE DATABASE SERVERS INSTEAD OF THE
# API SERVERS).

TRIBE_LEADER_IP="138.197.232.193"
CERTIFICATE_DOMAIN="aktve-app.com"
CERTIFICATE_ADMIN="certadmin"

echo "Determining server's role in tribe..."
echo "The tribe leader's IP address is ${TRIBE_LEADER_IP}."

current_floating_ip="$(curl -s http://169.254.169.254/metadata/v1/floating_ip/ipv4/ip_address)" # Retrieve this server's floating IP address, if it exists, from the Digial Ocean API
echo "This server's floating IP address is ${current_floating_ip}."

if [[ $current_floating_ip == ${TRIBE_LEADER_IP} ]]
then
	echo "This server is the tribe leader."

	echo "Attempting to update SSL certificate via Let's Encrypt..."
	/usr/bin/letsencrypt renew >> /var/log/letsencrypt-renewal.log
	/bin/systemctl reload nginx

	echo "Copying certificates to certificate admin's home directory..."
	mkdir -p /home/${CERTIFICATE_ADMIN}/current_ssl_certificate
	cp -f /etc/letsencrypt/live/${CERTIFICATE_DOMAIN}/* /home/${CERTIFICATE_ADMIN}/current_ssl_certificate
else
	echo "This server is not the tribe leader."

	echo "Attempting to update SSL certificate via Tribe Leader..."
	mkdir -p /home/${CERTIFICATE_ADMIN}/current_ssl_certificate
	scp -i /home/${CERTIFICATE_ADMIN}/.ssh/id_rsa ${CERTIFICATE_ADMIN}@${TRIBE_LEADER_IP}:~/current_ssl_certificate/* /home/${CERTIFICATE_ADMIN}/current_ssl_certificate
	cp -f /home/${CERTIFICATE_ADMIN}/current_ssl_certificate/* /etc/letsencrypt/live/${CERTIFICATE_DOMAIN}
fi
