.intel_syntax noprefix

.code16
.text

entry:
	lea si, [MSG_ENTRY]
	call println

fin:
	hlt
	jmp	fin

#
# subroutines
#

text_newline:
	push ax
	mov ah, 0x0e
	mov al, 0x0d	# CR
	int 0x10
	mov al, 0x0a	# LF
	int 0x10
	pop ax
	ret

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

MSG_ENTRY:     .string "CHNOSProject."
