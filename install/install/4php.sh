#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

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
Setup_Path=$Root_Path/server/php
php_path=$Root_Path/server/php
mysql_dir=$Root_Path/server/mysql
mysql_config="${mysql_dir}/bin/mysql_config"
Is_64bit=`getconf LONG_BIT`
run_path='/root'
apacheVersion=`cat /var/bt_apacheVersion.pl`

php_52="5.2.17"
php_53="5.3.29"
php_54="5.4.45"
php_55='5.5.38'
php_56='5.6.40'
php_70='7.0.33'
php_71='7.1.33'
php_72='7.2.33'
php_73='7.3.26'
php_74='7.4.14'
php_80='8.0.2'
opensslVersion="1.0.2u"
openssl111Version="1.1.1i"
nghttp2Version="1.42.0"
curlVersion="7.70.0"


UBUNTU_VER=$(cat /etc/issue|grep -i ubuntu|awk '{print $2}'|cut -d. -f1)
DEBIAN_VER=$(cat /etc/issue|grep -i debian|awk '{print $3}')
if [ "${UBUNTU_VER}" == "18" ] || [ "${UBUNTU_VER}" == "20" ];then
	OS_SYS="ubuntu"
	OS_VER="${UBUNTU_VER}"
elif [ "${DEBIAN_VER}" == "10" ]; then
	OS_SYS="debian"
	OS_VER="${DEBIAN_VER}"
fi
sysCheck=$(uname -m)

if [ -z "${OS_VER}" ] || [ "${sysCheck}" != "x86_64" ] || [ "$2" == "7.4" ];then
	wget -O php.sh ${download_Url}/install/0/php.sh && sh php.sh $1 $2
	exit;
fi

if [ "$2" == "5.2" ] || [ "${apacheVersion}" == "2.2" ];then
	wget -O php.sh $download_Url/install/0/old/php.sh -T 5
	bash php.sh $1 $2
	exit;
fi

if [ -z "${cpuCore}" ]; then
	cpuCore="1"
fi

#if [ ! -f "/etc/bt_lib.lock" ];then
#	wget -O lib.sh $download_Url/install/0/lib.sh
#	bash lib.sh
#	rm -f lib.sh
#fi

Error_Msg(){
	if [ "${actionType}" == "install" ];then
		AC_TYPE="安装"
	elif [ "${actionType}" == "update" ]; then
		AC_TYPE="升级"
	fi

	EN_CHECK=$(cat /www/server/panel/config/config.json |grep English)
	echo '========================================================'
	GetSysInfo
	echo -e "ERROR: php-${phpVersion} ${actionType} failed.";
	if [ "${EN_CHECK}" ];then
		echo -e "Please submit to https://forum.aapanel.com for help"
	else 
		echo -e "${AC_TYPE}失败，请截图以上报错信息发帖至论坛www.bt.cn/bbs求助"
	fi
	exit 1;
}

System_Lib(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ] ; then
		Centos8Check=$(cat /etc/redhat-release|grep ' 8.'|grep -i centos)
		CentosStream8Check=$(cat /etc/redhat-release |grep -i "Centos Stream"|grep 8)
		if [ "${Centos8Check}" ] || [ "${CentosStream8Check}" ];then
			yum config-manager --set-enabled PowerTools
			yum config-manager --set-enabled powertools
		fi
		Pack="gcc gcc-c++ libsodium-devel sqlite-devel oniguruma-devel libwebp-devel libvpx-devel openssl-devel"
	elif [ "${PM}" == "apt-get" ]; then
		Pack="gcc g++ libsodium-dev libonig-dev libsqlite3-dev libcurl4-openssl-dev libwebp-dev libvpx-dev"
	fi
	${PM} install ${Pack} -y
}

Service_Add(){
	wget -O /etc/init.d/php-fpm-${php_version} ${download_Url}/init/php/php-fpm-${php_version}
	sed -i "s/# Provides:          php-fpm/# Provides:          php-fpm-"${php_version}"/g" /etc/init.d/php-fpm-${php_version}
	chmod +x /etc/init.d/php-fpm-${php_version}
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
		chkconfig --add php-fpm-${php_version}
		chkconfig --level 2345 php-fpm-${php_version} on

	elif [ "${PM}" == "apt-get" ]; then
		update-rc.d php-fpm-${php_version} defaults
	fi

	/etc/init.d/php-fpm-${php_version} start 
}

Service_Del(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
		chkconfig --del php-fpm-${php_version}
		chkconfig --level 2345 php-fpm-${php_version} off
	elif [ "${PM}" == "apt-get" ]; then
		update-rc.d php-fpm-${php_version} remove
	fi
	rm -f /etc/init.d/php-fpm-$php_version
}
Install_Openssl_1_0_2()
{
	if [ ! -f "/usr/local/openssl/bin/openssl" ];then
		cd ${run_path}
		wget ${download_Url}/src/openssl-${opensslVersion}.tar.gz
		tar -zxf openssl-${opensslVersion}.tar.gz
		cd openssl-${opensslVersion}
		./config --openssldir=/usr/local/openssl zlib-dynamic shared
		make -j${cpuCore} 
		make install
		echo  "/usr/local/openssl/lib" > /etc/ld.so.conf.d/zopenssl.conf
		ldconfig
		cd ..
		rm -f openssl-${opensslVersion}.tar.gz
		rm -rf openssl-${opensslVersion}
	fi
}

Install_Openssl_1_1_1(){
	openssl111Check=$(openssl version |grep 1.1.1)
	if [ ! -f "/usr/local/openssl111/bin/openssl" ] && [ -z "${openssl111Check}" ];then
		cd ${run_path}
		wget ${download_Url}/src/openssl-${openssl111Version}.tar.gz -T 20
		tar -zxf openssl-${openssl111Version}.tar.gz
		rm -f openssl-${openssl111Version}.tar.gz
		cd openssl-${openssl111Version}
		./config --prefix=/usr/local/openssl111 --openssldir=/usr/local/openssl111 enable-md2 enable-rc5 sctp zlib-dynamic shared -fPIC
		make -j${cpuCore}
		make install
		[ $? -ne 0 ] && Error_Msg
		echo "/usr/local/openssl111/lib" >> /etc/ld.so.conf.d/zopenssl111.conf
		ldconfig
		cd ..
		rm -rf openssl-${openssl111Version} 
	fi
}
Install_Curl()
{
	if [ "${PM}" == "yum" ];then
		CURL_OPENSSL_LIB_VERSION=$(/usr/local/curl/bin/curl -V|grep -oE OpenSSL.*[0-9][a-z]|cut -f 2 -d "/")
		OPENSSL_LIB_VERSION=$(/usr/local/openssl/bin/openssl version|awk '{print $2}')
	fi
	if [ ! -f "/usr/local/curl/bin/curl" ] || [ "${CURL_OPENSSL_LIB_VERSION}" != "${OPENSSL_LIB_VERSION}" ];then
		wget ${download_Url}/src/curl-${curlVersion}.tar.gz
		tar -zxf curl-${curlVersion}.tar.gz
		cd curl-${curlVersion}
		rm -rf /usr/local/curl	
		./configure --prefix=/usr/local/curl --enable-ares --without-nss --with-ssl=/usr/local/openssl
		make -j${cpuCore}
		make install
		cd ..
		rm -f curl-${curlVersion}.tar.gz
		rm -rf curl-${curlVersion}
	fi
}

Install_Curl_New(){
	if [ ! -f "/usr/local/curl_2/bin/curl" ];then
		curlVersion="7.74.0"
		wget ${download_Url}/src/curl-${curlVersion}.tar.gz
		tar -zxf curl-${curlVersion}.tar.gz
		cd curl-${curlVersion}
		rm -rf /usr/local/curl_2
		./configure --prefix=/usr/local/curl_2 --enable-ldap --enable-ldaps --with-brotli --with-libssh2 --with-libssh --enable-ares --with-gssapi --without-nss --enable-smb --with-libidn2 --with-ssl=/usr/local/openssl111
		[ $? -ne 0 ] && Error_Msg
		make -j${cpuCore}
		make install
		cd ..
		rm -f curl-${curlVersion}.tar.gz
		rm -rf curl-${curlVersion}
	fi
}

Install_Curl2(){
	LibCurlVer=$(/usr/local/curl/bin/curl -V|grep curl|awk '{print $2}'|cut -d. -f2)
	if [[ "${LibCurlVer}" -le "60" ]]; then
		if [ ! -f "/usr/local/curl2/bin/curl" ];then
			curlVer="7.64.1"
			wget ${download_Url}/src/curl-${curlVer}.tar.gz
			tar -xvf curl-${curlVer}.tar.gz
			cd curl-${curlVer}
			./configure --prefix=/usr/local/curl2 --enable-ares --without-nss --with-ssl=/usr/local/openssl
			make -j${cpuCore}
			make install
			cd ..
			rm -rf curl*
		fi
	fi
}

Install_Icu4c(){
	cd ${run_path}
	icu4cVer=$(/usr/bin/icu-config --version)
	if [ ! -f "/usr/bin/icu-config" ] || [ "${icu4cVer:0:2}" -gt "60" ];then
		wget -O icu4c-60_3-src.tgz ${download_Url}/src/icu4c-60_3-src.tgz
		tar -xvf icu4c-60_3-src.tgz
		cd icu/source
		./configure --prefix=/usr/local/icu
		make -j${cpuCore}
		make install
		[ -f "/usr/bin/icu-config" ] && mv /usr/bin/icu-config /usr/bin/icu-config.bak 
		ln -sf /usr/local/icu/bin/icu-config /usr/bin/icu-config
		echo "/usr/local/icu/lib" > /etc/ld.so.conf.d/zicu.conf
		ldconfig
		cd ../../
		rm -rf icu
		rm -f icu4c-60_3-src.tgz 
	fi
}
Install_Libzip(){
	if [ "${PM}" == "yum" ];then
		el=$(cat /etc/redhat-release|grep -iE 'CentOS|Red Hat'|grep -Eo '([0-9]+\.)+[0-9]+'|grep -Eo '^[0-9]')
		if [ "${el}" == "8" ];then
			yum install -y libzip-devel
		elif [ "${el}" ]; then
			mkdir libzip
			cd libzip
			wget -O libzip5-1.5.2.rpm ${download_Url}/rpm/remi/${el}/libzip5-1.5.2.rpm
			wget -O libzip5-devel-1.5.2.rpm ${download_Url}/rpm/remi/${el}/libzip5-devel-1.5.2.rpm
			wget -O libzip5-tools-1.5.2.rpm ${download_Url}/rpm/remi/${el}/libzip5-tools-1.5.2.rpm
			yum install * -y
			cd ..
			rm -rf libzip
		fi
	elif [ "${PM}" == "apt-get" ];then
		apt-get install libzip-dev -y
	fi
	autoconfVer=$(autoconf -V|grep 'GNU Autoconf'|awk '{print $4}'|grep -oE .[0-9]+|grep -oE [0-9]+)
	if [ "${autoconfVer}" -lt "69" ]; then
		wget ${download_Url}/src/autoconf-2.69.tar.gz
		tar -xvf autoconf-2.69.tar.gz
		cd autoconf-2.69
		./configure --prefix=/usr
		make && make install
		cd ..
		rm -rf autoconf*
	fi

}
Install_Onig(){
	onigCheck=$(pkg-config --list-all|grep onig)
	if [ -z "${onigCheck}" ];then
		cd ${run_path}
		onigVer="6.9.6"
		wget -O onig-${onigVer}.tar.gz ${download_Url}/src/onig-${onigVer}.tar.gz
		tar  -xvf onig-${onigVer}.tar.gz
		cd onig-${onigVer}
		./configure --prefix=/usr/local/onig
		make -j${cpuCore}
		make install
		cd ..
		rm -rf onig-${onigVer}*
	fi
}
Install_Libsodium(){
	if [ ! -f "/usr/local/libsodium/lib/libsodium.so" ];then
		cd ${run_path}
		libsodiumVer="1.0.18"
		wget ${download_Url}/src/libsodium-${libsodiumVer}-stable.tar.gz
		tar -xvf libsodium-${libsodiumVer}-stable.tar.gz
		rm -f libsodium-${libsodiumVer}-stable.tar.gz
		cd libsodium-stable
		./configure --prefix=/usr/local/libsodium
		make -j${cpuCore}
		make install
		cd ..
		rm -f libsodium-${libsodiumVer}-stable.tar.gz
		rm -rf libsodium-stable
	fi
	if [ "${php_version}" == "73" ];then
		if [ "${PM}" == "apt-get" ]; then
			GET_LIBSODIUM_VER=$(dpkg -l |grep libsodium-dev|awk '{print $3}'|cut -d '.' -f3|cut -d '-' -f1)
			if [ "${GET_LIBSODIUM_VER}" -lt "15" ];then
				apt-get remove -y libsodium-dev
			fi
		fi
	fi
}

Create_Fpm(){
	cat >${php_setup_path}/etc/php-fpm.conf<<EOF
[global]
pid = ${php_setup_path}/var/run/php-fpm.pid
error_log = ${php_setup_path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi-${php_version}.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_${php_version}_status
pm.max_children = 30
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 10
request_terminate_timeout = 100
request_slowlog_timeout = 30
slowlog = var/log/slow.log
EOF
}

Set_PHP_FPM_Opt()
{
	MemTotal=`free -m | grep Mem | awk '{print  $2}'`
	if [[ ${MemTotal} -gt 1024 && ${MemTotal} -le 2048 ]]; then
		sed -i "s#pm.max_children.*#pm.max_children = 50#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.start_servers.*#pm.start_servers = 5#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 5#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 10#" ${php_setup_path}/etc/php-fpm.conf
	elif [[ ${MemTotal} -gt 2048 && ${MemTotal} -le 4096 ]]; then
		sed -i "s#pm.max_children.*#pm.max_children = 80#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.start_servers.*#pm.start_servers = 5#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 5#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 20#" ${php_setup_path}/etc/php-fpm.conf
	elif [[ ${MemTotal} -gt 4096 && ${MemTotal} -le 8192 ]]; then
		sed -i "s#pm.max_children.*#pm.max_children = 150#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.start_servers.*#pm.start_servers = 10#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 10#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 30#" ${php_setup_path}/etc/php-fpm.conf
	elif [[ ${MemTotal} -gt 8192 && ${MemTotal} -le 16384 ]]; then
		sed -i "s#pm.max_children.*#pm.max_children = 200#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.start_servers.*#pm.start_servers = 15#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 15#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 30#" ${php_setup_path}/etc/php-fpm.conf
	elif [[ ${MemTotal} -gt 16384 ]]; then
		sed -i "s#pm.max_children.*#pm.max_children = 300#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.start_servers.*#pm.start_servers = 20#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 20#" ${php_setup_path}/etc/php-fpm.conf
		sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 50#" ${php_setup_path}/etc/php-fpm.conf
	fi
	#backLogValue=$(cat ${php_setup_path}/etc/php-fpm.conf |grep max_children|awk '{print $3*1.5}')
	#sed -i "s#listen.backlog.*#listen.backlog = "${backLogValue}"#" ${php_setup_path}/etc/php-fpm.conf	
	sed -i "s#listen.backlog.*#listen.backlog = 8192#" ${php_setup_path}/etc/php-fpm.conf
}

Set_Phpini(){

	sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${php_setup_path}/etc/php.ini
	sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php_setup_path}/etc/php.ini
	sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' ${php_setup_path}/etc/php.ini
	sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;sendmail_path =.*/sendmail_path = \/usr\/sbin\/sendmail -t -i/g' ${php_setup_path}/etc/php.ini
	sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,putenv,chroot,chgrp,chown,shell_exec,popen,proc_open,pcntl_exec,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,imap_open,apache_setenv/g' ${php_setup_path}/etc/php.ini
	sed -i 's/display_errors = Off/display_errors = On/g' ${php_setup_path}/etc/php.ini
	sed -i 's/error_reporting =.*/error_reporting = E_ALL \& \~E_NOTICE/g' ${php_setup_path}/etc/php.ini

	if [ "${php_version}" = "52" ]; then
		sed -i "s#extension_dir = \"./\"#extension_dir = \"${php_setup_path}/lib/php/extensions/no-debug-non-zts-20060613/\"\n#" ${php_setup_path}/etc/php.ini
		sed -i 's#output_buffering =.*#output_buffering = On#' ${php_setup_path}/etc/php.ini
		sed -i 's/; cgi.force_redirect = 1/cgi.force_redirect = 0;/g' ${php_setup_path}/etc/php.ini
		sed -i 's/; cgi.redirect_status_env = ;/cgi.redirect_status_env = "yes";/g' ${php_setup_path}/etc/php.ini
	fi

	if [ "${php_version}" -ge "56" ]; then
		if [ -f "/etc/pki/tls/certs/ca-bundle.crt" ];then
			crtPath="/etc/pki/tls/certs/ca-bundle.crt"
		elif [ -f "/etc/ssl/certs/ca-certificates.crt" ]; then
			crtPath="/etc/ssl/certs/ca-certificates.crt"
		fi
		sed -i "s#;openssl.cafile=#openssl.cafile=${crtPath}#" ${php_setup_path}/etc/php.ini
		sed -i "s#;curl.cainfo =#curl.cainfo = ${crtPath}#" ${php_setup_path}/etc/php.ini
	fi

	sed -i 's/expose_php = On/expose_php = Off/g' ${php_setup_path}/etc/php.ini
	
}

Ln_PHP_Bin()
{
	rm -f /usr/bin/php*
	rm -f /usr/bin/pear
	rm -f /usr/bin/pecl

    ln -sf ${php_setup_path}/bin/php /usr/bin/php
    ln -sf ${php_setup_path}/bin/phpize /usr/bin/phpize
    ln -sf ${php_setup_path}/bin/pear /usr/bin/pear
    ln -sf ${php_setup_path}/bin/pecl /usr/bin/pecl
    ln -sf ${php_setup_path}/sbin/php-fpm /usr/bin/php-fpm
}

Pear_Pecl_Set()
{
 	if [ "${php_version}" -le "73" ];then
		pear config-set php_ini ${php_setup_path}/etc/php.ini
		pecl config-set php_ini ${php_setup_path}/etc/php.ini
	fi
}

Install_Composer()
{
	if [ ! -f "/usr/bin/composer" ];then
		wget -O /usr/bin/composer ${download_Url}/install/src/composer.phar -T 20;
		chmod +x /usr/bin/composer
		if [ "${download_Url}" == "http://$CN:5880" ];then
			composer config -g repo.packagist composer https://packagist.phpcomposer.com
		fi
	fi
}
Install_PHP(){
	php_setup_path="/www/server/php/${php_version}"
	if [ "${php_version}" -ge "73" ];then
		Install_Libzip
		Install_Libsodium
	fi

	wget -O bt-php${php_version}.deb ${download_Url}/deb/${OS_SYS}/${OS_VER}/bt-php${php_version}.deb
	dpkg -i bt-php${php_version}.deb
	rm -f bt-php${php_version}.deb

	[ ! -f "${php_setup_path}/bin/php" ] && Error_Msg
	
	cd ${php_setup_path}
	rm -rf ${php_setup_path}/include
	wget -O ${OS_SYS}-${OS_VER}-php-${php_version}-include.tar.gz ${download_Url}/deb/src/${OS_SYS}-${OS_VER}-php-${php_version}-include.tar.gz
	tar -xvf ${OS_SYS}-${OS_VER}-php-${php_version}-include.tar.gz
	rm -f ${OS_SYS}-${OS_VER}-php-${php_version}-include.tar.gz

	echo "${phpVersion}" > ${php_setup_path}/version.pl
	echo bt-php${php_version} > ${php_setup_path}/deb.pl

	mkdir -p ${php_setup_path}/etc
	wget -O ${php_setup_path}/etc/php.ini ${download_Url}/conf/php/php.ini.${php_version}
}

Install_Zip_ext(){
	mkdir -p ${php_setup_path}/src/ext
	cd ${php_setup_path}/src/ext
	wget -O zip${php_version}.tar.gz ${download_Url}/rpm/src/zip${php_version}.tar.gz
	tar -xvf zip${php_version}.tar.gz
	rm -f zip${php_version}.tar.gz
	cd zip
	${php_setup_path}/bin/phpize
	./configure --with-php-config=${php_setup_path}/bin/php-config
	make && make install
	cd ../../

	if [ "${php_version}" == "73" ];then
		extFile="/www/server/php/73/lib/php/extensions/no-debug-non-zts-20180731/zip.so"
	elif [ "${php_version}" == "74" ]; then
		extFile="/www/server/php/74/lib/php/extensions/no-debug-non-zts-20190902/zip.so"
	elif [ "${php_version}" == "80" ]; then
		extFile="/www/server/php/80/lib/php/extensions/no-debug-non-zts-20200930/zip.so"
	fi

	if [ -f "${extFile}" ];then
		echo "extension = zip.so" >> ${php_setup_path}/etc/php.ini
	fi
}

Install_Zend(){
	mkdir -p /usr/local/zend/php${php_version}
	if [ "${php_version}" -lt "70" ];then
		echo "Install ZendGuardLoader for PHP ${version}"
		echo "unavailable now."
		echo "Write ZendGuardLoader to php.ini..."
		wget -O php-ZendGuardLoader.tar.gz ${download_Url}/src/php-ZendGuardLoader.tar.gz
		tar -xvf php-ZendGuardLoader.tar.gz > /dev/null
		mv zend/ZendGuardLoader-${php_version}-${Is_64bit}.so /usr/local/zend/php${php_version}/ZendGuardLoader.so
		rm -f php-ZendGuardLoader.tar.gz
		rm -rf zend
	fi
}

Download_Conf(){
	if [ ! -f "/www/server/nginx/conf/enable-php-${php_version}.conf" ];then
		wget -O /www/server/nginx/conf/enable-php-${php_version}.conf ${download_Url}/conf/enable-php-${php_version}.conf
	fi
}

SetPHPMyAdmin()
{
	if [ -f "/www/server/nginx/sbin/nginx" ]; then
		webserver="nginx"
	fi
	PHPVersion=""
	for phpV in 52 53 54 55 56 70 71 72 73 74 80
	do
		if [ -f "/www/server/php/${phpV}/bin/php" ]; then
			PHPVersion=${phpV}
		fi
	done

	[ -z "${PHPVersion}" ] && PHPVersion="00"
	if [ "${webserver}" == "nginx" ];then
		sed -i "s#$Root_Path/wwwroot/default#$Root_Path/server/phpmyadmin#" $Root_Path/server/nginx/conf/nginx.conf
		rm -f $Root_Path/server/nginx/conf/enable-php.conf
		\cp $Root_Path/server/nginx/conf/enable-php-$PHPVersion.conf $Root_Path/server/nginx/conf/enable-php.conf
		sed -i "/pathinfo/d" $Root_Path/server/nginx/conf/enable-php.conf
		/etc/init.d/nginx reload
	else
		sed -i "s#$Root_Path/wwwroot/default#$Root_Path/server/phpmyadmin#" $Root_Path/server/apache/conf/extra/httpd-vhosts.conf
		sed -i "0,/php-cgi/ s/php-cgi-\w*\.sock/php-cgi-${PHPVersion}.sock/" $Root_Path/server/apache/conf/extra/httpd-vhosts.conf
		/etc/init.d/httpd reload
	fi
}
Uninstall_PHP()
{
	if [ -f "/www/server/php/${php_version}/rpm.pl" ];then
		yum remove -y bt-php${php_version}
		[ ! -f "/www/server/php/${php_version}/bin/php" ] && exit 0;
	fi

	/etc/init.d/php-fpm-$php_version stop

	if [ -f "/www/server/php/${php_version}/deb.pl" ];then
		apt-get remove -y bt-php${php_version}
	fi

	rm -rf $php_path/$php_version

	if [ -f "$Root_Path/server/phpmyadmin/version.pl" ];then
		SetPHPMyAdmin
	fi

	for phpV in 52 53 54 55 56 70 71 72 73 74 80
	do
		if [ -f "/www/server/php/${phpV}/bin/php" ]; then
			rm -f /usr/bin/php
			ln -sf /www/server/php/${phpV}/bin/php /usr/bin/php
		fi
	done
}

actionType=$1
version=$2
php_version=${2/./}
if [ "$actionType" == 'install' ] || [ "$actionType" == 'update' ] ;then
	phpVersion=$(eval echo '$'{php_${php_version}})
	System_Lib
	Install_Openssl_1_0_2
	Install_Curl
	Install_Icu4c
	Install_PHP
	if [ "${php_version}" -ge "73" ];then
		Install_Zip_ext
	fi 
	Ln_PHP_Bin
	Create_Fpm
	Set_PHP_FPM_Opt
	Set_Phpini
	Download_Conf
	Install_Zend
	Pear_Pecl_Set
	Install_Composer
	Service_Add
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_PHP
	Service_Del
fi

