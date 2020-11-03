## /etc/cron.d/ EXAMPLE
# TODO SET PATH TO git.update.sh
# EVERY 5 MINUTES START UPDATE OF REPOSITORYS
*/5 * * * * root /path/git.update.sh >/dev/null 2>&1
