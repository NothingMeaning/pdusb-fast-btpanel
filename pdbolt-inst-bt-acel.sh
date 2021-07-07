# !/usr/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "从官网下载宝塔安装脚本"
installPath="/tmp/btp/pdbolt-bt-install"
rm -rf "$installPath" 2>/dev/null
mkdir -p "$installPath"
mkdir "${installPath}"/pyenv
mkdir "${installPath}"/whls
cd "$installPath"

lsize=0
while [ -z "$lsize"  ] || [ "x$lsize" = "x0" ]
do
  set -x
  wget -O "${installPath}"/install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh
  set +x
  lsize=$(stat -c '%s' "${installPath}"/install.sh 2>/dev/null | tr -d '\n')
done

echo "给官方脚本打加速patch"
apt-get install -y patch libbrotli-dev
lsize=$(which patch)
if [ -z "$lsize" ] ;then
  echo "系统里面没有patch 命令，无法加速呀"
  exit 22
fi

patch -p1 < ${SCRIPT_DIR}/patch/ubuntu*aarch64*install*.patch

echo "准备加速包供安装使用"
mkdir -p "${installPath}"/tmppython
tar -C "${installPath}"/tmppython -jxf ${SCRIPT_DIR}/pyenv/pyenv-ubuntu*aarch64*.tar.xz 
mv "${installPath}"/tmppython/pyenv /tmp/btp
rm -rf "${installPath}"/tmppython/
cp -r ${SCRIPT_DIR}/whls /tmp/btp/

echo "安装各种依赖包"
apt-get install -y ${SCRIPT_DIR}/debs/aarch64/*.deb

echo "添加库路径到系统目录"
mkdir -p /etc/ld.so.conf.d
echo "/usr/local/libiconv/lib" > /etc/ld.so.conf.d/pdbolt-btpanel.conf
echo "/usr/local/openssl/lib" > /etc/ld.so.conf.d/zopenssl.conf
echo "/usr/local/icu/lib" > /etc/ld.so.conf.d/zopenssl.conf
ldconfig

chmod +x ${installPath}/install.sh

echo "可以安装宝塔面板了,速度飞起来哦"
echo "面板安装脚本路径 ${installPath}/install.sh"
echo "执行命令 bash ${installPath}/install.sh 就可以哦"
