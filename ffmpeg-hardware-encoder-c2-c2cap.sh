#!/bin/bash

VIDEO=/dev/video6
FRAMERATE=25
W=1280
H=720
BANDWIDTH=1500
USER=odroid
PASS=odroidpass

#ensure everything is turned off if this process is killed more or less gracefully
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT


function feeder(){
	
	echo "Feeder pid $BASHPID"
	while [ 1 ];
	do
		logger -s -t $0 "Feeder is restarting"
		/usr/bin/ffmpeg -loglevel 8 -r $FRAMERATE -f mjpeg -i "http://$USER:$PASS@127.0.0.1:8090/?action=stream" -an -c:v rawvideo -r $FRAMERATE -pix_fmt yuyv422 -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf: text='Webcam feed %{localtime\\:%F %T}': fontcolor=white@0.9: x=7: y=5" -f v4l2 $VIDEO
	done
}

#start feeder. If it dies, feeder restarts automatically
feeder &
FEEDERPID=$!
#give a bit of time to the feeder to output something to the fake webcam
sleep 1
logger -s -t $0 "Parent PID $BASHPID, feeder pid is $FEEDERPID"
#start ffmpeg. If it dies, kill feeder and close
logger -s -t $0 "Starting hardware encoding"
/usr/local/bin/c2cap -w $W -h $H -f $FRAMERATE -p yuyv -b $BANDWIDTH -d $VIDEO -o - |/usr/bin/ffmpeg -r $FRAMERATE -thread_queue_size 256 -f h264 -i - -thread_queue_size 32 -f alsa -i plughw:CARD=Camera,DEV=0 -acodec libmp3lame -async 1 -c:v copy -override_ffserver http://localhost:8099/mjpg-streamer.ffm
#sleep 30

echo "FFmpeg stopped. Cleaning up"
kill -9 $FEEDERPID
