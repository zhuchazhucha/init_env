REMOTE_PATH=~/
CMD=`cat $1`
echo ssh -t  $USER@$2 "\"$CMD\""
ssh -t  $USER@$2 "$CMD"
