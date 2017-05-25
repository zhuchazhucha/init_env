export LANG=zh_CN.UTF-8
export shost=`hostname | sed 's/.ayibang.org//g'`
export TEAM_HOME=/data/x/tools/team
export PATH=/data/x/tools/rigger-ng:$TEAM_HOME/bin:/usr/local/bin:/usr/local/go/bin:$PATH

if [ "$TERM" = "cons25" ]
then
#we're on the system console or maybe telnetting in
export PS1='$shost:\[\e[32;1m\]\u@\H \w \$ \[\e[0m\]'
else
#we're not on the console, assume an xterm
export PS1='$shost:\[\e]2;\u @ \H\a\e[32;1m\]\w \$ \[\e[0m\] '
fi
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

alias ll='ls --color -l'
alias la='ls --color -lA'
alias ls='ls --color -F'


alias gpull='$TEAM_HOME/bin/gpull'
alias gpush='$TEAM_HOME/bin/gpush'

export DEV_SPACE=$HOME/devspace/


for i in `find $TEAM_HOME/env -name '*.env'`
do
  echo $i
  source $i
done
