#!/usr/bin/env bash
# Restarts ALL services and removes ALL unprocessed audio
source /etc/birdnet/birdnet.conf
# set -x
#my_dir=$HOME/BirdNET-Pi/scripts
bird_rec_length=15
bird_extraction_length=3
bat_rec_length=9
bat_extraction_length=1.125

while getopts t:c: flag
do
    case "${flag}" in
        t) classifier_t=${OPTARG};;
        c) classifier=${OPTARG};;
        *) echo 'Specifiy -t type (bat,bird) and -c classifier.'
    esac
done

sudo /usr/local/bin/stop_core_services.sh

if [[ $classifier_t == "bird" ]];then
  sudo sed -i "s/BAT_CLASSIFIER=.*/BAT_CLASSIFIER=$classifier/g" /etc/birdnet/birdnet.conf
  sudo sed -i "s/RECORDING_LENGTH=.*/RECORDING_LENGTH=$bird_rec_length/g" /etc/birdnet/birdnet.conf
  sudo sed -i "s/EXTRACTION_LENGTH=.*/EXTRACTION_LENGTH=$bird_extraction_length/g" /etc/birdnet/birdnet.conf
fi

if [[ $classifier_t == "bat" ]];then
  sudo sed -i "s/BAT_CLASSIFIER=.*/BAT_CLASSIFIER=$classifier/g" /etc/birdnet/birdnet.conf
  sudo sed -i "s/RECORDING_LENGTH=.*/RECORDING_LENGTH=$bat_rec_length/g" /etc/birdnet/birdnet.conf
  sudo sed -i "s/EXTRACTION_LENGTH=.*/EXTRACTION_LENGTH=$bat_extraction_length/g" /etc/birdnet/birdnet.conf
fi

sudo /usr/local/bin/restart_services.sh
