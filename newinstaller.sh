#!/usr/bin/env bash

if [ "$EUID" == 0 ]
  then echo "Please run as a non-root user."
  exit
fi

if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "x86_64" ];then
  echo "BirdNET-Pi requires a 64-bit OS.
It looks like your operating system is using $(uname -m),
but would need to be aarch64."
  exit 1
fi

# Set up passwordless sudo for the current user
if ! sudo -n true 2>/dev/null; then
  echo "Setting up passwordless sudo for user '$USER'..."
  echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/batnet-installer >/dev/null
  sudo chmod 440 /etc/sudoers.d/batnet-installer
fi

# Verify it works
sudo -K
if ! sudo -n true; then
  echo "Passwordless sudo is not working. Aborting"
  exit
fi
 
# Simple new installer
HOME=$HOME
USER=$USER

export HOME=$HOME
export USER=$USER

PACKAGES_MISSING=
for cmd in git jq ; do
  if ! which $cmd &> /dev/null;then
      PACKAGES_MISSING="${PACKAGES_MISSING} $cmd"
  fi
done
if [[ ! -z $PACKAGES_MISSING ]] ; then
  sudo apt update
  sudo apt -y install $PACKAGES_MISSING
fi

branch=main
branch_classifier=main

git clone -b $branch --depth=1 https://github.com/rdz-oss/BattyBirdNET-Pi.git ${HOME}/BirdNET-Pi &&
git clone -b $branch_classifier --depth=1 https://github.com/rdz-oss/BattyBirdNET-Analyzer.git ${HOME}/BattyBirdNET-Analyzer &&

sudo find ${HOME}/BirdNET-Pi -type f -name "*.sh" -exec chmod +x {} \;

$HOME/BirdNET-Pi/scripts/install_birdnet.sh
if [ ${PIPESTATUS[0]} -eq 0 ];then
  echo "Installation completed successfully"
  sudo reboot
else
  echo "The installation exited unsuccessfully."
  exit 1
fi
