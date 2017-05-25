#!/bin/bash
echo '========================================================================='
echo '                  欢迎使用模板 '
echo '========================================================================='
adirname() { odir=`pwd`; cd `dirname $1`; pwd; cd "${odir}"; }
MYDIR=`adirname "$0"`
if test -e   /tmp/$USER/usetpl.sh  ; then
    rm /tmp/usetpl.sh
fi
/data/x/tools/rigger-ng/rigger tpl $MYDIR/cmdtpl/usetpl/ -o /tmp/$USER
SUC=$?
if test $SUC -eq 0  && test  -e   /tmp/$USER/usetpl.sh  ; then
    /tmp/$USER/usetpl.sh
fi
