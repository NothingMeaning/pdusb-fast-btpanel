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

Root_Path=`cat /var/bt_setupPath.conf`
Setup_Path=$Root_Path/server/apache
run_path='/root'
apache_24='2.4.46'
apache_22_version='2.2.34'
opensslVersion="1.1.1j"
nghttp2Version="1.43.0"
aprVersion="1.6.5"
aprutilVersion="1.6.1"
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

if [ -z "${OS_VER}" ] || [ "${sysCheck}" != "x86_64" ];then
	wget -O apache.sh ${download_Url}/install/0/apache.sh && sh apache.sh $1 $2
	exit;
fi

if [ -z "${cpuCore}" ]; then
	cpuCore="1"
fi
System_Lib(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ] ; then
		Pack="gcc gcc-c++ lua lua-devel ${RPM_NGHTTP2_PACK}"
		${PM} install ${Pack} -y
		sleep 1
		pkg-config lua --cflags
		if [ $? -eq 0 ];then
			ENABLE_LUA="--enable-lua"
		fi
	elif [ "${PM}" == "apt-get" ]; then
		Pack="gcc g++ lua5.1 lua5.1-dev lua-cjson lua-socket libnghttp2-dev"
		${PM} install ${Pack} -y
		ENABLE_LUA="--enable-lua"
	fi
}
Service_Add(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
		chkconfig --add httpd
		chkconfig --level 2345 httpd on
	elif [ "${PM}" == "apt-get" ]; then
		update-rc.d httpd defaults
	fi 
}
Service_Del(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
		chkconfig --del httpd
		chkconfig --level 2345 httpd off
	elif [ "${PM}" == "apt-get" ]; then
		update-rc.d httpd remove
	fi
}

Mpm_Opt(){
	MemInfo=$(free -g |grep Mem |awk '{print $2}')
	ServerLimit=$((400*(1+${MemInfo})))
	if [ "${ServerLimit}" -gt "20000" ]; then
		ServerLimit="20000"
	fi
	echo "ServerLimit" ${ServerLimit} >> ${Setup_Path}/conf/httpd.conf
	wget -O ${Setup_Path}/conf/extra/httpd-mpm.conf ${download_Url}/conf/httpd-mpm.conf
	sed -i 's/$work/'${ServerLimit}'/g' ${Setup_Path}/conf/extra/httpd-mpm.conf 
}
Install_cjson()
{
	if [ ! -f /usr/local/lib/lua/5.1/cjson.so ];then
		wget -O lua-cjson-2.1.0.tar.gz $download_Url/install/src/lua-cjson-2.1.0.tar.gz -T 20
		tar xvf lua-cjson-2.1.0.tar.gz
		rm -f lua-cjson-2.1.0.tar.gz
		cd lua-cjson-2.1.0
		make -j${cpuCore}
		make install
		cd ..
		rm -rf lua-cjson-2.1.0
	fi

	if [ -f /usr/local/lib/lua/5.1/cjson.so ];then
		if [ -d "/usr/lib64/lua/5.1" ];then
			ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib64/lua/5.1/cjson.so 
		fi
		if [ -d "/usr/lib/lua/5.1" ];then
			ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib/lua/5.1/cjson.so 
		fi
	fi
}
SSL_Check(){
	sslOn=$(cat /www/server/panel/vhost/apache/*.conf|grep "SSLEngine On")
	if [ "${sslOn}" != "" ]; then
		sed -i '/Listen 80/a\Listen 443' ${Setup_Path}/conf/httpd.conf
	fi
}

CheckPHPVersion()
{
	PHPVersion=""
	for phpVer in 52 53 54 55 56 70 71 72 73 74 80;
	do
		if [ -d "/www/server/php/${phpVer}/bin" ]; then
			PHPVersion=${phpVer}
		fi
	done
	if [ "${PHPVersion}" != '' ];then
		sed -i "s#VERSION#$PHPVersion#" ${Setup_Path}/conf/extra/httpd-vhosts.conf
	fi
}

Install_Apache_24()
{
	Install_cjson
	cd ${run_path}

	Run_User="www"
	wwwUser=$(cat /etc/passwd|grep www)
	if [ -z "${wwwUser}" ];then
		groupadd ${Run_User}
		useradd -s /sbin/nologin -g ${Run_User} ${Run_User}
	fi
	
	if [ "${actionType}" = "install" ]; then
		Uninstall_Apache
		mkdir -p ${Setup_Path}
		rm -rf ${Setup_Path}/*
		rm -f /etc/init.d/httpd
	fi

	cd /www/server	
	wget -O bt-${apacheVersion}.deb ${download_Url}/deb/${OS_SYS}/${OS_VER}/bt-${apacheVersion}.deb
	dpkg -i bt-${apacheVersion}.deb
	echo ${apacheVersion} > ${Setup_Path}/deb.pl

	
	if [ ! -f "${Setup_Path}/bin/httpd" ];then
		echo '========================================================'
		GetSysInfo
		echo -e "ERROR: apache-${apache_24} installation failed.";
		rm -rf ${Setup_Path}
		exit 0;
	fi

	ln -sf ${Setup_Path}/bin/httpd /usr/bin/httpd
	ln -sf ${Setup_Path}/bin/ab /usr/bin/ab

	mkdir ${Setup_Path}/conf/vhost
	mkdir -p $Root_Path/wwwroot/default
	mkdir -p $Root_Path/wwwlogs
	mkdir -p $Root_Path/server/phpmyadmin
	chmod -R 755 ${Setup_Path}/conf/vhost
	chmod -R 755 $Root_Path/wwwroot/default
	chown -R www.www $Root_Path/wwwroot/default

	mv ${Setup_Path}/conf/httpd.conf ${Setup_Path}/conf/httpd.conf.bak

	wget -O ${Setup_Path}/conf/httpd.conf ${download_Url}/conf/httpd24.conf
	wget -O ${Setup_Path}/conf/extra/httpd-vhosts.conf ${download_Url}/conf/httpd-vhosts.conf
	wget -O ${Setup_Path}/conf/extra/httpd-default.conf ${download_Url}/conf/httpd-default.conf
	wget -O ${Setup_Path}/conf/extra/mod_remoteip.conf ${download_Url}/conf/mod_remoteip.conf

	Mpm_Opt

	sed -i "s#/www/wwwroot/default#/www/server/phpmyadmin#" ${Setup_Path}/conf/extra/httpd-vhosts.conf
	sed -i "s#IncludeOptional conf/vhost/\*\.conf#IncludeOptional /www/server/panel/vhost/apache/\*\.conf#" ${Setup_Path}/conf/httpd.conf
	sed -i '/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/s/^/#/' ${Setup_Path}/conf/httpd.conf
	sed -i '/#LoadModule mpm_event_module modules\/mod_mpm_event.so/s/^#//' ${Setup_Path}/conf/httpd.conf

	SSL_Check
	CheckPHPVersion
	
	wget -O ${Setup_Path}/htdocs/index.html ${download_Url}/error/index.html -T20

	AA_PANEL_CHECK=$(cat /www/server/panel/config/config.json|grep "English")
	if [ "${AA_PANEL_CHECK}" ];then
		\cp -rf /www/server/panel/data/empty.html /www/server/apache/htdocs/index.html
		chmod 644 /www/server/apache/htdocs/index.html
		wget -O /www/server/panel/vhost/apache/0.default.conf ${download_Url}/conf/apache/en.0.default.conf
	fi
	wget -O /etc/init.d/httpd ${download_Url}/init/init.d.httpd -T20
	chmod +x /etc/init.d/httpd

	Service_Add
	
	mkdir -p /www/server/phpinfo
	/etc/init.d/httpd start
	
	cd ${Setup_Path}
	
	echo "2.4" > ${Setup_Path}/version.pl
	rm -f /www/server/panel/vhost/apache/phpinfo.conf
	rm -rf ${Setup_Path}/src
}

Install_Apache_22()
{
	Uninstall_Apache
	cd ${run_path}
	Run_User="www"
	groupadd ${Run_User}
	useradd -s /sbin/nologin -g ${Run_User} ${Run_User}
	
	mkdir -p ${Setup_Path}
	rm -rf ${Setup_Path}/*
	rm -f /etc/init.d/httpd
	cd ${Setup_Path}
	if [ ! -f "${Setup_Path}/src.tar.gz" ];then
		wget -O ${Setup_Path}/src.tar.gz ${download_Url}/src/httpd-${apache_22_version}.tar.gz -T20
	fi
	tar -zxvf src.tar.gz
	mv httpd-${apache_22_version} src
	cd src
	./configure --prefix=${Setup_Path} --enable-mods-shared=most --with-ssl=/usr/local/openssl --enable-headers --enable-mime-magic --enable-proxy --enable-so --enable-rewrite --enable-ssl --enable-deflate --enable-suexec --with-included-apr --with-mpm=prefork --with-expat=builtin
	make && make install
		
	if [ ! -f "${Setup_Path}/bin/httpd" ];then
		echo '========================================================'
		GetSysInfo
		echo -e "ERROR: apache-${apache_22_version} installation failed.";
		rm -rf ${Setup_Path}
		exit 0;
	fi

	mv ${Setup_Path}/conf/httpd.conf ${Setup_Path}/conf/httpd.conf.bak

	mkdir -p ${Setup_Path}/conf/vhost
	mkdir -p $Root_Path/wwwroot/default
	mkdir -p $Root_Path/wwwlogs
	chmod -R 755 $Root_Path/wwwroot/default
	chown -R www.www $Root_Path/wwwroot/default

	wget -O ${Setup_Path}/conf/httpd.conf ${download_Url}/conf/httpd22.conf -T20
	wget -O ${Setup_Path}/conf/extra/httpd-vhosts.conf ${download_Url}/conf/httpd-vhosts-22.conf -T20
	wget -O ${Setup_Path}/conf/extra/httpd-default.conf ${download_Url}/conf/httpd-default.conf -T20
	wget -O ${Setup_Path}/conf/extra/mod_remoteip.conf ${download_Url}/conf/mod_remoteip.conf -T20
	sed -i "s#Include conf/vhost/\*\.conf#Include /www/server/panel/vhost/apache/\*\.conf#" ${Setup_Path}/conf/httpd.conf
	sed -i "s#/www/wwwroot/default#/www/server/phpmyadmin#" ${Setup_Path}/conf/extra/httpd-vhosts.conf
	sed -i '/LoadModule php5_module/s/^/#/' ${Setup_Path}/conf/httpd.conf

	
	mkdir ${Setup_Path}/conf/vhost

	wget -O ${Setup_Path}/htdocs/index.html ${download_Url}/error/index.html -T20
	wget -O /etc/init.d/httpd ${download_Url}/init/init.d.httpd -T20
	chmod +x /etc/init.d/httpd
	chkconfig --add httpd
	
	chkconfig --level 2345 httpd on
	ln -sf ${Setup_Path}/bin/httpd /usr/bin/httpd

	cd ${Setup_Path}
	rm -f src.tar.gz
	mkdir -p /www/server/phpinfo
	echo "2.2" > ${Setup_Path}/version.pl
	echo '2.2' > /var/bt_apacheVersion.pl
	cat > /www/server/panel/vhost/apache/phpinfo.conf <<EOF
<VirtualHost *:80>
DocumentRoot "/www/server/phpinfo"
ServerAdmin phpinfo
ServerName 127.0.0.2
<Directory "/www/server/phpinfo">
	SetOutputFilter DEFLATE
	Options FollowSymLinks
	AllowOverride All
	Order allow,deny
	Allow from all
	DirectoryIndex index.php index.html index.htm default.php default.html default.htm
</Directory>
</VirtualHost>
EOF
	if [ -f "/www/server/php/52/libphp5.so" ];then
		\cp -a -r /www/server/php/52/libphp5.so /www/server/apache/modules/libphp5.so
		sed -i '/#LoadModule php5_module/s/^#//' ${Setup_Path}/conf/httpd.conf
	fi
	if [ -f "/www/server/php/53/libphp5.so" ];then
		\cp -a -r /www/server/php/53/libphp5.so /www/server/apache/modules/libphp5.so
		sed -i '/#LoadModule php5_module/s/^#//' ${Setup_Path}/conf/httpd.conf
	fi
	if [ -f "/www/server/php/54/libphp5.so" ];then
		\cp -a -r /www/server/php/54/libphp5.so /www/server/apache/modules/libphp5.so
		sed -i '/#LoadModule php5_module/s/^#//' ${Setup_Path}/conf/httpd.conf
	fi
	
	rm -f /www/server/panel/vhost/apache/btwaf.conf
	rm -f /www/server/panel/vhost/apache/total.conf
	
	if [ -f /www/server/apache/modules/libphp5.so ];then
		/etc/init.d/httpd start
	fi
}
Bt_Check(){
	checkFile="/www/server/panel/install/check.sh"
	wget -O ${checkFile} ${download_Url}/tools/check.sh			
	. ${checkFile} 
}
Uninstall_Apache()
{
	if [ -f "/etc/init.d/httpd" ];then
		Service_Del
		/etc/init.d/httpd stop
		rm -f /etc/init.d/httpd
	fi
	pkill -9 httpd
	[ -f "${Setup_Path}/deb.pl" ] && apt-get remove bt-$(cat ${Setup_Path}/deb.pl) -y
	rm -rf ${Setup_Path}
	rm -f /usr/bin/httpd
}

actionType=$1
version=$2

if [ "$actionType" == "install" ] || [ "${actionType}" == "update" ];then
	System_Lib
	if [ "$version" == "2.2" ];then
		Install_Apache_22
	else
		apacheVersion="apache24"
		Install_Apache_24
	fi
	Bt_Check
elif [ "$actionType" == "uninstall" ];then
	Uninstall_Apache
fi

