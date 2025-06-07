#!/bin/sh

exec > /root/setup.log 2>&1

# dont remove!
echo "Installed Time: $(date '+%A, %d %B %Y %T')"
sed -i "s#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' / ':'')+(luciversion||''),#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' OPEN-WRT':''),#g" /www/luci-static/resources/view/status/include/10_system.js
sed -i -E "s|icons/port_%s.png|icons/port_%s.gif|g" /www/luci-static/resources/view/status/include/29_ports.js
sed -i -E "s|services/ttyd|system/ttyd|g"
if grep -q "ImmortalWrt" /etc/openwrt_release; then
  sed -i "s/\(DISTRIB_DESCRIPTION='ImmortalWrt [0-9]*\.[0-9]*\.[0-9]*\).*'/\1'/g" /etc/openwrt_release
  echo Branch version: "$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')"
elif grep -q "OpenWrt" /etc/openwrt_release; then
  sed -i "s/\(DISTRIB_DESCRIPTION='OpenWrt [0-9]*\.[0-9]*\.[0-9]*\).*'/\1'/g" /etc/openwrt_release
  echo Branch version: "$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')"
fi
echo "Tunnel Installed: $(opkg list-installed | grep -e luci-app-openclash -e luci-app-nikki -e luci-app-passwall | awk '{print $1}' | tr '\n' ' ')"

# Set hostname and Timezone to Asia/Jakarta
echo "Set hostname and Timezone to Asia/Jakarta"
uci set system.@system[0].hostname='OPEN-WRT'
uci set system.@system[0].timezone='WIB-7'
uci set system.@system[0].zonename='Asia/Jakarta'
uci -q delete system.ntp.server
uci add_list system.ntp.server="pool.ntp.org"
uci add_list system.ntp.server="id.pool.ntp.org"
uci add_list system.ntp.server="time.google.com"
uci commit system

# set bahasa default
uci set luci.@core[0].lang='en' && uci commit

# configure wan and lan
echo "configure wan and lan"
uci set network.lan.ipaddr="192.168.1.1"
uci set network.wan=interface
uci set network.wan.proto='dhcp'
uci set network.wan.device='eth1'
uci set network.wan.metric='10'
uci set network.tethering=interface
uci set network.tethering.proto='dhcp'
uci set network.tethering.device='usb0'
uci set network.WAN2.metric='20'
uci -q delete network.wan6
uci commit network
uci set firewall.@zone[1].network='wan tethering'
uci commit firewall

# configure ipv6
uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra
uci -q delete dhcp.lan.ndp
uci commit dhcp

# Remove sysinfo banner if Devices Amlogic
if opkg list-installed | grep luci-app-amlogic > /dev/null; then
    rm -rf /etc/profile.d/30-sysinfo.sh
fi

# custom repo and Disable opkg signature check
echo "custom repo and Disable opkg signature check"
sed -i 's/option check_signature/# option check_signature/g' /etc/opkg.conf
# echo "src/gz custom_pkg https://dl.openwrt.ai/latest/packages/$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')/kiddin9" >> /etc/opkg/customfeeds.conf

# Set login root password
(echo "root"; sleep 1; echo "root") | passwd > /dev/null

# setup default theme
uci set luci.main.mediaurlbase='/luci-static/material' && uci commit

# remove login password ttyd
uci set ttyd.@ttyd[0].command='/bin/bash --login' && uci commit

# remove huawei me909s usb-modeswitch
sed -i -e '/12d1:15c1/,+5d' /etc/usb-mode.json

# remove dw5821e usb-modeswitch
sed -i -e '/413c:81d7/,+5d' /etc/usb-mode.json

# Thales MV31-W T99W175
sed -i -e '/1e2d:00b3/,+5d' /etc/usb-mode.json

# Disable /etc/config/xmm-modem
uci set xmm-modem.@xmm-modem[0].enable='0' && uci commit

# setup misc settings
echo "setup misc settings"
sed -i 's/\[ -f \/etc\/banner \] && cat \/etc\/banner/#&/' /etc/profile
sed -i 's/\[ -n "$FAILSAFE" \] && cat \/etc\/banner.failsafe/& || \/usr\/bin\/aday/' /etc/profile
chmod -R +x /sbin
chmod -R +x /usr/bin

# netdata
mv /usr/share/netdata/web/lib/jquery-3.6.0.min.js /usr/share/netdata/web/lib/jquery-2.2.4.min.js

# Setup Auto Vnstat Database Backup
echo "Setup Auto Vnstat Database Backup"
mkdir /etc/vnstat
chmod +x /etc/init.d/vnstat_backup
bash /etc/init.d/vnstat_backup enable

# vnstati
echo "configuring netdata"
chmod +x /www/vnstati/vnstati.sh
/etc/init.d/netdata restart
/etc/init.d/vnstat restart
/www/vnstati/vnstati.sh

# Setting Tinyfm
ln -s / /www/tinyfm/rootfs

# configurating openclash
if opkg list-installed | grep luci-app-openclash > /dev/null; then
  echo "Openclash Detected!"
  echo "Configuring Core..."
  chmod +x /etc/openclash/core/clash_meta
  chmod +x /etc/openclash/GeoIP.dat
  chmod +x /etc/openclash/GeoSite.dat
  chmod +x /etc/openclash/Country.mmdb
  chmod +x /usr/bin/patchoc.sh
  echo "Patching Openclash Overview"
  bash /usr/bin/patchoc.sh
  sed -i '/exit 0/i #/usr/bin/patchoc.sh' /etc/rc.local
  ln -s /etc/openclash/history/config-wrt.db /etc/openclash/cache.db
  ln -s /etc/openclash/core/clash_meta  /etc/openclash/clash
  rm -rf /etc/config/openclash
  rm -rf /etc/openclash/custom
  rm -rf /etc/openclash/game_rules
  rm -rf /usr/share/openclash/openclash_version.sh
  find /etc/openclash/rule_provider -type f ! -name "*.yaml" -exec rm -f {} \;
  mv /etc/config/openclash1 /etc/config/openclash
  echo "setup complete!"
else
  echo "No Openclash Detected."
  rm -rf /etc/config/openclash1
  rm -rf /etc/openclash
fi

# Setup PHP
echo "setup php"
uci set uhttpd.main.ubus_prefix='/ubus'
uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
uci set uhttpd.main.index_page='cgi-bin/luci'
uci add_list uhttpd.main.index_page='index.html'
uci add_list uhttpd.main.index_page='index.php'
uci commit uhttpd
sed -i -E "s|memory_limit = [0-9]+M|memory_limit = 128M|g" /etc/php.ini
sed -i -E "s|display_errors = On|display_errors = Off|g" /etc/php.ini
ln -s /usr/bin/php-cli /usr/bin/php
[ -d /usr/lib/php8 ] && [ ! -d /usr/lib/php ] && ln -sf /usr/lib/php8 /usr/lib/php
/etc/init.d/uhttpd restart

echo "All first boot setup complete!"
rm -f /etc/uci-defaults/$(basename $0)
exit 0