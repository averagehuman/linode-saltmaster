#!/bin/bash

##################
# update hostname
##################
echo "$LINODE_HOSTNAME" > /etc/hostname

hostname -F /etc/hostname

ip=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')
grep $LINODE_HOSTNAME /etc/hosts || echo "$ip   $ip $LINODE_HOSTNAME" >> /etc/hosts

######################
# add privileged group
######################
groupadd saltadmin
usermod -a -G saltadmin $LINODE_SSH_USER

#################################
# update sshd config and restart
#################################
origfile=/etc/ssh/sshd_config
tmpfile=sshd_config.tmp

cp $origfile $tmpfile

sed "s/^Port[[:space:]]\+[[:digit:]]\+$/Port $ANSIBLE_SSH_PORT/" -i $tmpfile
sed "s/^[#]\?PermitRootLogin[[:space:]].*$/PermitRootLogin no/" -i $tmpfile
sed "s/^[#]\?PasswordAuthentication .*/PasswordAuthentication no/g" -i $tmpfile
sed "s/^[#]\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/g" -i $tmpfile
echo "AllowGroups saltadmin" >> $tmpfile
echo "AddressFamily inet" >> $tmpfile

mv $tmpfile $origfile

systemctl restart sshd


