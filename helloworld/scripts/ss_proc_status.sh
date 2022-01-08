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
	XRAY=$(pidof xray)
	game_on=$(dbus list ss_acl_mode | cut -d "=" -f 2 | grep 3)

	if [ "$ss_basic_type" == "0" ]; then
		echo
		echo  检测当前相关进程工作状态：（你正在使用SS-libev,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$SS_REDIR" ] && echo "ss-redir	工作中	pid：$SS_REDIR" || echo "ss-redir	未运行"
		if [ -n "$SS_V2RAY" ]; then
			echo "v2ray-plugin	工作中	pid：$SS_V2RAY"
		fi
	elif [ "$ss_basic_type" == "1" ]; then
		echo
		echo 检测当前相关进程工作状态：（你正在使用SSR-libev,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$SSR_REDIR" ] && echo "ssr-redir	工作中	pid：$SSR_REDIR" || echo "ssr-redir	未运行"
	elif [ "$ss_basic_type" == "2" ]; then
		echo
		echo 检测当前相关进程工作状态：（你正在使用xray,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$XRAY" ] && echo "xray		工作中	pid：$XRAY" || echo "xray	未运行"
	elif [ "$ss_basic_type" == "3" ]; then
		echo
		echo 检测当前相关进程工作状态：（你正在使用trojan,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$XRAY" ] && echo "trojan	工作中	pid：$XRAY" || echo "trojan未运行"
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
