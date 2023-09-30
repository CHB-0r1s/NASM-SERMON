; hello.asm
section .data
message: db  'hello, world!', 0

section .text
global _start

exit:
    mov     rax, 60          ; 'exit' syscall number
    xor     rdi, rdi
    syscall

read_char:
    mov rax, 0
    dec rsp
    mov rsi, rsp
    mov rdx, 1
    syscall         

    cmp rax, -1                                     
    je .term_or_nothing                               

    test rax, rax                                   
    jz .term_or_nothing                             
    
    mov al, [rsp]                                   
    jmp .return_block                                 
    
    .term_or_nothing:
        mov rax, 0
        jmp .return_block
    
    .return_block:
        add rsp, 1                                    
        ret
        
read_word:
    mov rax, 0                                       ;   clear registers

    push r10                                            ;
    push r11                                            ;   store caller-saved registers
    push r12                                            ;

    mov r10, rdi
    mov r11, rsi
    mov r12, 0
    
    .loop:
        call read_char

                                          ;
        cmp al, `\t`
        je .spec_simbol                                  ;
        
        cmp al, `\n`  
        je .spec_simbol                                  ;
        
        cmp  al, ` `                                     ;   
        je .spec_simbol

        test rsi, rsi                                      ;   if buffer length is 0
        jz .end_of                                      ;   then just finish function execution

        cmp r12, r11                                    ;   if word does not fit in buffer
        jnl .buf_clear                            ;   then buffer overflow detected

        test rax, rax                                   ;   if got zf then finish   
        jz .end_of                                      ;
        
        mov [r10 + r12], al                             ;   storing current char in buffer
        add r12, 1                                         ;   increasing word length

        jmp .loop                                       ;   next iteration

    .spec_simbol:
        test r12, r12                                   ;   skipping space characters
        jz .loop
        jnz .end_of

    .buf_clear:
        mov rax, 0
        jmp .return_block
    
    .end_of:
        mov byte[r10 + r12], 0                          ;   applying null terminator to the end of word
        mov rax, r10                                    ;   buffer ptr
        mov rdx, r12                                    ;   word length

        jmp .return_block                                        ;   go to the end

    

    .return_block:
        pop r12
        pop r11
        pop r10
        ret                                             ;   the end

 

 ;_____________________

 print_char:
    mov rsi, rdi
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
    ret


_start:
    call read_word
    call exit
    