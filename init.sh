
origfile=/etc/ssh/sshd_config
tmpfile=sshd_config.tmp

cp $origfile $tmpfile

test -n $ANSIBLE_SSH_PORT && sed "s/^Port[[:space:]]\+[[:digit:]]\+$/Port $ANSIBLE_SSH_PORT/" -i $tmpfile
sed "s/^PermitRootLogin[[:space:]].*$/PermitRootLogin no/" -i $tmpfile

mv $tmpfile $origfile

systemctl restart sshd

