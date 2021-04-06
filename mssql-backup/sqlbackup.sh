#!/bin/bash
#
# GPLv2+
# V: 0.01-Beta1

### To change:

BACKUPDIR="/var/opt/mssql/backup/"
USERNAME="SA"
PASSWORD='PASS'

### Loglevel 0=only Errors
### Loglevel 1=start, exit, warn and errors
### Loglevel 2=every action

LOGLEVEL="2"
SYSLOGER="true"

### Set SysLoggerPath if not "logger"
#SYSLOGGERPATH="/usr/bin/logger"

### Send Log-Email with mailx - make sure it is configured:
### echo "bash testmail" | mail -s "testmail from bash" "your@email.com"
#LOGMAIL="true"
#MAILADRESS="the@mailadress.com" ### if not set send mail to $USER

### int. Variablen

BACKUPNAME=$(echo "$HOSTNAME")
INTRANDOME=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
DATE=$(date +%d-%m-%Y)-$(echo $INTRANDOME)
MAILFILE=$(mktemp /tmp/mail.XXXXXXXXX)
SQLCMD="/opt/mssql-tools/bin/sqlcmd"
IGNORDBS="master,tempdb,model,msdb"



### LOGGERMASSAGE function
### Var1: LOGGERMASSAGE LOGLEVEL "LOGMASSAGE"
### Var2: LOGGERMASSAGE "LOGMASSAGE" = LOGLEVEL 1 = only start and stop

function SYSLOGGER() {
  if [[ SYSLOGER -eq "true" ]]; then
    if [ -z ${SYSLOGGERPATH} ];then
      if hash logger 2>/dev/null; then
        logger $1
      fi
    else
      if [[ -x ${SYSLOGGERPATH} ]]; then
        $SYSLOGGERPATH $1
      fi
    fi
  fi
}

function LOGGERMASSAGE() {
  local TIME=$(date +'%H:%M')
  local NUMBER='^[0-9]+$'
  if [[ $1 =~ $NUMBER ]]; then
    local LOGGERMASSAGELEVEL="$1"
    local LOGGERMASSAGE="$2"
  else
    local LOGGERMASSAGELEVEL="2"
    local LOGGERMASSAGE="$1"
  fi
  if [[ $LOGGERMASSAGELEVEL -le $LOGLEVEL ]]; then
    echo $0: $LOGGERMASSAGE
    echo $TIME: $0:  $LOGGERMASSAGE >> $MAILFILE
  fi
  SYSLOGGER "$0: $LOGGERMASSAGE"  
}

### Send Mail

function MAILTO() {
  if [[ $LOGMAIL == "true" ]]; then
    if [[ $(cat $MAILFILE) != '' ]]; then
      if [[ -z ${MAILADRESS} ]]; then
        MAILADRESS=$USER
      fi
      if [[ $(cat $MAILFILE | grep -i "error") != '' ]]; then
        SUBJECT="SQL BACKUP-error: from $BACKUPNAME"
      else
        SUBJECT="SQL BACKUP-log: from $BACKUPNAME"
      fi
      cat $MAILFILE | mail -s "$SUBJECT" "$MAILADRESS"
    fi
  fi
}

### commands before exit + cleans up + exit the script
### QUIT "EXITCODE"
### QUIT 0 = exit 0

function QUIT() {
  MAILTO
  rm $MAILFILE
  LOGGERMASSAGE 1 "$0: SQL BACKUP FINISH"
  exit $1
}


function STARTBACKUP(){

    if [[ $? -ne 0 ]]; then
        LOGGERMASSAGE 0 "Error: When backup db: $1 - see syslog"
        return 1
    else
        return 0
    fi
}

function IGNOREDB(){
    IGNORE="false"
    IFS=',' read -ra IGNORDBLIST <<< "$IGNORDBS"
    for INGNOREDB in ${IGNORDBLIST[@]}; do
        if [[ $INGNOREDB = $1 ]]; then
            echo "true"
        fi
    done 
}


LOGGERMASSAGE 2 "start SQL Backup"

LOGGERMASSAGE 2 "Check if there the Backupdir"

if [[ ! -d ${BACKUPDIR} ]]; then
  LOGGERMASSAGE 1 "Create backup directory "
  mkdir -p $BACKUPDIR
  if [[ ! -d ${BACKUPDIR} ]]; then
  	LOGGERMASSAGE 0 "Error: Backupdir not found and could not be created."
  	QUIT 1
  fi
fi

### Fetching list SQL-Database
SQLDBS=$($SQLCMD -S localhost -U $USERNAME -P $PASSWORD -h-1 -W -Q " SET NOCOUNT ON;select name from sys.databases")

### Int. Count for Backup-DBs
COUNT=0

### Loop for Backup-DBs
for SQLDB in $SQLDBS; do
    if [[ $(IGNOREDB $SQLDB) != "true" ]]; then

        ### Count for Backup-DBS
        COUNT=$(($COUNT+1))
        
        ### Test is there a old Backupfile
        BACKUPFILE=$(echo $BACKUPDIR$SQLDB.$BACKUPNAME.bak)
        if [[ -f $BACKUPFILE.new ]]; then
            LOGGERMASSAGE 1 "Warn: Olt Temp Backup-File found - remove"
            rm $BACKUPFILE.new
            if [[ $? -ne 0 ]]; then
                LOGGERMASSAGE 0 "Error: Could not delete backup file: $BACKUPFILE"
	            QUIT 1
            fi
        fi
        
        ### Start MSSQL-BACKUP
        LOGGERMASSAGE 1 "Start Backup of $SQLDB"
        STOUTFILE=$(mktemp /tmp/stout.XXXXXXXXX)
        CMD=$(echo "BACKUP DATABASE [$SQLDB] TO DISK = N'$BACKUPFILE.new' WITH NOFORMAT, NOINIT, NAME = '$SQLDB', SKIP, NOREWIND, NOUNLOAD, STATS = 10")
        $SQLCMD -S localhost -U $USERNAME -P $PASSWORD -Q "$CMD" &>> $STOUTFILE
        if [[ $? -ne 0 ]]; then
            LOGGERMASSAGE 0 "Error: When backup db: $SQLDB - see syslog"
            EXPORTERROR="true"
        else
            mv $BACKUPFILE.new  $BACKUPFILE
            if [[ $? -ne 0 ]]; then
                LOGGERMASSAGE 0 "Error: Could move $BACKUPFILE.new to $BACKUPFILE"
                EXPORTERROR="true"
            fi
        fi
        if [[ -f $STOUTFILE ]]; then
          STOUT=$(cat $STOUTFILE)
          LOGGERMASSAGE 2 "$STOUT"
          rm $STOUTFILE
        fi
    fi
done 

### Were there any databases that were backed up? 
if [[ $COUNT = 0 ]]; then
	LOGGERMASSAGE 0 "Error: NO SQL-Databes found for backup"
	QUIT 1
fi

if [[ ! -z "$EXPORTERROR" ]]; then
  LOGGERMASSAGE 0 "Error: SQLBACKUP by finish $BACKUPNAME"
  QUIT 1
fi

LOGGERMASSAGE 2 "SQLBACKUP FINISH"
QUIT 0