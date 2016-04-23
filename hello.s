# MBR for CHNOS
.intel_syntax noprefix

.set CYLS, 0x0ff0
# http://d.hatena.ne.jp/wocota/20081029/1225274240
.set IPL_SEG, 0x7c0

.code16
.text
# FAT 32
# http://free.pjc.co.jp/fat/mem/fatm321.html
	jmp	entry			# BS_jmpBoot(3 bytes with NOP)
	nop					#
	.ascii	"CHNIPL  "	# OEM Name (8 bytes)
BPB_BytesPerSec:	.word	512			# Bytes per Sector
BPB_SecPerClus:		.byte	8			# Sector Per Cluster
BPB_RsvdSecCnt:		.word	32			# BPB_RsvdSecCnt:Num of rsvd sectors before FAT 
BPB_NumFATs:		.byte	2			# Number of FAT (2 normally)
	.word	0			# Max entries in root (not using in FAT32)
	.word	0			# Number of sectors (not using in FAT32)
	.byte	0xf0		# Media type
	.word	0			# Number of sectors in FAT (not using in FAT32)
	.word	0x0020		# Number of sectors in 1 Track
	.word	0x00ff		# Number of Heads
	.int	0			# Hidden Sectors (preceding this partiton)
	.int	0x00ef0000	# Number of sectors
BPB_FATSz32:		.int	0x00003ba3	# Number of sectors in FAT
	.word	0x0000		# FAT32 Extention Flags
	.word	0			# Version number
	.int	0x02		# Cluster number of beginning of root directory
	.word	0x01		# Sector number that contains file system info
	.word	0x06		# the sector number in the reserved of boot record
	.int	0			# Reserved
	.int	0			# Reserved
	.int	0			# Reserved
	.byte	0x00		# Drive Number
	.byte	0			# Reserved
	.byte	0x29		# Boot signature
	.int	0x3a961a09	# Volume ID
	.ascii	"CHNOSBOOT  "	# Volume Label (11 bytes) 
	.ascii	"FAT32   "		# File System Type (8 bytes)
	
	nop
	nop
	nop
	nop
entry:
	cli
	mov ax, 0x7c0
	mov ds, ax
	mov es, ax

	mov ax, 0
	mov ss, ax
	mov sp, 0x7c00

	sti

error:
	lea si, [msg_err]

err_putloop:	# siにある文字列を出力。
	mov	al, [si]
	add si, 1
	cmp	al, 0
	je	fin
	mov ah, 0x0e
	mov bx, 15
	int	0x10
	jmp	err_putloop
fin:
	hlt
	jmp fin

text_puthex_str_16:	# axを出力。0xの付加あり。
	push	ax
	push	cx
	mov	cx, ax
	mov	ah, 0x0e
	mov	al, '0'
	int	0x10
	mov	al, 'x'
	int	0x10
	mov	ax, cx
	shr	ax, 12
	call	text_puthex_char
	mov	ax, cx
	shr	ax, 8
	call	text_puthex_char
	mov	ax, cx
	shr	ax, 4
	call	text_puthex_char
	mov	ax, cx
	call	text_puthex_char
	pop	cx
	pop	ax
	ret

text_puthex_char:	# alの下位4bit分出力。0xの付加はなし。
	pusha
	and	al, 0x0f
	cmp	al, 9
	ja	text_puthex_char_alphabet
	add	al, 0x30
	jmp	text_puthex_char_end
text_puthex_char_alphabet:
	add	al, 0x37
text_puthex_char_end:
	mov	ah, 0x0e
	int	0x10
	popa
	ret

msg_err:
	.byte	0x0a
	.ascii	"CHNIPL_ERROR"
	.byte	0x0a, 0

.org 0x01fe
	.byte	0x55, 0xaa	# Magic Number
