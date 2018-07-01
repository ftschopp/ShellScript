#!/bin/bash
########################################################################################################################
# CHECK NAGIOS MYSQL-BACKUP
########################################################################################################################
SCRIPT_NAME="CHECK_NAGIOS_MYSQL-BACKUP"
SCRIPT_DESCRIPTION="Nagios Check Script for mysql-backup.sh"
SCRIPT_VERSION="1.0"
SCRIPT_AUTHOR="Fernando Tschopp"
SCRIPT_CONTACT="tschoppfernando@gmail.com"
SCRIPT_DATE="01/07/2018"
SCRIPT_GIT=""
SCRIPT_WEB=""
########################################################################################################################

# VARIABLES
MYSQL_DB=dbname
DST_PATH=/data/backups/$MYSQL_DB
NAME=MYSQL-$MYSQL_DB
NAGIOS_DST_EXIT_FILE=$DST_PATH
NAGIOS_EXIT_FILE=BKP-$NAME.exit
NAGIOS_TIME_FILE=BKP-$NAME-TIME.exit

# CHECKS
if [[ $(cat $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE) != 0 ]]; then
        echo "CRITICAL - EL BACKUP FALLO: "$(cat $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE)
        exit 2
else
        if test "`find $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE -mtime +2`"; then
                echo "CRITICAL - NO SE ENCUENTRA BACKUP RECIENTE"
                exit 2
        else
                echo "OK - BACKUP CORRECTO: "$(cat $NAGIOS_DST_EXIT_FILE/$NAGIOS_TIME_FILE)
                exit 0
        fi
fi
