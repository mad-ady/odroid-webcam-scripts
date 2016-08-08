#!/bin/bash

#this script requires ffmpeg
#sudo apt-get install ffmpeg

PICDIR='/home/odroid/Webcam';
BASE=camera;

#cleanup empty pictures
cd "$PICDIR";
for file in ./${BASE}-*.jpeg; do
  if [ ! -s "$file" ]; then
     rm -f "$file"
     echo "Deleting $file"
  fi
done

#make a movie
DATE=`date +%Y-%m-%d`
/usr/bin/ffmpeg -framerate 3 -i "$PICDIR/${BASE}-%*.jpeg" -c:v libx264 -preset ultrafast -r 25 -pix_fmt yuv420p -b:v 1500k "$PICDIR/${BASE}-${DATE}.mp4"

echo -n "Written $PICDIR/${BASE}-${DATE}.mp4 - "
SIZE=`stat --printf="%s" "$PICDIR/${BASE}-${DATE}.mp4"`;
echo $SIZE

if [ -s "$SIZE" ]; then
	#it's wise to delete (or move) the original pictures so that they won't become part of tomorrow's video
	#rm -f "$PICDIR/${BASE}-*.jpeg"
fi
