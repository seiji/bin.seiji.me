#!/usr/bin/env bash

# this script requires gcc, make, patch 
# yum -y install gcc
# yum -y install make
# yum -y install patch
SOURCE_DIR=/usr/local/src
USER-logadmin

# user for daemontools
groupadd $USER
id $USER || useradd -s /sbin/nologin -d /dev/null -g $USER -M $USER

#
cd $SOURCE_DIR
wget http://cr.yp.to/daemontools/daemontools-0.76.tar.gz
tar -zxf daemontools-0.76.tar.gz
cd admin/daemontools-0.76/

wget http://qmail.org/moni.csi.hu/pub/glibc-2.3.1/daemontools-0.76.errno.patch
patch -s -p1 <./daemontools-0.76.errno.patch

./package/install

# for centos6
SVSCAN_CONF=/etc/init/svscan.conf 
if [ ! -s $SVSCAN_CONF ]; then
    cat <<EOF > $SVSCAN_CONF

start on runlevel [12345]
respawn
exec /command/svscanboot

EOF

initctl reload-configuration
initctl start svscan
fi

# add service command
cat <<'EOF' >/command/add_service
#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin
export PATH
#
# usage
#
usage() {
  cat <<EOS
usage:
  $0 <service name>

EOS
  exit 1
}

#
# main
#
[ $# = 1 ] || usage

svdir=/service
svname=$(basename $1)
acct_name=logadmin
acct_group=logadmin

[ -d ${svdir}  ] || usage
[ -z ${svname} ] && usage
[ -d ${svdir}/.${svname} ] && usage
id ${acct_name} 2>&1 >/dev/null || { echo "no such acct: ${acct_name}"; usage; }


# directory, file
mkdir    ${svdir}/.${svname}
chmod +t ${svdir}/.${svname}
mkdir    ${svdir}/.${svname}/log
mkdir    ${svdir}/.${svname}/log/main
touch    ${svdir}/.${svname}/log/status
chown ${acct_name}:${acct_group} ${svdir}/.${svname}/log/main
chown ${acct_name}:${acct_group} ${svdir}/.${svname}/log/status

# run script

cat <<EOS > ${svdir}/.${svname}/run
#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin
export PATH

exec 2>&1
sleep 3

EOS
chmod +x ${svdir}/.${svname}/run


cat <<EOS > ${svdir}/.${svname}/log/run
#!/bin/sh
exec setuidgid ${acct_name} multilog t s1000000 n100 ./main
EOS

chmod +x ${svdir}/.${svname}/log/run

EOF
#
chmod +x /command/add_service

