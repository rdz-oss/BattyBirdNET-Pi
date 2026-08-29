#!/bin/bash
# Remote installation script for BattyBirdNET-Pi
# Fixes paths and runs with proper permissions

set -e

echo "=== BattyBirdNET-Pi Installation Script ==="
MY_DIR="$HOME/BattyBirdNET-Pi"

# FIX ALL PATHS FIRST
echo "[0/7] Fixing hardcoded paths..."
cd "$MY_DIR/scripts" || exit 1
for f in *.sh; do
    sed -i "s|BirdNET-Pi|BattyBirdNET-Pi|g" "$f"
    sed -i "s|/root/BirdSongs|/home/bat/BirdSongs|g" "$f"
done
sed -i "s|\$HOME/BirdNET-Pi|\$HOME/BattyBirdNET-Pi|g" install_services.sh
cd "$MY_DIR" || exit 1
sed -i "s|BirdNET-Pi|BattyBirdNET-Pi|g" birdnet.conf-defaults

echo "[1/7] Running install_config.sh..."
./install_config.sh || echo "Config: completed with warnings"

echo "[2/7] Running install_services.sh..."
export my_dir="$MY_DIR"
export PYTHON_VIRTUAL_ENV="$MY_DIR/birdnet/bin/python3"

# Create config if missing
if [ ! -f /etc/birdnet/birdnet.conf ]; then
    sudo mkdir -p /etc/birdnet
    sudo cp "$MY_DIR/birdnet.conf-defaults" /etc/birdnet/birdnet.conf
    sudo chmod 644 /etc/birdnet/birdnet.conf
    # Set default location (Frankfurt, Germany)
    sudo sed -i 's/LATITUDE=.*/LATITUDE=50.1109/' /etc/birdnet/birdnet.conf
    sudo sed -i 's/LONGITUDE=.*/LONGITUDE=8.6821/' /etc/birdnet/birdnet.conf
fi

# Create species list files in home directory
touch "$HOME/include_species_list.txt" "$HOME/exclude_species_list.txt"
chmod 644 "$HOME/include_species_list.txt" "$HOME/exclude_species_list.txt"

# Create species list files in project directory (for backwards compatibility)
touch "$MY_DIR/include_species_list.txt" "$MY_DIR/exclude_species_list.txt"
chmod 644 "$MY_DIR/include_species_list.txt" "$MY_DIR/exclude_species_list.txt"

# Run with sudo - ensure my_dir is exported
sudo bash -c "export my_dir='$MY_DIR'; export PYTHON_VIRTUAL_ENV='$PYTHON_VIRTUAL_ENV'; export HOME='$HOME'; export USER='$USER'; bash ./install_services.sh" || echo "Services: completed with warnings"

echo "[3/7] Setting up Python environment..."
cd "$MY_DIR" || exit 1
[ -d "birdnet" ] || python3 -m venv birdnet
source "$MY_DIR/birdnet/bin/activate"
pip install --upgrade pip -q
pip install -r "$MY_DIR/requirements.txt" -q || echo "Requirements: some packages may have failed"

echo "[4/7] Installing language labels..."
cd "$MY_DIR/scripts" || exit 1
[ -f "./install_language_label_nm.sh" ] && ./install_language_label_nm.sh -l "${DATABASE_LANG:-en}" || true

echo "[5/7] Creating database..."
[ -f "./createdb.sh" ] && { source "$MY_DIR/birdnet/bin/activate"; ./createdb.sh; } || true

echo "[6/7] Linking scripts..."
sudo ln -sf "$MY_DIR/scripts"/* /usr/local/bin/ 2>/dev/null || true

# Fix ownership
echo "[6b/7] Fixing file ownership..."
sudo chown -R bat:bat "$MY_DIR" 2>/dev/null || true

echo "[7/7] Fixing Caddy configuration..."
sudo tee /etc/caddy/Caddyfile > /dev/null << 'CEOF'
:80 {
    root * /home/bat/BattyBirdNET-Pi/homepage
    php_fastcgi unix//run/php/php8.4-fpm.sock
    file_server
    try_files {path} {path}/ /index.php
}
CEOF
sudo systemctl restart caddy

# Fix service files (User and paths)
echo "[8/7] Fixing service configurations..."
sudo sed -i 's|/usr/local/bin/server.py|/home/bat/BattyBirdNET-Pi/scripts/server.py|g' /etc/systemd/system/birdnet_server.service
sudo sed -i 's|User=root|User=bat|g' /etc/systemd/system/*.service 2>/dev/null || true

# Fix paths in symlinks (replace any remaining BirdNET-Pi references)
sudo sed -i 's|/root/BattyBirdNET-Pi|/home/bat/BattyBirdNET-Pi|g' /usr/local/bin/*.sh 2>/dev/null || true
sudo sed -i 's|\$HOME/BirdNET-Pi|\$HOME/BattyBirdNET-Pi|g' /usr/local/bin/*.sh 2>/dev/null || true

sudo systemctl daemon-reload

# Start services
echo "[9/7] Starting services..."
sudo systemctl reset-failed birdnet_server birdnet_analysis birdnet_recording 2>/dev/null || true
sudo systemctl start birdnet_server birdnet_analysis birdnet_recording 2>/dev/null || true

echo ""
echo "=== Installation Complete ==="
echo "Web interface: http://$(hostname -I | awk '{print $1}')/"
echo "Configure location: Tools → Settings → Location"
echo ""
echo "Service status:"
sudo systemctl status birdnet_server birdnet_analysis birdnet_recording --no-pager 2>&1 | grep -E "Active:|birdnet"
