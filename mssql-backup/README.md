# Script to Backup all MSSQL-Databases

**Caution: Only use it on a server that only does mssql. Only one user system. No Apache or anything! MSSQL does not support USERNAME and PASSWORD in the ~/.odbc.ini. Therefore there is a very large security hole in the script. A "ps aux | grep sqlcmd" reveals the password to all users.**

To create multiple backup loops, change 
```
BACKUPNAME=$(echo "$HOSTNAME")
```

To something like that 
```
BACKUPNAME=$(echo "$HOSTNAME-daily")
```