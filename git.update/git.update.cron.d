## /etc/cron.d/ EXAMPLE
# TODO SET PATH TO git.update.sh
# EVERY 5 MINUTES START UPDATE OF REPOSITORYS
*/5 * * * * root /usr/bin/git.update.sh >/dev/null 2>&1
