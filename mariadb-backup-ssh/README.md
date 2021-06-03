# Mariadb (Mysql) backup script to sftp/ssh server

## Min to do

**Sshfs** is used for the script, install it:
```
apt install sshfs 
```

### My.cnf
Copy *my.cnf* to */home/user/.my.cnf* and add the username and password for the mariadb-Server in [client] and [mysqldump]

### Change in the script:

- USERNAME="username"
- SERVER_IP="remote.server.eu"
- RemoteFileLocation="/"
- MAXBACKUPS="1"

### Create a ssh-key or copy a ssh-key to the server
create with 
```
ssh-keygen -t ed25519 
```

### Copy ssh-id.pub to the remote server
for sftp:
```
cd ~/.ssh/
echo -e "mkdir .ssh \n chmod 700 .ssh \n put id_ed25519.pub .ssh/authorized_keys \n chmod 600 .ssh/authorized_keys" | sftp username@remote-server.com
```

for ssh:
```
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server 
```

## Cron-Backup

For an automatic backup copy the script to one of this:
/etc/cron.daily or /etc/cron.weekly or /etc/cron.monthly

If you want to have more than one backup loop. Then modify in the scriptcopys in /etc/cron.* :

* BACKUPNAME=$(echo "mysql-$HOSTNAME") to like this:

- BACKUPNAME=$(echo "mysql-$HOSTNAME-daily")
- BACKUPNAME=$(echo "mysql-$HOSTNAME-weekly")
- BACKUPNAME=$(echo "mysql-$HOSTNAME-monthly")

## PGP encoding

The encrypted backup export is highly recommended!

### Activate gpg in the script 

If you like to export the vm encoding with GPG you must set this:
  - GPG="true"

Also you must set the GPG-Key-ID or the Name of the key to be used for encryption.
  - GPGID="key-id or Name"

if you have only 1 gpg-public-key on the system, you find the key-id with this:
```
gpg2 --list-public-keys --keyid-format LONG | grep 'pub ' | cut -d' ' -f4 | cut -d'/' -f2
```

### Install gpg
```
apt install gpg2
```
### Import or create a gpg-key

Creat the key with: (use "RSA and RSA (default)" and "4096 keysize")
```
gpg2 --full-gen-key 
```
and export the private key and store it in a safe place 
```
gpg2 -a --output gpg-secret-key.asc --export-secret-keys <privat-key-id>
```
or import the public key with
```
gpg2 --import gpg-pub-key.asc
```

