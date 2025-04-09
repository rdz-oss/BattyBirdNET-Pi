#!/usr/bin/env -S --default-signal=PIPE bash
# Runs BattyBirdNET-Analyzer
#set -x

source /etc/birdnet/birdnet.conf
my_dir=$HOME/BattyBirdNET-Analyzer

start_service() {
  PYTHON_VIRTUAL_ENV="$HOME/BirdNET-Pi/birdnet/bin/python3"
  DIR="$HOME/BattyBirdNET-Analyzer"
  cd $DIR || return
  # sleep .5
  if [ -z ${BAT_CLASSIFIER} ];then
    BAT_CLASSIFIER="Bavaria"
    echo "No classifier for bats set. Using default Bavaria classifier!"
  fi
  echo $PYTHON_VIRTUAL_ENV "$DIR/server.py --area ${BAT_CLASSIFIER}"
  $PYTHON_VIRTUAL_ENV $DIR/server.py --area $BAT_CLASSIFIER
  echo "Started BattyBirdNET-Analyzer service."

  # start second APi here with --port and the same classifier
  if [ -z ${DOUBLE_CLASSIFIER} ];then
    DOUBLE_CLASSIFIER=false
  fi
  if [ "$DOUBLE_CLASSIFIER" = true ] ; then
    echo $PYTHON_VIRTUAL_ENV "$DIR/server.py --no_noise on --area ${BAT_CLASSIFIER} --port 7668"
    $PYTHON_VIRTUAL_ENV $DIR/server.py --port 7668 --no_noise on --area $BAT_CLASSIFIER
    echo "Started BattyBirdNET-Analyzer high accuracy service."
  fi

}

start_service