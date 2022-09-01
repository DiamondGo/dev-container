# set golang as the base image of the Dockerfile
FROM golang:latest

ARG USERID
ARG USERNAME
ARG GROUPID
ARG GROUPNAME
ARG SCRIPTDIR
ARG SSHPORT

ENV USERID=$USERID
ENV USERNAME=$USERNAME
ENV GROUPID=$GROUPID
ENV GROUPNAME=$GROUPNAME
ENV SCRIPTDIR=$SCRIPTDIR
ENV SSHPORT=$SSHPORT


# update
RUN apt-get update -y
RUN apt-get upgrade -y
# sshd
RUN apt-get install openssh-server -y
RUN ssh-keygen -A
# other package
RUN apt-get install sudo -y
RUN sed -i "s/^%sudo\\s*ALL=(ALL:ALL)\\s*ALL$/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/g" /etc/sudoers
RUN sed -i "s/#Port\\s*22/Port $SSHPORT/g" /etc/ssh/sshd_config

# prepare dev software
RUN apt-get install vim net-tools -y
# install fpm
RUN apt-get install ruby -y
RUN gem install fpm
# install rpmbuild
RUN apt-get install python python2 -y
RUN apt-get install rpm -y
# install docker, https://docs.docker.com/engine/install/debian/
RUN apt-get install ca-certificates curl gnupg lsb-release -y
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update -y
RUN apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# map current user/group into image
RUN groupdel $(grep $GROUPID /etc/group|awk -F ':' '{print $1}') 2>/dev/null || echo no need to groupdel
RUN groupadd -g $GROUPID $GROUPNAME
RUN useradd -m -s /bin/bash -g $GROUPID -u $USERID $USERNAME
RUN usermod -G root,sudo,docker $USERNAME
RUN echo $USERNAME:dev | chpasswd
#RUN chown $USERNAME /var/run/docker.sock # file not exist in this stage

# copy ssh keys
#RUN mkdir -p /home/$USERNAME/.ssh
#RUN chown $USERNAME:$GROUPNAME /home/$USERNAME/.ssh
#RUN chmod 700 /home/$USERNAME/.ssh

RUN mkdir -p /root/script
RUN echo "#!/bin/bash" >> /root/script/sshd.sh
RUN echo "/etc/init.d/ssh restart" >> /root/script/sshd.sh
RUN echo "chown $USERNAME /var/run/docker.sock"
RUN echo "while true; do sleep 3600; done" >> /root/script/sshd.sh
RUN chmod +x /root/script/sshd.sh

# prepare gopath
#RUN echo "export GOPATH=\$HOME/go" >> /home/$USERNAME/.bashrc
#RUN echo "export GOROOT=/usr/local/go" >> /home/$USERNAME/.bashrc
#RUN echo "export PATH=\$PATH:\$GOPATH/bin:\$GOROOT/bin" >> /home/$USERNAME/.bashrc
#RUN mkdir -p /home/$USERNAME/go
#RUN chown $USERNAME:$GROUPNAME /home/$USERNAME/go

#RUN ssh-keygen -A

EXPOSE 2000-65535

# Set the default container command
# This can be overridden later when running a container
ENTRYPOINT ["/root/script/sshd.sh"]


#USER $USERNAME
#WORKDIR /home/$USERNAME
