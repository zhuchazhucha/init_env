#!/bin/bash
if [ -f ~/.agent.env ]; then
	. ~/.agent.env >/dev/null
	if ! kill -0 $SSH_AGENT_PID >/dev/null 2>&1; then
		echo "Stale agent file found. Spawning new agent..."
		eval `ssh-agent | tee ~/.agent.env`
		ssh-add ~/.ssh/id_rsa
		scp ~/.bash_profile  zuowenjian@172.19.0.13:~/
	fi

else
	echo "Starting ssh-agent..."
	eval `ssh-agent | tee ~/.agent.env`
	ssh-add ~/.ssh/id_rsa
	scp ~/.bash_profile  zuowenjian@172.19.0.13:~/

fi

echo "export SSH_AGENT_PID=$SSH_AGENT_PID";
