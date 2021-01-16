#!/bin/bash
CurrentDate=$(date +%Y-%m-%d)
# ======================================
# get gfwlist for shadowsocks ipset mode
curl https://cdn.jsdelivr.net/gh/gfwlist/gfwlist/gfwlist.txt > gfwlist_download.conf
generate_china_banned() {
cat $1 | base64 -d > gfwlist_tmp.txt
sed -i '/^@@|/d' gfwlist_tmp.txt
cat gfwlist_tmp.txt | sort -u |
sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' |
sed '/\*/d; /apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /byr\.cn/d; /jlike\.com/d; /weibo\.com/d; /zhongsou\.com/d; /youdao\.com/d; /sogou\.com/d; /so\.com/d; /soso\.com/d; /aliyun\.com/d; /taobao\.com/d; /jd\.com/d; /qq\.com/d; /windowsupdate/d' |
sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' |
grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | sed 's#^\.\+##' | sort -u |
awk 'BEGIN { prev = "________"; } {
cur = $0;
if (index(cur, prev) == 1 && substr(cur, 1 + length(prev) ,1) == ".") {
} else {
print cur;
prev = cur;
}
}' | sort -u
rm gfwlist_tmp.txt
}
generate_china_banned gfwlist_download.conf > gfwlist_download_tmp.conf
echo "dmhy.org" >> gfwlist_download_tmp.conf
echo "s3.amazonaws.com" >> gfwlist_download_tmp.conf
sed '/.*/s/.*/server=\/&\/127.0.0.1#7913\nipset=\/&\/gfwlist/' gfwlist_download_tmp.conf > gfwlist1.conf

md5sum1=$(md5sum gfwlist1.conf | sed 's/ /\n/g' | sed -n 1p)
md5sum2=$(md5sum ../gfwlist.conf | sed 's/ /\n/g' | sed -n 1p)

echo =================
if [ "$md5sum1"x = "$md5sum2"x ]; then
	echo gfwlist same md5!
else
	echo update gfwlist!
	cp -f gfwlist1.conf ../gfwlist.conf
	sed -i "1c $(date +%Y-%m-%d) # $md5sum1 gfwlist" ../version1
fi
echo =================
# ======================================
# get chnroute for shadowsocks chn and game mode
curl https://ispip.clang.cn/all_cn.txt > chnroute1.txt

md5sum3=$(md5sum chnroute1.txt | sed 's/ /\n/g' | sed -n 1p)
md5sum4=$(md5sum ../chnroute.txt | sed 's/ /\n/g' | sed -n 1p)

echo =================
if [ "$md5sum3"x = "$md5sum4"x ]; then
	echo chnroute same md5!
else
	IPLINE=$(cat chnroute1.txt | wc -l)
	IPCOUN=$(awk -F "/" '{sum += 2^(32-$2)-2};END {print sum}' chnroute1.txt)
	echo update chnroute, $IPLINE subnets, $IPCOUN unique IPs !
	cp -f chnroute1.txt ../chnroute.txt
	sed -i "2c $(date +%Y-%m-%d) # $md5sum3 chnroute" ../version1
fi
echo =================
# ======================================
# get cdn list for shadowsocks chn and game mode

wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf
wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf
wget -4 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf

cat accelerated-domains.china.conf apple.china.conf google.china.conf | sed '/^#/d' | sed "s/server=\/\.//g" | sed "s/server=\///g" | sed -r "s/\/\S{1,30}//g" | sed -r "s/\/\S{1,30}//g" >cdn_download.txt
cat cdn_download.txt | sort -u >cdn1.txt

md5sum5=$(md5sum cdn1.txt | sed 's/ /\n/g' | sed -n 1p)
md5sum6=$(md5sum ../cdn.txt | sed 's/ /\n/g' | sed -n 1p)

echo =================
if [ "$md5sum5"x = "$md5sum6"x ]; then
	echo cdn list same md5!
else
	echo update cdn!
	cp -f cdn1.txt ../cdn.txt
	sed -i "3c $(date +%Y-%m-%d) # $md5sum5 cdn" ../version1
fi
echo =================

#curl https://cdn.jsdelivr.net/gh/QiuSimons/Netflix_IP/getflix.txt > netflix_download.txt
# ======================================
rm google.china.conf
rm apple.china.conf
rm gfwlist1.conf gfwlist_download.conf gfwlist_download_tmp.conf chnroute1.txt
rm cdn1.txt accelerated-domains.china.conf cdn_download.txt
