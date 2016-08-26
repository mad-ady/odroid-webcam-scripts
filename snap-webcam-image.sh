#!/bin/bash

#This script requires curl and imagemagick
#sudo apt-get install curl imagemagick

PICFOLDER='/home/odroid/Webcam';
#time to save a new picture here
DATE=`date '+%Y-%m-%d-%H-%M-%S'`;

#save picture
curl -s -f -m 5 http://odroid:odroidpass@127.0.0.1:8090/?action=snapshot > "$PICFOLDER/camera-$DATE.jpeg"

if [ -s "$PICFOLDER/camera-$DATE.jpeg" ]; then
        #use montage to add date as a watermark
        cp -f "$PICFOLDER/camera-$DATE.jpeg" /tmp/.camera.jpeg
	convert "/tmp/.camera.jpeg" -gravity northwest -pointsize 16 -undercolor 'rgba(255,165,0,0.6)' -fill black -annotate +5+5 "Webcam snapshot $DATE" "$PICFOLDER/camera-$DATE.jpeg"
#        montage -geometry +0+0 -background orange -label "Webcam snapshot $DATE" "/tmp/.camera.jpeg" "$PICFOLDER/camera-$DATE.jpeg"
else
	logger -t $0 "Unable to save $PICFOLDER/camera-$DATE.jpeg"
	#Try to restart mjpeg_daemon - sometimes it gets stuck
	#the user that runs the script needs sudo access
	sudo systemctl restart mjpeg_streamer.service
fi

