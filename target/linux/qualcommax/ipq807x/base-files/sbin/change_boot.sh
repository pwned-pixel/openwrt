#!/bin/sh

echo "0" > /sys/class/leds/q1:channel1/device/run_engine
echo "00499C0040FF7E0040007E00A001" > /sys/class/leds/q1:channel1/device/engine1_load
echo "1" > /sys/class/leds/q1:channel1/device/run_engine

find_mtd_index() {
	local PART="$(grep "\"$1\"" /proc/mtd | awk -F: '{print $1}')"
	local INDEX="${PART##mtd}"
	echo ${INDEX}
}

mtd_part_2="mtd""$(find_mtd_index 0:bootconfig)"
mtd_part_3="mtd""$(find_mtd_index 0:bootconfig1)"

[ -z "$mtd_part_2" ] && reboot
[ -z "$mtd_part_3" ] && reboot

bootconfig0rootfs=$(hexdump -v -e '1/1 "%01x|"' -n 1 -s 168 -C /dev/"$mtd_part_2" | cut -f 1 -d "|" | head -n1)

prepare_bootconfig() {
	rm /tmp/"$mtd_part_2".bin
	dd if=/dev/"$mtd_part_2" of=/tmp/"$mtd_part_2".bin bs=336 count=1
	offset=$(echo 148 168 188)
	if [ "${bootconfig0rootfs}" -eq 0 ]; then
		for i in $offset; do printf '\x01' | dd of=/tmp/"$mtd_part_2".bin bs=1 seek="$i" count=1 conv=notrunc; done
	else
		for i in $offset; do printf '\x00' | dd of=/tmp/"$mtd_part_2".bin bs=1 seek="$i" count=1 conv=notrunc; done
	fi
}

prepare_bootconfig

write_bootconfig() {
	dd if=/tmp/"$mtd_part_2".bin 2>/dev/null | mtd -e /dev/"$mtd_part_2" write - /dev/"$mtd_part_2" 2>/dev/null
	dd if=/tmp/"$mtd_part_2".bin 2>/dev/null | mtd -e /dev/"$mtd_part_3" write - /dev/"$mtd_part_3" 2>/dev/null
	sync
}

write_bootconfig

echo "0" > /sys/class/leds/q1:channel1/device/run_engine

echo "Please reboot now!"

exit 0