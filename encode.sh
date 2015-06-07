#!/bin/bash


#
# Print help text to output.
#
function print_help {

  echo "Search files on synology nas and convert them for play in chromecast player"
  echo ""
  echo "Usage: chromecast <user> <ip> <synology_partition>"
  echo ""
  echo "<user> user with ssh access to synology server."
  echo "<ip> ip of synology server."
  echo "<synology_partition> path to directory under /volume*/ ."
  echo "Note: Script require HandBrakeCLI installed."
  exit

}

function error_handling {
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        echo "error with $1" >&2
        exit 1
    fi

}

while getopts "h" flag
do
  case $flag in
    h) print_help;
  esac
done

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]
  then
  print_help;
fi


SYNOLOGY_IP=$1
SYNOLOGY_USER=$2
SEARCH_PATH="/volume*/$3"
#TODO add this temporary files to system temporary files
TMP_ORIG_FILES="temp/orig/"
TMP_NEW_FILES="temp/new/"
#TODO remove
FILES="queue.txt"

#find files in avi format - in most cases bad format
#ssh $SYNOLOGY_USER@$SYNOLOGY_IP "find $SEARCH_PATH -name '*avi'" > queue.txt

while read FILES
do
    FILE_PATH=$(echo $FILES | sed 's/ /\\ /g')

    # get filename from path
    FILE_NAME=$(basename "$FILES")
    FILE_NAME=$(echo $FILE_NAME | sed 's/ /\\ /g')
#    TODO remove extension
    echo $FILE_NAME

    # copy files localy
    scp "$SYNOLOGY_USER@$SYNOLOGY_IP:$FILE_PATH" "$TMP_ORIG_FILES$FILE_NAME"
    error_handling

    # process to new
    # HandBrakeCLI stealing all stdin like ssh
    HandBrakeCLI -i "$TMP_ORIG_FILES$FILE_NAME" -o "$TMP_NEW_FILES$FILE_NAME.mkv" --format av_mkv --encoder x264 < /dev/null
    error_handling

    # remove original temporarily files
    rm "$TMP_ORIG_FILES$FILE_NAME"
    error_handling

    DIR=$(dirname "$FILE_PATH")
    scp "$TMP_NEW_FILES$FILE_NAME.mkv" "$SYNOLOGY_USER@$SYNOLOGY_IP:$DIR/$FILE_NAME.mkv"
    error_handling

    # remove encoded temporarily files
    rm "$TMP_NEW_FILES$FILE_NAME.mkv"
    error_handling

    # bugg
#    # remove original from remote
#    ssh $SYNOLOGY_USER@$SYNOLOGY_IP "rm \"$FILE_PATH\""
#    error_handling

done < queue.txt

rm $FILES

exit 0
