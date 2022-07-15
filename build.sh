#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )"
cd $SCRIPT_DIR
cd ..

USERID=$(id -u)
GROUPID=$(id -g)

USERNAME=$USER
# staff is already used by debian
GROUPNAME=macstaff

IMAGE_TAG=dev-remote


docker rmi $IMAGE_TAG 2>/dev/null

docker build \
  --build-arg USERID=$USERID \
  --build-arg GROUPID=$GROUPID \
  --build-arg USERNAME=$USERNAME \
  --build-arg GROUPNAME=$GROUPNAME \
  --build-arg SCRIPTDIR=$SCRIPT_DIR \
  -t $IMAGE_TAG \
  $SCRIPT_DIR
