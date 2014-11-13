#!/bin/bash
E_BADARGS=65

if [ ! -n "$2" ]
then
  echo "Usage: `basename $0` dirname"
  exit $E_BADARGS
fi 


fileName=$1
minArea=$2


# Determine the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#echo $DIR

#rm $DIR/run.eds
runScript=$(cat /proc/sys/kernel/random/uuid)
runScript="run_$runScript.eds"

#echo $1

# Create a temporary symbolic link as Edison has problems with absolute/long/weird paths


pwd
ls $DIR/tmp/$fileName > $DIR/$runScript	#prepare all filenames
sed -i "s/^/Load(\'/" $DIR/$runScript  #prepare eds segment
sed -i "s/$/\'\,IMAGE\)\;Segment\;/" $DIR/$runScript

sed -i '1i DisplayProgress OFF;' $DIR/$runScript
sed -i '1i Speedup = MEDIUM;' $DIR/$runScript
sed -i '1i MinimumRegionArea = '$minArea';' $DIR/$runScript
sed -i '1i RangeBandwidth = 6.5;' $DIR/$runScript
sed -i '1i SpatialBandwidth = 7;' $DIR/$runScript


echo "Running segmentation..."

start_time=$(date +%s)
$DIR/edisonProject $DIR/$runScript
finish_time=$(date +%s)
echo "Time duration: $((finish_time - start_time)) secs."
rm $DIR/$runScript

