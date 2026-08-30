#!/usr/bin/env bash
# Update BirdNET-Pi
source /etc/birdnet/birdnet.conf
trap 'exit 1' SIGINT SIGHUP
USER=$(awk -F: '/1000/ {print $1}' /etc/passwd)
HOME=$(awk -F: '/1000/ {print $6}' /etc/passwd)
my_dir=$HOME/BirdNET-Pi/scripts

# Sets proper permissions and ownership
sudo -E chown -R $USER:$USER $HOME/*
chmod -R g+wr $HOME
find $HOME/Bird* -type f ! -perm -g+wr -exec chmod g+wr {} + 2>/dev/null
find $HOME/Bird* -not -user $USER -execdir sudo -E chown $USER:$USER {} \+
chmod 666 ~/BirdNET-Pi/scripts/*.txt
chmod 666 ~/BirdNET-Pi/*.txt
find $HOME/BirdNET-Pi -path "$HOME/BirdNET-Pi/birdnet" -prune -o -type f ! -perm /o=w -exec chmod a+w {} \;

# remove world-writable perms
chmod -R o-w ~/BirdNET-Pi/templates/*

chmod +x ~/BirdNET-Pi/scripts/guano_edit.py
chmod +x ~/BirdNET-Pi/scripts/batnet_timer.sh
chmod +x ~/BirdNET-Pi/scripts/sun_info.py
chmod +x ~/BirdNET-Pi/scripts/switch_classifier.sh
$HOME/BirdNET-Pi/birdnet/bin/pip3 install python-dateutil datetime

install_batnet_timer_server() {
  cat << EOF > $HOME/BirdNET-Pi/templates/batnet_timer_server.service
[Unit]
Description=BatNET Dusk/Dawn Starter Server
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
  sudo systemctl enable batnet_timer_server.service
}

if grep -q 'php7.4-' /etc/caddy/Caddyfile &>/dev/null; then
  sed -i 's/php7.4-/php-/' /etc/caddy/Caddyfile
fi

if ! grep SWITCH_TO_BIRD /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "SWITCH_TO_BIRD=false" >> /etc/birdnet/birdnet.conf
  sudo -u $USER echo "BIRD_CLASSIFIER=\"BIRDS\"" >> /etc/birdnet/birdnet.conf
fi


if ! grep LAST_CLASSIFIER /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "LAST_CLASSIFIER=\"$BAT_CLASSIFIER\"" >> /etc/birdnet/birdnet.conf
fi

if ! grep BAT_TIMER /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "BAT_TIMER=false" >> /etc/birdnet/birdnet.conf
  sudo -u $USER echo "BAT_DUSK=\"18:00\"" >> /etc/birdnet/birdnet.conf
  sudo -u $USER echo "BAT_DAWN=\"06:00\"" >> /etc/birdnet/birdnet.conf
  install_batnet_timer_server
  sudo systemctl start batnet_timer_server.service
fi

if ! grep NOISERED /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "NOISERED=false" >> /etc/birdnet/birdnet.conf
  sudo -u $USER echo "NOISE_PROF=\"BattyBirdNET-Analyzer/checkpoints/bats/mic-noise/audiomoth_v12.prof\"" >> /etc/birdnet/birdnet.conf
  sudo -u $USER echo "NOISE_PROF_FACTOR=\"0.22\"" >> /etc/birdnet/birdnet.conf
fi

if ! grep INPUT_NOISERED /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "INPUT_NOISERED=false" >> /etc/birdnet/birdnet.conf
fi

if ! grep BAT_SUNTIMER /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "BAT_SUNTIMER=false" >> /etc/birdnet/birdnet.conf
  chmod +x ~/BirdNET-Pi/scripts/sun_info.py
fi

if ! grep BAT_HIGHPASS_FREQ /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "BAT_HIGHPASS_FREQ=10000" >> /etc/birdnet/birdnet.conf
fi

if ! grep INPUT_SPECTROGRAM_COLOR /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "INPUT_SPECTROGRAM_COLOR=\"\"" >> /etc/birdnet/birdnet.conf
fi

# Create blank sitename as it's optional. First time install will use $HOSTNAME.
if ! grep SITE_NAME /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "SITE_NAME=\"\"" >> /etc/birdnet/birdnet.conf
fi

if ! grep PRIVACY_THRESHOLD /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "PRIVACY_THRESHOLD=0" >> /etc/birdnet/birdnet.conf
  git -C $HOME/BirdNET-Pi rm $my_dir/privacy_server.py
fi
if [ -f $my_dir/privacy_server ] || [ -L /usr/local/bin/privacy_server.py ];then
  rm -f $my_dir/privacy_server.py
  rm -f /usr/local/bin/privacy_server.py
fi

# Adds python virtual-env to the python systemd services
if ! grep 'BirdNET-Pi/birdnet/' $HOME/BirdNET-Pi/templates/birdnet_server.service &>/dev/null || ! grep 'BirdNET-Pi/birdnet' $HOME/BirdNET-Pi/templates/chart_viewer.service &>/dev/null;then
  sudo -E sed -i "s|ExecStart=.*|ExecStart=$HOME/BirdNET-Pi/birdnet/bin/python3 /usr/local/bin/server.py|" ~/BirdNET-Pi/templates/birdnet_server.service
  sudo -E sed -i "s|ExecStart=.*|ExecStart=$HOME/BirdNET-Pi/birdnet/bin/python3 /usr/local/bin/daily_plot.py|" ~/BirdNET-Pi/templates/chart_viewer.service
  sudo systemctl daemon-reload && restart_services.sh
fi

if grep privacy ~/BirdNET-Pi/templates/birdnet_server.service &>/dev/null;then
  sudo -E sed -i 's/privacy_server.py/server.py/g' \
    ~/BirdNET-Pi/templates/birdnet_server.service
  sudo systemctl daemon-reload
  restart_services.sh
fi
if ! grep APPRISE_NOTIFICATION_TITLE /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "APPRISE_NOTIFICATION_TITLE=\"New BirdNET-Pi Detection\"" >> /etc/birdnet/birdnet.conf
fi
if ! grep APPRISE_NOTIFICATION_BODY /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "APPRISE_NOTIFICATION_BODY=\"A \$sciname \$comname was just detected with a confidence of \$confidence\"" >> /etc/birdnet/birdnet.conf
fi
if ! grep APPRISE_NOTIFY_EACH_DETECTION /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "APPRISE_NOTIFY_EACH_DETECTION=0 " >> /etc/birdnet/birdnet.conf
fi
if ! grep APPRISE_NOTIFY_NEW_SPECIES /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "APPRISE_NOTIFY_NEW_SPECIES=0 " >> /etc/birdnet/birdnet.conf
fi
if ! grep APPRISE_NOTIFY_NEW_SPECIES_EACH_DAY /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "APPRISE_NOTIFY_NEW_SPECIES_EACH_DAY=0 " >> /etc/birdnet/birdnet.conf
fi
if ! grep APPRISE_MINIMUM_SECONDS_BETWEEN_NOTIFICATIONS_PER_SPECIES /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "APPRISE_MINIMUM_SECONDS_BETWEEN_NOTIFICATIONS_PER_SPECIES=0 " >> /etc/birdnet/birdnet.conf
fi

# If the config does not contain the DATABASE_LANG setting, default to English.
if ! grep DATABASE_LANG /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "DATABASE_LANG=en" >> /etc/birdnet/birdnet.conf
fi

# Fix existing installs stuck with DATABASE_LANG=not-selected
if grep -q "DATABASE_LANG=not-selected" /etc/birdnet/birdnet.conf; then
  sudo sed -i 's/DATABASE_LANG=not-selected/DATABASE_LANG=en/' /etc/birdnet/birdnet.conf
fi

apprise_installation_status=$(~/BirdNET-Pi/birdnet/bin/python3 -c 'import pkgutil; print("installed" if pkgutil.find_loader("apprise") else "not installed")')
if [[ "$apprise_installation_status" = "not installed" ]];then
  $HOME/BirdNET-Pi/birdnet/bin/pip3 install -U pip
  $HOME/BirdNET-Pi/birdnet/bin/pip3 install apprise==1.6.0
fi
[ -f $HOME/BirdNET-Pi/apprise.txt ] || sudo -E -ucaddy touch $HOME/BirdNET-Pi/apprise.txt
if ! which lsof &>/dev/null;then
  sudo apt update && sudo apt -y install lsof
fi
if ! dpkg -l librubberband2 &>/dev/null;then
  sudo apt update && sudo apt -y install librubberband2
fi
if ! grep RTSP_STREAM /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "RTSP_STREAM=" >> /etc/birdnet/birdnet.conf
fi
if grep bash $HOME/BirdNET-Pi/templates/web_terminal.service &>/dev/null;then
  sudo sed -i '/User/d;s/bash/login/g' $HOME/BirdNET-Pi/templates/web_terminal.service
  sudo systemctl daemon-reload
  sudo systemctl restart web_terminal.service
fi
[ -L ~/BirdSongs/Extracted/static ] || ln -sf ~/BirdNET-Pi/homepage/static ~/BirdSongs/Extracted
if ! grep FLICKR_API_KEY /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "FLICKR_API_KEY=" >> /etc/birdnet/birdnet.conf
fi
if systemctl list-unit-files pushed_notifications.service &>/dev/null;then
  sudo systemctl disable --now pushed_notifications.service
  sudo rm -f /usr/lib/systemd/system/pushed_notifications.service
  sudo rm $HOME/BirdNET-Pi/templates/pushed_notifications.service
fi

if [ ! -f $HOME/BirdNET-Pi/model/labels.txt ];then
  [ $DATABASE_LANG == 'not-selected' ] && DATABASE_LANG=en
  $my_dir/install_language_label.sh -l $DATABASE_LANG \
  && logger "[$0] Installed new language label file for '$DATABASE_LANG'";
fi

if ! grep FLICKR_FILTER_EMAIL /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "FLICKR_FILTER_EMAIL=" >> /etc/birdnet/birdnet.conf
fi

pytest_installation_status=$(~/BirdNET-Pi/birdnet/bin/python3 -c 'import pkgutil; print("installed" if pkgutil.find_loader("pytest") else "not installed")')
if [[ "$pytest_installation_status" = "not installed" ]];then
  $HOME/BirdNET-Pi/birdnet/bin/pip3 install -U pip
  $HOME/BirdNET-Pi/birdnet/bin/pip3 install pytest==7.1.2 pytest-mock==3.7.0
fi

[ -L ~/BirdSongs/Extracted/weekly_report.php ] || ln -sf ~/BirdNET-Pi/scripts/weekly_report.php ~/BirdSongs/Extracted

if ! grep weekly_report /etc/crontab &>/dev/null;then
  sed "s/\$USER/$USER/g" $HOME/BirdNET-Pi/templates/weekly_report.cron | sudo tee -a /etc/crontab
fi
if ! grep APPRISE_WEEKLY_REPORT /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "APPRISE_WEEKLY_REPORT=1" >> /etc/birdnet/birdnet.conf
fi

if ! grep SILENCE_UPDATE_INDICATOR /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "SILENCE_UPDATE_INDICATOR=0" >> /etc/birdnet/birdnet.conf
fi

if ! grep '\-\-browser.gatherUsageStats false' $HOME/BirdNET-Pi/templates/birdnet_stats.service &>/dev/null ;then
  sudo -E sed -i "s|ExecStart=.*|ExecStart=$HOME/BirdNET-Pi/birdnet/bin/streamlit run $HOME/BirdNET-Pi/scripts/plotly_streamlit.py --browser.gatherUsageStats false --server.address localhost --server.baseUrlPath \"/stats\"|" $HOME/BirdNET-Pi/templates/birdnet_stats.service
  sudo systemctl daemon-reload && restart_services.sh
fi

# Make IceCast2 a little more secure
sudo sed -i.bak -e 's|<!-- <bind-address>.*|<bind-address>127.0.0.1</bind-address>|;s|<!-- <shoutcast-mount>.*|<shoutcast-mount>/stream</shoutcast-mount>|' /etc/icecast2/icecast.xml && if [ -s /etc/icecast2/icecast.xml.bak ] && ! sudo diff /etc/icecast2/icecast.xml /etc/icecast2/icecast.xml.bak > /dev/null; then sudo systemctl restart icecast2; fi

if ! grep FREQSHIFT_TOOL /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "FREQSHIFT_TOOL=sox" >> /etc/birdnet/birdnet.conf
fi

if ! grep SOX_SPEED /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "SOX_SPEED=0.1" >> /etc/birdnet/birdnet.conf
fi

if ! grep FREQSHIFT_HI /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "FREQSHIFT_HI=6000" >> /etc/birdnet/birdnet.conf
fi
if ! grep FREQSHIFT_LO /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "FREQSHIFT_LO=3000" >> /etc/birdnet/birdnet.conf
fi
if ! grep FREQSHIFT_PITCH /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "FREQSHIFT_PITCH=-1500" >> /etc/birdnet/birdnet.conf
fi
if ! grep ACTIVATE_FREQSHIFT_IN_LIVESTREAM /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "ACTIVATE_FREQSHIFT_IN_LIVESTREAM=false" >> /etc/birdnet/birdnet.conf
fi
if ! grep FREQSHIFT_RECONNECT_DELAY /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "FREQSHIFT_RECONNECT_DELAY=4000" >> /etc/birdnet/birdnet.conf
fi
if ! grep HEARTBEAT_URL /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "HEARTBEAT_URL=" >> /etc/birdnet/birdnet.conf
fi

if ! grep MODEL /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "MODEL=BirdNET_6K_GLOBAL_MODEL" >> /etc/birdnet/birdnet.conf
fi
if ! grep SF_THRESH /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "SF_THRESH=0.03" >> /etc/birdnet/birdnet.conf
fi
sudo chmod +x ~/BirdNET-Pi/scripts/install_language_label_nm.sh

sqlite3 $HOME/BirdNET-Pi/scripts/birds.db << EOF
CREATE INDEX IF NOT EXISTS "detections_Com_Name" ON "detections" ("Com_Name");
CREATE INDEX IF NOT EXISTS "detections_Date_Time" ON "detections" ("Date" DESC, "Time" DESC);
EOF

apprise_version=$($HOME/BirdNET-Pi/birdnet/bin/python3 -c "import apprise; print(apprise.__version__)" 2>/dev/null || echo "0")
streamlit_version=$($HOME/BirdNET-Pi/birdnet/bin/pip3 show streamlit 2>/dev/null | grep Version | awk '{print $2}' || echo "0")

# Python 3.13+ is incompatible with old streamlit (imghdr removed) and
# pip install of old apprise can downgrade protobuf, breaking TensorFlow.
python_major=$($HOME/BirdNET-Pi/birdnet/bin/python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
if (( $(echo "$python_major < 3.13" | bc -l) )); then
  [[ $apprise_version != "1.6.0" ]] && $HOME/BirdNET-Pi/birdnet/bin/pip3 install apprise==1.6.0
  [[ $streamlit_version != "1.31.0" ]] && $HOME/BirdNET-Pi/birdnet/bin/pip3 install streamlit==1.19.0
fi

if ! grep -q 'RuntimeMaxSec=' "$HOME/BirdNET-Pi/templates/birdnet_analysis.service"&>/dev/null; then
    sudo -E sed -i '/\[Service\]/a RuntimeMaxSec=900' "$HOME/BirdNET-Pi/templates/birdnet_analysis.service"
    sudo systemctl daemon-reload && restart_services.sh
fi

if ! grep RAW_SPECTROGRAM /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "RAW_SPECTROGRAM=0" >> /etc/birdnet/birdnet.conf
fi

if ! grep CUSTOM_IMAGE /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "CUSTOM_IMAGE=" >> /etc/birdnet/birdnet.conf
fi
if ! grep CUSTOM_IMAGE_TITLE /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "CUSTOM_IMAGE_TITLE=\"\"" >> /etc/birdnet/birdnet.conf
fi

if ! grep APPRISE_ONLY_NOTIFY_SPECIES_NAMES /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "APPRISE_ONLY_NOTIFY_SPECIES_NAMES=\"\"" >> /etc/birdnet/birdnet.conf
fi
if ! grep APPRISE_ONLY_NOTIFY_SPECIES_NAMES_2 /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "APPRISE_ONLY_NOTIFY_SPECIES_NAMES_2=\"\"" >> /etc/birdnet/birdnet.conf
fi

if ! grep RTSP_STREAM_TO_LIVESTREAM /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "RTSP_STREAM_TO_LIVESTREAM=\"0\"" >> /etc/birdnet/birdnet.conf
fi

suntime_installation_status=$(~/BirdNET-Pi/birdnet/bin/python3 -c 'import pkgutil; print("installed" if pkgutil.find_loader("suntime") else "not installed")')
if [[ "$suntime_installation_status" = "not installed" ]];then
  $HOME/BirdNET-Pi/birdnet/bin/pip3 install -U pip
  $HOME/BirdNET-Pi/birdnet/bin/pip3 install suntime
fi

# For new Advanced Setting Logging level options
if ! grep LogLevel_BirdnetRecordingService /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "LogLevel_BirdnetRecordingService=\"error\"" >> /etc/birdnet/birdnet.conf
fi

if ! grep LogLevel_LiveAudioStreamService /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "LogLevel_LiveAudioStreamService=\"error\"" >> /etc/birdnet/birdnet.conf
fi

if ! grep LogLevel_SpectrogramViewerService /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "LogLevel_SpectrogramViewerService=\"error\"" >> /etc/birdnet/birdnet.conf
fi

if grep -q '^MODEL=BirdNET_GLOBAL_3K_V2.3_Model_FP16$' /etc/birdnet/birdnet.conf;then
  language=$(grep "^DATABASE_LANG=" /etc/birdnet/birdnet.conf | cut -d= -f2)
  sed -i 's/BirdNET_GLOBAL_3K_V2.3_Model_FP16/BirdNET_GLOBAL_6K_V2.4_Model_FP16/' /etc/birdnet/birdnet.conf
  sed -i 's/BirdNET_GLOBAL_3K_V2.3_Model_FP16/BirdNET_GLOBAL_6K_V2.4_Model_FP16/' $HOME/BirdNET-Pi/scripts/thisrun.txt
  sed -i 's/BirdNET_GLOBAL_3K_V2.3_Model_FP16/BirdNET_GLOBAL_6K_V2.4_Model_FP16/' $HOME/BirdNET-Pi/birdnet.conf
  cp -f $HOME/BirdNET-Pi/model/labels.txt $HOME/BirdNET-Pi/model/labels.txt.old
  sudo chmod +x $HOME/BirdNET-Pi/scripts/install_language_label_nm.sh && $HOME/BirdNET-Pi/scripts/install_language_label_nm.sh -l "$language"
fi

# if labels_flickr.txt doesnt exist, create it
labels_file="$HOME/BirdNET-Pi/model/labels_flickr.txt"
if [ ! -f "$labels_file" ]; then
    if [ -f "$HOME/BirdNET-Pi/scripts/thisrun.txt" ]; then
        config_file="$HOME/BirdNET-Pi/scripts/thisrun.txt"
    elif [ -f "$HOME/BirdNET-Pi/scripts/thisrun.ini" ]; then
        config_file="$HOME/BirdNET-Pi/scripts/thisrun.ini"
    fi

    language=$(grep -oP "^DATABASE_LANG\s*=\s*\K.*" "$config_file")
    model=$(grep -oP "^MODEL\s*=\s*\K.*" "$config_file")

    if [ "$model" == "BirdNET_GLOBAL_6K_V2.4_Model_FP16" ]; then
        chmod +x "$HOME/BirdNET-Pi/scripts/install_language_label_nm.sh"
        "$HOME/BirdNET-Pi/scripts/install_language_label_nm.sh" -l "$language"
    else
        "$HOME/BirdNET-Pi/scripts/install_language_label.sh" -l "$language"
    fi
fi


sudo systemctl daemon-reload
restart_services.sh
sudo systemctl restart batnet_timer_server.service

# Add BIRD_SAMPLING_RATE and BAT_SAMPLING_RATE for mode switching
if ! grep BIRD_SAMPLING_RATE /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "BIRD_SAMPLING_RATE=48000" >> /etc/birdnet/birdnet.conf
fi

if ! grep BAT_SAMPLING_RATE /etc/birdnet/birdnet.conf &>/dev/null;then
  current_rate=$(grep -oP "^SAMPLING_RATE\s*=\s*\K.*" /etc/birdnet/birdnet.conf || echo "256000")
  sudo -u $USER echo "BAT_SAMPLING_RATE=$current_rate" >> /etc/birdnet/birdnet.conf
fi

# ===== S3 Backup Migration =====

# Add missing S3 backup config variables
if ! grep S3_BACKUP_ENABLED /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "S3_BACKUP_ENABLED=false" >> /etc/birdnet/birdnet.conf
fi
if ! grep RCLONE_REMOTE /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "RCLONE_REMOTE=" >> /etc/birdnet/birdnet.conf
fi
if ! grep RCLONE_BUCKET /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "RCLONE_BUCKET=" >> /etc/birdnet/birdnet.conf
fi
if ! grep RCLONE_PATH /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "RCLONE_PATH=\"db/\"" >> /etc/birdnet/birdnet.conf
fi
if ! grep S3_BACKUP_TIME /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "S3_BACKUP_TIME=\"02:00\"" >> /etc/birdnet/birdnet.conf
fi
if ! grep S3_BACKUP_WATCHDOG_INTERVAL /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "S3_BACKUP_WATCHDOG_INTERVAL=\"30min\"" >> /etc/birdnet/birdnet.conf
fi
if ! grep S3_BACKUP_PING_HOST /etc/birdnet/birdnet.conf &>/dev/null;then
  sudo -u $USER echo "S3_BACKUP_PING_HOST=\"8.8.8.8\"" >> /etc/birdnet/birdnet.conf
fi

# Install rclone if not present
if ! command -v rclone &> /dev/null; then
  echo "Installing rclone..."
  sudo apt update -qq && sudo apt install -y rclone
fi

# Regenerate S3 Backup systemd services and timers from templates
echo "Updating S3 Backup services..."

# Source config for placeholders
source /etc/birdnet/birdnet.conf

# Replace user placeholder and timer variables in all units
sed "s/%i/$USER/g" $HOME/BirdNET-Pi/templates/backup_detections.service | sudo tee /etc/systemd/system/backup_detections.service >/dev/null
sed "s/%i/$USER/g" $HOME/BirdNET-Pi/templates/backup_watchdog.service | sudo tee /etc/systemd/system/backup_watchdog.service >/dev/null

sed "s/\${S3_BACKUP_TIME}/${S3_BACKUP_TIME:-02:00}/g; s/\${S3_BACKUP_WATCHDOG_INTERVAL}/${S3_BACKUP_WATCHDOG_INTERVAL:-30min}/g" "$HOME/BirdNET-Pi/templates/backup_detections_daily.timer" | sudo tee /etc/systemd/system/backup_detections_daily.timer >/dev/null
sed "s/\${S3_BACKUP_TIME}/${S3_BACKUP_TIME:-02:00}/g; s/\${S3_BACKUP_WATCHDOG_INTERVAL}/${S3_BACKUP_WATCHDOG_INTERVAL:-30min}/g" "$HOME/BirdNET-Pi/templates/backup_watchdog.timer" | sudo tee /etc/systemd/system/backup_watchdog.timer >/dev/null

# Install sudoers helper
sudo cp $HOME/BirdNET-Pi/scripts/update_backup_timer.sh /usr/local/bin/update_backup_timer.sh
sudo chmod +x /usr/local/bin/update_backup_timer.sh

# Add sudoers rule if missing
if [ ! -f /etc/sudoers.d/www-data-update-backup-timer ]; then
  echo 'www-data ALL=(ALL) NOPASSWD: /usr/local/bin/update_backup_timer.sh' | sudo tee /etc/sudoers.d/www-data-update-backup-timer >/dev/null
  sudo chmod 440 /etc/sudoers.d/www-data-update-backup-timer
fi

sudo systemctl daemon-reload
sudo systemctl enable backup_detections_daily.timer 2>/dev/null || true
sudo systemctl enable backup_watchdog.timer 2>/dev/null || true

echo "S3 Backup services updated."

# Remove broken Cloudsmith Caddy repo if present
if [ -f /etc/apt/sources.list.d/caddy-stable.list ]; then
  sudo rm -f /etc/apt/sources.list.d/caddy-stable.list
  sudo apt-get update -qq
fi

# Install missing packages that may have been skipped due to apt failures
for pkg in ffmpeg icecast2 sox libsox-fmt-mp3 lsof bc; do
  if ! dpkg -l "$pkg" &>/dev/null | grep -q "^ii"; then
    sudo apt update -qq && sudo apt install -y "$pkg"
  fi
done
sudo systemctl enable --now icecast2 2>/dev/null

# Replace netstat with ss in scripts (netstat removed in Trixie)
for f in $my_dir/birdnet_analysis.sh $my_dir/birdnet_recording.sh $my_dir/restart_services.sh /usr/local/bin/birdnet_analysis.sh /usr/local/bin/birdnet_recording.sh /usr/local/bin/restart_services.sh; do
  if [ -f "$f" ] && grep -q 'netstat' "$f"; then
    sudo sed -i 's/netstat -tulpn/ss -tulpn/g' "$f"
  fi
done

# Add CAP_NET_BIND_SERVICE to Caddy systemd unit
if [ -f /etc/systemd/system/caddy.service ]; then
  if ! grep -q 'CAP_NET_BIND_SERVICE' /etc/systemd/system/caddy.service; then
    sudo sed -i '/^Group=caddy$/a AmbientCapabilities=CAP_NET_BIND_SERVICE' /etc/systemd/system/caddy.service
    sudo systemctl daemon-reload && sudo systemctl restart caddy
  fi
fi

# Fix php-fpm socket path in Caddyfile — detect actual PHP version
if [ -f /etc/caddy/Caddyfile ]; then
  # Find all installed php-fpm service names and pick the latest version
  fpm_svc=$(ls /lib/systemd/system/php*-fpm.service /etc/systemd/system/php*-fpm.service 2>/dev/null | grep -oP 'php\K[0-9]+\.[0-9]+-fpm' | sort -V | tail -1 || true)
  if [ -n "$fpm_svc" ]; then
    php_ver=$(echo "$fpm_svc" | grep -oP '[0-9]+\.[0-9]+')
    target_sock="php_fastcgi unix//run/php/php${php_ver}-fpm.sock"

    # Fix generic placeholder
    if grep -q 'php_fastcgi unix//run/php/php-fpm.sock' /etc/caddy/Caddyfile; then
      sudo sed -i "s|php_fastcgi unix//run/php/php-fpm.sock|${target_sock}|" /etc/caddy/Caddyfile
    fi

    # Fix hardcoded php8.4-fpm.sock (was the only replacement before)
    if grep -q 'php_fastcgi unix//run/php/php8.4-fpm.sock' /etc/caddy/Caddyfile; then
      sudo sed -i "s|php_fastcgi unix//run/php/php8.4-fpm.sock|${target_sock}|" /etc/caddy/Caddyfile
    fi

    # Only restart caddy if something actually changed
    if grep -q "${target_sock}" /etc/caddy/Caddyfile; then
      sudo systemctl restart caddy 2>/dev/null
    fi
  fi
fi

# Add www-data passwordless sudo for web UI service restarts
if [ ! -f /etc/sudoers.d/www-data-systemctl ]; then
  echo 'www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl' | sudo tee /etc/sudoers.d/www-data-systemctl >/dev/null
  sudo chmod 440 /etc/sudoers.d/www-data-systemctl
fi

# Add o+rX permissions so Caddy can follow symlinks
if [ -d $HOME/BirdNET-Pi ]; then
  chmod -R o+rX "$HOME/BirdNET-Pi"
fi
if [ -d $HOME/BirdSongs ]; then
  chmod -R o+rX "$HOME/BirdSongs"
fi

# Fix overview.php: add exit after "Database is busy"
for f in $my_dir/overview.php $my_dir/todays_detections.php $my_dir/history.php $my_dir/weekly_report.php $my_dir/play.php; do
  if [ -f "$f" ]; then
    sudo sed -i '/header("refresh: 0;");/{n;/exit/!a\  exit;
}' "$f"
  fi
done

# Add After=multi-user.target to systemd service units
for svc in birdnet_server batnet_server birdnet_analysis birdnet_recording birdnet_stats extraction spectrogram_viewer chart_viewer birdnet_log web_terminal batnet_timer_server; do
  tmpl="$HOME/BirdNET-Pi/templates/${svc}.service"
  if [ -f "$tmpl" ]; then
    if ! grep -q 'After=multi-user.target' "$tmpl"; then
      sed -i '/^\[Unit\]/a After=multi-user.target' "$tmpl"
    fi
  fi
done

# Add batnet_server dependency to birdnet_analysis
tmpl="$HOME/BirdNET-Pi/templates/birdnet_analysis.service"
if [ -f "$tmpl" ]; then
  if ! grep -q 'batnet_server' "$tmpl"; then
    sed -i 's/After=birdnet_server.service/After=birdnet_server.service batnet_server.service/' "$tmpl"
    sed -i 's/Requires=birdnet_server.service/Requires=birdnet_server.service batnet_server.service/' "$tmpl"
  fi
fi

# Fix livestream service: add PATH and wait for icecast2
tmpl="$HOME/BirdNET-Pi/templates/livestream.service"
if [ -f "$tmpl" ]; then
  if ! grep -q 'PATH=' "$tmpl"; then
    sed -i '/^\[Service\]/a Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' "$tmpl"
  fi
  if ! grep -q 'icecast2.service' "$tmpl"; then
    sed -i 's/After=network-online.target/After=multi-user.target icecast2.service/' "$tmpl"
    sed -i 's/Requires=network-online.target/Requires=icecast2.service/' "$tmpl"
  fi
fi

# Fix plotly_streamlit.py: use .loc for "All" species count
if [ -f $my_dir/plotly_streamlit.py ]; then
  if grep -q "hourly\[hourly.index == specie\]\['All'\]" $my_dir/plotly_streamlit.py; then
    sed -i "s/hourly\[hourly.index == specie\]\['All'\]/hourly.loc[specie, 'All']/" $my_dir/plotly_streamlit.py
  fi
fi

# Wait for batnet_server (port 7667) in birdnet_analysis.sh
if [ -f $my_dir/birdnet_analysis.sh ]; then
  if ! grep -q 'grep 7667' $my_dir/birdnet_analysis.sh; then
    sed -i '/grep 5050.*ss -tulpn/,/^done$/{/^done$/a\
\
# Wait for batnet_server (port 7667) to be ready\
until grep 7667 <(ss -tulpn 2>\&1) \&> \/dev\/null 2>\&1;do\
  sleep 1\
done
}' $my_dir/birdnet_analysis.sh
  fi
fi

# Add set -e to install_services.sh if not present
if [ -f $my_dir/install_services.sh ]; then
  if ! grep -q '^set -e' $my_dir/install_services.sh; then
    sed -i '/^set -x/i set -e # Exit immediately if any command fails' $my_dir/install_services.sh
  fi
fi

# Restart services to apply all changes
sudo systemctl daemon-reload
restart_services.sh
