all:
	mkdir -p isofs
	nasm -g -fbin -o isofs/ribonu ribonu.asm
	genisoimage -r -b ribonu -no-emul-boot -boot-load-size 4 -o shanos.iso isofs