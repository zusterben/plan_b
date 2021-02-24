#!/bin/sh

source /jffs/softcenter/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

backup_conf(){
	rm -rf /tmp/files
	rm -rf /jffs/softcenter/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /jffs/softcenter/webs/files
	dbus list ss | grep -v "ss_basic_enable" | grep -v "ssid_" | sed 's/=/=\"/' | sed 's/$/\"/g'|sed 's/^/dbus set /' | sed '1 isource /jffs/softcenter/scripts/base.sh' |sed '1 i#!/bin/sh' > /jffs/softcenter/webs/files/ssconf_backup.sh
}

backup_tar(){
	rm -rf /tmp/files
	rm -rf /jffs/softcenter/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /jffs/softcenter/webs/files
	echo_date "开始打包..."
	cd /tmp
	mkdir helloworld
	mkdir helloworld/bin
	mkdir helloworld/scripts
	mkdir helloworld/webs
	mkdir helloworld/res
	echo_date "请等待一会儿..."
	TARGET_FOLDER=/tmp/helloworld
	cp /jffs/softcenter/scripts/ss_install.sh $TARGET_FOLDER/install.sh
	cp /jffs/softcenter/scripts/uninstall_helloworld.sh $TARGET_FOLDER/uninstall.sh
	cp /jffs/softcenter/scripts/ss_* $TARGET_FOLDER/scripts/
	cp /jffs/softcenter/bin/ss-local $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/ss-redir $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/obfs-local $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/ssr-local $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/ssr-redir $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/dns2socks $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/pdnsd $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/chinadns-ng $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/client_linux $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/jq $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/v2ray $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/v2ctl $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/v2ray-plugin $TARGET_FOLDER/bin/
	cp /jffs/softcenter/bin/httping $TARGET_FOLDER/bin/
	cp /jffs/softcenter/webs/Module_helloworld*.asp $TARGET_FOLDER/webs/
	cp /jffs/softcenter/res/accountadd.png $TARGET_FOLDER/res/
	cp /jffs/softcenter/res/accountdelete.png $TARGET_FOLDER/res/
	cp /jffs/softcenter/res/accountedit.png $TARGET_FOLDER/res/
	cp /jffs/softcenter/res/icon-helloworld.png $TARGET_FOLDER/res/
	cp /jffs/softcenter/res/ss-menu.js $TARGET_FOLDER/res/
	cp /jffs/softcenter/res/tablednd.js $TARGET_FOLDER/res/
	cp /jffs/softcenter/res/qrcode.js $TARGET_FOLDER/res/
	cp /jffs/softcenter/res/helloworld.css $TARGET_FOLDER/res/
	cp -r /jffs/softcenter/ss $TARGET_FOLDER/
	rm -rf $TARGET_FOLDER/ss/*.json
	tar -czv -f /tmp/helloworld.tar.gz helloworld/
	rm -rf $TARGET_FOLDER
	mv /tmp/helloworld.tar.gz /tmp/files
	echo_date "打包完毕！"
}

remove_now(){
	echo_date 开始清理helloworld配置...
	confs=`dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign"`
	for conf in $confs
	do
		echo_date 移除$conf
		dbus remove $conf
	done
	echo_date 设置一些默认参数...
	dbus set ss_basic_enable="0"
	dbus set ss_basic_version_local=`cat /jffs/softcenter/ss/version` 
	echo_date 尝试关闭helloworld...
	sh /jffs/softcenter/ss/ssconfig.sh stop
}

remove_silent(){
	echo_date 先清除已有的参数...
	confs=`dbus list ss | cut -d "=" -f 1 | grep -v "version" | grep -v "ssserver_" | grep -v "ssid_" |grep -v "ss_basic_state_china" | grep -v "ss_basic_state_foreign"`
	for conf in $confs
	do
		echo_date 移除$conf
		dbus remove $conf
	done
	echo_date 设置一些默认参数...
	dbus set ss_basic_version_local=`cat /jffs/softcenter/ss/version` 
	echo_date "--------------------"
}

restore_sh(){
	echo_date 检测到ss备份文件...
	echo_date 开始恢复配置...
	chmod +x /tmp/upload/ssconf_backup.sh
	sh /tmp/upload/ssconf_backup.sh
	dbus set ss_basic_enable="0"
	dbus set ss_basic_version_local=`cat /jffs/softcenter/ss/version` 
	echo_date 配置恢复成功！
}

restore_json(){
	echo_date 检测到ss json配置文件...
	ss_format=`echo $confs|grep "obfs"`
	cat /tmp/ssconf_backup.json | jq --tab . > /tmp/ssconf_backup_formated.json
	if [ -z "$ss_format" ];then
		# SS json
		echo_date 检测到ss json配置文件...
		servers=$(cat /tmp/ssconf_backup_formated.json |grep -w server|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2)
		ports=`cat /tmp/ssconf_backup_formated.json |grep -w server_port|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		passwords=`cat /tmp/ssconf_backup_formated.json |grep -w password|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		methods=`cat /tmp/ssconf_backup_formated.json |grep -w method|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		remarks=`cat /tmp/ssconf_backup_formated.json |grep -w remarks|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		
		echo_date 开始导入配置...导入json配置不会覆盖原有配置.
		last_node=`dbus list ssconf_basic_server|cut -d "=" -f 1| cut -d "_" -f 4| sort -nr|head -n 1`
		if [ ! -z "$last_node" ];then
			k=`expr $last_node + 1`
		else
			k=1
		fi
		min=1
		max=`cat /tmp/ssconf_backup_formated.json |grep -wc server`
		while [ $min -le $max ]
		do
		    echo_date "==============="
		    echo_date import node $min
		    echo_date $k
		    
		    server=`echo $servers | awk "{print $"$min"}"`
			port=`echo $ports | awk "{print $"$min"}"`
			password=`echo $passwords | awk "{print $"$min"}"`
			method=`echo $methods | awk "{print $"$min"}"`
			remark=`echo $remarks | awk "{print $"$min"}"`
			
			echo_date $server
			echo_date $port
			echo_date $password
			echo_date $method
			echo_date $remark
			
			dbus set ssconf_basic_server_"$k"="$server"
			dbus set ssconf_basic_port_"$k"="$port"
			dbus set ssconf_basic_password_"$k"=`echo "$password" | base64_encode`
			dbus set ssconf_basic_method_"$k"="$method"
			dbus set ssconf_basic_name_"$k"="$remark"
			dbus set ssconf_basic_use_ssr_"$k"=0
			dbus set ssconf_basic_mode_"$k"=2
		    min=`expr $min + 1`
		    k=`expr $k + 1`
		done
		echo_date 导入配置成功！
	else
		# SSR json
		echo_date 检测到ssr json配置文件...
		servers=$(cat /tmp/ssconf_backup_formated.json |grep -w server|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2)
		ports=`cat /tmp/ssconf_backup_formated.json |grep -w server_port|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		passwords=`cat /tmp/ssconf_backup_formated.json |grep -w password|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		methods=`cat /tmp/ssconf_backup_formated.json |grep -w method|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		remarks=`cat /tmp/ssconf_backup_formated.json |grep -w remarks|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		obfs=`cat /tmp/ssconf_backup_formated.json |grep -w obfs|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		obfsparam=`cat /tmp/ssconf_backup_formated.json |grep -w obfsparam|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		protocol=`cat /tmp/ssconf_backup_formated.json |grep -w protocol|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|cut -d ":" -f 2`
		protocolparam=`cat /tmp/ssconf_backup_formated.json |grep -w protocolparam|sed 's/"//g'|sed 's/,//g'|sed 's/[[:space:]]//g'|sed 's/protocolparam://g'`
		
		echo_date 开始导入配置...导入json配置不会覆盖原有配置.
		last_node=`dbus list ssconf_basic_server|cut -d "=" -f 1| cut -d "_" -f 4| sort -nr|head -n 1`
		if [ ! -z "$last_node" ];then
			k=`expr $last_node + 1`
		else
			k=1
		fi
		min=1
		max=`cat /tmp/ssconf_backup_formated.json |grep -wc server`
		while [ $min -le $max ]
		do
		    echo_date "==============="
		    echo_date import node $min
		    echo_date $k
		    
		    server=`echo $servers | awk "{print $"$min"}"`
			port=`echo $ports | awk "{print $"$min"}"`
			password=`echo $passwords | awk "{print $"$min"}"`
			method=`echo $methods | awk "{print $"$min"}"`
			remark=`echo $remarks | awk "{print $"$min"}"`
			obf=`echo $obfs | awk "{print $"$min"}"`
			obfspara=`echo $obfsparam | awk "{print $"$min"}"`
			protoco=`echo $protocol | awk "{print $"$min"}"`
			protocolpara=`echo $protocolparam | awk "{print $"$min"}"`
			
			echo_date $server
			echo_date $port
			echo_date $password
			echo_date $method
			echo_date $remark
			echo_date $obf
			echo_date $obfspara
			echo_date $protoco
			echo_date $protocolpara
			
			dbus set ssconf_basic_server_"$k"="$server"
			dbus set ssconf_basic_port_"$k"="$port"
			dbus set ssconf_basic_password_"$k"=`echo "$password" | base64_encode`
			dbus set ssconf_basic_method_"$k"="$method"
			dbus set ssconf_basic_name_"$k"="$remark"
			dbus set ssconf_basic_ssr_obfs_"$k"="$obf"
			dbus set ssconf_basic_ssr_obfs_param_"$k"="$obfspara"
			dbus set ssconf_basic_ssr_protocol_"$k"="$protoco"
			dbus set ssconf_basic_ssr_protocol_para_"$k"="$protocolpara"
			dbus set ssconf_basic_use_ssr_"$k"=1
			dbus set ssconf_basic_mode_"$k"=2
		    min=`expr $min + 1`
		    k=`expr $k + 1`
		done
		echo_date 导入配置成功！
	fi
}

restore_now(){
	[ -f "/tmp/upload/ssconf_backup.sh" ] && restore_sh
	[ -f "/tmp/upload/ssconf_backup.json" ] && restore_json
	echo_date 一点点清理工作...
	rm -rf /tmp/ss_conf_*
	echo_date 完成！
}

reomve_ping(){
	# flush previous ping value in the table
	pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
	if [ -n "$pings" ];then
		for ping in $pings
		do
			echo "remove $ping"
			dbus remove "$ping"
		done
	fi
}

download_ssf(){
	rm -rf /tmp/files
	rm -rf /jffs/softcenter/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /jffs/softcenter/webs/files
	if [ -f "/tmp/upload/ssf_status.txt" ];then
		cp -rf /tmp/upload/ssf_status.txt /tmp/files/ssf_status.txt
	else
		echo "日志为空" > /tmp/files/ssf_status.txt
	fi
}

download_ssc(){
	rm -rf /tmp/files
	rm -rf /jffs/softcenter/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /jffs/softcenter/webs/files
	if [ -f "/tmp/upload/ssc_status.txt" ];then
		cp -rf /tmp/upload/ssc_status.txt /tmp/files/ssc_status.txt
	else
		echo "日志为空" > /tmp/files/ssc_status.txt
	fi
}

case $2 in
1)
	echo " " > /tmp/upload/ss_log.txt
	backup_conf
	http_response "$1"
	;;
2)
	echo " " > /tmp/upload/ss_log.txt
	backup_tar >> /tmp/upload/ss_log.txt
	sleep 1
	http_response "$1"
	sleep 2	
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
3)
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	remove_now >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
4)
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	remove_silent >> /tmp/upload/ss_log.txt
	restore_now >> /tmp/upload/ss_log.txt
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
5)
	reomve_ping
	;;
6)
	echo " " > /tmp/upload/ss_log.txt
	download_ssf
	http_response "$1"
	;;
7)
	echo " " > /tmp/upload/ss_log.txt
	download_ssc
	http_response "$1"
	;;
esac
