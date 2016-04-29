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

.org 0x5a
entry:
	# 割り込み禁止
	cli
	# データセグメント設定
	mov ax, 0x7c0
	mov ds, ax
	mov es, ax
	# スタックセグメント設定
	mov ax, 0
	mov ss, ax
	mov sp, 0x7c00
	# 割り込み再開
	sti

	# 起動ディスク番号を保存
	mov [BootDriveID], dl
	# 改行しておく
	call text_newline

checkLBA: # DL: ディスク番号
	cmp dl, 0x80
	jb	LBANotAvailable	# HDD型デバイスでなければエラー
	mov	ah, 0x41		# Check Extensions Present
	mov	bx, 0x55aa
	int	0x13
	jc	LBANotAvailable
	cmp	bx, 0xaa55
	jne	LBANotAvailable
	test	cl, 0x01	# extended disk access functions (AH=42h-44h,47h,48h) supported
	jz	LBANotAvailable 
	# ここまで来ればLBAアクセスが利用可能
	# call text_puthex_str_16

readsys:
	# RootDirの開始位置を計算
	mov eax, [BPB_FATSz32]
	mov ecx, 0
	mov cl, [BPB_NumFATs]
	imul eax, ecx
	mov cx, [BPB_RsvdSecCnt]
	add eax, ecx
	# eaxにRootDir開始セクタが入っているはず
	ror eax, 16
	call text_puthex_str_16
	ror eax, 16
	call text_puthex_str_16

# LBAアクセスで読んでみる
	mov [DAP0_StartLBALow], eax
	mov	ax, ds
	mov	[DAP0_DestSeg], ax
	lea	ax, [FATData]
	mov	[DAP0_DestOfs], ax

	lea	si, [DAP0]
	call	readWithLBA

# 読み込み結果を出力してみる
	mov si, 0
	call text_newline
dumploop:
	mov al, [si + FATData]
	call text_puthex_str_8
	add si, 1
	cmp si, 256
	jle dumploop
	
#
# Error reporting
#

error:
	lea si, [msg_err]
	jmp finmsg

LBANotAvailable:	# LBAアクセスが無理だったのであきらめる
	lea si, [msgLBANotAvailable]
	jmp finmsg

LBAError:	# LBAアクセスでエラーが起きた
	lea si, [msgLBAError]
	jmp finmsg

finmsg:
	call println
fin:
	hlt
	jmp fin

#
# subroutines
#

println:	# siにある0終端文字列を改行つきで出力
	pusha
println_loop:
	mov	al, [si]
	add si, 1
	cmp	al, 0
	je	fin
	mov ah, 0x0e
	mov bx, 15
	int	0x10
	jmp	println_loop
println_end:
	call text_newline
	popa
	ret

text_puthex_str_16:	# axを出力
	ror	ax, 8
	call	text_puthex_str_8
	rol ax, 8
	call	text_puthex_str_8
	ret

text_puthex_str_8:	# alを出力
	ror	al, 4
	call	text_puthex_char
	rol al, 4
	call	text_puthex_char
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

text_newline:
	push ax
	mov ah, 0x0e
	mov al, 0x0d	# CR
	int 0x10
	mov al, 0x0a	# LF
	int 0x10
	pop ax
	ret

# http://mbldr.sourceforge.net/specsedd30.pdf
readWithLBA:	# [DS:SI]: DAP
	#call text_newline
	#mov ax, [DAP0_DestOfs]
	#call text_puthex_str_16

	#call text_newline
	#mov ax, [DAP0_DestSeg]
	#call text_puthex_str_16

	#call text_newline
	#mov ax, si
	#call text_puthex_str_16

	mov	dl, [BootDriveID]

	#call text_newline
	#mov ah, 0
	#mov al, dl
	#call text_puthex_str_16

	mov ah, 0x42	# Extended Read Sectors From Drive
	int 0x13
	jc	LBAError
	ret
	

#
# Data
#

msg_err:			.string	"CHNIPL_ERROR"
msgLBANotAvailable:	.string	"ExtINT13H not ready"
msgLBAError:		.string	"LBA read failed"

.balign 4
DAP0:	# LBAで使用するDisk Address Packet
				.byte	0x10	# Packet Len
				.byte	0x00	# Reserved
				.word	1		# Num of sector to be read
DAP0_DestOfs:	.word	0		# dest offset
DAP0_DestSeg:	.word	0		# dest segment
DAP0_StartLBALow:	.int	0		# start LBA (Low)
DAP0_StartLBAHigh:	.int	0		# start LBA (High)

.org 0x01fe
	.byte	0x55, 0xaa	# Magic Number

.org 0x0200	# for tmp data
BootDriveID:	# MBR起動時にDLにセットされているものをコピーする
	.byte	0

.balign 8
FATData:	# dummy
