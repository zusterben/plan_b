#!/bin/sh

source /jffs/softcenter/scripts/ss_base.sh

get_mode_name() {
	case "$1" in
	1)
		echo "【gfwlist模式】"
		;;
	2)
		echo "【大陆白名单模式】"
		;;
	3)
		echo "【游戏模式】"
		;;
	5)
		echo "【全局模式】"
		;;
	esac
}

get_dns_name() {
	case "$1" in
	1)
		echo "pdnsd"
		;;
	2)
		echo "chinadns-ng"
		;;
	3)
		echo "dns2socks"
		;;
	esac
}

echo_version() {
	echo_date
	SOFVERSION=$(cat /jffs/softcenter/ss/version)
	if [ -z "$ss_basic_v2ray_version" ]; then
		ss_basic_v2ray_version_tmp=$(/jffs/softcenter/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2)
		if [ -n "$ss_basic_v2ray_version_tmp" ]; then
			ss_basic_v2ray_version="$ss_basic_v2ray_version_tmp"
			dbus set ss_basic_v2ray_version="$ss_basic_v2ray_version_tmp"
		else
			ss_basic_v2ray_version="null"
		fi
	fi
	echo ① 程序版本（插件版本：$SOFVERSION）：
	echo -----------------------------------------------------------
	echo "程序			版本			备注"
	echo "ss-redir		3.3.3			2019年11月03日编译"
	echo "ss-tunnel		3.3.3			2019年11月03日编译"
	echo "ss-local		3.3.3			2019年11月03日编译"
	echo "obfs-local		0.0.5			2018年11月25日编译"
	echo "ssr-redir		3.5.3			2018年12月06日编译"
	echo "ssr-local		3.5.3			2018年12月06日编译"
	echo "dns2socks		V2.0			2017年12月05日编译"
	echo "chinadns-ng		v1.0-beta.22		2020年06月02日编译"
	echo "httping			2.6			2020年01月06日编译"
	echo "v2ray			$ss_basic_v2ray_version			2020年06月02日编译"
	echo "v2ray-plugin		v1.3.1			Official Release 2020年06月01日"
	echo "kcptun			20200409		Official Release 2020年04月09日"
	echo -----------------------------------------------------------
}

check_status() {
	#echo
	SS_REDIR=$(pidof ss-redir)
	SS_TUNNEL=$(pidof ss-tunnel)
	SS_V2RAY=$(pidof v2ray-plugin)
	SS_LOCAL=$(ps | grep ss-local | grep 23456 | awk '{print $1}')
	SSR_REDIR=$(pidof ssr-redir)
	SSR_LOCAL=$(ps | grep ssr-local | grep 23456 | awk '{print $1}')
	SSR_TUNNEL=$(pidof ssr-tunnel)
	DNS2SOCKS=$(pidof dns2socks)
	PDNSD=$(pidof pdnsd)
	CHINADNS_NG=$(pidof chinadns-ng)
	KCPTUN=$(pidof client_linux)
	V2RAY=$(pidof v2ray)
	game_on=$(dbus list ss_acl_mode | cut -d "=" -f 2 | grep 3)

	if [ "$ss_basic_type" == "0" ]; then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用SS-libev,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$SS_REDIR" ] && echo "ss-redir	工作中	pid：$SS_REDIR" || echo "ss-redir	未运行"
		if [ -n "$SS_V2RAY" ]; then
			echo "v2ray-plugin	工作中	pid：$SS_V2RAY"
		fi
	elif [ "$ss_basic_type" == "1" ]; then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用SSR-libev,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$SSR_REDIR" ] && echo "ssr-redir	工作中	pid：$SSR_REDIR" || echo "ssr-redir	未运行"
	elif [ "$ss_basic_type" == "2" ]; then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用V2Ray,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$V2RAY" ] && echo "v2ray		工作中	pid：$V2RAY" || echo "v2ray	未运行"
	fi

		if [ "$ss_basic_use_kcp" == "1" ]; then
			[ -n "$KCPTUN" ] && echo "kcptun		工作中	pid：$KCPTUN" || echo "kcptun		未运行"
		fi
		if [ "$ss_foreign_dns" == "1" ]; then
			[ -n "$PDNSD" ] && echo "pdnsd		工作中	pid：$PDNSD" || echo "pdnsd	未运行"
		elif [ "$ss_foreign_dns" == "2" ]; then
			[ -n "${CHINADNS_NG}" ] && echo "chinadns-ng	工作中	pid：${CHINADNS_NG}" || echo "chinadns-ng	未运行"
		elif [ "$ss_foreign_dns" == "3" ]; then
			if [ -n "$ss_basic_ssr_obfs" ]; then
				[ -n "$SSR_LOCAL" ] && echo "ssr-local	工作中	pid：$SSR_LOCAL" || echo "ssr-local	未运行"
				[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			else
				if [ "$ss_basic_type" != "2" ]; then
					[ -n "$SS_LOCAL" ] && echo "ss-local	工作中	pid：$SS_LOCAL" || echo "ss-local	未运行"
				fi
				[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			fi
		fi
	echo -----------------------------------------------------------
	echo
	echo
	echo ③ 检测iptbales工作状态：
	echo ----------------------------------------------------- nat表 PREROUTING 链 --------------------------------------------------------
	iptables -nvL PREROUTING -t nat
	echo
	echo ----------------------------------------------------- nat表 OUTPUT 链 ------------------------------------------------------------
	iptables -nvL OUTPUT -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS 链 --------------------------------------------------------
	iptables -nvL SHADOWSOCKS -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_EXT 链 --------------------------------------------------------
	iptables -nvL SHADOWSOCKS_EXT -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GFW 链 ----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GFW -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_CHN 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_CHN -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GAM 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GAM -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GLO 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GLO -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_HOM 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_HOM -t nat
	echo -----------------------------------------------------------------------------------------------------------------------------------
	echo
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo ------------------------------------------------------ mangle表 PREROUTING 链 -------------------------------------------------------
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && iptables -nvL PREROUTING -t mangle
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo ------------------------------------------------------ mangle表 SHADOWSOCKS 链 -------------------------------------------------------
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && iptables -nvL SHADOWSOCKS -t mangle
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo ------------------------------------------------------ mangle表 SHADOWSOCKS_GAM 链 -------------------------------------------------------
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && iptables -nvL SHADOWSOCKS_GAM -t mangle
	echo -----------------------------------------------------------------------------------------------------------------------------------
	echo
}

if [ "$ss_basic_enable" == "1" ]; then
	check_status >/tmp/upload/ss_proc_status.txt 2>&1
	#echo XU6J03M6 >> /tmp/upload/ss_proc_status.txt
else
	echo 插件尚未启用！ >/tmp/upload/ss_proc_status.txt 2>&1
fi

http_response $1
