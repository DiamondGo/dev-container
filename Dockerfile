# set golang as the base image of the Dockerfile
FROM golang:latest

ARG USERID
ARG USERNAME
ARG GROUPID
ARG GROUPNAME
ARG SCRIPTDIR

ENV USERID=$USERID
ENV USERNAME=$USERNAME
ENV GROUPID=$GROUPID
ENV GROUPNAME=$GROUPNAME
ENV SCRIPTDIR=$SCRIPTDIR


# update
RUN apt-get update -y
RUN apt-get upgrade -y
# sshd
RUN apt-get install openssh-server -y
RUN ssh-keygen -A
# other package
RUN apt-get install sudo -y
RUN sed -i "s/^%sudo\\s*ALL=(ALL:ALL)\\s*ALL$/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/g" /etc/sudoers
RUN sed -i "s/#Port\\s*22/Port 2022/g" /etc/ssh/sshd_config

# prepare dev software
RUN apt-get install vim -y

# map current user/group into image
RUN groupdel $(grep $GROUPID /etc/group|awk -F ':' '{print $1}') 2>/dev/null
RUN groupadd -g $GROUPID $GROUPNAME
RUN useradd -m -s /bin/bash -g $GROUPID -u $USERID $USERNAME
RUN usermod -G root,sudo $USERNAME
RUN echo $USERNAME:dev | chpasswd

# copy ssh keys
RUN mkdir -p /home/$USERNAME/.ssh
RUN chown $USERNAME:$GROUPNAME /home/$USERNAME/.ssh
RUN chmod 700 /home/$USERNAME/.ssh

RUN mkdir -p /root/script
RUN echo "#!/bin/bash" >> /root/script/sshd.sh
RUN echo "/etc/init.d/ssh restart" >> /root/script/sshd.sh
RUN echo "while true; do sleep 3600; done" >> /root/script/sshd.sh
RUN chmod +x /root/script/sshd.sh

# prepare gopath
RUN echo "export GOPATH=\$HOME/go" >> /home/$USERNAME/.bashrc
RUN echo "export GOROOT=/usr/local/go" >> /home/$USERNAME/.bashrc
RUN echo "export PATH=\$PATH:\$GOPATH/bin:\$GOROOT/bin" >> /home/$USERNAME/.bashrc
RUN mkdir -p /home/$USERNAME/go
RUN chown $USERNAME:$GROUPNAME /home/$USERNAME/go

#RUN ssh-keygen -A

EXPOSE 2000-65535

# Set the default container command
# This can be overridden later when running a container
ENTRYPOINT ["/root/script/sshd.sh"]


#USER $USERNAME
#WORKDIR /home/$USERNAME