; 2048 for 8086
; Copyright 2014 Daniel Verkamp <daniel@drv.nu>

%include "color.inc"
%include "boxchar.inc"
%include "scancode.inc"

[org 0x100]
[cpu 8086]

TEXT_SEG equ 0xB800

; move directions
DIR_LEFT    equ 0
DIR_RIGHT   equ 1
DIR_UP      equ 2
DIR_DOWN    equ 3

    mov cx, 0x2607
    call set_text_mode

draw_borders:
    mov ax, TEXT_SEG
    mov es, ax

%define COORD(x, y) (((x) + (y) * 80) * 2)
;%define CHARCOLOR(ch, col) (((col) << 8) | ch)
;%define PUTCHAR(ch, col)    mov ax, CHARCOLOR(ch, col)

%macro MOVETO 1
    mov di, %1
%endmacro

%macro SETCOLOR 1
    mov ah, %1
%endmacro

%macro PUTCHAR 0-1
%if %0 > 0
    mov al, %1
%endif
    stosw
%endmacro

%macro REPCHAR 2
    mov al, %1
    mov cx, %2
    rep stosw
%endmacro

    xor si, si ; si = line num

.line:

    mov bx, si
    add bx, bx ; double to get word address

    MOVETO [lines + bx]
    SETCOLOR FG(COLOR_YELLOW)
    PUTCHAR [leftchar + si]
    REPCHAR [linechar + si], 4
    PUTCHAR [midchar  + si]
    REPCHAR [linechar + si], 4
    PUTCHAR [midchar  + si]
    REPCHAR [linechar + si], 4
    PUTCHAR [midchar  + si]
    REPCHAR [linechar + si], 4
    PUTCHAR [rightchar + si]

    inc si
    cmp si, 8
    jbe .line

draw_board:
    xor bp, bp ; bp = line num
.line:

    ; move to beginning of line
    mov si, bp
    add si, si ; double line number
    add si, si ; double to get word address

    mov ax, [lines + si + 2] ; + 2 to start on line 1
    add ax, 2 ; x + 1
    MOVETO ax

    ; draw this num
    ; si is already line num * 4
    SETCOLOR FG(COLOR_GREEN)
    mov cx, 4
.col:
    xor bx, bx
    mov bl, [board + si] ; load a num from board (index into nums)
    add bx, bx ; bx * 4 for 4-byte per nums
    add bx, bx
    push si
    lea si, [nums + bx] ; point si at first byte of num

    lodsb
    PUTCHAR
    lodsb
    PUTCHAR
    lodsb
    PUTCHAR
    lodsb
    PUTCHAR

    pop si

    inc si
    ; move cursor past divider
    inc di
    inc di
    loop .col

    inc bp
    cmp bp, 4
    jb .line

get_input:
    ; read keyboard input
    xor ax, ax
    int 0x16
    ; AH = scan code

    xchg al, ah ; put scan code in AL - CMP AL is smaller than CMP AH
    cmp al, SCAN_ESC
    je quit
    cmp al, SCAN_Q
    je quit
    cmp al, SCAN_LEFT
    je move_left
    cmp al, SCAN_RIGHT
    je move_right
    cmp al, SCAN_UP
    je move_up
    cmp al, SCAN_DOWN
    je move_down
    jmp get_input

quit:
    ; set text mode again to clear screen and reset cursor
    mov cx, 0x0607
    call set_text_mode
    int 0x20

move_left:
    mov bl, DIR_LEFT
    jmp move

move_right:
    mov bl, DIR_RIGHT
    jmp move

move_up:
    mov bl, DIR_UP
    jmp move

move_down:
    mov bl, DIR_DOWN
    ; fall through to move
move:
    ; TODO
    jmp draw_board

set_text_mode:
    push cx ; make sure CX doesn't get mangled by the first INT 10h
    mov ax, 0x03
    int 0x10
    pop cx
    ; set cursor - CX (cursor shape) is input parameter
    mov ah, 0x01
    int 0x10
    ret

; data

lines:
    dw (8  * 80 + 30) * 2
    dw (9  * 80 + 30) * 2
    dw (10 * 80 + 30) * 2
    dw (11 * 80 + 30) * 2
    dw (12 * 80 + 30) * 2
    dw (13 * 80 + 30) * 2
    dw (14 * 80 + 30) * 2
    dw (15 * 80 + 30) * 2
    dw (16 * 80 + 30) * 2

leftchar:
    db BOX_TOPLEFT
    db BOX_VERT
    db BOX_LEFTJUNCT
    db BOX_VERT
    db BOX_LEFTJUNCT
    db BOX_VERT
    db BOX_LEFTJUNCT
    db BOX_VERT
    db BOX_BOTTOMLEFT

linechar:
    db BOX_HORIZ
    db ' '
    db BOX_HORIZ
    db ' '
    db BOX_HORIZ
    db ' '
    db BOX_HORIZ
    db ' '
    db BOX_HORIZ

midchar:
    db BOX_TOPJUNCT
    db BOX_VERT
    db BOX_MIDJUNCT
    db BOX_VERT
    db BOX_MIDJUNCT
    db BOX_VERT
    db BOX_MIDJUNCT
    db BOX_VERT
    db BOX_BOTTOMJUNCT

rightchar:
    db BOX_TOPRIGHT
    db BOX_VERT
    db BOX_RIGHTJUNCT
    db BOX_VERT
    db BOX_RIGHTJUNCT
    db BOX_VERT
    db BOX_RIGHTJUNCT
    db BOX_VERT
    db BOX_BOTTOMRIGHT

nums:
    db '    '
    db '  2 '
    db '  4 '
    db '  8 '
    db ' 16 '
    db ' 32 '
    db ' 64 '
    db '128 '
    db '256 '
    db '512 '
    db '1024'
    db '2048'

board: ;resb 4*4
    db 1, 0, 0, 1
    db 2, 0, 2, 0
    db 3, 3, 0, 0
    db 4, 0, 0, 0
