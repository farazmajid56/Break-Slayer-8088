org 0x0100

jmp start

printString:
	push bp
	mov bp, sp					; conserving the previous data
	pusha 
	
	mov ah, 0x13				; service (print string)
	mov al, 1					; subservice |update cursor|
	mov bh, 0					; page no
	mov bl, byte[bp + 12] 		; attribute
	mov dh, byte[bp + 4]		; row no
	mov dl, byte[bp + 6]		; col no
	mov cx, word[bp + 8]		; length of string
	push cs
	pop es
	mov si, word[bp + 10]		; the string that we need
	mov bp, si
	int 0x10

	popa
	pop bp

	ret 10


drawBoxes:
	pusha
	mov ax, 2	; it controls column
	mov bx, 0	; it controls row
	mov si,0x37
	loop1:
		push si
		push str1
		push 6
		push ax
		push bx
		call printString
		
		add ax, 7
		cmp ax, 79
		jb loop1
		add si,0x10
		add bx, 2 ; next line
		mov ax, 2 ; reset ax to 2
		cmp bx, 7 ; print 3 lines
		jb loop1

	popa
	ret

clearscreen:
	pusha
	mov ah, 0x00
	mov al, 0x03  ; text mode 80x25 16 colours
	int 0x10
	popa
	ret

delay:
	pusha
	MOV     CX, 06H ; speed
	MOV     DX, 4240H
	MOV     AH, 86H
	INT     15H
	popa
	ret

moveBall:
	pusha
	mov ax, 13	; it controls column
	mov bx, 23	; it controls row

	loop2:
		push 0x37
		push str2
		push 1
		push ax
		push bx
		call printString

		call delay

		; clearing the previous position of ball
		push 0x07
		push str3
		push 1
		push ax
		push bx
		call printString

		dec bx
		cmp bx, 6
		jne loop2

		; removing the box
		push 0x07
		push str1
		push 6
		push 9
		push 5
		call printString	

	popa
	ret

drawSlate:

	pusha 

	push 0x47
	push str4
	push 10
	push word[slateX]
	push 25
	call printString

	popa
	ret

exitScreen:
	pusha
	push ax
	push cx
	mov ax,10001011b ; attr dark cyan on black
	mov cx,0
	
	push ax
	push f1
	push 47
	push 1 ;col
	push cx ;row
	call printString

	inc cx
	push ax
	push f2
	push 47
	push 1 ;col
	push cx ;row
	call printString

	inc cx
	push ax
	push f3
	push 47
	push 1 ;col
	push cx ;row
	call printString
	
	inc cx
	push ax
	push f4
	push 17
	push 1 ;col
	push cx ;row
	call printString

	inc cx
	push ax
	push f5
	push 17
	push 1 ;col
	push cx ;row
	call printString
		
	inc cx
	push ax
	push f6
	push 17
	push 1 ;col
	push cx ;row
	call printString

	mov ax,10001010b ; attr light green on black

	inc cx
	push ax
	push m1
	push 54
	push 1 ;col
	push cx ;row
	call printString

	inc cx
	push ax
	push m2
	push 54
	push 1 ;col
	push cx ;row
	call printString

	inc cx
	push ax
	push m3
	push 54
	push 1 ;col
	push cx ;row
	call printString
	
	inc cx
	push ax
	push m4
	push 17
	push 1 ;col
	push cx ;row
	call printString

	inc cx
	push ax
	push m5
	push 17
	push 1 ;col
	push cx ;row
	call printString
		
	inc cx
	push ax
	push m6
	push 17
	push 1 ;col
	push cx ;row
	call printString
	
	pop cx
	pop ax
	popa
	ret

customIsr:
	pusha

	push 0xb800
	pop es

	in al, 0x60			; reading the character from the keyboard

	; now we start the comparison with left arrow key
	cmp al, 0x4b
	jne rightArrowKey
	; removing the slate from its previous position
	push 0x07
	push str4
	push 10
	push word[slateX]
	push 24
	call printString

	; printing the new Slate
	sub word[slateX], 1
	push 0x47
	push str4
	push 10
	push word[slateX]
	push 24
	call printString
	jmp exit

rightArrowKey:
	cmp al, 0x4d
	jne checkEscape
	; removing the slate from previous position
	push 0x07
	push str4
	push 10
	push word[slateX]
	push 24
	call printString
	; printing the new Slate
	add word[slateX], 1
	push 0x47
	push str4
	push 10
	push word[slateX]
	push 24
	call printString
	jmp exit

checkEscape:
	cmp al, 0x01
	jne nomatch
	jmp exit

exit:
	mov al, 0x20
	out 0x20, al
	popa
	iret

nomatch:
	popa
	jmp far[cs:oldisr]

start:
	call clearscreen
	call drawBoxes
	call drawSlate

	; hooking the interrupts for changing direction of slate
	xor ax, ax
	mov es, ax
	mov ax, [es: 9*4] ; keyboard int
	mov [oldisr], ax ; store old int code
	mov ax, [es: 9*4 + 2]
	mov [oldisr + 2], ax
	cli 
	mov word[es: 9*4], customIsr ; overwrite code with this
	mov word[es: 9*4 + 2], cs
	sti

	call moveBall
	call delay
	call clearscreen
	call exitScreen
	mov eax, 0x4c00
	int 0x21


str1: db '      ',0
str2: db ' ',0
str3: db ' ',0
str4: db '          ',0

oldisr: dd 0

slateX: dw 10

f1: db '____ ____ ____ ____ ___     _  _ ____  _ _ ___ ',0  
f2: db '|___ |__| |__/ |__|   /     |\/| |__|  | | |  \',0
f3: db '|    |  | |  \ |  |  /__    |  | |  | _| | |__/',0
;47
f4: db '+-+-+-+-+-+-+-+-+',0
f5: db '|2|0|L|-|1|1|6|2|',0
f6: db '+-+-+-+-+-+-+-+-+',0
;17
m1: db '_  _ ____ ____ ____ ____ _  _    _  _ ____ _    _ _  _',0 
m2: db '|\/| |___ |___ |__/ |__| |\ |    |\/| |__| |    | |_/ ',0 
m3: db '|  | |___ |___ |  \ |  | | \|    |  | |  | |___ | | \_',0
;54
m4: db '+-+-+-+-+-+-+-+-+',0
m5: db '|2|0|L|-|2|1|1|1|',0
m6: db '+-+-+-+-+-+-+-+-+',0
;17
                                                       