#!/bin/bash

# Skriptname: /etc/cron.daily/nextcloud-update

NEXTCLOUD_DIR="/var/www/nextcloud"
PHP="/usr/bin/php"

# Temporäre Logdatei
LOGFILE="/tmp/nextcloud-update.log"
ERRORFLAG=0

log() {
  echo "$1"
  logger -t nextcloud-update "$1"
}

# Prüfe Erreichbarkeit des Update-Servers
check_updater_server() {
  curl --head --silent --max-time 5 https://updates.nextcloud.com | grep "200 OK" > /dev/null
  return $?
}

{
  log "=== Nextcloud Update gestartet: $(date) ==="

  # Verfügbarkeit prüfen
  if check_updater_server; then
    log "Updater-Server erreichbar"
  else
    log "Fehler: Updater-Server nicht erreichbar – Update wird abgebrochen"
    ERRORFLAG=1
  fi

  # Wartungsmodus aktivieren
  if [ "$ERRORFLAG" -eq 0 ]; then
    if sudo -u www-data $PHP $NEXTCLOUD_DIR/occ maintenance:mode --on; then
      log "Wartungsmodus aktiviert"
    else
      log "Fehler: Wartungsmodus konnte nicht aktiviert werden"
      ERRORFLAG=1
    fi
  fi

  # Core-Update
  if [ "$ERRORFLAG" -eq 0 ]; then
    if sudo -u www-data $PHP $NEXTCLOUD_DIR/updater/updater.phar --no-interaction; then
      log "Core-Update erfolgreich"
    else
      log "Fehler: Core-Update fehlgeschlagen"
      ERRORFLAG=1
    fi
  fi

  # Datenbankreparatur
  if [ "$ERRORFLAG" -eq 0 ]; then
    if sudo -u www-data $PHP $NEXTCLOUD_DIR/occ maintenance:repair --include-expensive; then
      log "maintenance:repair erfolgreich"
    else
      log "Fehler bei maintenance:repair"
      ERRORFLAG=1
    fi
  fi

  # Fehlende Indizes ergänzen
  if [ "$ERRORFLAG" -eq 0 ]; then
    if sudo -u www-data $PHP $NEXTCLOUD_DIR/occ db:add-missing-indices; then
      log "db:add-missing-indices erfolgreich"
    else
      log "Fehler bei db:add-missing-indices"
      ERRORFLAG=1
    fi
  fi

  # Apps aktualisieren
  if [ "$ERRORFLAG" -eq 0 ]; then
    if sudo -u www-data $PHP $NEXTCLOUD_DIR/occ app:update --all; then
      log "Apps erfolgreich aktualisiert"
    else
      log "Fehler beim Aktualisieren der Apps"
      ERRORFLAG=1
    fi
  fi

  # Wartungsmodus deaktivieren – nur wenn alles OK
  if [ "$ERRORFLAG" -eq 0 ]; then
    if sudo -u www-data $PHP $NEXTCLOUD_DIR/occ maintenance:mode --off; then
      log "Wartungsmodus deaktiviert"
    else
      log "Fehler: Wartungsmodus konnte nicht deaktiviert werden"
      ERRORFLAG=1
    fi
  else
    log "Wartungsmodus bleibt aktiv – Fehler ist aufgetreten"
  fi

  log "=== Nextcloud Update beendet: $(date) ==="

} > "$LOGFILE" 2>&1

# Fehler? → Mail an root
if [ "$ERRORFLAG" -ne 0 ]; then
  mail -s "Fehler beim Nextcloud-Update" root < "$LOGFILE"
fi

# Log löschen
rm "$LOGFILE"