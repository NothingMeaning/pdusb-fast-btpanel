#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

public_file=/www/server/panel/install/public.sh
public_file_Check=$(cat ${public_file} 2>/dev/null)
if [ ! -f $public_file ] || [ -z "${public_file_Check}" ];then
	wget -O $public_file http://download.bt.cn/install/public.sh -T 30;
fi
. $public_file

if [ -z "${NODE_URL}" ];then
	download_Url="http://download.bt.cn"
else
	download_Url=$NODE_URL
fi
echo ${download_Url}
mkdir -p /www/server
run_path="/pdnas/btpanel"
Is_64bit=`getconf LONG_BIT`

opensslVersion="1.0.2u"
curlVersion="7.70.0"
freetypeVersion="2.9.1"
pcreVersion="8.42"

aarch64Check=$(uname -a|grep aarch64)
if [ "${aarch64Check}" ];then
	CONFIGURE_BUILD_TYPE="--build=arm-linux"
	# CONFIGURE_BUILD_TYPE="--build=aarch64-linux-gnu"
fi

Error_Msg(){
	echo "Build failed"
	exit 1;
}

Install_Sendmail()
{
	if [ "${PM}" = "yum" ]; then
		yum install postfix mysql-libs -y
		if [ "${centos_version}" != '' ];then
			systemctl start postfix
			systemctl enable postfix	
		else
			service postfix start
			chkconfig --level 2345 postfix on
		fi
	elif [ "${PM}" = "apt-get" ]; then
		apt-get install sendmail sendmail-cf -y
	fi
}

Install_Curl()
{
	if [ ! -f "/usr/local/curl/bin/curl" ];then
		if [ ! -d ${run_path}/curl-${curlVersion} ] ; then
			wget ${download_Url}/src/curl-${curlVersion}.tar.gz
			tar -zxf curl-${curlVersion}.tar.gz
			cd curl-${curlVersion}
			./configure --prefix=/usr/local/curl --enable-ares --without-nss --with-ssl=/usr/local/openssl
			make -j${cpuCore}
		else
			cd curl-${curlVersion}
		fi
		make install
		cd ..
		rm -f curl-${curlVersion}.tar.gz
		#rm -rf curl-${curlVersion}
	fi
}

Install_Openssl()
{
	if [ ! -f "/usr/local/openssl/lib/libssl.so" ];then
		cd ${run_path}
		if [ ! -d ${run_path}/openssl-${opensslVersion} ] ; then
			wget ${download_Url}/src/openssl-${opensslVersion}.tar.gz
			tar -zxf openssl-${opensslVersion}.tar.gz
			cd openssl-${opensslVersion}
			./config --openssldir=/usr/local/openssl zlib-dynamic shared
			make -j${cpuCore} 
		else
			cd openssl-${opensslVersion}
		fi
		make install
		echo  "/usr/local/openssl/lib" > /etc/ld.so.conf.d/zopenssl.conf
		ldconfig
		cd ..
		rm -f openssl-${opensslVersion}.tar.gz
		#rm -rf openssl-${opensslVersion}
	fi	
}
Install_Pcre(){
	Cur_Pcre_Ver=`pcre-config --version|grep '^8.' 2>&1`
	if [ "$Cur_Pcre_Ver" == "" ];then
		if [ ! -d ${run_path}/pcre-${pcreVersion} ] ; then
			wget -O pcre-${pcreVersion}.tar.gz ${download_Url}/src/pcre-${pcreVersion}.tar.gz -T 5
			tar zxf pcre-${pcreVersion}.tar.gz
			rm -f pcre-${pcreVersion}.tar.gz
			cd pcre-${pcreVersion}
			if [ "$Is_64bit" == "64" ];then
				./configure --prefix=/usr --docdir=/usr/share/doc/pcre-${pcreVersion} --libdir=/usr/lib64 --enable-unicode-properties --enable-pcre16 --enable-pcre32 --enable-pcregrep-libz --enable-pcregrep-libbz2 --enable-pcretest-libreadline --disable-static --enable-utf8  
			else
				./configure --prefix=/usr --docdir=/usr/share/doc/pcre-${pcreVersion} --enable-unicode-properties --enable-pcre16 --enable-pcre32 --enable-pcregrep-libz --enable-pcregrep-libbz2 --enable-pcretest-libreadline --disable-static --enable-utf8
			fi
			make -j${cpuCore}
		else
			cd pcre-${pcreVersion}
		fi
		make install
		cd ..
		#rm -rf pcre-${pcreVersion}
	fi
}
Install_Freetype()
{
	if [ ! -f "/usr/bin/freetype-config" ] && [ ! -f "/usr/local/freetype/bin/freetype-config" ]; then
		cd ${run_path}
		if [ ! -d ${run_path}/freetype-${freetypeVersion} ] ;then
			wget -O freetype-${freetypeVersion}.tar.gz ${download_Url}/src/freetype-${freetypeVersion}.tar.gz -T 5
			tar zxf freetype-${freetypeVersion}.tar.gz
			cd freetype-${freetypeVersion}
			./configure --prefix=/usr/local/freetype --enable-freetype-config
			make -j${cpuCore}
		else
			cd freetype-${freetypeVersion}
		fi
		make install
		cd ../
		#rm -rf freetype-${freetypeVersion}
		rm -f freetype-${freetypeVersion}.tar.gz
	fi
}
Install_Libiconv()
{
	if [ -d '/usr/local/libiconv' ];then
		return
	fi
	cd ${run_path}
	if [ ! -d ${run_path}/libiconv-1.14 ] ; then
		if [ ! -f "libiconv-1.14.tar.gz" ];then
			wget -O libiconv-1.14.tar.gz ${download_Url}/src/libiconv-1.14.tar.gz -T 5
		fi
		mkdir ${run_path}/patch
		wget -O ${run_path}/patch/libiconv-glibc-2.16.patch ${download_Url}/src/patch/libiconv-glibc-2.16.patch -T 5
		tar zxf libiconv-1.14.tar.gz
		cd libiconv-1.14
			patch -p0 < ${run_path}/patch/libiconv-glibc-2.16.patch
			./configure --prefix=/usr/local/libiconv --enable-static $CONFIGURE_BUILD_TYPE
			make -j${cpuCore}
	else
		cd libiconv-1.14
	fi
  make install
  cd ${run_path}
  #rm -rf libiconv-1.14
	rm -f libiconv-1.14.tar.gz
	echo -e "Install_Libiconv" >> /www/server/lib.pl
}
Install_Libmcrypt()
{
	if [ -f '/usr/local/lib/libmcrypt.so' ];then
		return;
	fi
	cd ${run_path}
	if [ ! -d ${run_path}/libmcrypt-2.5.8 ] ; then
		if [ ! -f "libmcrypt-2.5.8.tar.gz" ];then
			wget -O libmcrypt-2.5.8.tar.gz ${download_Url}/src/libmcrypt-2.5.8.tar.gz -T 5
		fi
		tar zxf libmcrypt-2.5.8.tar.gz
		cd libmcrypt-2.5.8
		
			./configure $CONFIGURE_BUILD_TYPE
			make -j${cpuCore}
	else
		cd libmcrypt-2.5.8
	fi
	make install
	/sbin/ldconfig
	cd libltdl/
	./configure --enable-ltdl-install
	make && make install
	ln -sf /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
	ln -sf /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
	ln -sf /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
	ln -sf /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
	ldconfig
	cd ${run_path}
	#rm -rf libmcrypt-2.5.8
	rm -f libmcrypt-2.5.8.tar.gz
	echo -e "Install_Libmcrypt" >> /www/server/lib.pl
}
Install_Mcrypt()
{
	if [ -f '/usr/bin/mcrypt' ] || [ -f '/usr/local/bin/mcrypt' ];then
		return;
	fi
	cd ${run_path}
	if [ ! -d ${run_path}/mcrypt-2.6.8 ] ; then
		if [ ! -f "mcrypt-2.6.8.tar.gz" ];then
			wget -O mcrypt-2.6.8.tar.gz ${download_Url}/src/mcrypt-2.6.8.tar.gz -T 5
		fi
		tar zxf mcrypt-2.6.8.tar.gz
		cd mcrypt-2.6.8
			./configure $CONFIGURE_BUILD_TYPE
			make -j${cpuCore}
	else
		cd mcrypt-2.6.8
	fi
	make install
	cd ${run_path}
	#rm -rf mcrypt-2.6.8
	rm -f mcrypt-2.6.8.tar.gz
	echo -e "Install_Mcrypt" >> /www/server/lib.pl
}
Install_Mhash()
{
	if [ -f '/usr/local/lib/libmhash.so' ];then
		return;
	fi
	cd ${run_path}
	if [ ! -d ${run_path}/mhash-0.9.9.9 ] ; then
		if [ ! -f "mhash-0.9.9.9.tar.gz" ];then
			wget -O mhash-0.9.9.9.tar.gz ${download_Url}/src/mhash-0.9.9.9.tar.gz -T 5
		fi
		tar zxf mhash-0.9.9.9.tar.gz
		cd mhash-0.9.9.9
    ./configure $CONFIGURE_BUILD_TYPE
    make -j${cpuCore}
	else
		cd mhash-0.9.9.9
	fi
    make install
    ln -sf /usr/local/lib/libmhash.a /usr/lib/libmhash.a
    ln -sf /usr/local/lib/libmhash.la /usr/lib/libmhash.la
    ln -sf /usr/local/lib/libmhash.so /usr/lib/libmhash.so
    ln -sf /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
    ln -sf /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
    ldconfig
    cd ${run_path}
    #rm -rf mhash-0.9.9.9*
	echo -e "Install_Mhash" >> /www/server/lib.pl
}

Install_Yumlib(){
	sed -i "s#SELINUX=enforcing#SELINUX=disabled#" /etc/selinux/config
	rpm -e --nodeps mariadb-libs-*
	Centos8Check=$(cat /etc/redhat-release|grep ' 8.'|grep -i centos)
	CentosStream8Check=$(cat /etc/redhat-release|grep -i "Centos Stream"|grep 8)
	if [ "${Centos8Check}" ] || [ "${CentosStream8Check}" ];then
		yum config-manager --set-enabled PowerTools
		yum config-manager --set-enabled powertools
	fi
	mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
	rm -f /var/run/yum.pid
	Packs="make cmake gcc gcc-c++ flex bison file libtool libtool-libs autoconf kernel-devel patch wget libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel tar bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal gettext gettext-devel gmp-devel pspell-devel libcap diffutils ca-certificates net-tools libc-client-devel psmisc libXpm-devel c-ares-devel libicu-devel libxslt libxslt-devel zip unzip glibc.i686 libstdc++.so.6 cairo-devel bison-devel libaio-devel perl perl-devel perl-Data-Dumper lsof pcre pcre-devel vixie-cron crontabs expat-devel readline-devel oniguruma-devel libwebp-devel libvpx-devel"
	yum install ${Packs} -y
	for yumPack in ${Packs};
	do
		rpmPack=$(rpm -q ${yumPack})
		packCheck=$(echo $rpmPack|grep not)
		if [ "${packCheck}" ]; then
			yum install ${yumPack} -y
		fi
	done
	mv /etc/yum.repos.d/epel.repo.backup /etc/yum.repos.d/epel.repo
	
	ALI_OS=$(cat /etc/redhat-release |grep "Alibaba Cloud Linux release 3")
	if [ -z "${ALI_OS}" ];then
		yum install epel-release -y
	fi

	echo "true" > /etc/bt_lib.lock
}
Install_Aptlib(){
	#apt-get autoremove -y
	apt-get -fy install
	export DEBIAN_FRONTEND=noninteractive
	apt-get install -y build-essential gcc g++ make

	# for aptPack in debian-keyring debian-archive-keyring build-essential gcc g++ make cmake autoconf automake re2c wget cron bzip2 libzip-dev libc6-dev bison file rcconf flex vim bison m4 gawk less cpp binutils diffutils unzip tar bzip2 libbz2-dev libncurses5 libncurses5-dev libtool libevent-dev openssl libssl-dev zlibc libsasl2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libjpeg62 libjpeg62-dev libpng12-0 libpng12-dev libkrb5-dev libpq-dev libpq5 gettext libpng12-dev libxml2-dev libcap-dev ca-certificates libc-client2007e-dev psmisc patch git libc-ares-dev libicu-dev e2fsprogs libxslt-dev libc-client-dev xz-utils libgd3 libgd-dev libwebp-dev libvpx-dev;
	# do apt-get -y install $aptPack --force-yes; done

	# libpng12-0 libpng12-dev rcconf
	# sudo add-apt-repository -y ppa:linuxuprising/libpng12
	# sudo apt update
	apt-get -y install debian-keyring debian-archive-keyring build-essential gcc g++ make cmake autoconf \
	 automake re2c wget cron bzip2 libzip-dev libc6-dev bison file flex vim bison m4 gawk less cpp \
	 binutils diffutils unzip tar bzip2 libbz2-dev libncurses5 libncurses5-dev libtool libevent-dev openssl \
	 libssl-dev zlibc libsasl2-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 \
	 libglib2.0-dev libpng-dev libjpeg62 libkrb5-dev libpq-dev \
	 libpq5 gettext libxml2-dev libcap-dev ca-certificates libc-client2007e-dev psmisc \
	 patch git libc-ares-dev libicu-dev e2fsprogs libxslt1-dev libc-client-dev xz-utils libgd3 libgd-dev\
	 libwebp-dev libvpx-dev gcc g++ liblua5.1-0 liblua5.1-0-dev libbrotli-dev \
	 libsctp-dev libxslt-dev libpcre3 libpcre3-dev libssh2-1-dev 

	ln -s /usr/lib/aarch64-linux-gnu/libjpeg.so.8 /usr/lib/libjpeg.so
	ln -s /usr/lib/aarch64-linux-gnu/libjpeg.a /usr/lib/libjpeg.a
	ln -s /usr/lib/aarch64-linux-gnu/libpng.so /usr/lib/libpng.so
	ln -s /usr/lib/aarch64-linux-gnu/libpng.a /usr/lib/libpng.a
	echo "true" > /etc/bt_lib.lock
}
Install_Lib()
{
	lockFile="/etc/bt_lib.lock"
	if [ -f "${lockFile}" ]; then
		return
	fi

	if [ "${PM}" = "yum" ]; then
		Install_Yumlib
	elif [ "${PM}" = "apt-get" ]; then
		Install_Aptlib
	fi
	Install_Sendmail
	Run_User="www"
	groupadd ${Run_User}
	useradd -s /sbin/nologin -g ${Run_User} ${Run_User}

}
openssl111Version="1.1.1k"
Install_Openssl_1_1_1(){
	openssl111Check=$(openssl version |grep 1.1.1)
	if [ ! -f "/usr/local/openssl111/bin/openssl" ] ;then
		cd ${run_path}
		if [ ! -d ${run_path}/openssl-${openssl111Version} ] ; then
			wget ${download_Url}/src/openssl-${openssl111Version}.tar.gz -T 20
			tar -zxf openssl-${openssl111Version}.tar.gz
			rm -f openssl-${openssl111Version}.tar.gz
			cd openssl-${openssl111Version}
			./config --prefix=/usr/local/openssl111 --openssldir=/usr/local/openssl111 enable-md2 enable-rc5 sctp zlib-dynamic shared -fPIC
			make -j${cpuCore}
		else
			cd openssl-${openssl111Version}
		fi
		make install
		[ $? -ne 0 ] && Error_Msg
		echo "/usr/local/openssl111/lib" >> /etc/ld.so.conf.d/zopenssl111.conf
		ldconfig
		cd ..
		# rm -rf openssl-${openssl111Version} 
	fi
}

Install_Curl_New(){
	if [ ! -f "/usr/local/curl_2/bin/curl" ];then
		curlVersion="7.74.0"
		cd ${run_path}
		if [ ! -d ${run_path}/curl-${curlVersion} ] ; then
			wget ${download_Url}/src/curl-${curlVersion}.tar.gz
			tar -zxf curl-${curlVersion}.tar.gz
			cd curl-${curlVersion}
			rm -rf /usr/local/curl_2
			./configure --prefix=/usr/local/curl_2 --enable-ldap --enable-ldaps --with-brotli --with-libssh2 --with-libssh --enable-ares --with-gssapi --without-nss --enable-smb --with-libidn2 --with-ssl=/usr/local/openssl111
			[ $? -ne 0 ] && Error_Msg
			make -j${cpuCore}
		else
			cd curl-${curlVersion}
		fi
		make install
		cd ..
		rm -f curl-${curlVersion}.tar.gz
		# rm -rf curl-${curlVersion}
	fi
}

Install_Icu4c(){
	cd ${run_path}
	icu4cVer=$(/usr/bin/icu-config --version)
	if [ ! -f "/usr/bin/icu-config" ] || [ "${icu4cVer:0:2}" -gt "60" ];then
		cd ${run_path}
		if [ ! -d ${run_path}/icu ] ; then
			wget -O icu4c-60_3-src.tgz ${download_Url}/src/icu4c-60_3-src.tgz
			tar -xvf icu4c-60_3-src.tgz
			cd icu/source
			./configure --prefix=/usr/local/icu
			make -j${cpuCore}
		else
			cd icu/source
		fi
		make install
		[ -f "/usr/bin/icu-config" ] && mv /usr/bin/icu-config /usr/bin/icu-config.bak 
		ln -sf /usr/local/icu/bin/icu-config /usr/bin/icu-config
		echo "/usr/local/icu/lib" > /etc/ld.so.conf.d/zicu.conf
		ldconfig
		cd ../../
		# rm -rf icu
		rm -f icu4c-60_3-src.tgz 
	fi
}

Install_Onig(){
	onigCheck=$(pkg-config --list-all|grep onig)
	if [ ! -f /usr/local/onig/bin/onig-config ] && [ -z "${onigCheck}" ];then
		cd ${run_path}
		onigVer="6.9.6"
		if [ ! -d ${run_path}/onig-${onigVer} ] ; then
			wget -O onig-${onigVer}.tar.gz ${download_Url}/src/onig-${onigVer}.tar.gz
			tar  -xvf onig-${onigVer}.tar.gz
			cd onig-${onigVer}
			./configure --prefix=/usr/local/onig
			make -j${cpuCore}
		else
			cd onig-${onigVer}
		fi
		make install
		cd ..
		rm -rf onig-${onigVer}.tar.gz
	fi
}
Install_Libsodium(){
	if [ ! -f "/usr/local/libsodium/lib/libsodium.so" ];then
		cd ${run_path}
		libsodiumVer="1.0.18"
		if [ ! -d ${run_path}/libsodium-stable ] ; then
			wget ${download_Url}/src/libsodium-${libsodiumVer}-stable.tar.gz
			tar -xvf libsodium-${libsodiumVer}-stable.tar.gz
			rm -f libsodium-${libsodiumVer}-stable.tar.gz
			cd libsodium-stable
			./configure --prefix=/usr/local/libsodium
			make -j${cpuCore}
		else
			cd libsodium-stable
		fi
		make install
		cd ..
		rm -f libsodium-${libsodiumVer}-stable.tar.gz
		# rm -rf libsodium-stable
	fi
}

Install_Rpcgen(){
	if [ ! -f "/usr/bin/rpcgen" ];then
		if [ ! -d ${run_path}/rpcsvc-proto-1.4 ] ; then
			cd ${run_path}
			wget ${download_Url}/src/rpcsvc-proto-1.4.tar.gz 
			tar -xvf rpcsvc-proto-1.4.tar.gz
			cd rpcsvc-proto-1.4
			./configure --prefix=/usr/local/rpcgen
			make
		else
			cd rpcsvc-proto-1.4
		fi
		make install
		ln -sf /usr/local/rpcgen/bin/rpcgen /usr/bin/rpcgen
		cd ..
		rm -rf rpcsvc-proto*.tar.gz
	fi
}

nghttp2Version="1.41.0"
Install_Nghttp2(){
	if [ ! -f "/usr/local/nghttp2/lib/libnghttp2.so" ];then
		cd ${run_path}
		if [ ! -d ${run_path}/nghttp2-${nghttp2Version} ] ; then
			wget ${download_Url}/src/nghttp2-${nghttp2Version}.tar.gz
			tar -zxf nghttp2-${nghttp2Version}.tar.gz
			cd nghttp2-${nghttp2Version}
			export CFLAGS='-I/usr/local/openssl111/include' LIBS='-L/usr/local/openssl111/lib'
			./configure --prefix=/usr/local/nghttp2 LDFLAGS="-L/www/server/panel/pyenv/lib"
			make -j${cpuCore}
		else
			cd nghttp2-${nghttp2Version}
		fi
		make install
		cd ..
		rm -rf nghttp2-${nghttp2Version}.tar.gz
	fi
}
Install_cjson()
{
	if [ ! -f /usr/local/lib/lua/5.1/cjson.so ];then
		cd ${run_path}
		if [ ! -d ${run_path}/lua-cjson-2.1.0 ] ;then
			wget -O lua-cjson-2.1.0.tar.gz $download_Url/install/src/lua-cjson-2.1.0.tar.gz -T 20
			tar xvf lua-cjson-2.1.0.tar.gz
			rm -f lua-cjson-2.1.0.tar.gz
			cd lua-cjson-2.1.0
			mkdir build
			cd build
			cmake ..
			make -j${cpuCore}
		else
			cd lua-cjson-2.1.0
		fi
		make install
		cd ..
		# rm -rf lua-cjson-2.1.0
	fi

	if [ -f /usr/local/lib/lua/5.1/cjson.so ];then
		ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/local/lib/cjson.so 
		if [ -d "/usr/lib/lua/5.1" ];then
			ln -sf /usr/local/lib/lua/5.1/cjson.so /usr/lib/lua/5.1/cjson.so 
		fi
	fi
}

# wget download_Url=http://dg2.bt.cn/src/

Install_Lib
Install_Openssl
Install_Openssl_1_1_1
Install_Pcre
Install_Curl
Install_Curl_New
Install_Mhash
Install_Libmcrypt
Install_Mcrypt	
Install_Libiconv
Install_Freetype
Install_Icu4c
Install_Onig
Install_Libsodium
Install_Rpcgen
#Install_Nghttp2
Install_cjson
