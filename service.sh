#!/system/bin/sh

LOG_FILE="/data/adb/modules/Quest3-NCM/ncm-aio-setup.log"

# remove usb gadget configs so we can add new ones
rm -rf /config/usb_gadget/g1/configs/b.1/*

ln -s /config/usb_gadget/g1/functions/ncm.0 /config/usb_gadget/g1/configs/b.1 && ln -s /config/usb_gadget/g1/functions/ffs.adb /config/usb_gadget/g1/configs/b.1 && ln -s /config/usb_gadget/g1/functions/ffs.xrsp /config/usb_gadget/g1/configs/b.1
echo "$(date) linked functions" >> $LOG_FILE

# Wait for usb0 to exist
while ! ip link show usb0 >/dev/null 2>&1; do
    sleep 1
done

# start usb0
echo "$(date) setting usb0 up" >> $LOG_FILE
ip addr flush dev usb0
ip addr add 192.168.42.2/24 dev usb0
ip link set usb0 up

# Wait until usb0 is fully UP
while ! ip link show usb0 | grep -q "state UP"; do
    sleep 1
done
echo "$(date) usb0 is up" >> $LOG_FILE

# start dhcp server
/debug_ramdisk/.magisk/busybox/udhcpd /data/adb/modules/Quest3-NCM/udhcpd-usb0.conf
echo "$(date) udhcpd started" >> $LOG_FILE

# sleep incase usb0 is taking a while to startup
sleep 5

# add static ip to usb0 (again), so you dont need to replug usb after root
ifconfig usb0 192.168.42.2 netmask 255.255.255.0 up
echo "$(date) usb0 IP set" >> $LOG_FILE

echo "$(date) starting usb0 prio iptables sh" >> $LOG_FILE
chmod +x /data/adb/modules/Quest3-NCM/iptables-setter.sh
/data/adb/modules/Quest3-NCM/iptables-setter.sh &

echo "$(date) auto usb ip starting" >> $LOG_FILE
# Monitor usb0 link events
/system/bin/ip monitor link | while read line; do
    if echo "$line" | grep -q "usb0:.*UP"; then
        echo "$(date) usb0 is up, assigning IP..." >> $LOG_FILE
        /system/bin/ip addr flush dev usb0
        /system/bin/ip addr add 192.168.42.2/24 dev usb0
        /system/bin/ip link set usb0 up
        echo "$(date) usb0 IP assigned" >> $LOG_FILE
    fi
done
