#!/bin/bash
CWD="$(pwd)"
LOG_NAME=TIME_log"$(date +%Y%m%d)"
EnterDIR=${PWD##*/}	#Save current dir
START_TIME=$SECONDS	#Save Start time

pre_install(){
sudo apt-get install imagemagick libmagickwand-dev
}

init_cnn(){
tmp_PATH="$(pwd)"
cd /home/$(whoami)
if [ ! -d darknet ]; then
	git clone https://github.com/pjreddie/darknet.git
	cd darknet
	make
fi
download_weight "yolo"
download_weight "tiny-yolo-voc"
download_weight "extraction"
download_weight "alexnet"
cd $tmp_PATH
}

download_weight(){
tmp_PATH="$(pwd)"
cd /home/$(whoami)/darknet
if [ ! -e "$1.weights" ]; then
	wget https://pjreddie.com/media/files/"$1.weights" 
	#add weights
fi
cd $tmp_PATH
}
clean_old_pictures(){
temp_path="$(pwd)"
cd /home/$(whoami)/darknet/data
rm tmp*.* *.mp4
cd /home/$(whoami)/tmp_darknet_Stats
rm *.png
cd /home/$(whoami)/tmp_darknet_Stats/darknet_GIT
rm *.png *.mp4
cd $temp_path
}


get_my_pc_info(){
VGA="$(lspci -v | grep VGA | awk -F ' ' '{print $7$8" "$9" "$10 }')"
CPUs="$(sed -n "1,10p" cat /proc/cpuinfo | grep "model name" | cat -n)"
CPU="$(echo "$CPUs" | awk -F '	' '{printf $3}')"
CPU_NUM_OF_CORES="$(cat /proc/cpuinfo | grep "model name" | wc -l)"
}

print_my_pc_info(){
printf "\nCPU $CPU with $CPU_NUM_OF_CORES cores\nGPU : $VGA\n"
}
#============================TABLE==============================================
update_TIME(){
#echo "\e[38;05;75m$@ \e[38;05;82m step time is:" # >> $CWD/$LOG_NAME.out
ELAPSED_TIME=$(($SECONDS - $TMP_TIME))
RUN_TIME="$(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec" # >> $CWD/$LOG_NAME.out
TMP_TIME=$SECONDS
}

init_table(){
if [ -e $table ]; then
	mv $table $table"$(date +%Y%m%d)".old
fi
touch $table
	echo "---------------|---------------|---------------|---------------|---------------|" >> $CWD/$table
	echo "Net Name       |Picture name   |format type    |size           |run time       |" >> $CWD/$table
	echo "---------------|---------------|---------------|---------------|---------------|" >> $CWD/$table
}
add_to_table(){
addspace "$1"
A="$size_of_15"
addspace "$picture_noEND"
B="$size_of_15"
addspace "$picture_type"
C="$size_of_15"
addspace "$picture_resolution"
D="$size_of_15"
addspace "$RUN_TIME"
E="$size_of_15"
echo "\e[38;05;70m$A\e[38;05;71m$B\e[38;05;72m$C\e[38;05;73m$D\e[38;05;74m$E" >> $CWD/$table
echo "---------------|---------------|---------------|---------------|---------------|" >> $CWD/$table
}
addspace(){
tmp_space="$1"
declare -i n
l=${#tmp_space}
n=15-$l
for (( i=0; i < $n ; i++ ))
do
tmp_space="$tmp_space "
done
size_of_15="$tmp_space|"
}
#============================TABLE===END========================================


#===============================Viedo===========================================
update_path(){
echo "update_path"
if [ -d $CWD/$ffmpeg_dir ];	#Check if dir exist
then
	cd $CWD/$ffmpeg_dir/ffmpeg* && ffmpeg_PATH="$(pwd)" && echo "$ffmpeg_PATH"
else
	init_ffmpeg #Create it
fi
}

init_ffmpeg(){
echo "init_ffmpeg"
mkdir -p $CWD/$ffmpeg_dir
cd $CWD/$ffmpeg_dir
wget https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-64bit-static.tar.xz
tar -xvf *.tar*
cd ffmpeg*
ffmpeg_PATH="$(pwd)"
echo "$ffmpeg_PATH"
}

mp4_to_jpg(){
echo "mp4_to_jpg(){"
cd $ffmpeg_PATH
./ffmpeg -ss 00:00:25 -t 00:00:00.04 -i /home/$(whoami)/darknet/data/$picture -r 25.0 /home/$(whoami)/darknet/data/tmp%4d.jpg
picture_type="$picture_type -> jpg"
picture="tmp0001.jpg"

}

#============================Viedo===END========================================
run_YOLO(){
cd /home/$(whoami)/darknet
./darknet detect cfg/yolo.cfg yolo.weights data/$picture
#save_TIME_toLOG "running YOLO on $picture $picture_resolution"
update_TIME
add_to_table "YOLO"
cp predictions.png $CWD
cd $CWD
mv predictions.png YOLO_$picture_noEND.png
}



#./darknet detector demo cfg/coco.data cfg/yolo.cfg yolo.weights <video file>
run_tiny_YOLO(){
cd /home/$(whoami)/darknet
./darknet detector test cfg/voc.data cfg/tiny-yolo-voc.cfg tiny-yolo-voc.weights data/$picture
#save_TIME_toLOG "running tiny YOLO on $picture $picture_resolution"
update_TIME
add_to_table "tiny YOLO"
cp predictions.png $CWD
cd $CWD
mv predictions.png tiny_YOLO_$picture_noEND.png
}
run_Extraction(){
cd /home/$(whoami)/darknet
./darknet classifier predict cfg/imagenet1k.data cfg/extraction.cfg extraction.weights data/$picture
#save_TIME_toLOG "running Extraction on $picture $picture_resolution"
update_TIME
add_to_table "Extraction"
cp predictions.png $CWD
cd $CWD
mv predictions.png Extraction_$picture_noEND.png
}
run_AlexNet(){
cd /home/$(whoami)/darknet
./darknet classifier predict cfg/imagenet1k.data cfg/alexnet.cfg alexnet.weights data/$picture
#save_TIME_toLOG "running AlexNet on $picture $picture_resolution"
update_TIME
add_to_table "AlexNet"
cp predictions.png $CWD
cd $CWD
mv predictions.png AlexNet_$picture_noEND.png
}

picture_resolution(){
echo "$(identify /home/$(whoami)/darknet/data/$picture | awk -F ' ' '{printf $3}')"
}
display_outputs(){
display tiny_YOLO_$picture_noEND.png &
display YOLO_$picture_noEND.png &
display Extraction_$picture_noEND.png &
display AlexNet_$picture_noEND.png &
}
download_youtube(){
tmp_path="$(pwd)"
chmod 777 youtube_wget.pl
#sed -i -e 's/\r$//' youtube_wget.pl
./youtube_wget.pl $picture
sleep 3
mv *.mp4 youtube.mp4
cp youtube.mp4 /home/$(whoami)/darknet/data/
picture="youtube.mp4"
cd $tmp_path
}
#===============================MAIN============================================
clean_old_pictures

picture="$1"
if [[ $picture == *"www.youtube"* ]]; then
	download_youtube
fi
picture_noEND="$((echo "$picture") | awk -F '.' '{printf $1}')"
picture_type="$((echo "$picture") | awk -F '.' '{printf $2}')"

#echo "$(identify /home/$(whoami)/darknet/data/$picture | awk -F ' ' '{printf $3}')"
RUN_TIME=""
table="name_of_table"
init_table
tmp_space=""
size_of_15=""

ffmpeg_dir="ffmpeg"
tmp_path="$(pwd)"
if [ $picture_type == "mp4" ]; then
{
	tmp_path="$(pwd)"
	update_path
	mp4_to_jpg
	cd $tmp_path
}
fi
picture_resolution="$(identify /home/$(whoami)/darknet/data/$picture | awk -F ' ' '{printf $3}')"
if [ -z "$picture_resolution" ];then
	echo "arrgument is not valid picture!" && exit 0;
fi
get_my_pc_info
init_cnn
TMP_TIME=$SECONDS	#Save Last time
run_YOLO
run_tiny_YOLO
run_Extraction
run_AlexNet
#echo -e "$(cat $LOG_NAME.out)"
echo -e "\n$(cat $table)"
print_my_pc_info
#display /home/$(whoami)/darknet/data/$picture &
display_outputs

#rm $LOG_NAME.out
