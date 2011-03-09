org 7C00h


jmp _start ; Jump over our initial data segment

_boot_drive_number_str: db "Boot drive number: ", 0 ; String
_newline: db 13, 10, 0 ; Newline ("\r\n")
_boot_drive_number: db 0xff ; Value must be 0x0<something> to be valid.
_RSDP_pointer: dw 0x040e

_start:
        ;call get_drive_number
        mov [_boot_drive_number], dl
        and BYTE [_boot_drive_number], 0x0f

        mov ah, 0xe ; Set everything up for text printing
        
        mov si, _boot_drive_number_str
        call _print
        mov al, [_boot_drive_number]
        call print_AX_hex
        mov si, _newline
        call _print
        jmp $

;;; All below are "library" functions.
;;; All functions are considered callee saves unless it starts with
;;; a leading underscore.

;;; Print a string, pointer to which is in si. (print macro preferred)
_print:
        push ax
.start:
lodsb ; Load a char from 'string'
cmp al, 0 ; Null terminated means stop.
jz .end
int 0x10 ; Tell BIOS to print a char.
jmp .start
.end:
        pop ax
        ret

;;; Print a string, pointer to which is in si, followed by a newline. (println macro preferred)
_println:
        call _print
        mov si, _newline
        call _print
        ret

_print_char:
        push bx                 ; save bx as we zero it out before
        mov ah, 0xe             ; the bios call.
        xor bx, bx
        int 0x10
        pop bx
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
        mov ax, [_RSDP_pointer]
        ret

times 510 - ($-$$) db 0         ; We have to be 512 bytes.
dw 0xAA55                       ; Boot Signiture 