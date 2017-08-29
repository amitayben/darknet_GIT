#!/bin/bash

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
download_weight "tiny-yolo"
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
if [ -e $table ]; then
	mv $table $table"$(date +%Y%m%d)".old
fi
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
run_NETS(){
run_YOLO
run_tiny_YOLO_COCO
#run_Extraction
run_AlexNet
run_tiny_YOLO_VOC
#run_MSR_152
}
add_to_display(){
display_arr=("${display_arr[@]}" "$1")
}
display_outputs(){
convert -delay 5 -loop 0 *.png myimage.gif
montage -geometry "$picture_resolution" "${display_arr[0]}" "${display_arr[1]}" "${display_arr[2]}" "${display_arr[3]}" out.png
#sizeof_arr="${#display_arr[@]}"
#for((i=0 ; i < $sizeof_arr ; i++))
#do #echo "${display_arr[$i]}";
#	display "${display_arr[$i]}" &
#done
display myimage.gif &
display out.png &
}
save_cnn_result(){
update_TIME
add_to_table "$1"
cp predictions.png $CWD
cd $CWD
mv predictions.png $1_$picture_noEND.png
convert -pointsize 36 -fill red -draw "text 50,50 "$1" " $1_$picture_noEND.png $1_$picture_noEND.png
add_to_display "$1_$picture_noEND.png"
}
run_MSR_152(){
cd /home/$(whoami)/darknet
./darknet detect cfg/msr_152.cfg $picture_PATH/$picture
save_cnn_result "MSR_152"
}
run_YOLO(){
cd /home/$(whoami)/darknet
./darknet detect cfg/yolo.cfg yolo.weights $picture_PATH/$picture
save_cnn_result "YOLO"
}
run_tiny_YOLO_COCO(){
cd /home/$(whoami)/darknet
echo "./darknet detect cfg/tiny-yolo.cfg tiny-yolo.weights $picture_PATH/$picture"
./darknet detect cfg/tiny-yolo.cfg tiny-yolo.weights $picture_PATH/$picture
save_cnn_result "tiny_YOLO_COCO"
}
run_tiny_YOLO_VOC(){
cd /home/$(whoami)/darknet
./darknet detector test cfg/voc.data cfg/tiny-yolo-voc.cfg tiny-yolo-voc.weights $picture_PATH/$picture
save_cnn_result "tiny_YOLO_VOC"
}
run_Extraction(){
cd /home/$(whoami)/darknet
./darknet classifier predict cfg/imagenet1k.data cfg/extraction.cfg extraction.weights $picture_PATH/$picture
save_cnn_result "Extraction"
}
run_AlexNet(){
cd /home/$(whoami)/darknet
./darknet classifier predict cfg/imagenet1k.data cfg/alexnet.cfg alexnet.weights $picture_PATH/$picture
save_cnn_result "AlexNet"
}
picture_resolution(){
echo "$(identify /home/$(whoami)/darknet/data/$picture | awk -F ' ' '{printf $3}')"
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
#init
CWD="$(pwd)"
LOG_NAME=TIME_log"$(date +%Y%m%d)"
EnterDIR=${PWD##*/}	#Save current dir
START_TIME=$SECONDS	#Save Start time
table="name_of_table"
ffmpeg_dir="ffmpeg"
tmp_space=""
size_of_15=""
RUN_TIME=""
picture="$1"
picture_PATH="/home/$(whoami)/darknet/data"

init_cnn
clean_old_pictures


## handle user arrgement
if [[ "`dirname "$1"`" != "." && "`dirname "$1"`" != "https://www.youtube.com" ]]; then
	picture_PATH=`dirname "$1"`
	if [ ! -d $picture_PATH ]; then
		echo "arrgument is not valid path!" && exit 0;
	fi
picture=`basename "$1"`
cp "$1" /home/$(whoami)/darknet/data
fi
## handle youtube case
if [[ $picture == *"www.youtube"* ]]; then
	download_youtube
fi
picture_noEND="$((echo "$picture") | awk -F '.' '{printf $1}')"
picture_type="$((echo "$picture") | awk -F '.' '{printf $2}')"
## init out put table
init_table
## handle video case
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
#get pc info
get_my_pc_info
TMP_TIME=$SECONDS	#Save Last time
#run alll nets
run_NETS

#print and display outputs
echo -e "\n$(cat $table)"
print_my_pc_info
display_outputs

#END
