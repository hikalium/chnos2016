# http://stackoverflow.com/questions/31479054/is-there-something-like-org-for-nasm-in-gas
hello.bin : hello.o Makefile
	gobjcopy --only-section=.text --output-target binary hello.o hello.bin

hello.o : hello.s Makefile
	gcc -c -m16 -Wall -march=i386 -o hello.o hello.s

run : hello.bin
	cp dump0.bin bootdisk.img
	dd of=./bootdisk.img if=./hello.bin bs=512 count=1 conv=notrunc
	qemu-system-x86_64 -vga std -drive file=bootdisk.img,index=0,if=ide,format=raw

# https://program.g.hatena.ne.jp/lnznt/?word=*%5Bx86%20asm%5D
disasm : hello.bin
	gobjdump -D hello.bin -b binary -m i8086 -M data16,addr16

clean :
	-rm *.o

src_only :
	make clean
	-rm hello.bin
