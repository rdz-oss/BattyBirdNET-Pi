#!/usr/bin/env -S --default-signal=PIPE bash
# Runs BattyBirdNET-Analyzer
#set -x


my_dir=$HOME/BattyBirdNET-Analyzer

start_service() {
  PYTHON_VIRTUAL_ENV="$HOME/BirdNET-Pi/birdnet/bin/python3"
  DIR="$HOME/BattyBirdNET-Analyzer"
  sleep .5
  echo $PYTHON_VIRTUAL_ENV "$DIR/server.py"
  $PYTHON_VIRTUAL_ENV $DIR/server.py
  echo "Started BattyBirdNET-Analyzer service."
}

start_service