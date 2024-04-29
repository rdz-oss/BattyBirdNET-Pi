#!/bin/bash
set -x # Uncomment to enable debugging
source /etc/birdnet/birdnet.conf
USER=$(awk -F: '/1000/ {print $1}' /etc/passwd)
HOME=$(awk -F: '/1000/ {print $6}' /etc/passwd)
my_dir="$HOME/BirdNET-Pi/scripts"
PYTHON_VIRTUAL_ENV="$HOME/BirdNET-Pi/birdnet/bin/python3"


echo "Beginning $(date)"
echo "Beginning $(date)" >> ${HOME}/copy_to_remote.log
echo "Removing old files $(date)"
echo "Removing old files $(date)" >> ${HOME}/copy_to_remote.log

# Deleting all files to leave transfwer directory empty`
rm ${HOME}/toTransfer/*

# finding and copying all files less than half a day old
echo "Copying files $(date)"
echo "Copying files $(date)" >> ${HOME}/copy_to_remote.log
find ${HOME}/BirdSongs/Extracted/By_Date/ -mtime -1 -name '*.wav' -exec cp -u {} ${HOME}/toTransfer/ \;
#find ${HOME}/BirdSongs/Processed/ -mtime -1 -name '*.wav' -exec cp -u {} ${HOME}/toTransfer/ \;

echo "Renaming files $(date)"
echo "Renaming files $(date)" >> ${HOME}/copy_to_remote.log
cd ${HOME}/toTransfer

# Renaming files to BattyBirdNetPi_yyyymmdd_hhmmss_species.wav
for fileName in *.wav
do
  if [[ $fileName == *birdnet* ]]
    # if file name contain birdnet
    then
      # Make an array of the filename separated by -
      IFS='-' read -ra my_array <<< "$fileName"

      # Count number of array elements
      mycount="${#my_array[@]}"

      if [ $mycount -gt 5 ]
        then
          # If more than 5 array elements
          species="${my_array[0]}"
        else
          # If less than 5 array elements
          species="NoID"
      fi

      # Remove .wav from last elemwent
      my_array["${mycount}-1"]=$(echo "${my_array[${mycount}-1]}" | cut -d'.' -f1)

      # Split filename array up
      mytime=${my_array[${mycount}-1]}
      myday=${my_array[${mycount}-3]}
      mymonth=${my_array[${mycount}-4]}
      myyear=${my_array[${mycount}-5]}

      # Make an array of time split by :
      IFS=':' read -ra my_time <<< "${mytime}"
      myhour="${my_time[0]}"
      myminute="${my_time[1]}"
      mysecond="${my_time[2]}"

      # Rename files
      echo "mv ${fileName} BattyBirdNetPi_${myyear}${mymonth}${myday}_${myhour}${myminute}${mysecond}_${species}.wav"
      echo "mv ${fileName} BattyBirdNetPi_${myyear}${mymonth}${myday}_${myhour}${myminute}${mysecond}_${species}.wav" >> ${HOME}/copy_to_remote.log
      echo "mv ${fileName} BattyBirdNetPi_${myyear}${mymonth}${myday}_${myhour}${myminute}${mysecond}_${species}.wav" | bash
  fi
done

# Copy files to RemoteSFTPLocation
echo "Cloning to RemoteSFTPLocation $(date)"
echo "Cloning to RemoteSFTPLocation $(date)" >> ${HOME}/copy_to_remote.log
rclone copy ${HOME}/toTransfer/ RemoteSFTPLocation:/remoteLocation/ --ignore-errors --ignore-existing --log-file=${HOME}/copy_to_remote.log --log-level INFO

# Copy files to LocalSFTPLocation
echo "Cloning to LocalSFTPLocation $(date)"
echo "Cloning to LocalSFTPLocation $(date)" >> ${HOME}/copy_to_remote.log
rclone copy ${HOME}/toTransfer/ LocalSFTPLocation:/FromBattyBirdNETPi/ --ignore-errors --ignore-existing --log-file=${HOME}/copy_to_remote.log --log-level INFO

echo "Complete"
echo "Complete" >> ${HOME}/copy_to_remote.log
echo " " >> ${HOME}/copy_to_remote.log
