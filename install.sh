#!/bin/sh
# Installs the TSC sync tool + early-boot unit and adds tsc=reliable to all kernels.
# Run as root. Backups go to /root/tscsync-backup/<timestamp>/.
#
# Undo:  grubby --remove-args="tsc=reliable" --update-kernel=ALL
#        systemctl disable tscsync.service
set -eu
SRC=$(cd "$(dirname "$0")" && pwd)
BK=/root/tscsync-backup/$(date +%Y%m%d-%H%M%S)

echo "== backup -> $BK"
mkdir -p "$BK/loader-entries"
cp -a /boot/loader/entries/*.conf "$BK/loader-entries/"
cp -a /etc/default/grub "$BK/grub"
grubby --info=ALL > "$BK/grubby-info-before.txt"

echo "== install tool"
mkdir -p /usr/local/src/tscsync
install -m 0644 "$SRC/tscsync.c" /usr/local/src/tscsync/tscsync.c
gcc -O2 -pthread -o /usr/local/sbin/tscsync /usr/local/src/tscsync/tscsync.c
chmod 0755 /usr/local/sbin/tscsync
restorecon -v /usr/local/sbin/tscsync /usr/local/src/tscsync/tscsync.c || true

echo "== install unit + module autoload"
install -m 0644 "$SRC/msr.conf" /etc/modules-load.d/msr.conf
install -m 0644 "$SRC/tscsync.service" /etc/systemd/system/tscsync.service
systemctl daemon-reload
systemctl enable tscsync.service

echo "== kernel argument"
grubby --args="tsc=reliable" --update-kernel=ALL
grubby --info=ALL > "$BK/grubby-info-after.txt"

echo "== result"
grubby --info=DEFAULT | grep -E '^(kernel|args)'
systemctl is-enabled tscsync.service
echo "Installed. Reboot when convenient, then check:"
echo "  cat /sys/devices/system/clocksource/clocksource0/current_clocksource   # tsc"
echo "  tscsync --measure                                                       # all ~0"
echo "  journalctl -u tscsync -b                                                # one apply line, no FAILED"
