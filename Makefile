

# http://stackoverflow.com/questions/31479054/is-there-something-like-org-for-nasm-in-gas

%.o : %.S Makefile
	gcc -c -m16 -Wall -march=i386 -o $*.o $*.S

%.bin : %.o Makefile
	gobjcopy --only-section=.text --output-target binary $*.o $*.bin


testhdd.img : mbr.bin Makefile
	qemu-img create testhdd.img 128M
	mountpoint=`hdiutil attach testhdd.img -nomount`; \
	newfs_msdos -F 32 $${mountpoint}; \
	dd of=$${mountpoint} if=./mbr.bin bs=1 count=422 skip=90 seek=90; \
	dd of=$${mountpoint} if=./mbr.bin bs=1 count=3; \
	hdiutil detach $${mountpoint}

run : testhdd.img boot16.bin Makefile
	cp boot16.bin ./bootfiles/boot16.bin
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
	-rm *.bin

mount : testhdd.img
	hdiutil attach testhdd.img -mountpoint ./dev/

unmount :
	hdiutil detach ./dev/

