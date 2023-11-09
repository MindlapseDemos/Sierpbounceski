; Sierpbounceski / Mindlapse
; --------------------------
; Sierpinski fractal, bummed to 253b down from the 416b initial version
; Author: John Tsiombikas (Nuclear / Mindlapse) <nuclear@member.fsf.org>
; This code is public domain
; --------------------------
; Build for DOS: nasm -o sierpb.com -f bin sierpb.asm
; Build as boot sector: nasm -o sierpb.img -f bin -DBOOTSECT sierpb.asm
; --------------------------
	bits 16
%ifdef BOOTSECT
	org 7c00h
%else
	org 100h
%endif

NUM_POINTS equ 8192
SHADOW_OFFS equ 5

SIERP_PT equ code_end
RANDVAL equ code_end + 4
SIERP_VERTS equ code_end + 8


%macro WAIT_VBLANK 0
	mov dx, 3dah
.notblank:
	in al, dx
	and al, 8
	jz .notblank	; loop while vblank bit is 0 (visible area)
%endmacro

%macro RAND 0
	; random number generator
	mov ax, [randval]
	mov bx, ax
	shr bx, 7
	xor ax, bx
	mov bx, ax
	shl bx, 9
	xor ax, bx
	mov [randval], ax
%endmacro


start:
%ifdef ROM
	dw 0aa55h
	db 10h		; length in 512-byte blocks (8k)
	mov ax, cs
	test ax, ax
	jz .skipcopy
	mov ds, ax
	xor ax, ax
	mov es, ax
	mov si, ax
	mov di, 7c00h
	mov cx, 256
	rep movsw
	jmp 0:7c03h
.skipcopy:
%endif
%ifdef BOOTSECT
	xor ax, ax
	mov ds, ax
	mov es, ax
	jmp 00:.setcs
.setcs:
%ifndef ROM
	mov ss, ax
	xor sp, sp
%endif
%endif
	mov al, 13h
	int 10h

	; "allocate" the next segment for the framebuffer
	mov ax, es
	add ax, 1000h
	mov es, ax

mainloop:
	; --- animate start ---
	mov cx, 3
	mov di, sierp_verts
	mov si, sierp_vel
.loop:
	mov bx, 4
.xyloop:
	mov ax, [di]		; grab vertex X
	add ax, [si]		; add velocity X
	jl .xout
	cmp ax, [bx + bounds - 2]
	jge .xout
	jmp .skip_xflip
.xout:
	sub ax, [si]		; revert to previous X
	neg word [si]		; negate velocity X
.skip_xflip:
	mov [di], ax		; update vertex X

	; to do the same for Y increment edi and esi by 2
	add di, 2
	add si, 2
	sub bx, 2
	jnz .xyloop

	dec cx
	jnz .loop
	; --- animate end ---


	; clear the framebuffer
	mov al, 128
	mov cx, 64000
	xor di, di
	rep stosb

	mov si, setcol + 1
	; draw shadow
	mov bp, 5
	mov byte [si], 199	; shadow color
	call drawsierp
	; draw fractal
	xor bp, bp
	mov byte [si], 48h	; fractal color
	call drawsierp

	; copy framebuffer to video ram
	push ds
	push es
	; point ds:si (source) to es:0 (framebuffer)
	push es
	pop ds
	xor si, si
	; point es:di (dest) to a000:0
	push word 0a000h
	pop es
	xor di, di
	mov cx, 32000
	WAIT_VBLANK
	rep movsw
	pop es
	pop ds

%ifndef BOOTSECT
%define ESCQUIT
%endif
%ifdef ROM
%define ESCQUIT
%endif

%ifndef ESCQUIT
	jmp mainloop
%else
	in al, 60h	; read pending scancode from the keyboard port (if any)
	dec al		; ESC is 1, so decrement ...
	jnz mainloop	; ... and loop as long as the result was not 0

	; switch back to text mode (mode 3)
	mov ax, 3
	int 10h
%ifdef ROM
	retf	; return to BIOS POST
%else
	ret	; return to dos
%endif
%endif

	; draw sierpinski triangle
drawsierp:
	; start from one of the vertices
	mov ax, [sierp_verts]
	mov bx, [sierp_verts + 2]
	mov [SIERP_PT], ax
	mov [SIERP_PT + 2], bx
	; number of iterations in cx
	mov cx, NUM_POINTS
dsloop:	; pick a vertex at random and move half-way there
	RAND
	mov bx, 3
	xor dx, dx
	div bx	; dx is now rand % 3
	; put the vertex address in bx
	mov bx, sierp_verts
	shl dx, 2
	add bx, dx
	; add to SIERP_PT and divide by 2 to move half-way there
	mov ax, [bx]
	add ax, [SIERP_PT]
	shr ax, 1
	mov [SIERP_PT], ax	; store the resulting X back to [SIERP_PT]
	mov di, ax		; save X coordinate in di
	mov ax, [bx + 2]
	add ax, [SIERP_PT + 2]
	shr ax, 1
	mov [SIERP_PT + 2], ax	; store the reuslting Y back to [SIERP_PT + 2]
	add ax, bp	; add offset
	mov bx, ax
	shl ax, 8
	shl bx, 6
	add bx, ax		; bx = Y * 320
setcol:	mov al, 1
	mov byte [es:bx + di], al

	dec cx
	jnz dsloop
	ret

sierp_verts:
	dw 160, 40
	dw 240, 160
	dw 80, 160
sierp_vel:
	dw 1, 1
	dw -1, 1
	dw -1, -1
bounds	dw 200 - SHADOW_OFFS
	dw 320


	; random number generator
;rand:
;	mov eax, [RANDVAL]
;	mul dword [randmul]
;	add eax, 12345
;	and eax, 0x7fffffff
;	mov [RANDVAL], eax
;	shr eax, 16
;	ret

;randmul dd 1103515245
randval dw 0ace1h
code_end:

%ifdef BOOTSECT
	times 510-($-$$) db 0
	db 0x55,0xaa
%endif
; vi:ft=nasm:
