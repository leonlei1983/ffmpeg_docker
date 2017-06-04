#!/bin/bash

cmd()
{
	#echo "cmd: $*"
	eval "$* >/dev/null 2>&1"
}

CURRENT_PATH=$(cd $(dirname $0) && pwd)
VIDEO_PATH=${CURRENT_PATH}/videos
OUT_FOLDER1=${CURRENT_PATH}/video_fps_2
OUT_FOLDER2=${CURRENT_PATH}/video_each

f_clean_out()
{
	[ ! -d ${OUT_FOLDER1} ] || cmd rm -rf ${OUT_FOLDER1}
	cmd mkdir -p ${OUT_FOLDER1}
	[ ! -d ${OUT_FOLDER2} ] || cmd rm -rf ${OUT_FOLDER2}
	cmd mkdir -p ${OUT_FOLDER2}
}

f_get_resolution()
{
	local video=$1

	env=$(ffprobe -v error -select_streams v:0 \
	-show_entries stream=r_frame_rate,width,height,duration \
	-of default=noprint_wrappers=1 -i ${video} 2>/dev/null)
	
	for line in ${env}
	do
		eval "${line}"
	done
	
	echo "${width}x${height}"
}

f_cut_frames()
{
	local video=$1
	local resolution=`f_get_resolution ${video}`

	cmd ffmpeg -i ${video} -vf fps=2:round=0 -s ${resolution} -qscale:v 2 -t 1 ${OUT_FOLDER1}/%6d.jpg
	cmd ffmpeg -i ${video} -s ${resolution} -qscale:v 2 -t 2 ${OUT_FOLDER2}/%6d.jpg
}

f_find_match_index()
{
	for file1 in $(find ${OUT_FOLDER1} -type f | sort -k 6)
	do
		for file2 in $(find ${OUT_FOLDER2} -type f | sort -k 6)
		do
			diff ${file1} ${file2} >/dev/null 2>&1
			if [ $? -eq 0 ]; then
				echo "${file1} ${file2}"
				break
			fi
		done
	done
}

f_run()
{
	echo "video: $1"
	f_clean_out
	f_cut_frames $1
	f_find_match_index
	echo
}

main()
{
	local video=${VIDEO_PATH}/$1

	if [ -f ${video} ]; then
		f_run ${video}
	else
		for video in $(find ${VIDEO_PATH} -type f)
		do
			f_run ${video}
		done
	fi
}

main $1

