LOGROOT=/data/logs/project
G_PROJ=""
function get_proj() {
    CUR_PATH=`pwd`
    PRJ=`basename $CUR_PATH`
    if test -e $LOGROOT/$PRJ ; then
        G_PROJ=$PRJ
    else
        echo "没有找到日志目录 $LOGROOT/$PRJ"
        exit;
    fi
}
function  tail_mutifile () {
    NAMES=$1
    DATE=$2
    PRJ=$3

    LOGFILE="" 
    
    NAMES=`echo $NAMES | sed "s/,/ /g"`
    for I  in `echo $NAMES` ;  do
        ILOG="$LOGROOT/$PRJ/$I/$DATE.log"
        if test -e $LOGFILE ; then
            LOGFILE="$LOGFILE $ILOG"
        fi

    done
    tail -f  $LOGFILE
}

function help() {
    echo "根据当前的目录名，来查看项目日志"
    echo "wlog pylon,data -1 "
    echo "wlog -a "
    echo "wlog -a -1"
}



DATE=`date  +%Y/%m/%d/%H`




case $# in
    0)
        get_proj ;
        ls $LOGROOT/$G_PROJ
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
        get_proj ;
        tail_mutifile $LOGNAMES  $DATE  $G_PROJ ;
        ;;
    2)
        get_proj ;
        LOGNAMES=$1
        DATA=`date -d "$2 hour" +%Y/%m/%d/%H`
        tail_mutifile $LOGNAMES  $DATE  $G_PROJ ;
        ;;
esac
