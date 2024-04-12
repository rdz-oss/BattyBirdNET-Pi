#!/usr/bin/env bash
# Make sox spectrogram
source /etc/birdnet/birdnet.conf

# Read the logging level from the configuration option
LOGGING_LEVEL="${LogLevel_SpectrogramViewerService}"
# If empty for some reason default to log level of error
[ -z $LOGGING_LEVEL ] && LOGGING_LEVEL='error'
# Additionally if we're at debug or info level then allow printing of script commands and variables
if [ "$LOGGING_LEVEL" == "info" ] || [ "$LOGGING_LEVEL" == "debug" ];then
  # Enable printing of commands/variables etc to terminal for debugging
  set -x
fi

# Time to sleep between generating spectrogram's, default set the recording length
# To try catch the spectrogram as soon as possible run at a smaller intervals
#SLEEP_DELAY=$(echo ""$RECORDING_LENGTH" / ("$RECORDING_LENGTH" / 2.8)" | bc)

# Continuously loop generating a spectrogram every 10 seconds
while true; do
  #analyzing_now="$(cat $HOME/BirdNET-Pi/analyzing_now.txt)"

  #if [ ! -z "${analyzing_now}" ] && [ -f "${analyzing_now}" ]; then
  #  spectrogram_png=${EXTRACTED}/spectrogram.png
  #  sox -V1 "${analyzing_now}" -n remix 1 rate "${SAMPLING_RATE}" spectrogram -c "${analyzing_now//$HOME\//}" -o "${spectrogram_png}"
  #fi

  #while [ "$(cat $HOME/BirdNET-Pi/analyzing_now.txt)" == "${analyzing_now}" ]; do
  #  sleep 0.1
  #done
  sleep 100
done
