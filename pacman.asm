

[org 100h]

jmp main


;----------------------------------------------

;   movement flags

Left:     db 0    ; Left movement flag
Right:    db 0    ; right movement flag
Up:      db 0    ; up movement flag
Down:   db 0    ; down movement flag

;----------------------------------------------

;   old IVT values

oldkbisr:   dd 0    ; old keyboard interrupt service routine
oldtimerisr:    dd 0    ; old timerISR interrupt service routine

;----------------------------------------------

;   score variable
Score:      dw 0    ; score

;----------------------------------------------------------------
;   message strings

gameovermsg:   db 'Game Over!!!', 0
;   game over message
scoremsg:   db 'Score: ', 0

;-----------------------------------------------------------------------
;timerISR variables

ticks:      dw 0    ; count of ticks

;------------------------------------------------------------------------



;subroutine to print a grid of green and red cells on the screen
printgrid:

push ax
push es
push ds

mov ax, 0xb800
mov es, ax

mov ax, 0
mov ds, ax

;print red cell on first row
mov ax, 0x4C20
mov cx, 81
rep stosw

mov ax, 0x2A20 ; green cell
mov cx, 80*7 
rep stosw

mov ax, 0x0720 ; Black cell
mov cx, 80*4+3
rep stosw

mov ax, 0x4C20 ; red cell
mov cx, 80*1-3
rep stosw

mov ax, 0x2A20 ; green cell
mov cx, 80*6 
rep stosw

mov ax, 0x0720 ; Black cell
mov cx, 80*1
rep stosw

mov ax, 0x2A20 ; green cell
mov cx, 80*3 
rep stosw



mov ax, 0x4C20 ; red cell
mov cx, 80*1
rep stosw


mov ax, 0xb800
mov es, ax
mov di, 360 ; di pointing to the first cell 
mov ax, 0x4c20
mov cx, 20 ; number of cells to print from the first cell
cld
rep stosw


;vertical line from position 5,40 to 13,40
mov cx , 16
mov                 di, 5*80+40
partitionLine:        mov [es:di], ax
                    add di, 2
                    mov [es:di], ax
                    add di, 158
                    loop partitionLine




pop ds
pop es
pop ax


ret

;------------------------------------------------------------------------

;subroutine to print game over message
printGameOver:

push ax

mov ax, 30 
push ax ; push x position 
mov ax, 20 
push ax ; push y position 
mov ax, 1 ; blue on black attribute 
push ax ; push attribute 
mov ax, gameovermsg 
push ax ; push address of message 
call printstr

pop ax
ret



;------------------------------------------------------------------------

;subroutine to print a string on the screen ; from book.
printstr:
push bp 
mov bp, sp 
push es 
push ax 
push cx 
push si 
push di 
push ds 
pop es  
mov di, [bp+4] ; di = y position
mov cx, 0xffff  
xor al, al ; al = 0
repne scasb  ; find end of string, delimeter = 0
mov ax, 0xffff 
sub ax, cx     ; ax = length of string
dec ax  
jz exitprintstr 
mov cx, ax ; cx = length of string
mov ax, 0xb800 ; video memory
mov es, ax 
mov al, 80 ;
mul byte [bp+8] 
add ax, [bp+10] 
shl ax, 1 
mov di,ax 
mov si, [bp+4] 
mov ah, [bp+6]  
cld 
nextch: lodsb ; al = next character
stosw 
loop nextch 
exitprintstr: 
pop di 
pop si 
pop cx 
pop ax 
pop es 
pop bp 
ret 8 







;-------------------------------------------------------------------------




; to clear video screen
clrscr:
    
push es
pusha

mov ax, 0xb800
mov es, ax 
xor di, di 
mov ax, 0x0720 
mov cx, 2000 
cld 
rep stosw 

popa
pop es
ret 

;------------------------------------------------------------------------

;subroutine to check if the player is crossing a red or green cell
checkcell:

push es
pusha

mov ax, 0xb800
mov es, ax

cmp word [es:di], 0x2A20 ; green cell
je green

cmp word [es:di], 0x4C20 ; red cell
je red

jmp checkcellend

green:

add word [Score], 1 
jmp checkcellend

red: ;TODO: add code to end game

popa
pop es

jmp EOIandexit


checkcellend:

popa
pop es
ret



;------------------------------------------------------------------------


;keyboard interrupt handler
kbhandler:
push    ax
push    es

;push to stack

mov     ax, 0xb800
mov     es, ax

;check if key is pressed

in      al, 0x60


;check if right key is pressed
;flags are set in the keyboard controller
;right key is 0x4D
;left key is 0x4B
;up key is 0x48
;down key is 0x50

cmp     al, 0x4B  ;left key
jne     right_key
mov     byte[Right], 0
mov     byte[Left], 1
mov     byte[Up], 0
mov     byte[Down], 0
call printplayer
jmp nokeymatch



right_key:
cmp     al, 0x4D  ;right key
jne up_key
mov     byte[Right], 1
mov     byte[Left], 0
mov     byte[Up], 0
mov     byte[Down], 0
call printplayer
jmp nokeymatch

;printplayer called so that the player is moved instantly if the key is pressed
;otherwise the player is moved only after the timer interrupt handler is called
;which is every 1/18th of a second
;this is done to make the game more responsive

up_key:
cmp     al, 0x48   ;up key
jne down_key
mov     byte[Right], 0
mov     byte[Left], 0
mov     byte[Up], 1
mov     byte[Down], 0
call printplayer
jmp nokeymatch

down_key:
cmp     al, 0x50
jne exitgame
mov     byte[Right], 0
mov     byte[Left], 0
mov     byte[Up], 0
mov     byte[Down], 1
call printplayer
jmp nokeymatch

exitgame:
;exit on pressing x key
cmp     al, 0x2D ;x key
jne nokeymatch

;exit on pressing x key
;sending end of interrupt to PIC
;pop the stack 
EOIandexit:
mov     al, 0x20
out     0x20, al
pop     es
pop     ax
jmp end

;if neither key is pressed
;send end of interrupt to PIC and return
nokeymatch:
;send end of interrupt to PIC    
mov     al, 0x20
out     0x20, al
;pop the stack
pop     es
pop     ax
;return
iret



;------------------------------------------------------------------------

;subroutine to print the score on the screen
printnum:
push bp 
mov bp, sp 
push es
pusha

mov ax, 0xb800  ;video memory
mov es, ax
mov ax, [bp+4] ;score
mov bx, 10 ;base
mov cx, 0 ;counter

nxtdig:
mov dx, 0 
div bx 
add dl, 0x30 ;convert to ascii
push dx 
inc cx ;increment counter
cmp ax, 0  
jnz nxtdig

mov di, 3990 ; point di to last column of last row

nxtpos:
pop dx 
mov dh, 0x07 ;attribute
mov [es:di], dx 
add di, 2 ;increment di by 2

loop nxtpos 


popa
pop es
pop bp
ret 2



;------------------------------------------------------------------------





; DI == position of asterisk in the video memory
; checks which flag is set and moves the player accordingly
; if the player is moved, the old position is cleared
; if the player is not moved, the old position is not cleared
; this is done to avoid flickering
; if the player is moved on to a green cell, the score is incremented
; if the player is moved on to a red cell, the game is ended
; the player is moved only if the new position is not a wall(red cell border)
printplayer:
push    ax
push    es

mov     ax, 0xb800
mov     es, ax          ; points to video memory
;check if the player is moving right
;check if the player is moving left
;check if the player is moving up
;check if the player is moving down
;if none of the above, return

mov     word [es: di], 0x0720   ; clear previous location



chkRightDirFlag:
cmp     byte [Right], 1   ;checking right flag
JNE     chkLeftDirFlag
add     di, 2  ;move right
call    checkcell ;check if the new player postion is on a green or red cell
jmp     updateScreen

chkLeftDirFlag:
cmp     byte [Left], 1
JNE     chkUpDirFlag
sub     di, 2 ;move left
call    checkcell
jmp     updateScreen



chkUpDirFlag:
cmp     byte [Up], 1
JNE     chkDownDirFlag
sub     di, 160 ;move up
call    checkcell
jmp     updateScreen

chkDownDirFlag:
cmp     byte [Down], 1
JNE     updateScreen
add     di, 160 ;move down
call    checkcell   ;check if the new player postion is on a green or red cell
jmp     updateScreen  ;jump to printscreen to print the player


updateScreen:
;print the player on the screen at the new position    
mov     ah, 0x7    ; attribute
mov     al, '*'
mov     word [es: di], ax

;print score
push word [Score] ;push score on stack to printnum
call printnum ;uses the printnum subroutine from the book

;prints the score string on the screen using the printnum subroutine from the book
mov ax, 68 
push ax ; push x position 
mov ax, 24 
push ax ; push y position 
mov ax, 5 ; blue on black attribute 
push ax ; push attribute 
mov ax, scoremsg 
push ax ; push address of message 
call printstr 

;
pop es
pop ax
ret

;------------------------------------------------------------------------

Trimmer:
push bp
mov bp,sp
push es
push ds
push ax
push bx
push cx
push dx
push si
push di
mov ax,0xb800
mov es,ax
lds si,[bp+4]
mov al,80
mul byte [bp+12]
add ax,[bp+10]
shl ax,1
mov di,ax
mov ax,[bp+8]
push ds

l5:
push ax

cmp di,4000
je skip
push ax
sub di,2

push ax
lds si,[bp+4]
mov al,80
mul byte [bp+12]
add ax,[bp+10]
shl ax,1
mov di,ax
pop ax

jmp l5
skip:
pop di
pop si
pop dx
pop cx
pop bx
pop ax
pop ds
pop es
mov sp,bp
pop bp
ret 10

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-



; hook timerISR interrupt service routine
; this is called every 1/18th of a second
; this is done to make the game more responsive
;using delay subroutine would have made the game less responsive which wastes clock cycles
; the player is moved only after the timer interrupt handler is called
timerISR:
push    ax

;counts the number of times the timer interrupt handler is called
inc     word [cs: ticks]
cmp     word [cs: ticks], 11        ; 18.2 ticks per second  ; can speed up by changing this value

; if the number of times the timer interrupt handler is called is less than 11, return
jne     exittimerISR

;reset the ticks counter and increment the seconds counter
;the player movement and printing subroutine is called
mov     word [cs: ticks], 0
CALL    printplayer

jmp     exittimerISR


swap:
push bp
mov bp,sp
pusha
push ds
push es
xor bx,bx
mov di,0
xor dl,dl
mov ax,0xb800
mov es,ax
mov ds,ax
mov ax,0
mov si,2000
loop1:
mov cx,40
s:
mov ax,[es:di]
movsw
mov [ds:si-2],ax
loop s
inc dl
add di,80
add si,80
cmp dl,12
jne loop1

pop es
pop ds
popa
mov sp,bp

pop bp
ret

;sending end of interrupt to PIC
exittimerISR:
mov     al, 0x20        ; send EOI
out     0x20, al
pop     ax
iret

;------------------------------------------------------------------------
    
;entry point of the program
main:
call    clrscr      ; to clear screen
call    printgrid   ; to print grid
;the code is generic and can work with any grid having red and green cells.
;you can change the layout of the grid and the code will work fine

mov     di, 160 ; initial position ; can change this value to change the initial position of the player
xor     ax, ax
mov     es, ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;saving old keyboard interrupt service routine
mov     ax, 0
mov     es, ax
mov     ax, [es:9*4]
mov     [oldkbisr], ax
mov     ax, [es:9*4+2]
mov     [oldkbisr+2], ax

;saving old timerISR interrupt service routine
mov     ax, 0
mov     es, ax
mov     ax, [es:8*4]
mov     [oldtimerisr], ax
mov     ax, [es:8*4+2]
mov     [oldtimerisr+2], ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;hooking keyboard interrupt service routine
mov     ax, 0
mov     es, ax
mov     ax, kbhandler ;keyboard interrupt service routine
mov     [es:9*4], ax ; 9 is the interrupt number for keyboard
mov     ax, cs ; code segment
mov     [es:9*4+2], ax ;




; hooking timerISR interrupt service routine
cli
mov     word [es: 8*4], timerISR ; 8 is the interrupt number for timer
mov     [es: 8*4+2], cs
sti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;infinite loop to keep the program running
infinite:
jmp infinite

;ending the program by restoring the old interrupt service routines
end:

;print game over message
call printGameOver

;restoring old keyboard interrupt service routine

cli
mov     ax, 0
mov     es, ax
mov     ax, [oldkbisr] ; old keyboard interrupt service routine
mov     [es:9*4], ax ; restoring offset
mov     ax, [oldkbisr+2] ; restoring segment
mov     [es:9*4+2], ax

;restoring old timerISR interrupt service routine
mov     ax, 0
mov     es, ax
mov     ax, [oldtimerisr]
mov     [es:8*4], ax
mov     ax, [oldtimerisr+2]
mov     [es:8*4+2], ax
sti


;end of program
mov     ax, 4c00h
int     21h




; ; to make program TSR
; mov     dx, main
; add     dx, 15
; mov     cl, 4
; shr     dx, cl
; mov     ax, 0x3100
; INT     0x21



initial: mov ax, [bp + 6]   ;loading first value in the parameter
mov cx, [bp + 4]     ; loading the number of params
dec cx                ; dec number of params since first val is already loaded and n-1 are left
mov si, 8
jmp recur

addit: add si, 2

recur: cmp ax, [bp + si]
jbe check
mov ax, [bp + si]

check: dec cx
cmp cx, 0
jne addit
pop cx
pop si
pop bp
ret 4













