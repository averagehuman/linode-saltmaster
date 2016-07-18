#!/bin/bash

##################
# update hostname
##################
echo "$LINODE_HOSTNAME" > /etc/hostname

hostname -F /etc/hostname

ip=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')
grep $LINODE_HOSTNAME /etc/hosts || echo "$ip   $ip $LINODE_HOSTNAME" >> /etc/hosts

#################################
# update sshd config and restart
#################################
origfile=/etc/ssh/sshd_config
tmpfile=sshd_config.tmp

cp $origfile $tmpfile

test -n $ANSIBLE_SSH_PORT && sed "s/^Port[[:space:]]\+[[:digit:]]\+$/Port $ANSIBLE_SSH_PORT/" -i $tmpfile
sed "s/^PermitRootLogin[[:space:]].*$/PermitRootLogin no/" -i $tmpfile

mv $tmpfile $origfile

systemctl restart sshd

