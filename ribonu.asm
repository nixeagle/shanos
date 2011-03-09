;;; Ribonu kernel for Shanos

;;; [a-zA-Z0-9_$#@~.?]
        org 7C00h
        bits 16
        CPU 686                 ; Not going to support anything older.

RSD_pointer:   equ 0x040e       ; Same as 0x40:0E
        jmp 0x0000:drive_number_ ; Far jump over our initial data segment
_hello_world: db `Hello, world!\r\n`, 0
_boot_drive_number: db 0xff ; Value must be 0x0<something> to be valid.
        
drive_number_: ; Make note of what drive we were loaded from.
        mov [_boot_drive_number], dl
        and BYTE [_boot_drive_number], 0x0f

        
        mov ah, 0xe ; for the interrupt.
        mov si, _hello_world
        jmp print
        
print:
lodsb ; Load a char from 'string'
cmp al, 0 ; Null terminated means stop.
jz test
int 0x10 ; Tell BIOS to print a char.
jmp print

test:
        mov al, 0xbc
        call print_AX_hex
        mov al, [_boot_drive_number]
        call print_newline
        call print_AX_hex
        call print_newline
        call print_AX_hex
        call print_newline

        jz $


;;; All below are "library" functions.
;;; All functions are considered callee saves unless it starts with
;;; a leading underscore.
print_newline:
        push ax
        mov al, `\r`
        call _print_char
        mov al, `\n`
        call _print_char
        pop ax
        ret

_print_char:
        mov ah, 0xe
        int 0x10
        ret

__print_hex:
        and al, 0x0f
        cmp al, 0x9
        ja .letter ; al is 'a' .. 'f'
        add al, 0x30
        jmp .endif
.letter:
        add al, 'A' - 10
.endif:
        call _print_char
        ret

;;; BIOS print the "string" "0x". No registers are modified.
print_0x:
        push ax
        mov al, '0'
        call _print_char
        mov al, 'x'
        call _print_char
        pop ax
        ret

;;; Print hex with the number to be printed in AL.
;;; State of all registers is preserved.
print_AX_hex:
        call print_0x
        
        push ax
        push ax
        mov al, ah ; Print upper half first
        push ax
        shr al, 4 ; high nibble must be output before low nibble
        call __print_hex
        pop ax ; Now recover the low nibble
        call __print_hex ; and call the printer function again.
        pop ax ; Restore original AL.

        push ax
        shr al, 4 ; Again print upper nibble first.
        call __print_hex
        pop ax ; Recover lower nibble so we can print that.
        call __print_hex
        pop ax ; Restore state to what we were given.
        ret






;;; Returns the pointer vie ax register
load_rsdp_pointer:
        mov ax, [RSDP_POINTER]
        ret
