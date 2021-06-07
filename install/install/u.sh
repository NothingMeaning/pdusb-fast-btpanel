download_Url="http://dg1.bt.cn"
# 4 Is Ubuntu
# 1 Is Centos 
# 0 Is Centos, fallback
# 3 Is 
[ -n "$1" ] && type="$1" || type="4"
echo "Update from $download_Url for $type"
wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh
wget -O apache.sh ${download_Url}/install/${type}/apache.sh
cp apache.sh ${type}apache.sh
wget -O nginx.sh ${download_Url}/install/${type}/nginx.sh
cp nginx.sh ${type}nginx.sh
wget -O mysql.sh ${download_Url}/install/${type}/mysql.sh
cp mysql.sh ${type}mysql.sh
wget -O php.sh ${download_Url}/install/${type}/php.sh
cp php.sh ${type}php.sh
wget -O phpmyadmin.sh ${download_Url}/install/${type}/phpmyadmin.sh
cp phpmyadmin.sh ${type}phpmyadmin.sh
