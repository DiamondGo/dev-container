SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )"
cd $SCRIPT_DIR
cd ..

USERID=$(id -u)
GROUPID=$(id -g)

USERNAME=$USER
# staff is already used by debian
GROUPNAME=macstaff

ignore_strict_host_checking () {
  ssh_config_dir=$HOME/.ssh
  ssh_config=$ssh_config_dir/config
  mkdir $ssh_config_dir 2>/dev/null
  touch $ssh_config

  localhost_setting=$(egrep '^\s*StrictHostKeyChecking\s+yes\s*' $ssh_config -B 1|egrep '^Host\s+localhost$')
  if [ ! -z "$localhost_setting" ]
  then
    echo "replace strict checking from yes to no"
    gsed '/Host localhost/!b;n;c\\tStrictHostKeyChecking no' -i $ssh_config
  fi

  ignore_localhost_setting=$(egrep '^\s*StrictHostKeyChecking\s+no\s*' $ssh_config -B 1|egrep '^Host\s+localhost$')
  if [ -z "$ignore_localhost_setting" ]
  then
    echo "ignore strict checking"
    echo "Host localhost" >> $ssh_config
    echo "  StrictHostKeyChecking no" >> $ssh_config
  fi
}

docker build \
  --build-arg USERID=$USERID \
  --build-arg GROUPID=$GROUPID \
  --build-arg USERNAME=$USERNAME \
  --build-arg GROUPNAME=$GROUPNAME \
  --build-arg SCRIPTDIR=$SCRIPT_DIR \
  -t dev-remote \
  $SCRIPT_DIR

ignore_strict_host_checking 

docker run \
  --rm \
  --detach \
  --name dev-remote \
  -v $HOME/.ssh:/home/$USERNAME/.ssh \
  -p 8022:22 \
  dev-remote
