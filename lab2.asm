section .data
    prompt db "Enter seconds (N, 0-86400): "
    prompt_len equ $ - prompt
    result_msg db "Seconds since last hour: "
    result_len equ $ - result_msg
    error_msg db "Error: Number must be between 0 and 86400", 10
    error_len equ $ - error_msg
    newline db 10
    buffer times 20 db 0

section .text
global _start

_start:
    ; Вывод приглашения для ввода
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Чтение ввода с клавиатуры
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 20
    syscall

    ; Преобразование строки в число
    mov rsi, buffer
    call string_to_int
    mov rbx, rax  ; сохраняем N в rbx

    ; Проверка диапазона (0-86400)
    cmp rbx, 0
    jl .error     ; если меньше 0 - ошибка
    cmp rbx, 86400
    jg .error     ; если больше 86400 - ошибка
    
    ; Вычисление остатка от деления на 3600
    mov rax, rbx
    mov rcx, 3600
    xor rdx, rdx
    div rcx
    
    ; Теперь в rdx - результат
    ; Преобразуем число в строку
    mov rax, rdx
    mov rdi, buffer
    call int_to_string
    mov r8, rax  ; сохраняем длину

    ; Вывод сообщения с результатом
    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_len
    syscall

    ; Вывод результата
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, r8
    syscall

    ; Новая строка
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Завершение
    mov rax, 60
    xor rdi, rdi
    syscall

.error:
    ; Вывод сообщения об ошибке
    mov rax, 1
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    
    ; Завершение с кодом ошибки
    mov rax, 60
    mov rdi, 1
    syscall


string_to_int:
    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx
; Функция преобразования строки в число
; Вход: RSI - указатель на строку
; Выход: RAX - число
.convert_loop:
    mov cl, [rsi]
    cmp cl, 10     ; проверка на новую строку
    je .done
    cmp cl, 0      ; проверка на конец строки
    je .done
    cmp cl, '0'    ; проверка на цифру
    jb .invalid
    cmp cl, '9'
    ja .invalid
    sub cl, '0'    ; преобразование символа в цифру
    imul rax, 10
    add rax, rcx
    ; Проверка на переполнение (если число слишком большое)
    jc .overflow
    inc rsi
    jmp .convert_loop
.invalid:
    ; Если встретили нецифровой символ, возвращаем -1
    mov rax, -1
    ret
.overflow:
    ; Если произошло переполнение, возвращаем -1
    mov rax, -1
    ret
.done:
    ret


int_to_string:
; Функция преобразования числа в строку
; Вход: RAX - число, RDI - буфер
; Выход: RAX - длина строки
    mov rbx, 10
    mov rcx, buffer + 19
    mov byte [rcx], 0
    mov r9, 0
    
.convert_loop:
    dec rcx
    inc r9
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rcx], dl
    test rax, rax
    jnz .convert_loop
    
    mov rsi, rcx
    mov rdi, buffer
    mov rcx, r9
    rep movsb
    mov rax, r9
    ret