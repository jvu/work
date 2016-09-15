#!/bin/bash

# quietMode=0 means to print out what file is being checked, 1 means to mute it
quietMode=0

if [ "$#" -lt 2 ]
then
	echo "You must provide two arguments to compare!"
	exit 1
fi

parentPath=$( cd "$(dirname "${BASH_SOURCE}")" ; pwd -P )
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
	for i in "$parentPath/$folderA/$1/$2"/*;do
		folderAChild=$( basename $i );
		relativePath="$1/$2/$folderAChild"
		if [ -d "$i" ];then
			if [ -d "$parentPath/$folderB/$relativePath" ];then
				# It is a folder
				recurse "$1/$2" $folderAChild 
			else
				echo "ERROR: folder $i exists but folder $parentPath/$folderB/$relativePath does not exists"
			fi
		elif [ -f "$i" ]; then
			if [ -f "$parentPath/$folderB/$relativePath" ];then
				if [ $quietMode -eq 0 ];then
					echo "===== Checking $relativePath"
				fi
				# It is a file
				# & is to assist with muli-threading - http://stackoverflow.com/questions/18384505/how-do-i-use-parallel-programming-multi-threading-in-my-bash-script
				sortAndCompareFiles $i "$parentPath/$folderB/$relativePath" &
			else
				echo "ERROR: file $i exists but file $parentPath/$folderB/$relativePath does not exists"
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
for i in "$parentPath/$folderA"/*; do
	folderAChild=$( basename $i );
	if [ -d "$i" ];then
		recurse "" $folderAChild
	elif [ -f "$i" ]; then
		if [ -f "$parentPath/$folderB/$folderAChild" ];then
			if [ $quietMode -eq 0 ];then
				echo "===== Checking $folderAChild"
			fi
			# It is a file
			# & is to assist with muli-threading - http://stackoverflow.com/questions/18384505/how-do-i-use-parallel-programming-multi-threading-in-my-bash-script
			sortAndCompareFiles $i "$parentPath/$folderB/$folderAChild" &
		else
			echo "ERROR: file $i exists but file $folderB/$folderAChild does not exists"
		fi
	fi
done
echo "===== File Check Differences Completed ====="

# End the timer (http://stackoverflow.com/questions/8903239/how-to-calculate-time-difference-in-bash-script)
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."