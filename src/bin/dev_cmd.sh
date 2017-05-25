FILE_PATH=`dirname $0`
CUR_PATH=`pwd`
ABS_PATH= $CUR_PATH/$FILE_PATH
if ! test -e $ABS_PATH/dev_cmd.sh  ; then 
    ABS_PATH=`which dev_cmd.sh`
    ABS_PATH=`dirname $ABS_PATH`
fi
cd  $ABS_PATH
echo "****************************************************"
echo "*************** Game Team Env Tools ****************"
echo "[s] syn  team env "
echo "[a] authorization me! "
echo "[p] scp file "
echo "[k] syn php pkg "
echo "***************************************************"
read cmd
if test $cmd == "s"  ;
then  
    sudo -u search ./svrs/wanda_svr.sh ./cmds/syn_team.sh
fi

if test $cmd == "a"  ;
then  
    ./svrs/wanda_svr.sh ./cmds/auth2.sh
fi


if test $cmd == "p"  ;
then  
    echo "please input file !"
    read file
    if test -e $file ; then 
        ./svrs/wanda_svr.sh  ./cmds/scp.sh  $file
    else
        echo "$file not  exist!"
    fi
fi


if test $cmd == "k"  ;
then  
    echo "please input file !"
    read pkg
    sudo -u search ./svrs/wanda_svr.sh  ./cmds/call_gsh.sh  cmds/syn_phppkg.sh $pkg
fi

