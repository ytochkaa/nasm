global _start

section .data
    prompt1 db "Enter first number (m): ", 0
    prompt1_len equ $-prompt1
    prompt2 db "Enter second number (n): ", 0
    prompt2_len equ $-prompt2
    negative_msg db "Negative divisors: ", 0
    negative_len equ $-negative_msg
    positive_msg db "Positive divisors: ", 0
    positive_len equ $-positive_msg
    error_zero_msg db "Error: numbers cannot be zero", 10, 0
    error_zero_msg_len equ $-error_zero_msg
    space db " "
    newline db 10
    buffer times 21 db 0
    
section .bss
    num1 resq 1
    num2 resq 1
    gcd_value resq 1
    temp resq 1
    negative_divisors resq 100
    positive_divisors resq 100
    negative_count resq 1
    positive_count resq 1
    strNum1 resb 256
    strNum2 resb 256

section .text

_start:
    ; Ввод первого числа
    mov rsi, prompt1
    mov rdx, prompt1_len
    call FuncPrintMsg

    mov rsi, strNum1
    mov rdx, 256
    call FuncReadString
    jc .read_error

    ; Конвертация первого числа
    mov rsi, strNum1
    call FuncStrToInt
    jc .conversion_error
    mov [num1], rax

    ; Ввод второго числа
    mov rsi, prompt2
    mov rdx, prompt2_len
    call FuncPrintMsg

    mov rsi, strNum2
    mov rdx, 256
    call FuncReadString
    jc .read_error

    ; Конвертация второго числа
    mov rsi, strNum2
    call FuncStrToInt
    jc .conversion_error
    mov [num2], rax

    ; Проверка на ноль
    cmp qword [num1], 0
    je .zero_error
    cmp qword [num2], 0
    je .zero_error

    ; Вычисление НОД через простой перебор
    call compute_gcd_simple
    mov [gcd_value], rax

    ; Нахождение всех делителей НОД
    call find_all_divisors_separate

    ; Вывод отрицательных делителей
    mov rsi, negative_msg
    mov rdx, negative_len
    call FuncPrintMsg
    call print_negative_divisors
    mov rsi, newline
    mov rdx, 1
    call FuncPrintMsg

    ; Вывод положительных делителей
    mov rsi, positive_msg
    mov rdx, positive_len
    call FuncPrintMsg
    call print_positive_divisors
    mov rsi, newline
    mov rdx, 1
    call FuncPrintMsg

    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall

.zero_error:
    mov rsi, error_zero_msg
    mov rdx, error_zero_msg_len
    call FuncPrintMsg
    mov rax, 60
    mov rdi, 1
    syscall

.read_error:
    mov rax, 60
    mov rdi, 1
    syscall

.conversion_error:
    mov rax, 60
    mov rdi, 1
    syscall


; ========================================== САМА СУТЬ ==========================================

; + вместо -
abs:
    test rax, rax
    jns .done
    neg rax
.done:
    ret

; ===================== НОД =====================
compute_gcd_simple:
; Выход: RAX - НОД
    push rbx
    push rcx
    push rdx
    
    ; Берем абсолютные значения
    mov rax, [num1]
    call abs
    mov [num1], rax
    
    mov rax, [num2]
    call abs
    mov [num2], rax
    
    ; Находим минимальное из двух чисел
    mov rax, [num1]
    mov rbx, [num2]
    cmp rax, rbx
    jle .min_found
    mov rax, rbx
.min_found:
    mov rcx, rax    ; RCX = min(|num1|, |num2|)
    
    ; Простой перебор от min до 1
.find_gcd_loop:
    ; Проверяем, делит ли RCX оба числа
    mov rax, [num1]
    xor rdx, rdx
    div rcx ; Результат: RAX = частное, RDX = остаток
    test rdx, rdx
    jnz .not_divisor
    
    mov rax, [num2]
    xor rdx, rdx
    div rcx
    test rdx, rdx
    jnz .not_divisor
    
    ; Нашли НОД
    mov rax, rcx
    jmp .done_gcd
    
.not_divisor:
    dec rcx ; RCX = RCX - 1
    test rcx, rcx  Проверяем, не стал ли RCX нулем
    jnz .find_gcd_loop
    
    ; Если не нашли, НОД = 1
    mov rax, 1
    
.done_gcd:
    pop rdx
    pop rcx
    pop rbx
    ret

; ===================== ОПТИМИЗИРОВАННОЕ РАЗЛОЖЕНИЕ НОД НА ДЕЛИТЕЛИ =====================
find_all_divisors_separate:
; Назначение: Нахождение всех делителей через перебор с однократным поиском
; Вход: [gcd_value] - число
; Выход: отрицательные делители в negative_divisors, положительные в positive_divisors
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Инициализация счетчиков
    mov qword [negative_count], 0
    mov qword [positive_count], 0
    
    ; Получаем абсолютное значение НОД
    mov rax, [gcd_value]
    call abs
    mov [temp], rax
    
; ===== находим только ПОЛОЖИТЕЛЬНЫЕ делители =====
    mov rdi, positive_divisors      ; RDI = указатель на массив положительных делителей
    mov rcx, 1                      ; Начинаем с 1
    
.positive_loop:
    cmp rcx, [temp]                 
    jg .positive_done               
    
    ; Проверяем делимость: gcd_value % RCX == 0?
    mov rax, [temp]                 
    xor rdx, rdx                    
    div rcx                         
    test rdx, rdx                   
    jnz .positive_next              
    
    ; Нашли делитель
    mov [rdi], rcx                  
    add rdi, 8                      ; Перемещаем указатель
    inc qword [positive_count]      ; Увеличиваем счетчик
    
.positive_next:
    inc rcx                         ; RCX = RCX + 1
    jmp .positive_loop              ; Продолжаем цикл

.positive_done:
    ; ===== ШАГ 2: Копируем положительные делители в отрицательные =====
    mov rcx, [positive_count]       ; Количество делителей для копирования
    mov qword [negative_count], rcx 
    
    test rcx, rcx                   
    jz .done_find                   
    
    mov rsi, positive_divisors      ; RSI положительные делители)
    mov rdi, negative_divisors      ; RDI отрицательные делители
    
    lea rsi, [rsi + 8*rcx - 8]     ; RSI указывает на ПОСЛЕДНИЙ элемент положительных
    
.negative_copy_loop:
    mov rax, [rsi]                  
    neg rax                         
    mov [rdi], rax                  
    add rdi, 8                      
    sub rsi, 8                      
    dec rcx                         
    jnz .negative_copy_loop         

.done_find:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
; ===================== ФУНКЦИИ =====================
FuncPrintNumber:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rdi, buffer
    call FuncIntToStr
    
    mov rsi, buffer
    call FuncStrLen
    mov rdx, rax
    
    mov rsi, buffer
    call FuncPrintMsg
    
    mov rsi, space
    mov rdx, 1
    call FuncPrintMsg
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

FuncStrLen:
    xor rcx, rcx
.loop:
    cmp byte [rsi + rcx], 0
    je .done
    inc rcx
    jmp .loop
.done:
    mov rax, rcx
    ret

FuncPrintMsg:
    mov rax, 1
    mov rdi, 1
    syscall
    ret

FuncReadString:
    mov rax, 0
    mov rdi, 0
    syscall
    cmp rax, 0
    jl .error
    clc
    ret
.error:
    stc
    ret

FuncStrToInt:
    xor rax, rax
    xor rcx, rcx
    mov r8, 1
    mov r9, 0

.skip_spaces:
    mov bl, byte [rsi + rcx]
    cmp bl, ' '
    jne .check_sign
    inc rcx
    jmp .skip_spaces

.check_sign:
    mov bl, byte [rsi + rcx]
    cmp bl, '-'
    jne .check_empty
    mov r8, -1
    inc rcx

.check_empty:
    mov bl, byte [rsi + rcx]
    cmp bl, 0xA
    je .invalid_format
    cmp bl, 0
    je .invalid_format
    cmp bl, ' '
    je .invalid_format

.convert_loop:
    mov bl, byte [rsi + rcx]
    cmp bl, 0xA
    je .done
    cmp bl, 0
    je .done
    cmp bl, ' '
    je .done
    
    cmp bl, '0'
    jl .invalid_format
    cmp bl, '9'
    jg .invalid_format
    
    inc r9
    sub bl, '0'
    
    push rdx
    mov rdx, 10
    imul rax, rdx
    pop rdx
    jo .overflow
    
    movzx rdx, bl
    add rax, rdx
    jo .overflow
    
    inc rcx
    jmp .convert_loop

.done:
    cmp r9, 0
    je .invalid_format
    
    imul rax, r8
    jo .overflow
    
    clc
    ret

.invalid_format:
    mov rax, 1
    stc
    ret

.overflow:
    mov rax, 2
    stc
    ret

FuncMax:
    cmp rax, rbx
    jge .no_swap
    mov rax, rbx
.no_swap:
    ret

FuncIntToStr:
    mov rsi, rdi
    test rax, rax
    jns .convert
    neg rax
    mov byte [rsi], '-'
    inc rsi

.convert:
    mov rbx, 10
    mov rcx, 0
    mov rdi, rsi

.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .convert_loop

.pop_loop:
    pop rax
    mov [rdi], al
    inc rdi
    loop .pop_loop

    mov byte [rdi], 0
    ret