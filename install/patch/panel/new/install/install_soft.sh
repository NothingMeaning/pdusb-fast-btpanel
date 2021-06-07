#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
mtype=$1
actionType=$2
name=$3
version=$4
. /www/server/panel/install/public.sh
serverUrl=$NODE_URL/install

if [ ! -f 'lib.sh' ];then
	wget -O lib.sh $serverUrl/$mtype/lib.sh
fi

libNull=`cat lib.sh`
if [ "$libNull" == '' ];then
	wget -O lib.sh $serverUrl/$mtype/lib.sh
fi

wget -O $name.sh $serverUrl/$mtype/$name.sh
tpatch=$(ls -1 /tmp/btp/patch/install/${name}*.patch 2>/dev/null)
if [ -n "$tpatch" ] ; then
        patch -p1 </tmp/btp/patch/install/${name}*.patch
fi
if [ "$actionType" == 'install' ];then
	bash lib.sh
fi
bash $name.sh $actionType $version
