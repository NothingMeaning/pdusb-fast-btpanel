#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

public_file=/www/server/panel/install/public.sh
publicFileMd5=$(md5sum ${public_file} 2>/dev/null|awk '{print $1}')
md5check="a70364b7ce521005e7023301e26143c5"
if [ "${publicFileMd5}" != "${md5check}"  ]; then
	wget -O Tpublic.sh http://download.bt.cn/install/public.sh -T 20;
	publicFileMd5=$(md5sum Tpublic.sh 2>/dev/null|awk '{print $1}')
	if [ "${publicFileMd5}" == "${md5check}"  ]; then
		\cp -rpa Tpublic.sh $public_file
	fi
	rm -f Tpublic.sh
fi
. $public_file
download_Url=$NODE_URL

ubuntuVerCheck=$(cat /etc/issue|grep "Ubuntu 18")
debianVerCheck=$(cat /etc/issue|grep Debian|grep 10)
sysCheck=$(uname -m)

UBUNTU_VER=$(cat /etc/issue|grep -i ubuntu|awk '{print $2}'|cut -d. -f1)
DEBIAN_VER=$(cat /etc/issue|grep -i debian|awk '{print $3}')
if [ "${UBUNTU_VER}" == "18" ] || [ "${UBUNTU_VER}" == "20" ];then
	OS_SYS="ubuntu"
	OS_VER="${UBUNTU_VER}"
elif [ "${DEBIAN_VER}" == "10" ]; then
	OS_SYS="debian"
	OS_VER="${DEBIAN_VER}"
fi

if [ -z "${OS_VER}" ] || [ "${sysCheck}" != "x86_64" ] || [ "$2" == "openresty" ] || [ "${2}" == "1.18.gmssl" ];then
	wget -O nginx.sh ${download_Url}/install/0/nginx.sh && sh nginx.sh $1 $2
	exit;
fi

Root_Path=$(cat /var/bt_setupPath.conf)
Setup_Path=$Root_Path/server/nginx
run_path="/root"
Is_64bit=$(getconf LONG_BIT)

if [ -z "${cpuCore}" ]; then
	cpuCore="1"
fi

System_Lib(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ] ; then
		Pack="curl curl-devel libtermcap-devel ncurses-devel libevent-devel readline-devel libuuid-devel"
		${PM} install ${Pack} -y
	elif [ "${PM}" == "apt-get" ]; then
		Pack="libgd3 libgd-dev libevent-dev libncurses5-dev libreadline-dev uuid-dev"
		${PM} install ${Pack} -y
	fi
}
Service_Add(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
		chkconfig --add nginx
		chkconfig --level 2345 nginx on
	elif [ "${PM}" == "apt-get" ]; then
		update-rc.d nginx defaults
	fi 
}
Service_Del(){
 	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
		chkconfig --del nginx
		chkconfig --level 2345 nginx off
	elif [ "${PM}" == "apt-get" ]; then
		update-rc.d nginx remove
	fi
}
Install_Jemalloc(){
	if [ ! -f '/usr/local/lib/libjemalloc.so' ]; then
		wget -O jemalloc-5.0.1.tar.bz2 ${download_Url}/src/jemalloc-5.0.1.tar.bz2
		tar -xvf jemalloc-5.0.1.tar.bz2
		cd jemalloc-5.0.1
		./configure
		make && make install
		ldconfig
		cd ..
		rm -rf jemalloc*
	fi
}
Install_LuaJIT()
{
	if [ ! -d '/usr/local/include/luajit-2.0' ];then
		wget -c -O LuaJIT-2.0.4.tar.gz ${download_Url}/install/src/LuaJIT-2.0.4.tar.gz -T 10
		tar xvf LuaJIT-2.0.4.tar.gz
		cd LuaJIT-2.0.4
		make linux
		make install
		cd ..
		rm -rf LuaJIT-*
		export LUAJIT_LIB=/usr/local/lib
		export LUAJIT_INC=/usr/local/include/luajit-2.0/
		ln -sf /usr/local/lib/libluajit-5.1.so.2 /usr/local/lib64/libluajit-5.1.so.2
		echo "/usr/local/lib" >> /etc/ld.so.conf
		ldconfig
	fi
}
Install_cjson()
{
	if [ ! -f /usr/local/lib/lua/5.1/cjson.so ];then
		wget -O lua-cjson-2.1.0.tar.gz $download_Url/install/src/lua-cjson-2.1.0.tar.gz -T 20
		tar xvf lua-cjson-2.1.0.tar.gz
		rm -f lua-cjson-2.1.0.tar.gz
		cd lua-cjson-2.1.0
		make
		make install
		cd ..
		rm -rf lua-cjson-2.1.0
	fi
}
Install_Nginx(){
	Run_User="www"
	wwwUser=$(cat /etc/passwd|grep www)
	if [ "${wwwUser}" == "" ];then
		groupadd ${Run_User}
		useradd -s /sbin/nologin -g ${Run_User} ${Run_User}
	fi

	cd /www/server	
	wget -O bt-${nginxVersion}.deb ${download_Url}/deb/${OS_SYS}/${OS_VER}/bt-${nginxVersion}.deb
	dpkg -i bt-${nginxVersion}.deb
	echo ${nginxVersion} > ${Setup_Path}/deb.pl

	if [ "${version}" == "openresty" ];then
		ln -sf /www/server/nginx/nginx/html /www/server/nginx/html
		ln -sf /www/server/nginx/nginx/conf /www/server/nginx/conf
		ln -sf /www/server/nginx/nginx/logs /www/server/nginx/logs
		ln -sf /www/server/nginx/nginx/sbin /www/server/nginx/sbin
	fi

	ln -sf ${Setup_Path}/sbin/nginx /usr/bin/nginx

	rm -f nginx.tar.gz
}
Set_Conf(){
	Default_Website_Dir=$Root_Path'/wwwroot/default'
	mkdir -p ${Default_Website_Dir}
	mkdir -p ${Root_Path}/wwwlogs
	mkdir -p ${Setup_Path}/conf/vhost
	mkdir -p /usr/local/nginx/logs
	mkdir -p ${Setup_Path}/conf/rewrite

	wget -O ${Setup_Path}/conf/nginx.conf ${download_Url}/conf/nginx.conf -T20
	wget -O ${Setup_Path}/conf/pathinfo.conf ${download_Url}/conf/pathinfo.conf -T20
	wget -O ${Setup_Path}/conf/enable-php.conf ${download_Url}/conf/enable-php.conf -T20
	wget -O ${Setup_Path}/html/index.html ${download_Url}/error/index.html -T 5

	cat > ${Root_Path}/server/panel/vhost/nginx/phpfpm_status.conf<<EOF
server {
	listen 80;
	server_name 127.0.0.1;
	allow 127.0.0.1;
	location /nginx_status {
		stub_status on;
		access_log off;
	}
EOF
 	echo > /www/server/nginx/conf/enable-php-00.conf
	for phpV in 52 53 54 55 56 70 71 72 73 74 80
	do
		cat > ${Setup_Path}/conf/enable-php-${phpV}.conf<<EOF
	location ~ [^/]\.php(/|$)
	{
		try_files \$uri =404;
		fastcgi_pass  unix:/tmp/php-cgi-${phpV}.sock;
		fastcgi_index index.php;
		include fastcgi.conf;
		include pathinfo.conf;
	}
EOF
		cat >> ${Root_Path}/server/panel/vhost/nginx/phpfpm_status.conf<<EOF
	location /phpfpm_${phpV}_status {
		fastcgi_pass unix:/tmp/php-cgi-${phpV}.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
EOF
	done
	echo \} >> ${Root_Path}/server/panel/vhost/nginx/phpfpm_status.conf
	
	cat > ${Setup_Path}/conf/proxy.conf<<EOF
proxy_temp_path ${Setup_Path}/proxy_temp_dir;
proxy_cache_path ${Setup_Path}/proxy_cache_dir levels=1:2 keys_zone=cache_one:20m inactive=1d max_size=5g;
client_body_buffer_size 512k;
proxy_connect_timeout 60;
proxy_read_timeout 60;
proxy_send_timeout 60;
proxy_buffer_size 32k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 128k;
proxy_temp_file_write_size 128k;
proxy_next_upstream error timeout invalid_header http_500 http_503 http_404;
proxy_cache cache_one;
EOF
	
	cat > ${Setup_Path}/conf/luawaf.conf<<EOF
lua_shared_dict limit 10m;
lua_package_path "/www/server/nginx/waf/?.lua";
init_by_lua_file  /www/server/nginx/waf/init.lua;
access_by_lua_file /www/server/nginx/waf/waf.lua;
EOF

	mkdir -p /www/wwwlogs/waf
	chown www.www /www/wwwlogs/waf
	chmod 744 /www/wwwlogs/waf
	mkdir -p /www/server/panel/vhost
	wget -O waf.zip ${download_Url}/install/waf/waf.zip
	unzip -o waf.zip -d $Setup_Path/ > /dev/null
	if [ ! -d "/www/server/panel/vhost/wafconf" ];then
		mv $Setup_Path/waf/wafconf /www/server/panel/vhost/wafconf
	fi

	sed -i "s#include vhost/\*.conf;#include /www/server/panel/vhost/nginx/\*.conf;#" ${Setup_Path}/conf/nginx.conf
	sed -i "s#/www/wwwroot/default#/www/server/phpmyadmin#" ${Setup_Path}/conf/nginx.conf
	sed -i "/pathinfo/d" ${Setup_Path}/conf/enable-php.conf
	sed -i "s/#limit_conn_zone.*/limit_conn_zone \$binary_remote_addr zone=perip:10m;\n\tlimit_conn_zone \$server_name zone=perserver:10m;/" ${Setup_Path}/conf/nginx.conf
	sed -i "s/mime.types;/mime.types;\n\t\tinclude proxy.conf;\n/" ${Setup_Path}/conf/nginx.conf
	#if [ "${nginx_version}" == "1.12.2" ] || [ "${nginx_version}" == "openresty" ] || [ "${nginx_version}" == "1.14.2" ];then
	sed -i "s/mime.types;/mime.types;\n\t\t#include luawaf.conf;\n/" ${Setup_Path}/conf/nginx.conf
	#fi

	PHPVersion=""
	for phpVer in 52 53 54 55 56 70 71 72 73 74 80;
	do
		if [ -d "/www/server/php/${phpVer}/bin" ]; then
			PHPVersion=${phpVer}
		fi
	done

	if [ "${PHPVersion}" ];then
		\cp -r -a ${Setup_Path}/conf/enable-php-${PHPVersion}.conf ${Setup_Path}/conf/enable-php.conf
	fi

	AA_PANEL_CHECK=$(cat /www/server/panel/config/config.json|grep "English")
	if [ "${AA_PANEL_CHECK}" ];then
		\cp -rf /www/server/panel/data/empty.html /www/server/nginx/html/index.html
		chmod 644 /www/server/nginx/html/index.html
		wget -O /www/server/panel/vhost/nginx/0.default.conf ${download_Url}/conf/nginx/en.0.default.conf
	fi

	wget -O /etc/init.d/nginx ${download_Url}/init/nginx.init -T 5
	chmod +x /etc/init.d/nginx
}
Bt_Check(){
	checkFile="/www/server/panel/install/check.sh"
	if [ ! -f "${checkFile}" ];then
		wget -O ${checkFile} ${download_Url}/tools/check.sh
	fi
	checkFileMd5=$(md5sum ${checkFile}|awk '{print $1}')
	local md5Check="d3a76081aafd6493484a81cd446527b3"
	if [ "${checkFileMd5}" != "${md5Check}" ];then
		wget -O ${checkFile} ${download_Url}/tools/check.sh			
	fi
	. ${checkFile} 
}
Set_Version(){
	if [ "${version}" == "tengine" ]; then
		echo "-Tengine2.2.3" > ${Setup_Path}/version.pl
		echo "2.2.4(2.3.2)" > ${Setup_Path}/version_check.pl
	elif [ "${version}" == "openresty" ]; then
		echo "openresty" > ${Setup_Path}/version.pl
	else
		echo "${ngxVer}" > ${Setup_Path}/version.pl
	fi
}

Uninstall_Nginx()
{
	if [ -f "/etc/init.d/nginx" ];then
		Service_Del
		/etc/init.d/nginx stop
		rm -f /etc/init.d/nginx
	fi
	[ -f "${Setup_Path}/rpm.pl" ] && yum remove bt-$(cat ${Setup_Path}/rpm.pl) -y
	[ -f "${Setup_Path}/deb.pl" ] && apt-get remove bt-$(cat ${Setup_Path}/deb.pl) -y
	pkill -9 nginx
	rm -rf ${Setup_Path}
}

actionType=$1
version=$2

if [ "${actionType}" == "uninstall" ]; then
	Service_Del
	Uninstall_Nginx
else
	case "${version}" in
		'1.10')
		nginxVersion="nginx112"
		ngxVer="1.12.2"
		;;
		'1.12')
		nginxVersion="nginx112"
		ngxVer="1.12.2"
		;;
		'1.14')
		nginxVersion="nginx114"
		ngxVer="1.14.2"
		;;		
		'1.15')
		nginxVersion="nginx115"
		ngxVer="1.15.10"
		;;
		'1.16')
		nginxVersion="nginx116"
		ngxVer="1.16.1"
		;;
		'1.17')
		nginxVersion="nginx117"
		ngxVer="1.17.10"
		;;
		'1.18')
		nginxVersion="nginx118"
		ngxVer="1.18.0"
		;;
		'1.19')
		nginxVersion="nginx119"
		ngxVer="1.19.0"
		;;
		'1.20')
		nginxVersion="nginx120"
		ngxVer="1.20.0"
		;;
		'1.21')
		nginxVersion="nginx121"
		ngxVer="1.21.0"
		;;
		'1.8')
		nginxVersion="nginx108"
		ngxVer="1.8.1"
		;;
		'openresty')
		nginxVersion="openresty"
		;;
		*)
		nginxVersion="tengine"
		version="tengine"
		;;
	esac
	if [ "${actionType}" == "install" ];then
		if [ -f "/www/server/nginx/sbin/nginx" ]; then
			Uninstall_Nginx
		fi
		System_Lib
		Install_Jemalloc
		Install_LuaJIT
		Install_cjson
		Install_Nginx
		Set_Conf
		Set_Version
		Service_Add
		Bt_Check
		/etc/init.d/nginx start
	elif [ "${actionType}" == "update" ];then
		Download_Src
		Install_Configure
		Update_Nginx
	fi
fi


