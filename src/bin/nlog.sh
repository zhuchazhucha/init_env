LOGROOT=/data/logs/nginx
G_PROJ=""
function get_proj() {
    CUR_PATH=`pwd`
    PRJ=`basename $CUR_PATH`
    if test -e $LOGROOT/$PRJ ; then
        G_PROJ=$PRJ
    else
        echo "没有找到日志目录 $LOGROOT"
        exit;
    fi
}
function  tail_mutifile () {
    DOMAIN=$1
    DATE=$2

    LOGFILE="$LOGROOT/$DOMAIN/$DATE.log"
    echo $LOGFILE;
    tail -f  $LOGFILE
}

function help() {
    echo "根据当前的目录名，来查看项目日志"
    echo "wlog pylon,data -1 "
    echo "wlog -a "
    echo "wlog -a -1"
}


FORMAT=+%Y/%m/%d/access_%H
DATE=`date  $FORMAT`




case $# in
    0)
        ls $LOGROOT
        ;;
    1)
        LOGNAMES=$1
        if test $1 =  "-h" ; then
            help ;
            exit ;
        fi 
        if test $1 = "-a" ; then 
            LOGNAMES="_all"
        fi
        tail_mutifile $LOGNAMES  $DATE  $G_PROJ ;
        ;;
    2)
        LOGNAMES=$1
        DATA=`date -d "$2 hour" $FORMAT`
        tail_mutifile $LOGNAMES  $DATE  $G_PROJ ;
        ;;
esac
