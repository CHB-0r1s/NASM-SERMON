;global _start

section .data
 %define END_OF_STRING 0x0
 %define ASCII_ZERO_CODE 0x30
 %define ASCII_NINE_CODE 0x39
 %define DEC_SYS_BASE 0xA
 %define BYTE_LEN 0x8
 NEW_LINE: db 0xA

section .text

; Принимает код возврата и завершает текущий процесс
exit: 
    mov rax, 60
    syscall
    ret 

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax
    .loop:                                  
        cmp byte[rdi+rax], END_OF_STRING
        je .return_block
        inc rax
        jmp .loop
    .return_block:
    ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
    mov rsi, rdi
    push rsi
    call string_length
    pop rsi
    mov rdx, rax
    mov rdi, 1
    mov rax, 1
    syscall
    ret

; Принимает код символа и выводит его в stdout
print_char:
    push rdi
    mov rsi, rsp
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
    pop rdi
    ret


; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    mov rdi, NEW_LINE
    jmp print_char

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
    push rbx
    push r12
    
    mov r12, rsp ; save rsp
    xor rdx, rdx
    mov rax, rdi
    mov rbx, DEC_SYS_BASE
    
    dec rsp
    mov byte[rsp], 0x0

    .loop:
        xor rdx, rdx
        div rbx
        
        add rdx, ASCII_ZERO_CODE
        dec rsp
        mov byte[rsp], dl

        test rax, rax
        jz .empty_integer_part

        jmp .loop
    
    .empty_integer_part:
        mov rdi, rsp
        call print_string
        
        mov rsp, r12 ; upload rsp
        pop r12
        pop rbx
        
        ret

; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
    push r12
    xor rax, rax

    cmp rdi, 0
    jge .positive
    jl  .negative

    .positive:
        call print_uint
        jmp .return_block
    .negative:
        push rdi
        mov rdi, '-'
        call print_char
        pop rdi

        mov r12, -1
        mov rax, rdi
        mul r12
        mov rdi, rax

        call print_uint
    .return_block:
        pop r12
        ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
    xor rdx, rdx
    xor rax, rax

    .loop:
        mov ah, byte[rdi]

        cmp ah, byte[rsi]
        jne .not_equal

        cmp ah, END_OF_STRING
        je .equal

        inc rdi
        inc rsi
        jmp .loop
        
    .equal:
        mov rax,1
        ret
    .not_equal:
        mov rax,0
        ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
    mov rax, 0
    mov rdi, 0

    sub rsp, BYTE_LEN

    mov rsi, rsp
    mov rdx, 1
    syscall

    cmp rax, -1
    jz .end_of

    test rax, rax
    jz .end_of
    
    mov al, [rsp]
    jmp .return_block
    
    .end_of:
        xor rax, rax
    
    .return_block:
        add rsp, BYTE_LEN
        ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор

read_word:
    xor rax, rax

    push rbx
    push r12
    push r13

    mov rbx, rdi ; начало буфера
    mov r12, rsi ; размер буфера
    xor r13, r13 ; счетчик байт
    
    .loop:
        call read_char
                      
        cmp al, `\n`
        jz .spec_simb
        cmp al, `\t`
        jz .spec_simb
        cmp al, ` `
        jz .spec_simb

        cmp r13, r12
        jge .clear_buff

        test rax, rax ; проверка на терминатор 
        jz .end_of
        
        mov [rbx + r13], al
        inc r13

        jmp .loop

    .spec_simb:
        test r13, r13
        jz .loop
        jnz .end_of

    .clear_buff:
        mov rax, 0
        jmp .return_block

    .end_of:
        mov byte[rbx + r13], 0
        mov rax, rbx
        mov rdx, r13
        jmp .return_block

    .return_block:
        pop r13
        pop r12
        pop rbx
        ret

 

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    xor rax, rax
    push r12
    push r13
    push r14

    mov r12, DEC_SYS_BASE
    xor r13, r13; зануляем r13

    .loop:
        mov r14b, byte[rdi]

        cmp r14b, ASCII_ZERO_CODE
        jl .end

        cmp r14b, ASCII_NINE_CODE
        jg .end

        sub r14b, ASCII_ZERO_CODE ; получаем цифру
        mul r12
        add rax, r14

        inc r13
        inc rdi
        
        jmp .loop

    .end:
        mov rdx, r13
        pop r14
        pop r13
        pop r12
        ret




; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:
    xor rax, rax; зануляем rax, rdx
    xor rdx, rdx

    cmp byte[rdi], '-'
    jne .if_without_sign

    inc rdi
    call parse_uint
    inc rdx
    neg rax
    
    jmp .end
    
    .if_without_sign:
        call parse_uint; С зануленным rax, rdx прыгаем на метку

    .end:
        ret 

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
    push r12
    push rdi
    push rsi
    call string_length
    pop rsi
    pop rdi
    inc rax

    mov r12, rax
    cmp rdx, rax
    jl .buffer_size_overflow

    .loop:
        mov al, byte[rdi]
        mov byte[rsi], al
        cmp byte[rdi], 0x0
        je .end
        inc rsi
        inc rdi
        xor rax, rax
        jmp .loop

    .buffer_size_overflow:
        xor rax, rax
        mov r12, rax

    .end:
        mov rax, r12
        pop r12
        ret
