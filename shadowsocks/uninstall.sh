#! /bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

sh /jffs/softcenter/ss/ssconfig.sh stop
sh /jffs/softcenter/scripts/ss_conf.sh jffs/softcenter 3
sleep 1

rm -rf /jffs/softcenter/ss/*
rm -rf /jffs/softcenter/scripts/ss_*
rm -rf /jffs/softcenter/webs/Module_shadowsocks*
rm -rf /jffs/softcenter/bin/ss-redir
rm -rf /jffs/softcenter/bin/ss-tunnel
rm -rf /jffs/softcenter/bin/ss-local
rm -rf /jffs/softcenter/bin/rss-redir
rm -rf /jffs/softcenter/bin/rss-tunnel
rm -rf /jffs/softcenter/bin/rss-local
rm -rf /jffs/softcenter/bin/obfs-local
rm -rf /jffs/softcenter/bin/koolgame
rm -rf /jffs/softcenter/bin/pdu
rm -rf /jffs/softcenter/bin/haproxy
rm -rf /jffs/softcenter/bin/dnscrypt-proxy
rm -rf /jffs/softcenter/bin/dns2socks
rm -rf /jffs/softcenter/bin/client_linux_arm*
rm -rf /jffs/softcenter/bin/chinadns
rm -rf /jffs/softcenter/bin/chinadns1
rm -rf /jffs/softcenter/bin/resolveip
rm -rf /jffs/softcenter/bin/speederv1
rm -rf /jffs/softcenter/bin/speederv2
rm -rf /jffs/softcenter/bin/udp2raw
rm -rf /jffs/softcenter/bin/v2ray
rm -rf /jffs/softcenter/bin/v2ctl
rm -rf /jffs/softcenter/bin/v2ray-plugin
rm -rf /jffs/softcenter/bin/https_dns_proxy
rm -rf /jffs/softcenter/bin/httping
rm -rf /jffs/softcenter/bin/haveged
rm -rf /jffs/softcenter/res/icon-shadowsocks.png
rm -rf /jffs/softcenter/res/ss-menu.js
rm -rf /jffs/softcenter/res/qrcode.js
rm -rf /jffs/softcenter/res/tablednd.js
rm -rf /jffs/softcenter/res/all.png
rm -rf /jffs/softcenter/res/gfw.png
rm -rf /jffs/softcenter/res/chn.png
rm -rf /jffs/softcenter/res/game.png
rm -rf /jffs/softcenter/res/shadowsocks.css
find /jffs/softcenter/init.d/ -name "*shadowsocks.sh" | xargs rm -rf
find /jffs/softcenter/init.d/ -name "*socks5.sh" | xargs rm -rf

dbus remove softcenter_module_shadowsocks_home_url
dbus remove softcenter_module_shadowsocks_install
dbus remove softcenter_module_shadowsocks_md5
dbus remove softcenter_module_shadowsocks_version

dbus remove ss_basic_enable
dbus remove ss_basic_version_local
dbus remove ss_basic_version_web
dbus remove ss_basic_v2ray_version
