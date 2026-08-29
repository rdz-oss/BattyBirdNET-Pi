#!/bin/bash
# Simple, robust installation script
set -e

MY_DIR="$HOME/BattyBirdNET-Pi"
cd "$MY_DIR"

echo "=== Simple BattyBirdNET-Pi Installation ==="

# 1. Create venv
echo "[1/8] Creating Python environment..."
[ -d birdnet ] || python3 -m venv birdnet
source birdnet/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q

# 2. Create config
echo "[2/8] Setting up configuration..."
sudo mkdir -p /etc/birdnet
[ -f /etc/birdnet/birdnet.conf ] || sudo cp birdnet.conf-defaults /etc/birdnet/birdnet.conf
sudo sed -i 's/LATITUDE=0.0000/LATITUDE=50.1109/' /etc/birdnet/birdnet.conf
sudo sed -i 's/LONGITUDE=0.0000/LONGITUDE=8.6821/' /etc/birdnet/birdnet.conf

# 3. Create directories
echo "[3/8] Creating directories..."
mkdir -p ~/BirdSongs/Processed ~/BirdSongs/Extracted
sudo mkdir -p /var/log/birdnet-pi

# 4. Create database
echo "[4/8] Creating database..."
cd scripts
source ~/birdnet/bin/activate
sqlite3 birds.db << 'EOF'
CREATE TABLE IF NOT EXISTS detections (
  id INTEGER PRIMARY KEY,
  Date DATE,
  Time TIME,
  Sci_Name VARCHAR(100),
  Com_Name VARCHAR(100),
  Confidence FLOAT,
  Lat FLOAT,
  Lon FLOAT,
  Cutoff FLOAT,
  Week INT,
  Sens FLOAT,
  Overlap FLOAT,
  File_Name VARCHAR(100));
EOF
chmod 644 birds.db

# 5. Create species lists
echo "[5/8] Creating species lists..."
cd ..
touch include_species_list.txt exclude_species_list.txt

# 6. Install services manually
echo "[6/8] Installing services..."
mkdir -p templates
cd templates

# birdnet_server.service
cat > birdnet_server.service << 'EOF'
[Unit]
Description=BattyBirdNET Server
After=network.target

[Service]
Type=simple
User=bat
WorkingDirectory=/home/bat/BattyBirdNET-Pi
ExecStart=/home/bat/BattyBirdNET-Pi/birdnet/bin/python3 /home/bat/BattyBirdNET-Pi/scripts/server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# birdnet_analysis.service
cat > birdnet_analysis.service << 'EOF'
[Unit]
Description=BattyBirdNET Analysis
After=birdnet_server.service

[Service]
Type=simple
User=bat
WorkingDirectory=/home/bat/BattyBirdNET-Pi
ExecStart=/usr/bin/bash /home/bat/BattyBirdNET-Pi/scripts/birdnet_analysis.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# birdnet_recording.service
cat > birdnet_recording.service << 'EOF'
[Unit]
Description=BirdNET Recording
After=network.target

[Service]
Environment=XDG_RUNTIME_DIR=/run/user/1000
Type=simple
User=bat
ExecStart=/usr/bin/bash /home/bat/BattyBirdNET-Pi/scripts/birdnet_recording.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Install services
cd ..
sudo cp templates/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable birdnet_server birdnet_analysis birdnet_recording

# 7. Configure Caddy
echo "[7/8] Configuring Caddy..."
sudo tee /etc/caddy/Caddyfile > /dev/null << 'CEOF'
:80 {
    root * /home/bat/BattyBirdNET-Pi/homepage
    php_fastcgi unix//run/php/php8.4-fpm.sock
    file_server
    try_files {path} {path}/ /index.php
}
CEOF
sudo systemctl restart caddy

# 8. Start services
echo "[8/8] Starting services..."
sudo systemctl start birdnet_server birdnet_analysis birdnet_recording

echo ""
echo "=== Installation Complete! ==="
echo "Web interface: http://$(hostname).local/"
echo "Configure location: Tools → Settings → Location"
