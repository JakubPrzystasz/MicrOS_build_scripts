#!/bin/bash

if test $# -eq 0; then
	echo "Mode not specified"
	exit 1
fi

while test $# -gt 0; do
	case "$1" in
		-debug)
			DEBUG=1
            shift
			;;
		-run)
			RUN=1
            shift
            ;;
	esac
done

#killall qemu
# -drive file=build/hdd.img,format=raw
# -d cpu_reset\ #cpu reset log
# -d int\ # interrupt cpu log

if [ $DEBUG -eq 1 ]; then
qemu-system-i386 -m 640M\
 -machine kernel_irqchip=off\
 -drive file=build/floppy.img,format=raw,if=floppy\
 -drive file=build/hdd.img,format=raw,if=virtio\
 -netdev user,id=mynet0,hostfwd=tcp::5555-:22 -net nic,model=rtl8139,netdev=mynet0\
 -boot a -S -s\
 -object filter-dump,id=f1,netdev=mynet0,file=dump.dat\
 -no-shutdown -no-reboot\
 -monitor stdio
fi

if [ $RUN -eq 1 ]; then
qemu-system-i386 -m 640M\
 -drive file=build/floppy.img,format=raw,if=floppy\
 -drive file=build/hdd.img,format=raw -boot a -soundhw pcspk\
 -netdev user,id=u1,hostfwd=tcp::5555-:22\
 -device rtl8139,netdev=u1
fi
