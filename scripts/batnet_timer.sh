#!/usr/bin/env -S --default-signal=PIPE bash
# Runs a start/stop timer for BattyBirdNET-Pi
#set -x

source /etc/birdnet/birdnet.conf
#/usr/local/bin
my_dir=$HOME/BirdNET-Pi/scripts
#export my_dir=$my_dir
cd "$my_dir" || exit 1

start_service() {
  echo "Starting BattyBirdNET timer (dusk - dawn) service."

  if [ -z ${BAT_TIMER} ];then
    BAT_TIMER=false
    echo "No timer set. Using default timer=false!"
  fi

  if [ -z ${BAT_DUSK} ];then
    BAT_DUSK="18:00"
    echo "No dusk time set. Using default dusk=18:00!"
  fi

  if [ -z ${BAT_DAWN} ];then
    BAT_DAWN="06:00"
    echo "No dawn time set. Using default dawn=06:00!"
  fi

  running=true

  while :; do
    source /etc/birdnet/birdnet.conf

    if [[ $BAT_TIMER == false ]];then
      sleep 240
      continue
    fi

    currenttime=$(date +%H:%M)

    if [[ "$currenttime" > "$BAT_DUSK" ]] || [[ "$currenttime" < "$BAT_DAWN" ]];then
      if [[ $running == false ]];then
        ./restart_services.sh
        running=true
      fi
    else
      if [[ $running == true ]];then
        ./stop_core_services.sh
        running=false
      fi
    fi
    sleep 60
  done
  echo "Stopped BattyBirdNET timer (dusk - dawn) service."
}

start_service