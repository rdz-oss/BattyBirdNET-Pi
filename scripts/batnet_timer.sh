#!/usr/bin/env bash
# Runs a start/stop timer for BattyBirdNET-Pi
#set -x

source /etc/birdnet/birdnet.conf
#/usr/local/bin
my_dir="$HOME/BirdNET-Pi/scripts"
PYTHON_VIRTUAL_ENV="$HOME/BirdNET-Pi/birdnet/bin/python3"
#export my_dir=$my_dir
# cd "$my_dir" || exit 1

start_service() {
  echo "Starting BattyBirdNET timer (dusk - dawn) service."

  if [ -z "${BAT_TIMER}" ];then
    BAT_TIMER=false
    echo "No timer set. Using default timer=false!"
  fi

  if [ -z "${BAT_DUSK}" ];then
    BAT_DUSK="18:00"
    echo "No dusk time set. Using default dusk=18:00!"
  fi

  if [ -z "${BAT_DAWN}" ];then
    BAT_DAWN="06:00"
    echo "No dawn time set. Using default dawn=06:00!"
  fi

  if [ -z "${BAT_SUNTIMER}" ];then
    BAT_SUNTIMER=false
    echo "No sun timer set. Default to false!"
  fi

  if [ -z "${BIRD_CLASSIFIER}" ];then
    BIRD_CLASSIFIER=BIRDS
    echo "No bird classifier set! Going with BIRDS."
  fi

  if [ -z "${SWITCH_TO_BIRD}" ];then
    SWITCH_TO_BIRD=false
    echo "No SWITCH_TO_BIRD set. Going with false."
  fi
  if [ -z "${LAST_CLASSIFIER}" ];then
    LAST_CLASSIFIER=Bavaria
    echo "No last bat classifier set! Going with Bavaria."
  fi

  running=true

  while :; do
    source /etc/birdnet/birdnet.conf

    if [[ $BAT_TIMER == false ]];then
      if [[ $running == false ]];then
        #sudo /usr/local/bin/restart_services.sh
        sudo /usr/local/bin/switch_classifier.sh -c "${LAST_CLASSIFIER}" -t bat
        running=true
      fi
      sleep 60
      continue
    fi

    currenttime=$(date +%H:%M)

    if [[ $BAT_SUNTIMER == true ]];then
      BAT_DAWN=$($PYTHON_VIRTUAL_ENV "${my_dir}"/sun_info.py --lat "${LATITUDE}" --lon "${LONGITUDE}" --updown up)
      BAT_DUSK=$($PYTHON_VIRTUAL_ENV "${my_dir}"/sun_info.py --lat "${LATITUDE}" --lon "${LONGITUDE}" --updown down)
    fi

    if [[ "$currenttime" > "$BAT_DUSK" ]] || [[ "$currenttime" < "$BAT_DAWN" ]];then
      if [[ $running == false ]];then
        if [[ $SWITCH_TO_BIRD == true ]];then
          sudo /usr/local/bin/switch_classifier.sh -c "${LAST_CLASSIFIER}" -t bat
        else
          sudo /usr/local/bin/restart_services.sh
        fi
        running=true
      fi
    else
      if [[ $running == true ]];then
        if [[ $SWITCH_TO_BIRD == true ]];then
          sudo /usr/local/bin/switch_classifier.sh -c "${BIRD_CLASSIFIER}" -t bird
        else
          sudo /usr/local/bin/stop_core_services.sh
        fi
        running=false
      fi
    fi
    sleep 60
  done
  echo "Stopped BattyBirdNET timer (dusk - dawn) service."
}

start_service