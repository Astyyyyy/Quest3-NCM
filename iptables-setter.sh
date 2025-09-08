#!/system/bin/sh

LOG_FILE="/data/adb/modules/Quest3-NCM/iptables-setter.log"

while ! /system/bin/ip link show usb0 >/dev/null 2>&1; do
    sleep 1
done

while true; do
    while /system/bin/ip route get 192.168.42.1 | grep -q usb0; do
	sleep 1
    done

    echo "$(date) adding usb0 as route over wlan0" >> $LOG_FILE
    /system/bin/ip rule add to 192.168.42.0/24 lookup usb0 priority 10500

    sleep 2
done
