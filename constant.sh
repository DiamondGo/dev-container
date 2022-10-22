export SSH_PORT=3022
export HTTP_PORT=3000
export HOST_HTTP_PORT=3000
export USERNAME=$USER
# staff is already used by debian
export GROUPNAME=macstaff

export WORKSPACE_DIR=/home/$USER

[ $(uname -m) == 'x86_64' ] && export ARCH=amd64
[ $(uname -m) == 'arm64' ] && export ARCH=arm64

export GO_PACKAGE=go1.19.2.linux-${ARCH}.tar.gz

export DOCKER_SOCK=/var/run/docker.sock
export IMAGE_TAG=dev-remote-$USERNAME

export SECRET_TOKEN=changeyourpassword
