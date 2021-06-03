# Mariadb (Mysql) backup script to sftp/ssh server

sshfs is used for the script 
> apt install sshfs 

## my.cnf
Copy my.cnf to /user/my.cnf and add the username and password in [client] and [mysqldump]

### min to change in the script:

USERNAME="username"
SERVER_IP="remote.server.eu"
RemoteFileLocation="/"
MAXBACKUPS="1"

### create a ssh-key
> ssh-keygen -t ed25519 

### copy ssh-id.pub to the remote sftp server
for sftp:
> cd ~/.ssh/
> echo -e "mkdir .ssh \n chmod 700 .ssh \n put id_ed25519.pub .ssh/authorized_keys \n chmod 600 .ssh/authorized_keys" | sftp username@remote-server.com

for ssh:
> ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server 

### PGP encoding

The encrypted backup export is highly recommended!

Install gpg
> apt install gpg2

#### Import or create a gpg-key

Creat the key with: (use "RSA and RSA (default)" and "4096 keysize")
> gpg2 --full-gen-key 

Importet with
> gpg2 --import gpg-pub-key.asc

Export the private key and store it in a safe place 
> gpg2 -a --output gpg-secret-key.asc --export-secret-keys <privat-key-id>

#### Activate gpg in the script 

If you like to export the vm encoding with GPG you must set this:
  - GPG="true"

Also you must set the GPG-Key-ID or the Name of the key to be used for encryption.
  - GPGID="key-id or Name"

if you have only 1 gpg-public-key on the system, you find the key-id with this:
> gpg2 --list-public-keys --keyid-format LONG | grep 'pub ' | cut -d' ' -f4 | cut -d'/' -f2

### Cron-Backup

For an automatic backup copy the script to one of this:
/etc/cron.daily or /etc/cron.weekly or /etc/cron.monthly

If you want to have more than one backup loop. Then modify in the scriptcopys in /etc/cron.* :

* BACKUPNAME=$(echo "mysql-$HOSTNAME") to like this:

- BACKUPNAME=$(echo "mysql-$HOSTNAME-daily")
- BACKUPNAME=$(echo "mysql-$HOSTNAME-weekly")
- BACKUPNAME=$(echo "mysql-$HOSTNAME-monthly")