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
ignore_strict_host_checking 

map_sources () {
  mappings=""
  for var in "$@"
  do
    LOCAL_SOURCE=$(echo $var | cut -d ":" -f 1)
    REMOTE_SOURCE=$(echo $var | cut -d ":" -f 2)
    if [[ ! $REMOTE_SOURCE =~ ^/.* ]]; then
        if [[ $REMOTE_SOURCE =~ ^~/.* ]]; then
            REMOTE_SOURCE=$WORKSPACE_DIR/${REMOTE_SOURCE:2}
        else
            REMOTE_SOURCE=$WORKSPACE_DIR/$REMOTE_SOURCE
        fi
    fi
    mappings=$mappings" -v $LOCAL_SOURCE:$REMOTE_SOURCE"
  done
  echo $mappings
}
MAPPINGS=$(map_sources "$@")


#docker stop $CONTAINER_NAME 2>/dev/null

# docker run \
#   --detach \
#   --name $CONTAINER_NAME \
#   --privileged=true \
#   -v $DOCKER_SOCK:$DOCKER_SOCK \
#   -v $HOME:/home/$USERNAME \
#   $MAPPINGS \
#   -p $SSH_PORT:$SSH_PORT \
#   $CONTAINER_NAME
#   #--expose 2000-65535 \
#   #-p $HOST_HTTP_PORT:$HTTP_PORT \


docker run \
  --name $CONTAINER_NAME \
  --restart always \
  --privileged=true \
  --mount source=x64common,target=/home \
  --mount source=none,target=/home/$USERNAME/.docker \
  -v $HOME:/home/$USERNAME \
  -v $DOCKER_SOCK:$DOCKER_SOCK \
  $MAPPINGS \
  -p $SSH_PORT:$SSH_PORT \
  -d $CONTAINER_NAME
  #--expose 2000-65535 \
  #-p $HOST_HTTP_PORT:$HTTP_PORT \
  #--expose $SSH_PORT \
  #-v x64common:/home \ 
  # -v $DOCKER_SOCK:$DOCKER_SOCK \
  #--cap-add SYS_NICE \


