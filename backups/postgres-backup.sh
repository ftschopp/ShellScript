#!/bin/bash
########################################################################################################################
# MYSQL-BACKUP
########################################################################################################################
SCRIPT_NAME="PG-BACKUP"
SCRIPT_DESCRIPTION="Backup Script for postgres, with gzip, encryption, rsync, s3, and nagios output."
SCRIPT_VERSION="1.0"
SCRIPT_AUTHOR="Fernando Tschopp"
SCRIPT_CONTACT="tschoppfernando@gmail.com"
SCRIPT_DATE="01/07/2018"
SCRIPT_GIT=""
SCRIPT_WEB=""
########################################################################################################################
# HOW TO CREATE PGPASS:
# sudo -E bash -c 'echo "localhost:5432:mydbname:postgres:mypass" | tee ~/.pgpass
# chmod 600  ~/.pgpass
########################################################################################################################

# VARIABLES
PG_DB=
PG_USER=
PG_HOST=localhost
DST_PATH=
NAME=PG-$PG_DB
#MYSQL_DUMP_OPTIONS="--set-gtid-purged=OFF"

# CHECK DST PATH
if [ ! -d $DST_PATH ]; then
        echo "Creando Directorio: $DST_PATH"
       sudo  mkdir -p $DST_PATH
fi

# OUTPUT FOR: check_nagios_mysql_backup.sh (DST_NAGIOS_EXIT_FILE=0 LO DESHABILITA)
NAGIOS_DST_EXIT_FILE=$DST_PATH
NAGIOS_EXIT_FILE=BKP-$NAME.exit
NAGIOS_TIME_FILE=BKP-$NAME-TIME.exit
NAGIOS_STARTTIME=$(date +"%s")

# VARIABLES PARA GENERAR RSYNC. (DST_RMT_SERVER=0 LO DESHABILITA)
RMT_DST_SERVER=0
RMT_DST_PATH=
RMT_DST_USER=
RMT_DST_CERT=

# VARIABLES PARA GENERAR S3. (DST_RMT_S3=0 LO DESHABILITA)
S3_ENABLE=0
S3_BUCKET=

## LOG
DATE=$(date +%m-%d-%Y_%H-%M)Hs
LOG=$DST_PATH/LOG-BKP-$NAME-$DATE.log
echo "--------------------------------------------------------" | tee -a $LOG
echo "SCRIPT: $SCRIPT_NAME" | tee -a $LOG
echo "VERSION: $SCRIPT_VERSION" | tee -a $LOG
echo "INICIO: $DATE" | tee -a $LOG
echo "--------------------------------------------------------" | tee -a $LOG

echo "----------------------------------------------------------" | tee -a $LOG
echo " Dump de Base de Datos..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
PG_FILE_BACKUP=BKP-$NAME-$DATE.sql
echo " Dumpeando en $DST_PATH/$PG_FILE_BACKUP " | tee -a $LOG
sudo pg_dump -h $PG_HOST -U $PG_USER -f "$DST_PATH/$PG_FILE_BACKUP" 2>> $LOG 1>> $LOG \
&& { echo "OK" | tee -a $LOG ; EC_DUMP=0; } || { echo "! ERROR" | tee -a $LOG ; EC_DUMP=1; }

echo "----------------------------------------------------------" | tee -a $LOG
echo " Coprimiendo Dump..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
echo " Comprimiendo archivo de backup: $DST_PATH/$PG_FILE_BACKUP" | tee -a $LOG   
sudo gzip -v $DST_PATH/$PG_FILE_BACKUP 2>> $LOG 1>> $LOG \
&& { echo "OK" | tee -a $LOG ; EC_GZIP=0; } || { echo "! ERROR" | tee -a $LOG ; EC_GZIP=1; }

echo "----------------------------------------------------------" | tee -a $LOG
echo " Encripto Dump..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
echo " Encriptando: $DST_PATH/$PG_FILE_BACKUP.gz" | tee -a $LOG
openssl enc -aes256 -salt -k '$ENC_PASSWORD' -in $DST_PATH/$PG_FILE_BACKUP.gz -out $DST_PATH/$PG_FILE_BACKUP.gz.enc \
&& { echo "OK" | tee -a $LOG ; EC_ENC=0; rm -f $DST_PATH/$PG_FILE_BACKUP.gz; } || { echo "! ERROR" | tee -a $LOG ; EC_ENC=1; }

echo "----------------------------------------------------------" | tee -a $LOG
echo " Nagios Exit Files..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
if [ "$NAGIOS_DST_EXIT_FILE" != "0" ]; then
        if  [[ "$EC_DUMP" == "0" && "$EC_GZIP" == "0" && "$EC_ENC" == "0" ]]; then
                echo "0" | tee -a $LOG > $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE
        else
                echo "EXIT CODE DUMP: $EC_DUMP" | tee -a $LOG > $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE
                echo "EXIT CODE GZIP: $EC_GZIP" | tee -a $LOG >> $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE
                echo "EXIT CODE ENC: $EC_ENC" | tee -a $LOG >> $NAGIOS_DST_EXIT_FILE/$NAGIOS_EXIT_FILE
        fi
        NAGIOS_ENDTIME=$(date +"%s")
        diff=$(($NAGIOS_ENDTIME-$NAGIOS_STARTTIME))
        echo " TIEMPO DEL PROCESO: $(($diff / 60)) MINUTOS Y $(($diff % 60)) SEGUNDOS." | tee -a $LOG > $NAGIOS_DST_EXIT_FILE/$NAGIOS_TIME_FILE
else
        echo "NAGIOS EXIT FILES: DISABLE." | tee -a $LOG
fi

echo "----------------------------------------------------------" | tee -a $LOG
echo " CHECK OLD..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
OLDDAYS=180
find $DST_PATH \( -name "*.enc" -or -name "*.log" \) -type f -mtime +$OLDDAYS -exec rm {} \; -exec /bin/echo {} \; 2>> $LOG 1>> $LOG

echo "----------------------------------------------------------" | tee -a $LOG
echo " RSYNC..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
if [ "$RMT_DST_SERVER" != "0" ]; then
	echo "" | tee -a $LOG
	echo " REMOTE SERVER: $RMT_DST_CERT" | tee -a $LOG
	rsync --delete-before -avze "ssh -i $RMT_DST_CERT" $DST_PATH/ $RMT_DST_USER@$RMT_DST_SERVER:$RMT_DST_PATH 2>> $LOG 1>> $LOG
else
	echo "RSYNC: DISABLE." | tee -a $LOG
fi

echo "----------------------------------------------------------" | tee -a $LOG
echo " S3..." | tee -a $LOG
echo "----------------------------------------------------------" | tee -a $LOG
if [ "$S3_ENABLE" != "0" ]; then
    command -v aws >/dev/null 2>&1 || { echo >&2 "AWSCLI Not Installed..." | tee -a $LOG ; exit 1; }
    echo "" | tee -a $LOG
    echo " BUCKET: $S3_BUCKET" | tee -a $LOG
    aws s3 cp $DST_PATH/$PG_FILE_BACKUP.gz.enc $S3_BUCKET/ 2>> $LOG 1>> $LOG
else
    echo "S3: DISABLE" | tee -a $LOG
fi
