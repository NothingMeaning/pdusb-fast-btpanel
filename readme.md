
# Arm Aarch64 Ubuntu安装宝塔面板加速包, ARM 64上5分钟安装完宝塔面板

![加速](https://gitee.com/pdusb/pdusb-fast-btpanel/raw/master/imgs/pdbolt-bt-acel.jpg)

- Arm64系统上安装宝塔面板从100+分钟到10分钟之内
- 加速安装LNMP/LAMP的常见依赖,后续安装也加速

## 加速包能做什么

- 在Arm 64位设备上加速宝塔面板安装过程,从常见的100+分钟缩减为不足10分钟
- 加速安装LNMP/LAMP的常见依赖,后续安装也加速

## 加速包为什么能快

主要是针对宝塔安装脚本当前一些可优化空间做的优化
- 使用预编译的python 3.7.8 ,节省大量重新完整编译python的时间.
- 使用cache的whl用于PIP安装. 此部分节省大量时间
- 使用打包好的deb,用于满足宝塔以及LNMP/LAMP常见依赖软件

## 哪些系统可以使用加速包

目前版本加速包针对 64位的ARM机器,以Ubuntu 20.04为主，其他类似以及接近系统大概率也能直接使用

## 加速包如何使用
- 获取加速包到本地电脑
- 在加速包目录下执行
```Bash
  su -
  mkdir testmeiyou
  cd testmeiyou
  git clone https://gitee.com/pdusb/pdusb-fast-btpanel.git .
  ./pdbolt-inst-bt-acel.sh
  bash /tmp/btp/pdbolt-bt-install/install.sh
```
上面如果执行失败需要重新执行，需要把第二条和第三条的 testmeiyou 更换成其他不存在的路径,如 aaa等
此步骤的典型输出如下
```
从官网下载宝塔安装脚本
++ wget -O /tmp/btp/pdbolt-bt-install/install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh
--2021-06-05 11:16:41--  http://download.bt.cn/install/install-ubuntu_6.0.sh
Resolving download.bt.cn (download.bt.cn)... 116.10.184.219, 2001:19f0:4400:5138:5400:2ff:fe1f:10f2
Connecting to download.bt.cn (download.bt.cn)|116.10.184.219|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 25977 (25K) [application/octet-stream]
Saving to: '/tmp/btp/pdbolt-bt-install/install.sh'

/tmp/btp/pdbolt-bt-install/install.s 100%[===================================================================>]  25.37K  --.-KB/s    in 0.04s

2021-06-05 11:16:41 (608 KB/s) - '/tmp/btp/pdbolt-bt-install/install.sh' saved [25977/25977]

++ set +x
给官方脚本打加速patch
Reading package lists... Done
Building dependency tree
Reading state information... Done
patch is already the newest version (2.7.6-6).
0 upgraded, 0 newly installed, 0 to remove and 100 not upgraded.
patching file install.sh
准备加速包供安装使用
安装各种依赖包
Reading package lists... Done
Building dependency tree
Reading state information... Done
Note, selecting 'curl70' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/curl70_7.70.0_arm64.deb'
Note, selecting 'curl74' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/curl74_7.74.0_arm64.deb'
Note, selecting 'freetype' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/freetype_2.9.1_arm64.deb'
Note, selecting 'icu4c' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/icu4c_60.3_arm64.deb'
Note, selecting 'libiconv' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/libiconv_1.14_arm64.deb'
Note, selecting 'libmcrypt' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/libmcrypt_2.5.8_arm64.deb'
Note, selecting 'libsodium' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/libsodium_1.0.18_arm64.deb'
Note, selecting 'lua-cjson' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/lua-cjson_2.1.0_arm64.deb'
Note, selecting 'lua' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/lua_5.1.5-1_arm64.deb'
Note, selecting 'luajit' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/luajit_2.1_arm64.deb'
Note, selecting 'luasocket' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/luasocket_5.1_arm64.deb'
Note, selecting 'mcrypt' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/mcrypt_2.5.8_arm64.deb'
Note, selecting 'mhash' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/mhash_0.9.9.9_arm64.deb'
Note, selecting 'onig' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/onig_6.9.6_arm64.deb'
Note, selecting 'openssl102' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/openssl102_1.0.2u_arm64.deb'
Note, selecting 'openssl111' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/openssl111_1.1.1k_arm64.deb'
Note, selecting 'rpcsvc-proto' instead of '/pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/rpcsvc-proto_1.4_arm64.deb'
The following NEW packages will be installed:
  curl70 curl74 freetype icu4c libiconv libmcrypt libsodium lua lua-cjson luajit luasocket mcrypt mhash onig openssl102 openssl111 rpcsvc-proto
0 upgraded, 17 newly installed, 0 to remove and 100 not upgraded.
Need to get 0 B/16.2 MB of archives.
After this operation, 84.1 MB of additional disk space will be used.
Get:1 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/curl70_7.70.0_arm64.deb curl70 arm64 7.70.0 [636 kB]
Get:2 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/curl74_7.74.0_arm64.deb curl74 arm64 7.74.0 [692 kB]
Get:3 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/freetype_2.9.1_arm64.deb freetype arm64 2.9.1 [488 kB]
Get:4 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/icu4c_60.3_arm64.deb icu4c arm64 60.3 [8707 kB]
Get:5 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/libiconv_1.14_arm64.deb libiconv arm64 1.14 [568 kB]
Get:6 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/libmcrypt_2.5.8_arm64.deb libmcrypt arm64 2.5.8 [87.3 kB]
Get:7 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/libsodium_1.0.18_arm64.deb libsodium arm64 1.0.18 [146 kB]
Get:8 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/lua_5.1.5-1_arm64.deb lua arm64 5.1.5-1 [128 kB]
Get:9 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/lua-cjson_2.1.0_arm64.deb lua-cjson arm64 2.1.0 [12.3 kB]
Get:10 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/luajit_2.1_arm64.deb luajit arm64 2.1 [358 kB]
Get:11 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/luasocket_5.1_arm64.deb luasocket arm64 5.1 [38.1 kB]
Get:12 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/mcrypt_2.5.8_arm64.deb mcrypt arm64 2.5.8 [49.6 kB]
Get:13 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/mhash_0.9.9.9_arm64.deb mhash arm64 0.9.9.9 [114 kB]
Get:14 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/onig_6.9.6_arm64.deb onig arm64 6.9.6 [185 kB]
Get:15 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/openssl102_1.0.2u_arm64.deb openssl102 arm64 1.0.2u [1952 kB]
Get:16 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/openssl111_1.1.1k_arm64.deb openssl111 arm64 1.1.1k [2009 kB]
Get:17 /pdnas/test/pdbolt-bt-accel-arm/debs/aarch64/rpcsvc-proto_1.4_arm64.deb rpcsvc-proto arm64 1.4 [57.2 kB]
Selecting previously unselected package curl70.
(Reading database ... 140657 files and directories currently installed.)
Preparing to unpack .../00-curl70_7.70.0_arm64.deb ...
Unpacking curl70 (7.70.0) ...
Selecting previously unselected package curl74.
Preparing to unpack .../01-curl74_7.74.0_arm64.deb ...
Unpacking curl74 (7.74.0) ...
Selecting previously unselected package freetype.
Preparing to unpack .../02-freetype_2.9.1_arm64.deb ...
Unpacking freetype (2.9.1) ...
Selecting previously unselected package icu4c.
Preparing to unpack .../03-icu4c_60.3_arm64.deb ...
Unpacking icu4c (60.3) ...
Selecting previously unselected package libiconv.
Preparing to unpack .../04-libiconv_1.14_arm64.deb ...
Unpacking libiconv (1.14) ...
Selecting previously unselected package libmcrypt.
Preparing to unpack .../05-libmcrypt_2.5.8_arm64.deb ...
Unpacking libmcrypt (2.5.8) ...
Selecting previously unselected package libsodium.
Preparing to unpack .../06-libsodium_1.0.18_arm64.deb ...
Unpacking libsodium (1.0.18) ...
Selecting previously unselected package lua.
Preparing to unpack .../07-lua_5.1.5-1_arm64.deb ...
Unpacking lua (5.1.5-1) ...
Selecting previously unselected package lua-cjson.
Preparing to unpack .../08-lua-cjson_2.1.0_arm64.deb ...
Unpacking lua-cjson (2.1.0) ...
Selecting previously unselected package luajit.
Preparing to unpack .../09-luajit_2.1_arm64.deb ...
Unpacking luajit (2.1) ...
Selecting previously unselected package luasocket.
Preparing to unpack .../10-luasocket_5.1_arm64.deb ...
Unpacking luasocket (5.1) ...
Selecting previously unselected package mcrypt.
Preparing to unpack .../11-mcrypt_2.5.8_arm64.deb ...
Unpacking mcrypt (2.5.8) ...
Selecting previously unselected package mhash.
Preparing to unpack .../12-mhash_0.9.9.9_arm64.deb ...
Unpacking mhash (0.9.9.9) ...
Selecting previously unselected package onig.
Preparing to unpack .../13-onig_6.9.6_arm64.deb ...
Unpacking onig (6.9.6) ...
Selecting previously unselected package openssl102.
Preparing to unpack .../14-openssl102_1.0.2u_arm64.deb ...
Unpacking openssl102 (1.0.2u) ...
Selecting previously unselected package openssl111.
Preparing to unpack .../15-openssl111_1.1.1k_arm64.deb ...
Unpacking openssl111 (1.1.1k) ...
Selecting previously unselected package rpcsvc-proto.
Preparing to unpack .../16-rpcsvc-proto_1.4_arm64.deb ...
Unpacking rpcsvc-proto (1.4) ...
Setting up openssl111 (1.1.1k) ...
Setting up icu4c (60.3) ...
Setting up onig (6.9.6) ...
Setting up luajit (2.1) ...
Setting up freetype (2.9.1) ...
Setting up libsodium (1.0.18) ...
Setting up rpcsvc-proto (1.4) ...
Setting up lua-cjson (2.1.0) ...
Setting up libmcrypt (2.5.8) ...
Setting up mhash (0.9.9.9) ...
Setting up lua (5.1.5-1) ...
Setting up mcrypt (2.5.8) ...
Setting up curl74 (7.74.0) ...
Setting up openssl102 (1.0.2u) ...
Setting up curl70 (7.70.0) ...
Setting up libiconv (1.14) ...
Setting up luasocket (5.1) ...
Processing triggers for man-db (2.9.1-1) ...
Processing triggers for libc-bin (2.31-0ubuntu9.2) ...
添加库路径到系统目录
可以安装宝塔面板了,速度飞起来哦
面板安装脚本路径 /tmp/btp/pdbolt-bt-install/install.sh
执行命令 /tmp/btp/pdbolt-bt-install/install.sh 就可以哦
```

## 交流沟通

愉快的加入QQ群聊吧

![群聊](https://gitee.com/pdusb/pdusb-fast-btpanel/raw/master/imgs/pdbolt-conn-qq-group.jpeg)

