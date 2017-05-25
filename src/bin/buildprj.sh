#!/bin/bash
echo '========================================================================='
echo '    Embracing the (mighty fabulous awesome ...) PHP 5.3 with php-fpm     '
echo '========================================================================='
read -p '请输入项目名称 [PRJ_NAME]:' PRJ_NAME

if [ -z $PRJ_NAME ]
then
   echo "Ooops! can't do anything without a project name."
   exit 1
fi

PRJ_ROOT=$HOME/devspace/$PRJ_NAME
TEAM_HOME=$(cd $(dirname "$0")"/../" && pwd)

[ ! -d $PRJ_ROOT ] && mkdir -p $PRJ_ROOT

/data/x/tools/rigger-ng/rg tpl $TEAM_HOME/tpl/pylon-1.1/ -o $PRJ_ROOT -v "PROJECT=$PRJ_NAME"

$TEAM_HOME/bin/reloadprjide.sh $PRJ_ROOT

echo Done! enjoying $PRJ_ROOT
