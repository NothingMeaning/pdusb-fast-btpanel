#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
bt_lock(){
	curl -Ss --connect-timeout 3 http://www.bt.cn/api/panel/to_pjs
	/etc/init.d/bt 16
}

init_check(){
	CRACK_URL=(oss.yuewux.com download.btpanel.net 182.61.16.58);
	for url in ${CRACK_URL[@]};
	do
		CRACK_INIT=$(cat /etc/init.d/bt |grep ${url})
		if [ "${CRACK_INIT}" ];then
			bt_lock
		fi
		CRACK_TOOLS=$(cat /www/server/panel/tools.py|grep ${url})
		if [ "${CRACK_TOOLS}" ];then
			bt_lock
		fi
	done
}
rm -rf /www/server/panel/plugin/redisutil
init_check
