#!/bin/bash
E_BADARGS=65

if [ ! -n "$1" ]
then
  echo "Usage: `basename $0` dirname"
  exit $E_BADARGS
fi 

minArea=$2

# Determine the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#echo $DIR

rm $DIR/run.eds

#echo $1
ln -s $1 tmpLink

# Create ppm files if necessary
count=`ls -1 tmpLink/*.ppm 2>/dev/null | wc -l`
if [ $count == 0 ]
then
  mogrify -format jpg tmpLink/*.png	
  mogrify -format ppm tmpLink/*.jpg
fi

# Create a temporary symbolic link as Edison has problems with absolute/long/weird paths


pwd
ls tmpLink/*.ppm > $DIR/run.eds	#prepare all filenames
sed -i "s/^/Load(\'/" $DIR/run.eds  #prepare eds segment
sed -i "s/$/\'\,IMAGE\)\;Segment\;/" $DIR/run.eds

sed -i '1i DisplayProgress OFF;' $DIR/run.eds
sed -i '1i Speedup = MEDIUM;' $DIR/run.eds
sed -i '1i MinimumRegionArea = '$minArea';' $DIR/run.eds
sed -i '1i RangeBandwidth = 6.5;' $DIR/run.eds
sed -i '1i SpatialBandwidth = 7;' $DIR/run.eds


echo "Running segmentation..."

start_time=$(date +%s)
$DIR/edisonProject $DIR/run.eds
finish_time=$(date +%s)
echo "Time duration: $((finish_time - start_time)) secs."
rm tmpLink

