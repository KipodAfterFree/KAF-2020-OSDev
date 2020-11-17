all: boot_img

boot_img:
	nasm src/bootsector.asm -fbin -o build/sector.bin
	nasm src/keys.asm -fbin -o build/keys.bin
	cat build/sector.bin build/keys.bin > build/boot.img