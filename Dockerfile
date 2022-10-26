# set golang as the base image of the Dockerfile
FROM --platform=linux/amd64 debian:latest

ARG USERID
ARG USERNAME
ARG GROUPID
ARG GROUPNAME
ARG SCRIPTDIR
ARG SSHPORT
ARG WORKSPACE_DIR
ARG SECRET_TOKEN
#ARG GO_PACKAGE

ENV USERID=$USERID
ENV USERNAME=$USERNAME
ENV GROUPID=$GROUPID
ENV GROUPNAME=$USERNAME
ENV SCRIPTDIR=$SCRIPTDIR
ENV SSHPORT=$SSHPORT
#ENV GO_PACKAGE=$GO_PACKAGE


# update
RUN apt-get update -y
RUN apt-get upgrade -y
# sshd
RUN apt-get install openssh-server -y
RUN ssh-keygen -A
# sudo
RUN apt-get install sudo -y
RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
# use custom ssh port
RUN sed -i "s/#Port\\s*22/Port $SSHPORT/g" /etc/ssh/sshd_config

# prepare dev software
RUN apt-get install vim file net-tools -y

# # install fpm
# RUN apt-get install ruby -y
# RUN gem install fpm
# # install rpmbuild
# RUN apt-get install python python2 -y
# RUN apt-get install rpm -y

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

# for openvscode server
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        sudo \
        wget \
        libatomic1 \
    && rm -rf /var/lib/apt/lists/*

# startup script
RUN mkdir -p $HOME/script
RUN echo "#!/bin/bash" >> $HOME/script/sshd.sh
RUN echo "sudo /etc/init.d/ssh restart" >> $HOME/script/sshd.sh
#RUN echo "sudo chown $USERNAME /var/run/docker.sock" >> $HOME/script/sshd.sh
RUN echo "while true; do sleep 3600; done" >> $HOME/script/sshd.sh
RUN chmod +x $HOME/script/sshd.sh
#
##EXPOSE 2000-65535

# build essential
#RUN apt-get update -y
#RUN apt-get install build-essential -y

# install go
# RUN wget https://go.dev/dl/$GO_PACKAGE -O /tmp/$GO_PACKAGE
# RUN tar xzvf /tmp/$GO_PACKAGE -C /usr/local/
# RUN rm -f /tmp/$GO_PACKAGE



ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=$WORKSPACE_DIR \
    USER=$USERNAME


ENTRYPOINT ["/root/script/sshd.sh"]
