#!/bin/bash
########################################################################################################################
# CHECK NAGIOS TARGZ-BACKUP
########################################################################################################################
SCRIPT_NAME="CHECK_NAGIOS_TARGZ-BACKUP"
SCRIPT_DESCRIPTION="Nagios Check Script for targz-backup.sh"
SCRIPT_VERSION="1.0"
SCRIPT_AUTHOR="Fernando Tschopp"
SCRIPT_CONTACT="tschoppfernando@gmail.com"
SCRIPT_DATE="01/07/2018"
SCRIPT_GIT=""
SCRIPT_WEB=""
########################################################################################################################

# VARIABLES
NAME=
NAGIOS_DST_EXIT_FILE=
NAGIOS_EXIT_FILE=KP-$NAME.exit
NAGIOS_TIME_FILE=BKP-$NAME-TIME.exit

# CHECKS
if [ $(cat $NAGIOS_DST_EXIT_FILE\$NAGIOS_EXIT_FILE) -eq 0 ]; then
	if test "`find $NAGIOS_DST_EXIT_FILE\$NAGIOS_EXIT_FILE -mtime +2`"; then
	if ! find $NAGIOS_DST_EXIT_FILE\$NAGIOS_EXIT_FILE -ctime -2 > /dev/null; then
		echo "CRITICAL - NO SE ENCUENTRA BACKUP RECIENTE"
		exit 2
	else
		echo "OK - BACKUP CORRECTO: "$(cat $NAGIOS_DST_EXIT_FILE\$NAGIOS_TIME_FILE)
		exit 0
	fi
else
	echo "CRITICAL - EL BACKUP FALLO: "$(cat $NAGIOS_DST_EXIT_FILE\$NAGIOS_EXIT_FILE)
	exit 2
fi
