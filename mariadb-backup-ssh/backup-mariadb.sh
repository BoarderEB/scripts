#!/bin/bash
#
# Fork: Boardereb
# GPLv2+
# V: 0.90b

### To change:

USERNAME="username"
SERVER_IP="remote.server.eu"
RemoteFileLocation="/"
MAXBACKUPS="1"

### Loglevel 0=only Errors
### Loglevel 1=start, exit, warn and errors
### Loglevel 2=every action

LOGLEVEL="2"
SYSLOGER="true"

### Set SysLoggerPath if not "logger"
#SYSLOGGERPATH="/usr/bin/logger"

### GPG
### make shure the you pgp-public-key is importet in the xcp-server
### gpg2 --import gpg-pub-key.asc
### if you like to test in this system import and export you neet also do import the secret-keys
### gpg2 --import gpg-secret-key.asc
### for import - export test:
### $ echo "YES GPG WORKS" | gpg2 --encrypt -a --recipient KEY-ID_or_Name --trust-model always | gpg2 --decrypt

#GPG="true"

### if you only imported 1 gpg-public-key on the system, you find the key-id with this:
### $ gpg2 --list-public-keys --keyid-format LONG | grep 'pub ' | cut -d' ' -f4 | cut -d'/' -f2

#GPGID="public-key-id"

### Send Log-Email with mailx - make sure it is configured:
### echo "bash testmail" | mail -s "testmail from bash" "your@email.com"

#LOGMAIL="true"
#MAILADRESS="mail@adress.com" ### if not set send mail to $USER

### if the my.cf is not in ~/ it can be specified here 
#CONF=/path/to/my.cf

### int. Variablen

BACKUPNAME=$(echo "mariadb-$HOSTNAME")
INTRANDOME=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
MOUNTPOINT=$(echo "/mnt/$INTRANDOME")
DATE=$(date +%Y-%m-%d)
MAILFILE=$(mktemp /tmp/mail.XXXXXXXXX)
SCRIPT="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
IGNORE="phpmyadmin|mysql|information_schema|performance_schema|test|Warning|sys"

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
    SYSLOGGER "$0: $LOGGERMASSAGE"
    fi
}

### Send Mail

function MAILTO() {
  if [[ $LOGMAIL == "true" ]]; then
    if [[ $(cat $MAILFILE) != '' ]]; then
      if [[ -z ${MAILADRESS} ]]; then
        MAILADRESS=$USER
      fi
      if [[ $(cat $MAILFILE | grep -i "error") != '' ]]; then
        SUBJECT="$SCRIPT-error: from $BACKUPNAME"
      else
        SUBJECT="$SCRIPT-log: from $BACKUPNAME"
      fi
      cat $MAILFILE | mail -s "$SUBJECT" "$MAILADRESS"
    fi
  fi
}

### commands before exit + cleans up + exit the script
### QUIT "EXITCODE"
### QUIT 0 = exit 0

function QUIT() {
  REMOVEMOUNT
  MAILTO
  rm $MAILFILE
  LOGGERMASSAGE 1 "$SCRIPT: Backup finished"
  exit $1
}

### get a List of Backupdirs
### -c = count of Backupsdirs
### $(BACKUPDIRS -c)

function BACKUPDIRS() {
  local BACKUPPATH="$MOUNTPOINT/$BACKUPNAME/"
  local BACKUPDIRS=$(find $BACKUPPATH  -maxdepth 1 -type d -printf "%T@ %p\n"  | sort -n -r | cut -d' ' -f2 |  grep -v "^$BACKUPPATH$" | grep -v "^.$")
  if [[ $1 = "-c" ]]; then
    local BACKUPDIRS=$(echo "$BACKUPDIRS" | wc -l)
  fi
  echo "$BACKUPDIRS"
}


### Is there the specified GPG key?
function TESTGPG() {
  if [[ $GPG == "true" ]]; then
    if [[ ! -z $GPGID ]]; then
      gpg2 --list-public-keys "$GPGID" >> /dev/null
      if [[ $? -ne 0 ]]; then
        LOGGERMASSAGE 0 "Error: GPG-KEY-ID not found"
        echo "false"
      else
        echo "true"
      fi
    fi
  fi
}

function REMOVEMOUNT() {
  # unmount if not befor for the script moundet
  if [[ $MOUNDET != "allrady"  ]]; then
    if [[ $(AllradyMoundet) == "false" ]]; then 
      LOGGERMASSAGE "delete the created mountpoint $MOUNTPOINT"
      rm -rf $MOUNTPOINT
    else
      LOGGERMASSAGE "unmount $MOUNTPOINT" 
      umount $MOUNTPOINT
      if [[ $? -eq 0 ]]; then
        if [[ ! -z MOUNTEXIST ]]; then
          LOGGERMASSAGE "delete the created mountpoint $MOUNTPOINT"
          rm -rf $MOUNTPOINT
        fi
      else
        LOGGERMASSAGE 0 "Error: could not umount $MOUNTPOINT because of that not deleted"
      fi
    fi
  fi
}

function AllradyMoundet(){
  MOUNT=$(grep "$USERNAME@$SERVER_IP:$RemoteFileLocation $MOUNTPOINT" /proc/mounts | grep $MOUNTPOINT)
  if [[ -z $MOUNT ]]; then
    echo "false"
  else
    echo "true"
  fi
}


LOGGERMASSAGE 1 "Start $SCRIPT Backup"

### Create mount point
LOGGERMASSAGE "Create mountpoint $MOUNTPOINT if not exist"
if [[ ! -d ${MOUNTPOINT} ]]; then
  mkdir -p $MOUNTPOINT
  if [[ ! -d ${MOUNTPOINT} ]]; then
  	LOGGERMASSAGE 0 "Error: No mount point found, kindly check"
  	QUIT 1
  fi
else
  MOUNTEXIST="true"
fi

### check if allrady moundet - if not mount
MOUNDET=$(stat -c%d "$MOUNTPOINT")
if [[ $(AllradyMoundet) == "false" ]]; then
    LOGGERMASSAGE "mount sshfs $SERVER_IP:$RemoteFileLocation"
    sshfs $USERNAME@$SERVER_IP:$RemoteFileLocation $MOUNTPOINT
    if [[ `stat -c%d "$MOUNTPOINT"` -eq $MOUNDET ]]; then
      LOGGERMASSAGE 0 "Error: Coult not mount $SERVER_IP:$RemoteFileLocation $MOUNTPOINT"
      QUIT 1
    fi
else
  MOUNDET="allrady"
  LOGGERMASSAGE "$SERVER_IP:$RemoteFileLocation $MOUNTPOINT allrady mounted"
fi

### creat backuppath if not exist
BACKUPPATH="$MOUNTPOINT/$BACKUPNAME/$DATE"
if [[ -d ${BACKUPPATH} ]]; then
    LOGGERMASSAGE 1 "Warn: Create backuppath $BACKUPPATH already exists."
    BACKUPPATH=$(echo "$MOUNTPOINT/$BACKUPNAME/$DATE")-$(echo $INTRANDOME)
fi
LOGGERMASSAGE "Create backuppath $BACKUPPATH"
mkdir -p $BACKUPPATH
if [[ ! -d ${BACKUPPATH} ]]; then
	LOGGERMASSAGE 0 "Error: No backup directory found"
	QUIT 1
fi

### Fetching list UUIDs of all VMs running on XenServer
DBS="$(mariadb --defaults-extra-file=$CONF -Bse 'show databases' | /bin/grep -Ev $IGNORE)"
if [[ -z ${DBS} ]]; then
	LOGGERMASSAGE 0 "Error: No Databases found for backup"
	QUIT 1
fi

for DB in $DBS; do
    if [[ $GPG == "true" ]]; then
        LOGGERMASSAGE "Start export of $DB gpg encodet"
        mariadb-dump --defaults-extra-file=$CONF --databases $DB | gpg2 --encrypt -a --recipient $GPGID --trust-model always >  "$BACKUPPATH/$DB-$DATE.sql.gpg"
        if [[ ${PIPESTATUS[0]} != 0 ]]; then
            EXPORTERROR="true"
            LOGGERMASSAGE 0 "Error: there was a problem exporting the database $DB"
        else
            LOGGERMASSAGE "Export of $DB successfully"
        fi
    else
        LOGGERMASSAGE "Start export of $DB"
        mariadb-dump --defaults-extra-file=$CONF --skip-extended-insert --skip-comments --databases $DB >  "$BACKUPPATH/$DB-$DATE.sql" 
        if [[ $? -ne 0 ]]; then
            EXPORTERROR="true"
            LOGGERMASSAGE 0 "Error: there was a problem exporting the database $DB"
        else
            LOGGERMASSAGE "Export of $DB successfully"
        fi
    fi    
done

### Remove old Backups
if [[ -z "$EXPORTERROR" ]]; then
  BACKUPS=$(BACKUPDIRS -c)
  COUNT=$(($BACKUPS-$MAXBACKUPS))
  if [[ $COUNT -lt 0 ]]; then
    COUNT=0
  fi
  LOGGERMASSAGE "$BACKUPS backup found - remove $COUNT old backup"

  if [[ $COUNT > 0 ]]; then
    COUNT=1
    for DIR in $(BACKUPDIRS);do
      if [[ $COUNT > $MAXBACKUPS ]]; then
        rm -rf $DIR
      fi
      COUNT=$(($COUNT+1))
    done

    if [[ $(BACKUPDIRS -c) == $MAXBACKUPS ]]; then
      LOGGERMASSAGE "old backups are removed"
    else
      LOGGERMASSAGE 0 "Error: not all old backups are removed"
    fi
  fi
else
  LOGGERMASSAGE 0 "Error: Do not remove old Backups becouse a error in the new backup"
fi

### YIPPI we are finished

if [[ ! -z "$EXPORTERROR" ]]; then
  QUIT 1
fi

QUIT 0