#insert team

###########UPDATE bash.profile##############
INST_ROOT=/data/x/tools/team
FOUND=`grep $INST_ROOT/env/team.bashrc $HOME/.bash_profile`
if test -z "$FOUND" ; then
    echo "source /data/x/tools/team/env/team.bashrc"  > /tmp/$USER.bash_profile
    cat  $HOME/.bash_profile   | sed '/team/ d' >> /tmp/$USER.bash_profile
    cp   -f  /tmp/$USER.bash_profile   $HOME/.bash_profile
    echo "----------------- updated .bash_profile -------------"
fi

###########COMPATIBLE NEW VJ##############
NEW_VJ=`sed -n '/_vj_bashrc/p' ~/.bash_profile`
if [[ -n "$NEW_VJ" ]]; then
    sed -i '/_vj_bashrc/d' ~/.bash_profile
fi

NEW_VIMRC=`sed -n '/vimide\/.vimrc/p' ~/.vimrc`
if [[ -n "$NEW_VIMRC" ]]; then
    bash /data/x/tools/team/vimide/backup.sh
    rm -rf ~/.vimrc
fi

###########UPDATE IDE #####################
cd $HOME
if test -d $HOME/.vim  ; then
	rm -r $HOME/.vim
fi
VIM_SRC=/data/x/tools/team/vim
ln -s $VIM_SRC/runtime  .vim

CLEAR_OLD_RC="s/.+pylon-1.4.+_vimrc//g"
TIME_RC="s/.+team.+_vimrc//g"
############UPDATE .VIMRC ################
if test -e $HOME/.vimrc  ; then
    #rm -f $HOME/.vimrc
    echo "source  $VIM_SRC/runtime/_vimrc "  > /tmp/$USER.vimrc
    cat  $HOME/.vimrc | sed -r "$CLEAR_OLD_RC" | sed -r "$TIME_RC"  >> /tmp/$USER.vimrc
    cp   -f  /tmp/$USER.vimrc   $HOME/.vimrc
    echo "----------------- updated .vimrc -------------"
else
    ln -s $VIM_SRC/runtime/_vimrc  .vimrc
    echo "----------------- added new .vimrc -------------"
fi

mkdir -p $HOME/backup/vim
chmod -R 777 $HOME/backup
echo  "--------------- ide setup ok ---------------"

mkdir -p $HOME/devspace

chmod a+rx $HOME

OS=`uname`
if test $OS  = "Linux" ; then
    echo "LANG=zh_CN.UTF-8"  > $HOME/.i18n
    echo "----------- setup i18n to utf8----------"
fi
/data/x/tools/team/vimide/update.sh
echo "Happy using with the great XCODECRATF TEAM develop-env!"
