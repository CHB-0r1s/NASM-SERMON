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
    sup rsp, 1
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
    
    .return_block
        add rsp, 1                                    
        ret                                         
 

 ;_____________________

 print_char:
    mov rsi, rdi
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
    ret


_start:
    call read_char
    ;аски код символа в rax
    push rax
    mov rdi, rsp
    mov r9, message
    call print_char
    call exit
    