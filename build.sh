#!/bin/bash
# Set threads count used during GCC compilation
THREADS_COUNT=4
WORKSPACE_DIR="$PWD"
HDD_SIZE=1440

# Delete old ELF and BIN files
find build -iname "*.elf" -type f -delete
find build -iname "*.bin" -type f -delete

find environment -iname "*.elf" -type f -delete
find library -iname "*.elf" -type f -delete
find os -iname "*.elf" -type f -delete

# Set release mode to reduce binary size
export MODE=release

# Build bootloader
cd os/bootloader || exit
	if ! make $1 -j "$THREADS_COUNT"; then
		exit 1
	fi
cd ../.. || exit

# Build C Library
cd library || exit
	if ! make $1 -j "$THREADS_COUNT"; then
		exit 1
	fi
cd .. || exit

# Build applications
cd environment || exit
	for i in *;
	do
		cd "$i" || exit
		if ! make $1 -j "$THREADS_COUNT"; then
			exit 1
		fi

		if [ "$1" != "clean" ]; then
			mkdir -p ../../build/floppy/ENV
			cp "bin/$i.elf" "../../build/floppy/ENV/$(echo "$i" | tr '[:lower:]' '[:upper:]')".ELF
		fi

		cd .. || exit
	done
cd .. || exit

# Build kernel
cd os/kernel || exit
	if ! make $1 -j "$THREADS_COUNT"; then
		exit 1
	fi

	if [ "$1" != "clean" ]; then
		cp bin/kernel.bin ../../build/floppy/KERNEL.BIN
		cp bin/kernel.elf ../../build/kernel.elf
	fi
cd ../.. || exit

copy() {
	cd "$1" || exit
	for i in *;
	do
		mcopy -bvi "$FLOPPY_IMG" "$i" ::"$i"
	done
	cd "$WORKSPACE_DIR" || exit
}

# Create floppy
if [ "$1" != "clean" ]; then
	FLOPPY_IMG="$WORKSPACE_DIR/build/floppy.img"
	# Remove old floppy img
	rm -f "$FLOPPY_IMG"

	# Make and format the floppy
	/sbin/mkfs.msdos -C "$FLOPPY_IMG" 1440

	# Upload bootloader to the floppy
	dd if=os/bootloader/bin/bootloader.bin of="$FLOPPY_IMG" bs=512 conv=notrunc

	# Copy kernel to the floppy
	copy build/floppy
	copy resources
fi

# Create hdd
if [ "$1" != "clean" ]; then
	mkdir -p "$WORKSPACE_DIR/build"
	mkdir -p "$WORKSPACE_DIR/build/hdd"
	HDD_IMG="$WORKSPACE_DIR/build/hdd.img"
	# Remove old hdd img
	rm -f "$HDD_IMG"

	# Make and format the hdd
	/sbin/mkfs.msdos -C "$HDD_IMG" $HDD_SIZE

	mcopy -i "$HDD_IMG" build/hdd ::
fi
