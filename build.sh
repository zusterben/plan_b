#!/bin/sh

MODULE=helloworld
VERSION=0.3.4
TITLE="ShadowSocksR Plus"
DESCRIPTION="ShadowSocksR Plus"
HOME_URL=Module_helloworld.asp
arch_list="mips arm armng arm64 mipsle"

cp_rules(){
	cp -rf ./rules/gfwlist.conf helloworld/ss/rules/
	cp -rf ./rules/chnroute.txt helloworld/ss/rules/
	cp -rf ./rules/cdn.txt helloworld/ss/rules/
	cp -rf ./rules/version1 helloworld/ss/rules/version
}

sync_v2ray_binary(){
	v2ray_version=`cat ./v2ray_binary/latest.txt`
	md5_latest=`md5sum ./v2ray_binary/$1/$v2ray_version/v2ray | sed 's/ /\n/g'| sed -n 1p`
	md5_old=`md5sum ./bin_arch/$1/v2ray | sed 's/ /\n/g'| sed -n 1p`
	if [ "$md5_latest"x != "$md5_old"x ]; then
		echo update v2ray binary！
		cp -rf ./v2ray_binary/$1/$v2ray_version/v2ray ./bin_arch/$1/
		cp -rf ./v2ray_binary/$1/$v2ray_version/v2ctl ./bin_arch/$1/
	fi
}

sync_xray_binary(){
	xray_version=`cat ./xray_binary/latest.txt`
	md5_latest=`md5sum ./xray_binary/$1/$xray_version/xray | sed 's/ /\n/g'| sed -n 1p`
	md5_old=`md5sum ./bin_arch/$1/xray | sed 's/ /\n/g'| sed -n 1p`
	if [ "$md5_latest"x != "$md5_old"x ]; then
		echo update xray！
		cp -rf ./xray_binary/$1/$xray_version/xray ./bin_arch/$1/
	fi
}

do_build() {
	if [ "$VERSION" = "" ]; then
		echo "version not found"
		exit 3
	fi
	
	rm -f ${MODULE}.tar.gz
	rm -f $MODULE/.DS_Store
	rm -f $MODULE/*/.DS_Store
	rm -rf $MODULE/bin/*
	cp -rf ./bin_arch/$1/* $MODULE/bin/
	echo $VERSION > helloworld/ss/version
	tar -zcvf ${MODULE}.tar.gz $MODULE
	cat > $MODULE/version <<-EOF
	$VERSION
	EOF
	md5value=`md5sum ${MODULE}.tar.gz|tr " " "\n"|sed -n 1p`
	cat > ./version <<-EOF
	$VERSION
	$md5value
	EOF
	cat version
	
	DATE=`date +%Y-%m-%d_%H:%M:%S`
	cat > ./config.json.js <<-EOF
	{
	"build_date":"$DATE",
	"description":"$DESCRIPTION",
	"home_url":"$HOME_URL",
	"md5":"$md5value",
	"name":"$MODULE",
	"tar_url": "https://raw.githubusercontent.com/zusterben/plan_b/master/bin/$1/helloworld.tar.gz", 
	"title":"$TITLE",
	"version":"$VERSION"
	}
	EOF
	cp -rf version ./bin/$1/version
	cp -rf config.json.js ./bin/$1/config.json.js
	cp -rf helloworld.tar.gz ./bin/$1/helloworld.tar.gz
}

do_backup(){
	HISTORY_DIR="./history_package/$1"
	# backup latested package after pack
	backup_version=`cat version | sed -n 1p`
	backup_tar_md5=`cat version | sed -n 2p`
	echo backup VERSION $backup_version
	cp ${MODULE}.tar.gz $HISTORY_DIR/${MODULE}_$backup_version.tar.gz
	sed -i "/$backup_version/d" "$HISTORY_DIR"/md5sum.txt
	echo $backup_tar_md5 ${MODULE}_$backup_version.tar.gz >> "$HISTORY_DIR"/md5sum.txt
}

cp_rules
for arch in $arch_list
do
#sync_v2ray_binary $arch
sync_xray_binary $arch
do_build $arch
do_backup $arch
done
rm version config.json.js helloworld.tar.gz
rm -rf $MODULE/bin/*

