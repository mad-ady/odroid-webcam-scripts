#!/bin/bash

FRAMERATE=25
W=1280
H=720
BANDWIDTH=1500000
USER=odroid
PASS=odroidpass
PIPE=/tmp/c2enc

#ensure everything is turned off if this process is killed more or less gracefully
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

#create the named pipe
if [ ! -p $PIPE ]; then mkfifo $PIPE; fi

function feeder(){
	
	echo "Feeder pid $BASHPID"
	while [ 1 ];
	do
		logger -s -t $0 "Feeder is restarting"
		/usr/bin/ffmpeg -loglevel 8 -r $FRAMERATE -f mjpeg -i "http://$USER:$PASS@127.0.0.1:8090/?action=stream" -an -c:v rawvideo -r $FRAMERATE -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf: text='Webcam feed %{localtime\\:%F %T}': fontcolor=white@0.9: x=7: y=5" -pix_fmt nv21 -f rawvideo - >  $PIPE
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
cat $PIPE | /usr/local/bin/c2enc -w $W -h $H -f $FRAMERATE -b $BANDWIDTH | /usr/bin/ffmpeg -r $FRAMERATE -thread_queue_size 256 -f h264 -i - -thread_queue_size 32 -f pulse -server 127.0.0.1 -i alsa_input.usb-Sonix_Technology_Co.__Ltd._USB_2.0_Camera-02.analog-mono -acodec libmp3lame -async 1 -c:v copy -override_ffserver http://127.0.0.1:8099/mjpg-streamer.ffm
#sleep 30

echo "FFmpeg stopped. Cleaning up"
kill -9 $FEEDERPID
