

# http://stackoverflow.com/questions/31479054/is-there-something-like-org-for-nasm-in-gas
mbr.bin : mbr.o Makefile
	gobjcopy --only-section=.text --output-target binary mbr.o mbr.bin

mbr.o : mbr.s Makefile
	gcc -c -m16 -Wall -march=i386 -o mbr.o mbr.s

testhdd.img : mbr.bin Makefile
	qemu-img create testhdd.img 128M
	mountpoint=`hdiutil attach testhdd.img -nomount`; \
	newfs_msdos -F 32 $${mountpoint}; \
	dd of=$${mountpoint} if=./mbr.bin bs=1 count=422 skip=90 seek=90; \
	dd of=$${mountpoint} if=./mbr.bin bs=1 count=3; \
	hdiutil detach $${mountpoint}

run : testhdd.img
	make mount
	cp -r ./bootfiles/* ./dev/
	make unmount
	qemu-system-x86_64 -vga std -drive file=testhdd.img,index=0,if=ide,format=raw,media=disk

installMBR : mbr.bin

# https://program.g.hatena.ne.jp/lnznt/?word=*%5Bx86%20asm%5D
disasm : mbr.bin
	gobjdump -D mbr.bin -b binary -m i8086 -M data16,addr16

clean :
	-rm *.o

mount : testhdd.img
	hdiutil attach testhdd.img -mountpoint ./dev/

unmount :
	hdiutil detach ./dev/

src_only :
	make clean
	-rm mbr.bin
