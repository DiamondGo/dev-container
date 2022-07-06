# set golang as the base image of the Dockerfile
FROM debian:latest

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
RUN apt-get install openssh-server -y
RUN ssh-keygen -A

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

#USER $USERNAME
#WORKDIR /home/$USERNAME
#RUN ssh-keygen -A

EXPOSE 22

# Set the default container command
# This can be overridden later when running a container
ENTRYPOINT ["/root/script/sshd.sh"]

