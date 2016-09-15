#!/bin/bash

# quietMode=0 means to print out what file is being checked, 1 means to mute it
quietMode=0

# multithread=1 means to use multithreading (will use your CPU) 0 means to not use it
# multithread=1 resulted time 7 min 46 seconds compare to multithread=0 resulted time 14 minutes 6 seconds
multithread=1

if [ "$#" -lt 2 ]
then
	echo "You must provide two arguments to compare!"
	exit 1
fi

sortedExtension="sorted"
folderA=$1
folderB=$2

# Do a difference between two files and print out the differences
diffTwoFiles() {
	DIFF=$(diff -B --strip-trailing-cr "$1.$sortedExtension" "$2.$sortedExtension")
	if [ "$DIFF" != "" ] 
	then
		echo "===== File Difference ====="
		echo "< LEFT FILE  " $1
		echo "$DIFF"
		echo "> RIGHT FILE " $2
		echo "==========================="
	fi
}

# Sort the files in a temporary place and call diffTwoFiles
sortAndCompareFiles() {
	leftSortedFile="$1.$sortedExtension"
	rightSortedFile="$2.$sortedExtension"
	sort -b --output=$leftSortedFile $1
	sort -b --output=$rightSortedFile $2
	diffTwoFiles $1 $2
	rm $leftSortedFile
	rm $rightSortedFile
}

# Function to go through the files and folders of the target
# Adapted from http://stackoverflow.com/questions/2154166/how-to-recursively-list-subdirectories-in-bash-without-using-find-or-ls-commands
recurse() {
	for i in "$folderA/$1/$2"/*;do
		folderAChild=$( basename $i );
		relativePath="$1/$2/$folderAChild"
		if [ -d "$i" ];then
			if [ -d "$folderB/$relativePath" ];then
				# It is a folder
				recurse "$1/$2" $folderAChild 
			else
				echo "===== ERROR: folder $i exists but folder $folderB/$relativePath does not exists"
			fi
		elif [ -f "$i" ]; then
			if [ -f "$folderB/$relativePath" ];then
				if [ $quietMode -eq 0 ];then
					echo "Checking $relativePath"
				fi
				# It is a file
				# & is to assist with muli-threading - http://stackoverflow.com/questions/18384505/how-do-i-use-parallel-programming-multi-threading-in-my-bash-script
				if [ $multithread -eq 1 ];then
					sortAndCompareFiles $i "$folderB/$relativePath" &
				else
					sortAndCompareFiles $i "$folderB/$relativePath"
				fi
				
			else
				echo "===== ERROR: file $i exists but file $folderB/$relativePath does not exists"
			fi
		fi
	done
}

# Start the timer (http://stackoverflow.com/questions/8903239/how-to-calculate-time-difference-in-bash-script)
SECONDS=0

# Check the file structure of the two folders
echo "===== Directory Structure Differences ====="
diff -qr $folderA $folderB
echo "==========================================="

echo "===== Starting File Check Differences ====="
for i in "$folderA"/*; do
	folderAChild=$( basename $i );
	if [ -d "$i" ];then
		recurse "" $folderAChild
	elif [ -f "$i" ]; then
		if [ -f "$folderB/$folderAChild" ];then
			if [ $quietMode -eq 0 ];then
				echo "Checking $folderAChild"
			fi
			# It is a file
			# & is to assist with muli-threading - http://stackoverflow.com/questions/18384505/how-do-i-use-parallel-programming-multi-threading-in-my-bash-script
			if [ $multithread -eq 1 ];then
				sortAndCompareFiles $i "$folderB/$folderAChild" &
			else
				sortAndCompareFiles $i "$folderB/$folderAChild"
			fi
		else
			echo "===== ERROR: file $i exists but file $folderB/$folderAChild does not exists"
		fi
	fi
done
echo "===== File Check Differences Completed ====="

# End the timer (http://stackoverflow.com/questions/8903239/how-to-calculate-time-difference-in-bash-script)
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."