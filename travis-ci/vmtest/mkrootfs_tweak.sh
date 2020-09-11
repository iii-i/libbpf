#!/bin/bash
# This script prepares a mounted root filesystem for testing libbpf in a virtual
# machine.
set -e -u -x -o pipefail
root=$1
shift

chroot "${root}" /bin/busybox --install

cat > "$root/etc/fstab" << "EOF"
dev /dev devtmpfs rw,nosuid 0 0
proc /proc proc rw,nosuid,nodev,noexec 0 0
sys /sys sysfs rw,nosuid,nodev,noexec 0 0
debugfs /sys/kernel/debug debugfs mode=755,realtime 0 0
bpffs /sys/fs/bpf bpf realtime 0 0
EOF
chmod 644 "$root/etc/fstab"

cat > "$root/etc/inittab" << "EOF"
::sysinit:/etc/init.d/rcS
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
::restart:/sbin/init
EOF
chmod 644 "$root/etc/inittab"

mkdir -m 755 "$root/etc/init.d" "$root/etc/rcS.d"
cat > "$root/etc/rcS.d/S10-mount" << "EOF"
#!/bin/sh

/bin/mount -a
EOF
chmod 755 "$root/etc/rcS.d/S10-mount"

cat > "$root/etc/rcS.d/S40-network" << "EOF"
#!/bin/sh

ip link set lo up
EOF
chmod 755 "$root/etc/rcS.d/S40-network"

cat > "$root/etc/init.d/rcS" << "EOF"
#!/bin/sh

for path in /etc/rcS.d/S*; do
	[ -x "$path" ] && "$path"
done
EOF
chmod 755 "$root/etc/init.d/rcS"

chmod 755 "$root"
