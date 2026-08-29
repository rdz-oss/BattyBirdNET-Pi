#!/usr/bin/env bash
# This installs the services that have been selected
set -e # Exit immediately if any command fails
set -x # Uncomment to enable debugging
trap 'rm -f ${tmpfile}' EXIT
trap 'exit 1' SIGINT SIGHUP
tmpfile=$(mktemp)

config_file=$my_dir/birdnet.conf
export USER=$USER
export HOME=$HOME

export PYTHON_VIRTUAL_ENV="$HOME/BirdNET-Pi/birdnet/bin/python3"

install_depends() {
  # Ensure any stray 'ftpd' package from previous attempts is removed to avoid install failures
  sudo apt -qqy purge ftpd || true
  sudo apt -qqy autoremove -y ftpd || true
  apt install -y debian-keyring debian-archive-keyring apt-transport-https
  apt -qq update
  apt -qqy upgrade

  echo "icecast2 icecast2/icecast-setup boolean false" | debconf-set-selections
  apt install -qqy sqlite3 php-sqlite3 alsa-utils \
    pulseaudio avahi-utils sox libsox-fmt-mp3 php-fpm php-curl php-xml \
    php-zip php icecast2 swig ffmpeg wget unzip curl cmake make bc libjpeg-dev \
    zlib1g-dev python3-dev python3-pip python3-venv lsof net-tools build-essential rclone
}

# ----------------------------------------------------------------------
# install_caddy_manually – download the official Caddy tarball, place the
# binary in /usr/local/bin, create a minimal systemd unit and enable it.
# ----------------------------------------------------------------------
install_caddy_manually() {
  ARCH=$(uname -m)
  case "$ARCH" in
    aarch64) CADDY_URL="https://github.com/caddyserver/caddy/releases/download/v2.8.4/caddy_2.8.4_linux_arm64.tar.gz" ;;
    x86_64) CADDY_URL="https://github.com/caddyserver/caddy/releases/download/v2.8.4/caddy_2.8.4_linux_amd64.tar.gz" ;;
    *) echo "Unsupported architecture $ARCH for manual Caddy install" ; return 1 ;;
  esac

  echo "Downloading Caddy from $CADDY_URL ..."
  curl -L -o /tmp/caddy.tar.gz "$CADDY_URL"
  sudo tar -xzf /tmp/caddy.tar.gz -C /usr/local/bin caddy
  sudo chmod +x /usr/local/bin/caddy

  # create a system user if it does not exist
  if ! id -u caddy >/dev/null 2>&1; then
    sudo useradd --system --no-create-home --shell /usr/sbin/nologin caddy
  fi

  # create required dirs and set ownership
  sudo mkdir -p /etc/caddy /var/lib/caddy
  sudo chown -R caddy:caddy /etc/caddy /var/lib/caddy

  # minimal Caddyfile (will be overwritten later by install_Caddyfile())
  if [ ! -f /etc/caddy/Caddyfile ]; then
    sudo tee /etc/caddy/Caddyfile >/dev/null <<'EOF'
:80 {
    root * /var/www/html
    file_server browse
}
EOF
  fi

  # systemd unit (mirrors the official package’s unit)
  sudo tee /etc/systemd/system/caddy.service >/dev/null <<'EOF'
[Unit]
Description=Caddy web server
After=network-online.target
Wants=network-online.target

[Service]
User=caddy
Group=caddy
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
Restart=on-failure
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now caddy
}



set_hostname() {
  if [ "$(hostname)" == "raspberrypi" ];then
    hostnamectl set-hostname birdnetpi
    sed -i 's/raspberrypi/birdnetpi/g' /etc/hosts
  fi
}

update_etc_hosts() {
  sed -ie s/'$(hostname).local'/"$(hostname).local ${BIRDNETPI_URL//https:\/\/} ${WEBTERMINAL_URL//https:\/\/} ${BIRDNETLOG_URL//https:\/\/}"/g /etc/hosts
}

install_scripts() {
  chmod +x ${my_dir}/scripts/*.sh
  ln -sf ${my_dir}/scripts/* /usr/local/bin/
}

install_birdnet_analysis() {
  cat << EOF > $HOME/BirdNET-Pi/templates/birdnet_analysis.service
[Unit]
Description=BirdNET Analysis
After=multi-user.target birdnet_server.service batnet_server.service
Requires=birdnet_server.service batnet_server.service
[Service]
RuntimeMaxSec=900
Restart=always
Type=simple
RestartSec=2
User=${USER}
ExecStart=/usr/local/bin/birdnet_analysis.sh
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/birdnet_analysis.service /usr/lib/systemd/system
  systemctl enable birdnet_analysis.service
}

install_batnet_server() {
  cat << EOF > $HOME/BirdNET-Pi/templates/batnet_server.service
[Unit]
Description=BatNET Server
After=multi-user.target
Before=birdnet_server.service
[Service]
Restart=always
Type=simple
RestartSec=5
User=${USER}
ExecStart=/usr/local/bin/batnet_analysis.sh
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/batnet_server.service /usr/lib/systemd/system
  systemctl enable batnet_server.service
}

install_birdnet_server() {
  cat << EOF > $HOME/BirdNET-Pi/templates/birdnet_server.service
[Unit]
Description=BirdNET Analysis Server
After=multi-user.target batnet_server.service
Before=birdnet_analysis.service
[Service]
Restart=always
Type=simple
RestartSec=10
User=${USER}
ExecStart=$PYTHON_VIRTUAL_ENV /usr/local/bin/server.py
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/birdnet_server.service /usr/lib/systemd/system
  systemctl enable birdnet_server.service
}

install_batnet_timer_server() {
  cat << EOF > $HOME/BirdNET-Pi/templates/batnet_timer_server.service
[Unit]
Description=BatNET Dusk/Dawn Starter Server
After=multi-user.target
[Service]
Restart=always
Type=simple
RestartSec=5
User=${USER}
ExecStart=/usr/local/bin/batnet_timer.sh
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/batnet_timer_server.service /usr/lib/systemd/system
  systemctl enable batnet_timer_server.service
}


install_extraction_service() {
  cat << EOF > $HOME/BirdNET-Pi/templates/extraction.service
[Unit]
Description=BirdNET BirdSound Extraction
After=multi-user.target
[Service]
Restart=on-failure
RestartSec=3
Type=simple
User=${USER}
ExecStart=/usr/bin/env bash -c 'while true;do extract_new_birdsounds.sh;sleep 3;done'
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/extraction.service /usr/lib/systemd/system
  systemctl enable extraction.service
}

create_necessary_dirs() {
  echo "Creating necessary directories"
  mkdir -p ${EXTRACTED}
  mkdir -p ${EXTRACTED}/By_Date
  mkdir -p ${EXTRACTED}/Charts
  mkdir -p ${PROCESSED}
  # Ensure the user owns these directories (running as root)
  chown -R "$USER:$USER" "$HOME/BirdSongs"

  sudo -u ${USER} ln -fs $my_dir/exclude_species_list.txt $my_dir/scripts
  sudo -u ${USER} ln -fs $my_dir/include_species_list.txt $my_dir/scripts
  sudo -u ${USER} ln -fs $my_dir/homepage/* ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/model/labels.txt ${my_dir}/scripts
  sudo -u ${USER} ln -fs $my_dir/scripts ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/scripts/play.php ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/scripts/spectrogram.php ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/scripts/overview.php ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/scripts/stats.php ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/scripts/todays_detections.php ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/scripts/history.php ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/scripts/weekly_report.php ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/homepage/images/favicon.ico ${EXTRACTED}
  sudo -u ${USER} ln -fs ${HOME}/phpsysinfo ${EXTRACTED}
  sudo -u ${USER} ln -fs $my_dir/templates/phpsysinfo.ini ${HOME}/phpsysinfo/
  sudo -u ${USER} ln -fs $my_dir/templates/green_bootstrap.css ${HOME}/phpsysinfo/templates/
  sudo -u ${USER} ln -fs $my_dir/templates/index_bootstrap.html ${HOME}/phpsysinfo/templates/html
  chmod -R g+rw $my_dir
  chmod -R g+rw ${RECS_DIR}
}

generate_BirdDB() {
  echo "Generating BirdDB.txt"
  if ! [ -f $my_dir/BirdDB.txt ];then
    sudo -u ${USER} touch $my_dir/BirdDB.txt
    echo "Date;Time;Sci_Name;Com_Name;Confidence;Lat;Lon;Cutoff;Week;Sens;Overlap" | sudo -u ${USER} tee -a $my_dir/BirdDB.txt
  elif ! grep Date $my_dir/BirdDB.txt;then
    sudo -u ${USER} sed -i '1 i\Date;Time;Sci_Name;Com_Name;Confidence;Lat;Lon;Cutoff;Week;Sens;Overlap' $my_dir/BirdDB.txt
  fi
  chown $USER:$USER ${my_dir}/BirdDB.txt && chmod g+rw ${my_dir}/BirdDB.txt
}

set_login() {
  if ! [ -d /etc/lightdm ];then
    systemctl set-default multi-user.target
    ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
    if ! [ -d /etc/systemd/system/getty@tty1.service.d ];then
      mkdir /etc/systemd/system/getty@tty1.service.d
    fi
    cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF
  fi
}

install_recording_service() {
  echo "Installing birdnet_recording.service"
  cat << EOF > $HOME/BirdNET-Pi/templates/birdnet_recording.service
[Unit]
Description=BirdNET Recording
After=multi-user.target
[Service]
Environment=XDG_RUNTIME_DIR=/run/user/1000
Restart=always
Type=simple
RestartSec=3
User=${USER}
ExecStart=/usr/local/bin/birdnet_recording.sh
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/birdnet_recording.service /usr/lib/systemd/system
  systemctl enable birdnet_recording.service
}

install_custom_recording_service() {
  echo "Installing custom_recording.service"
  cat << EOF > $HOME/BirdNET-Pi/templates/custom_recording.service
[Unit]
Description=BirdNET Custom Recording
[Service]
Environment=XDG_RUNTIME_DIR=/run/user/1000
Restart=always
Type=simple
RestartSec=3
User=${USER}
ExecStart=/usr/local/bin/custom_recording.sh
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/custom_recording.service /usr/lib/systemd/system
}

install_Caddyfile() {
  [ -d /etc/caddy ] || mkdir /etc/caddy
  if [ -f /etc/caddy/Caddyfile ];then
    cp /etc/caddy/Caddyfile{,.original}
  fi

  # Use :80 if BIRDNETPI_URL is not set
  CADDY_HOST="${BIRDNETPI_URL:-:80}"

  if ! [ -z ${CADDY_PWD} ];then
  HASHWORD=$(caddy hash-password --plaintext ${CADDY_PWD})
  cat << EOF > /etc/caddy/Caddyfile
${CADDY_HOST} {
  root * ${EXTRACTED}
  file_server browse
  handle /By_Date/* {
    file_server browse
  }
  handle /Charts/* {
    file_server browse
  }
  basicauth /views.php?view=File* {
    birdnet ${HASHWORD}
  }
  basicauth /Processed* {
    birdnet ${HASHWORD}
  }
  basicauth /scripts* {
    birdnet ${HASHWORD}
  }
  basicauth /stream {
    birdnet ${HASHWORD}
  }
  basicauth /phpsysinfo* {
    birdnet ${HASHWORD}
  }
  basicauth /terminal* {
    birdnet ${HASHWORD}
  }
  reverse_proxy /stream localhost:8000
  php_fastcgi unix//run/php/php-fpm.sock
  reverse_proxy /log* localhost:8080
  reverse_proxy /stats* localhost:8501
  reverse_proxy /terminal* localhost:8888
}
EOF
  else
    cat << EOF > /etc/caddy/Caddyfile
${CADDY_HOST} {
  root * ${EXTRACTED}
  file_server browse
  handle /By_Date/* {
    file_server browse
  }
  handle /Charts/* {
    file_server browse
  }
  reverse_proxy /stream localhost:8000
  php_fastcgi unix//run/php/php-fpm.sock
  reverse_proxy /log* localhost:8080
  reverse_proxy /stats* localhost:8501
  reverse_proxy /terminal* localhost:8888
}
EOF
  fi

  systemctl enable caddy
  usermod -aG $USER caddy
  usermod -aG video caddy
  chmod g+x $HOME
# Ensure the BirdSongs directory exists before adjusting permissions
  mkdir -p "$HOME/BirdSongs"
  chown -R "$USER:$USER" "$HOME/BirdSongs"
  chmod -R o+rX "$HOME/BirdNET-Pi" "$HOME/BirdSongs"

  # Allow www-data to restart services via the web UI
  echo 'www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl' | sudo tee /etc/sudoers.d/www-data-systemctl >/dev/null
  sudo chmod 440 /etc/sudoers.d/www-data-systemctl
}

install_avahi_aliases() {
  cat << 'EOF' > $HOME/BirdNET-Pi/templates/avahi-alias@.service
[Unit]
Description=Publish %I as alias for %H.local via mdns
After=network.target network-online.target
Requires=network-online.target
[Service]
Restart=always
RestartSec=3
Type=simple
ExecStart=/bin/bash -c "/usr/bin/avahi-publish -a -R %I $(hostname -I |cut -d' ' -f1)"
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/avahi-alias@.service /usr/lib/systemd/system
  systemctl enable avahi-alias@"$(hostname)".local.service
}

install_birdnet_stats_service() {
  cat << EOF > $HOME/BirdNET-Pi/templates/birdnet_stats.service
[Unit]
Description=BirdNET Stats
After=multi-user.target
[Service]
Restart=on-failure
RestartSec=5
Type=simple
User=${USER}
ExecStart=$HOME/BirdNET-Pi/birdnet/bin/streamlit run $HOME/BirdNET-Pi/scripts/plotly_streamlit.py --browser.gatherUsageStats false --server.address localhost --server.baseUrlPath "/stats"

[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/birdnet_stats.service /usr/lib/systemd/system
  systemctl enable birdnet_stats.service
}

install_spectrogram_service() {
  cat << EOF > $HOME/BirdNET-Pi/templates/spectrogram_viewer.service
[Unit]
Description=BirdNET Spectrogram Viewer
After=multi-user.target
[Service]
Restart=always
RestartSec=1
Type=simple
User=${USER}
ExecStart=/usr/local/bin/spectrogram.sh
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/spectrogram_viewer.service /usr/lib/systemd/system
  systemctl enable spectrogram_viewer.service
}

install_chart_viewer_service() {
  echo "Installing the chart_viewer.service"
  cat << EOF > $HOME/BirdNET-Pi/templates/chart_viewer.service
[Unit]
Description=BirdNET-Pi Chart Viewer Service
[Service]
Restart=always
RestartSec=120
Type=simple
User=$USER
ExecStart=$PYTHON_VIRTUAL_ENV /usr/local/bin/daily_plot.py
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/chart_viewer.service /usr/lib/systemd/system
  systemctl enable chart_viewer.service
}

install_gotty_logs() {
  sudo -u ${USER} ln -sf $my_dir/templates/gotty \
    ${HOME}/.gotty
  sudo -u ${USER} ln -sf $my_dir/templates/bashrc \
    ${HOME}/.bashrc
  cat << EOF > $HOME/BirdNET-Pi/templates/birdnet_log.service
[Unit]
Description=BirdNET Analysis Log
After=multi-user.target
[Service]
Restart=on-failure
RestartSec=3
Type=simple
User=${USER}
Environment=TERM=xterm-256color
ExecStart=/usr/local/bin/gotty --address localhost -p 8080 -P log --title-format "BirdNET-Pi Log" birdnet_log.sh
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/birdnet_log.service /usr/lib/systemd/system
  systemctl enable birdnet_log.service
  cat << EOF > $HOME/BirdNET-Pi/templates/web_terminal.service
[Unit]
Description=BirdNET-Pi Web Terminal
After=multi-user.target
[Service]
Restart=on-failure
RestartSec=3
Type=simple
Environment=TERM=xterm-256color
ExecStart=/usr/local/bin/gotty --address localhost -w -p 8888 -P terminal --title-format "BirdNET-Pi Terminal" login
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/web_terminal.service /usr/lib/systemd/system
  systemctl enable web_terminal.service
}

configure_caddy_php() {
  echo "Configuring PHP for Caddy"
  sed -i 's/www-data/caddy/g' /etc/php/*/fpm/pool.d/www.conf
  systemctl restart php\*-fpm.service
  echo "Adding Caddy sudoers rule"
  cat << EOF > /etc/sudoers.d/010_caddy-nopasswd
caddy ALL=(ALL) NOPASSWD: ALL
EOF
  chmod 0440 /etc/sudoers.d/010_caddy-nopasswd
}

install_phpsysinfo() {
  sudo -u ${USER} git clone https://github.com/phpsysinfo/phpsysinfo.git \
    ${HOME}/phpsysinfo
}

config_icecast() {
  if [ -f /etc/icecast2/icecast.xml ];then
    cp /etc/icecast2/icecast.xml{,.prebirdnetpi}
  fi
  sed -i 's/>admin</>birdnet</g' /etc/icecast2/icecast.xml
  passwords=("source-" "relay-" "admin-" "master-" "")
  for i in "${passwords[@]}";do
  sed -i "s/<${i}password>.*<\/${i}password>/<${i}password>${ICE_PWD}<\/${i}password>/g" /etc/icecast2/icecast.xml
  done
  sed -i 's|<!-- <bind-address>.*|<bind-address>127.0.0.1</bind-address>|;s|<!-- <shoutcast-mount>.*|<shoutcast-mount>/stream</shoutcast-mount>|'  /etc/icecast2/icecast.xml

  systemctl enable icecast2.service
}

install_livestream_service() {
  cat << EOF > $HOME/BirdNET-Pi/templates/livestream.service
[Unit]
Description=BirdNET-Pi Live Stream
After=multi-user.target icecast2.service
Requires=icecast2.service
[Service]
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=XDG_RUNTIME_DIR=/run/user/1000
Restart=always
RestartSec=5
Type=simple
User=${USER}
ExecStart=/usr/local/bin/livestream.sh
[Install]
WantedBy=multi-user.target
EOF
  ln -sf $HOME/BirdNET-Pi/templates/livestream.service /usr/lib/systemd/system
  systemctl enable livestream.service
}

install_s3_backup_services() {
  echo "Installing S3 Backup services..."
  # Source config to get default values for timer placeholders
  source /etc/birdnet/birdnet.conf

  # Create systemd service files from templates
  cp $HOME/BirdNET-Pi/templates/backup_detections.service /etc/systemd/system/backup_detections.service
  cp $HOME/BirdNET-Pi/templates/backup_watchdog.service /etc/systemd/system/backup_watchdog.service

  # Create timer files from templates, replacing placeholders with config values
  sed "s/\${S3_BACKUP_TIME}/$S3_BACKUP_TIME/g" $HOME/BirdNET-Pi/templates/backup_detections_daily.timer > /etc/systemd/system/backup_detections_daily.timer
  sed "s/\${S3_BACKUP_WATCHDOG_INTERVAL}/$S3_BACKUP_WATCHDOG_INTERVAL/g" $HOME/BirdNET-Pi/templates/backup_watchdog.timer > /etc/systemd/system/backup_watchdog.timer

  # Reload systemd and enable timers
  systemctl daemon-reload
  systemctl enable backup_detections_daily.timer 2>/dev/null || true
  systemctl enable backup_watchdog.timer 2>/dev/null || true

  # Install sudoers helper for timer updates
  rm -f /usr/local/bin/update_backup_timer.sh
  cp $HOME/BirdNET-Pi/scripts/update_backup_timer.sh /usr/local/bin/update_backup_timer.sh
  chmod +x /usr/local/bin/update_backup_timer.sh

  # Add sudoers rule for www-data to run the helper (if not already present)
  if [ ! -f /etc/sudoers.d/www-data-update-backup-timer ]; then
    echo 'www-data ALL=(ALL) NOPASSWD: /usr/local/bin/update_backup_timer.sh' | sudo tee /etc/sudoers.d/www-data-update-backup-timer >/dev/null
    sudo chmod 440 /etc/sudoers.d/www-data-update-backup-timer
  fi

  echo "S3 Backup services installed."
}

install_cleanup_cron() {
  sed "s/\$USER/$USER/g" $my_dir/templates/cleanup.cron >> /etc/crontab
}

install_weekly_cron() {
  sed "s/\$USER/$USER/g" $my_dir/templates/weekly_report.cron >> /etc/crontab
}

chown_things() {
  chown -R $USER:$USER $HOME/Bird*
  chown -R $USER:$USER $HOME/Bat*
}

increase_caddy_timeout() {
  # Ensure the directory for Caddy overrides exists (no error if already present)
mkdir -p /etc/systemd/system/caddy.service.d
  cat << EOF > /etc/systemd/system/caddy.service.d/override.conf
[Service]
TimeoutSec=300s
EOF
  systemctl daemon-reload
}

install_services() {
  set_hostname
  update_etc_hosts
  set_login

  install_depends
  install_caddy_manually
  install_scripts
  install_Caddyfile
  install_avahi_aliases
  install_batnet_server
  install_birdnet_analysis
  install_birdnet_server
  install_birdnet_stats_service
  install_recording_service
  install_custom_recording_service # But does not enable
  install_extraction_service
  install_spectrogram_service
  install_chart_viewer_service
  install_gotty_logs
  install_phpsysinfo
  install_livestream_service
  install_s3_backup_services
  install_cleanup_cron
  install_weekly_cron
  increase_caddy_timeout
  install_batnet_timer_server

  create_necessary_dirs
  generate_BirdDB
  configure_caddy_php
  config_icecast
  USER=$USER HOME=$HOME ${my_dir}/scripts/createdb.sh
}

if [ -f ${config_file} ];then
  source ${config_file}
  install_services
  chown_things
else
  echo "Unable to find a configuration file. Please make sure that $config_file exists."
fi
