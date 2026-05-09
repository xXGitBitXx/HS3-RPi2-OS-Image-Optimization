#!/bin/bash

uzb="/var/www/Main/UZB.txt"
devtty="/dev/ttyACM0"
if [ -e "$uzb" ] ; then
	echo "UZB Connected"
else
	echo "Finding UZB..."
	if [ -e "$devtty" ] ; then
		sudo wget www.homeseer.com/linux/UZB.txt
		sudo cp UZB.txt /var/www/Main
		sudo rm /etc/ser2net.conf
		sudo cp /var/www/Main/ser2net.conf /etc
		echo "UZB Found and Connected"
	else
		echo "No UZB Connected"
	fi
fi
