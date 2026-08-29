#!/usr/bin/env bash
# Install BirdNET script
set -x # Debugging
exec > >(tee -i installation-$(date +%F).txt) 2>&1 # Make log
set -e # exit installation if anything fails

my_dir=$HOME/BirdNET-Pi
export my_dir=$my_dir

cd $my_dir/scripts || exit 1
git log -n 1 --pretty=oneline --no-color --decorate

source install_helpers.sh

if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "x86_64" ];then
  echo "BirdNET-Pi requires a 64-bit OS.
It looks like your operating system is using $(uname -m),
but would need to be aarch64."
  exit 1
fi

#Install/Configure /etc/birdnet/birdnet.conf
./install_config.sh || exit 1
sudo -E HOME=$HOME USER=$USER ./install_services.sh || exit 1
source /etc/birdnet/birdnet.conf

install_birdnet() {
  cd ~/BirdNET-Pi || exit 1
  echo "Establishing a python virtual environment"
  sudo apt install -y python3-dev build-essential
  python3 -m venv birdnet
  source ./birdnet/bin/activate
  pip3 install wheel
  # Install the appropriate tflite_runtime wheel if available
get_tf_whl
# Use the custom requirements if it was generated, otherwise fall back to the default
REQ_FILE="./requirements.txt"
if [ -f "requirements_custom.txt" ]; then
  REQ_FILE="requirements_custom.txt"
fi
pip3 install -U -r $REQ_FILE
}

[ -d ${RECS_DIR} ] || mkdir -p ${RECS_DIR} &> /dev/null

install_birdnet

cd $my_dir/scripts || exit 1

./install_language_label_nm.sh -l $DATABASE_LANG || exit 1

exit 0
