#!/usr/bin/env bash
# Uninstall script to remove everything
#set -x # Uncomment to debug
trap 'rm -f ${TMPFILE}' EXIT
my_dir=$HOME/BirdNET-Pi/scripts
source /etc/birdnet/birdnet.conf &> /dev/null
SCRIPTS=($(ls -1 ${my_dir}) ${HOME}/.gotty)
set -x
services=($(awk '/service/ && /systemctl/ && !/php/ {print $3}' ${my_dir}/install_services.sh | sort) custom_recording.service avahi-alias@.service)

backup_database() {
  DB_FILE="$HOME/BirdNET-Pi/scripts/birds.db"
  if [ -f "$DB_FILE" ]; then
    BACKUP_NAME="$HOME/BirdNET-Pi-backup-$(date +%F).db"
    echo "Backing up detections database to $BACKUP_NAME ..."
    cp "$DB_FILE" "$BACKUP_NAME"
    echo "Backup complete."
  else
    echo "No database found at $DB_FILE. Skipping backup."
  fi
}

remove_services() {
  for i in "${services[@]}"; do
    if [ -L /etc/systemd/system/multi-user.target.wants/"${i}" ];then
      sudo systemctl disable --now "${i}"
    fi
    if [ -L /lib/systemd/system/"${i}" ];then
      sudo rm -f /lib/systemd/system/$i
    fi
    if [ -f /etc/systemd/system/"${i}" ];then
      sudo rm /etc/systemd/system/"${i}"
    fi
    if [ -d /etc/systemd/system/"${i}" ];then
      sudo rm -drf /etc/systemd/system/"${i}"
    fi
  done
  set +x
  remove_icecast
  remove_crons
}

remove_crons() {
  sudo sed -i '/birdnet/,+1d' /etc/crontab
}

remove_icecast() {
  if [ -f /etc/init.d/icecast2 ];then
    sudo /etc/init.d/icecast2 stop
    sudo systemctl disable --now icecast2
  fi
}

remove_caddy() {
  echo "Removing Caddy web server..."
  sudo systemctl disable --now caddy 2>/dev/null || true
  sudo rm -rf /etc/caddy /etc/systemd/system/caddy.service /etc/systemd/system/caddy.service.d
  # Remove the caddy system user if it exists
  sudo deluser caddy 2>/dev/null || true
  echo "Caddy removed."
}

remove_sudoers() {
  echo "Removing Web UI sudoers rule..."
  sudo rm -f /etc/sudoers.d/www-data-systemctl
  echo "Sudoers rule removed."
}

remove_data_dirs() {
  echo "Removing data directories (BirdSongs, BattyBirdNET-Analyzer)..."
  rm -rf ~/BirdSongs ~/BattyBirdNET-Analyzer
  echo "Data directories removed."
}

remove_scripts() {
  for i in "${SCRIPTS[@]}";do
    if [ -L "/usr/local/bin/${i}" ];then
      sudo rm -v "/usr/local/bin/${i}"
    fi
  done
}

backup_database

remove_services
remove_scripts
remove_caddy
remove_sudoers
remove_data_dirs

if [ -d /etc/birdnet ];then sudo rm -drf /etc/birdnet;fi
if [ -f ${HOME}/BirdNET-Pi/birdnet.conf ];then sudo rm -f ${HOME}/BirdNET-Pi/birdnet.conf;fi
echo "Uninstall finished. Remove the BirdNET-Pi directory with 'rm -drfv ~/BirdNET-Pi' to finish."
