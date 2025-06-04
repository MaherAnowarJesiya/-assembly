org 100h
jmp start

; ----------------------
; DATA SECTION
; ----------------------
temp dw 0
pressure dw 0
cooling_mode db 3
pressure_relief db 0

msg_temp db 13,10, 'Enter 3-digit Temperature (000-999): $'
msg_pres db 13,10, 'Enter 3-digit Pressure (000-999): $'
msg_invalid db 13,10, 'Invalid input! Use 3 digits.$'
msg_mode db 13,10, 'Cooling Mode: $'
msg_relief db 13,10, 'Pressure Relief: $'
msg_end db 13,10, 'Program Ended.$'

; Cooling mode descriptions
msg_normal db 'Normal Cooling$'
msg_partial db 'Partial Cooling$'
msg_emergency db 'Emergency Cooling$'
msg_invalid_mode db 'Invalid/No Cooling$'

; ----------------------
; CODE SECTION
; ----------------------
start:
    ; Initialize outputs
    mov [cooling_mode], 3
    mov [pressure_relief], 0

    ; Get valid temperature
temp_input:
    mov ah, 09h
    lea dx, msg_temp
    int 21h
    call get_valid_number
    jc temp_input       ; Retry on error
    mov [temp], ax

    ; Get valid pressure
pres_input:
    mov ah, 09h
    lea dx, msg_pres
    int 21h
    call get_valid_number
    jc pres_input
    mov [pressure], ax

    ; Process values
    mov ax, [temp]
    mov bx, [pressure]

    ; Check Emergency Cooling
    cmp ax, 500
    ja emergency
    cmp bx, 200
    ja emergency

    ; Check Partial Cooling
    cmp ax, 400
    ja partial

    ; Check Normal Cooling
    cmp ax, 300
    jb check_pres
    cmp ax, 400
    ja check_pres
    cmp bx, 50
    jb check_pres
    cmp bx, 150
    ja check_pres
    mov [cooling_mode], 0
    jmp check_pres

emergency:
    mov [cooling_mode], 2
    jmp check_pres

partial:
    mov [cooling_mode], 1

check_pres:
    ; Pressure Relief Check
    cmp bx, 150
    jbe show_results
    mov [pressure_relief], 1

show_results:
    ; Display cooling mode description
    mov ah, 09h
    lea dx, msg_mode
    int 21h

    mov al, [cooling_mode]
    cmp al, 0
    je normal_mode
    cmp al, 1
    je partial_mode
    cmp al, 2
    je emergency_mode
    jmp invalid_mode

normal_mode:
    lea dx, msg_normal
    jmp print_mode

partial_mode:
    lea dx, msg_partial
    jmp print_mode

emergency_mode:
    lea dx, msg_emergency
    jmp print_mode

invalid_mode:
    lea dx, msg_invalid_mode

print_mode:
    mov ah, 09h
    int 21h

    ; Display pressure relief
    mov ah, 09h
    lea dx, msg_relief
    int 21h
    mov dl, [pressure_relief]
    add dl, '0'
    mov ah, 02h
    int 21h

    ; Exit message
    mov ah, 09h
    lea dx, msg_end
    int 21h

    ; Exit to DOS
    mov ax, 4C00h
    int 21h

; ---------------------------
; INPUT FUNCTION (validates 3 digits)
; ---------------------------
get_valid_number:
    push cx
    push dx
    mov cx, 3
    xor bx, bx

input_loop:
    ; Read character
    mov ah, 01h
    int 21h

    ; Validate digit
    cmp al, '0'
    jb invalid_input
    cmp al, '9'
    ja invalid_input

    ; Convert to number
    sub al, '0'
    mov ah, 0
    
    ; Accumulate: BX = BX * 10 + AX
    xchg ax, bx
    mov dx, 10
    mul dx
    add ax, bx
    xchg ax, bx
    
    loop input_loop

    ; Success
    mov ax, bx
    clc
    jmp exit_input

invalid_input:
    ; Show error
    mov ah, 09h
    lea dx, msg_invalid
    int 21h
    stc

exit_input:
    pop dx
    pop cx
    ret