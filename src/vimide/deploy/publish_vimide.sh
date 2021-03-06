#!/bin/bash

if [[ -r "$1" ]]; then
    IPFILE=$1
else
    IPFILE='testiplist'
fi

BASEDIR=$(cd $(dirname $BASH_SOURCE);pwd)
source $BASEDIR/../config.sh
if [[ -z "$2" ]]; then
   SOURCE_DIR=$CURRENT_VIMIDE
elif [[ ! -d "$2" ]]; then
    echo "路径无效或不可读"
    return 0
else
    SOURCE_DIR=$2
fi

if [[ -z "$3" ]]; then
    USER=$(whoami)
else
    USER=$3
fi

TARGET_IP="10.16.73.21"

while read <&10 remote_ip; do
    ssh -t $remote_ip "if [ ! -d $SOURCE_DIR ]; then sudo mkdir -p $SOURCE_DIR; fi; sudo chmod 777 -R $SOURCE_DIR;sudo rsync -avz --delete --force $USER@$TARGET_IP:$SOURCE_DIR/ $SOURCE_DIR/ ;"
    echo -e "---- 同步 $remote_ip:$SOURCE_DIR 完成----\n"
done 10< $1

