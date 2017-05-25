SVR=$1
scp ~/.ssh/id_rsa.pub  $SVR:/tmp/id_rsa.pub.$USER
ssh $SVR "mkdir -p ~/.ssh;  chmod 700 ~/.ssh ;  cat /tmp/id_rsa.pub.$USER >> ~/.ssh/authorized_keys ; chmod 600 ~/.ssh/authorized_keys "
