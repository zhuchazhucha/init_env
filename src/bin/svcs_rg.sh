CMD=$1
ROOT=/data/x/projects
RG=/data/x/tools/rigger-ng/rg
PRJS=`ls /data/x/projects`
echo $PRJS

for  pjs in $PRJS
do
    if  test -e  $ROOT/$pjs/_rg ; then
        cd $ROOT/$pjs ;
        # sudo $RG  start
        echo $ROOT/$pjs ;
        echo  $CMD
        sudo $RG  $CMD
    fi
done

SVCS=`ls /data/x/svcs`
echo $SVCS

ROOT=/data/x/svcs
for  svc in $SVCS
do
    if  test -e  $ROOT/$svc/_rg ; then
        cd $ROOT/$svc ;
        # sudo $RG  start
        echo $ROOT/$svc ;
        echo $RG $CMD
        sudo $RG  $CMD
    fi
done
