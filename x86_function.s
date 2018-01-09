section .data
minusTen: dd -10.0
delta: dd 100.0
half: dd 0.5
one-tenth: dd 0.1
one-hundredth: dd 0.01
zero: dd 0.0
	section .text
	global x86_function
_x86_function:
x86_function:
	push rbp	; push "calling procedure" frame pointer
	mov rbp, rsp	; set new frame pointer 
			;	- "this procedure" frame pointer

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;LIST OF REGISTERS

; RAX - temporary
; RBX - unused
; RCX - Bisection method counter
; RDX - height
; RSI - width
; RDI - buffer

; R8 - temporary
; R9 - temporary
; R10 - unused
; R11 - unused
; R12 - unused
; R13 - previous X coordinate in buffer [y,x] x€[0;width)
; R14 height/2
; R15 width/2

;	XMM0 - A
;	XMM1 - B
;	XMM2 - C
;	XMM3 - S
	xor r13, r13
	movlhps xmm0,xmm0 ; A|A
	movlhps xmm1,xmm1 ; B|B
	movlhps xmm2,xmm2 ; C|C
	movlhps xmm3,xmm3 ; S|S
	mulps xmm3, xmm3  ; S^2|S^2
	mov r14, rdx 	;height
	sar r14,1 		;height/2
	mov r15, rsi 	;width
	sar r15,1 		;width/2

	
	movd xmm15, [half]
;computeFirstXY
	;xmm4 - x
	;xmm5 - y
    movd xmm4, [minusTen] ;-10
	movaps xmm5,xmm4 ;copy of -10
	mulss xmm5, xmm0 ;ax
	addss xmm5, xmm1 ;ax+b
	mulss xmm5,xmm4 ;ax^2+bx 
	addss xmm5, xmm2; ax^2+bx+c
	
	;
	;set x1,x2
	movapd xmm6, xmm4
	movd xmm7, [delta]
	addss xmm7, xmm6
	
nextBisection:
	mov rcx, 50
	movaps xmm13, xmm4
	movaps xmm14, xmm5
bisection:
	;x1 to xmm6
	;x2 to xmm7
	;(x1+x2)/2 to xmm8
	
	;x1+x2 /2
	movapd xmm8,xmm6 ;x1
	addss xmm8,xmm7; x1+x2
	mulss xmm8,xmm15;
	
	;f(x1+x2 /2 | x1)
	;(x-x0)^2+(ax^2+bx+c-y0)^2-s^2=0
	;xmm4 x0, xmm5 y0
	
	movss xmm12,xmm6 
	movlhps xmm12,xmm8 ;x1+x2 /2 | x1
	

	movlhps xmm4,xmm4;x | x
	movlhps xmm5,xmm5;y | y
	
	;xmm11 (x-x0)^2
	movaps xmm11, xmm12;x
	subps xmm11, xmm4;x-x0
	mulps xmm11, xmm11;(x1-x0)^2
	
	;xmm10 (ax^2+bx+c-y0)^2
	movaps xmm10, xmm12;x
	mulps xmm10, xmm0;ax
	addps xmm10, xmm1;ax+b
	mulps xmm10,xmm12;(ax+b)x
	addps xmm10, xmm2;(ax+b)x+c
	subps xmm10, xmm5;(ax+b)x+c-y0
	mulps xmm10, xmm10;((ax+b)x+c-y0)^2
	
	;(x-x0)^2+(ax^2+bx+c-y0)^2
	addps xmm10, xmm11
	subps xmm10, xmm3; -s^2
	
	movaps xmm11,xmm10 ;f(x1)
	movhlps xmm9,xmm10 ;f(x1+x2/2)
	
	mulss xmm9,xmm11
	movd xmm11, [zero]
	cmpless xmm9,xmm11 ;if product is less than zero
	;xmm9 equals FFFFFFFF if it is true
	movd eax, xmm9
	cmp eax, 0xFFFFFFFF
	jnz setX2
	;if negative then x2=x1+x2/2
	movapd xmm7,xmm8
bisectionElse:
	dec rcx
	jge bisection

	movapd xmm4,xmm8 ;set x0
	movapd xmm5, xmm4;x
	mulss xmm5, xmm0;ax
	addss xmm5, xmm1;ax+b
	mulss xmm5,xmm4;(ax+b)x
	addss xmm5,xmm2;(ax+b)x +c
		;set y0
	
	movapd xmm6, xmm4;next x1
	movd xmm7, [delta]
	addss xmm7, xmm6;next x2,
	
	
	;;;;;;;;;;;;;;;;;;;;
	;computing address
	;xmm5*1/10*height/2 cast to int
	;add height/2
	;all * width -> row
	;;;;;;;;;;;;;;;;;;;;
	
	movd xmm12, [one-tenth]
	
	cvtsi2ss xmm11, edx
	mulss xmm11, xmm15; height/2
	
	mulss xmm11,xmm12;height/20
	mulss xmm11, xmm5;height/20 * y
	cvtss2si r9d,xmm11
	neg r9d
	add r9d,r14d ; +height/2

	
	mov r13, r8 ; previous x on bitmap
	
	;compute x
	cvtsi2ss xmm11, esi
	mulss xmm11, xmm15 ;width/2
	mulss xmm11,xmm12;width/20
	mulss xmm11, xmm4;width/20 * x
	cvtss2si r8d,xmm11
	add r8d,r15d;+width/2
	;x coordinate in r8d 
	
	cmp r8,r13
	jg drawLine
	
	cmp r9d,0
	jle pointOutOfBitmap ;if y coordinate on bitmap is less than 0 continue
	cmp r9d, edx
	jge pointOutOfBitmap
	
	;r9 *width + r8	
	imul r9,rsi
	

	
	add r9, r8
	imul r9, 4
	add r9, rdi
	mov DWORD [rax],0xff00ff00
	pointOutOfBitmap:
	
	cvtss2si r13d,xmm4;if x>10 then break
	cmp r13d,10
	jle nextBisection
	
	pozaPetla:
end:
;------------------------------------------------------------------------------

	mov rsp, rbp	; restore original stack pointer
	pop rbp		; restore "calling procedure" frame pointer
	ret

setX2:
	movapd xmm6,xmm8
jmp bisectionElse






drawLine:
;xmm13 - previous x +0.01

;previous y - current y
movaps xmm10, xmm5
subss xmm10, xmm14 ;- previous y

movaps xmm12, xmm4
subss xmm12, xmm13;- previous x

divss xmm10,xmm12
;xmm10 - a
movaps xmm14, xmm4;current x
mulss xmm14,xmm10;ax
subss xmm14, xmm5; ax-y == -b


;a in xmm10, -b in xmm14
lineAfterComputingAB:


	;;;;;;;;;;;;;;;;;;;;
	;computing address
	;f(x)*1/10*height/2 cast to int
	;add height/2
	;all * width -> row
	;;;;;;;;;;;;;;;;;;;;
	movaps xmm9, xmm13 ;x
	mulss xmm9, xmm10 ;ax
	subss xmm9, xmm14;ax+b = f(x)
	
	
	movd xmm12, [one-tenth]
	cvtsi2ss xmm11, edx
	mulss xmm11, xmm15; height/2
	mulss xmm11,xmm12;height/20
	mulss xmm11, xmm9;height/20 * y
	
	cvtss2si eax,xmm11
	neg eax
	add eax,r14d ; +height/2
	cmp eax,0
	jle outOfBitmap ;if y coordinate on bitmap is less than 0 continue
	cmp eax, edx
	jge outOfBitmap
	
	imul eax,esi
	
	;compute x
	cvtsi2ss xmm11, esi
	mulss xmm11, xmm15 ;width/2
	mulss xmm11,xmm12;width/20
	mulss xmm11, xmm13;width/20 * x
	cvtss2si r8d,xmm11 ;width/20 * x cast to int
	add r8d,r15d;+width/2
	;x coordinate in r8d 
	add eax,r8d
	
	imul rax, 4
	add rax, rdi
	mov DWORD [rax],0xff00ff00
	outOfBitmap:
	movd xmm12, [one-hundredth]
	
	addss xmm13,xmm12 ;+=0.01
	
	movaps xmm11,xmm13
	
	cmpltss xmm11,xmm4;check drawing points condition
	;xmm11 equals FFFFFFFF if it is true
	movd eax, xmm11
	cmp eax, 0xFFFFFFFF
	je lineAfterComputingAB
jmp pointOutOfBitmap