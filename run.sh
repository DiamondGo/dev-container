#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )"
cd $SCRIPT_DIR

source $SCRIPT_DIR/constant.sh

CONTAINER_NAME=dev-remote-$USERNAME
SOURCE_MAPPING=$1
if [ -z $SOURCE_MAPPING ]; then
    echo "no source mapping"
    exit 1
fi

ignore_strict_host_checking () {
  ssh_config_dir=$HOME/.ssh
  ssh_config=$ssh_config_dir/config
  mkdir $ssh_config_dir 2>/dev/null
  touch $ssh_config

  localhost_setting=$(egrep '^\s*StrictHostKeyChecking\s+yes\s*' $ssh_config -B 1|egrep '^Host\s+localhost$')
  if [ ! -z "$localhost_setting" ]; then
    echo "replace strict checking from yes to no"
    gsed '/Host localhost/!b;n;c\\tStrictHostKeyChecking no' -i $ssh_config
  fi

  ignore_localhost_setting=$(egrep '^\s*StrictHostKeyChecking\s+no\s*' $ssh_config -B 1|egrep '^Host\s+localhost$')
  if [ -z "$ignore_localhost_setting" ]; then
    echo "ignore strict checking"
    echo "Host localhost" >> $ssh_config
    echo "  StrictHostKeyChecking no" >> $ssh_config
  fi
}

map_source () {
    LOCAL_SOURCE=$(echo $1 | cut -d ":" -f 1)
    REMOTE_SOURCE=$(echo $1 | cut -d ":" -f 2)
    if [[ ! $REMOTE_SOURCE =~ ^/.* ]]; then
        if [[ $REMOTE_SOURCE =~ ^~/.* ]]; then
            REMOTE_SOURCE=/home/$USERNAME/${REMOTE_SOURCE:2}
        else
            REMOTE_SOURCE=/home/$USERNAME/$REMOTE_SOURCE
        fi
    fi
    echo $LOCAL_SOURCE:$REMOTE_SOURCE
}

ignore_strict_host_checking 



docker stop $CONTAINER_NAME 2>/dev/null

docker run \
  --detach \
  --name $CONTAINER_NAME \
  --privileged=true \
  -v $DOCKER_SOCK:$DOCKER_SOCK \
  -v $HOME:/home/$USERNAME \
  -v $(map_source $SOURCE_MAPPING) \
  -p $SSH_PORT:$SSH_PORT \
  --expose 2000-65535 \
  $CONTAINER_NAME


#docker run --net=host \
#          --cap-add SYS_NICE \
#          --name cvpdev_$USER \
#          --privileged=true \
#          -v /var/run/docker.sock:/var/run/docker.sock \
#          -v /home/$USER:/home/$USER \
#          -v /garage/$USER:/garage/$USER \
#          -v /etc/passwd:/etc/passwd \
#          -v /etc/shadow:/etc/shadow \
#          -v /etc/shadow-:/etc/shadow- \
#          -v /etc/group:/etc/group \
#          -v /etc/group-:/etc/group- \
#          --expose $port \
#          --entrypoint /bin/sh \
#          -d docker.corp.arista.io/cvp-dev \
#          -c "chmod 666 /dev/kvm && /usr/sbin/sshd -D -p $port"
