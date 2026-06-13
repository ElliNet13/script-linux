run
part-disk /dev/sda mbr
mkfs ext4 /dev/sda1
mount /dev/sda1 /
copy-in rootfsworkdir/. /
sync
quit