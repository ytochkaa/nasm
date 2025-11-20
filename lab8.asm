section .data
    prompt_msg:      db "Введите булев вектор ", 0
    len_prompt_msg   equ $-prompt_msg
    result_msg:      db "Вес булевого вектора (количество единичных битов): ", 0
    len_result_msg   equ $-result_msg
    newline:         db 10
    error_msg:       db "Ошибка: неверный формат двоичного числа", 10, 0
    len_error_msg    equ $-error_msg
    
    ; Константы для работы с числами
    str_buffer_size  equ 256
    num_size         equ 8

section .bss
    input_buffer     resb str_buffer_size
    number           resq num_size
    weight           resq num_size

section .text
global _start

_start:
    ; Вывод приглашения для ввода
    mov rsi, prompt_msg
    mov rdx, len_prompt_msg
    call print_string

    ; Чтение ввода пользователя
    mov rsi, input_buffer
    mov rdx, str_buffer_size
    call read_string
    
    ; Проверка на ошибку чтения
    jc .read_error

    ; Преобразование двоичной строки в число
    mov rsi, input_buffer
    call binary_string_to_int
    jc .conversion_error
    
    mov [number], rax  ; Сохраняем введенное число

    ; Вычисление веса булевого вектора
    mov rax, [number]
    call calculate_weight
    mov [weight], rax  ; Сохраняем результат

    ; Вывод результата
    mov rsi, result_msg
    mov rdx, len_result_msg
    call print_string
    
    mov rax, [weight]
    call print_number
    
    mov rsi, newline
    mov rdx, 1
    call print_string

    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall

.read_error:
    ; Обработка ошибки чтения
    mov rsi, error_msg
    mov rdx, len_error_msg
    call print_string
    mov rax, 60
    mov rdi, 1
    syscall

.conversion_error:
    ; Обработка ошибки преобразования
    mov rsi, error_msg
    mov rdx, len_error_msg
    call print_string
    mov rax, 60
    mov rdi, 1
    syscall

; ===================== ПРЕОБРАЗОВАНИЕ ДВОИЧНОЙ СТРОКИ В ЧИСЛО =====================
binary_string_to_int:
; Преобразует двоичную строку в число
; Вход: RSI - указатель на строку
; Выход: RAX - число, CF=1 при ошибке

    push rbx
    push rcx
    push rdx
    
    xor rax, rax        ; Обнуляем результат
    xor rcx, rcx        ; Счетчик позиции в строке
    xor rbx, rbx        ; Для временного хранения символа
    
    ; Пропускаем начальные пробелы
.skip_spaces:
    mov bl, byte [rsi + rcx]
    cmp bl, ' '
    je .skip_char
    cmp bl, 9           ; TAB
    je .skip_char
    jmp .check_sign
.skip_char:
    inc rcx
    jmp .skip_spaces

.check_sign:
    mov bl, byte [rsi + rcx]
    cmp bl, '-'
    je .error
    cmp bl, '+'
    jne .convert
    inc rcx 

.convert:
    mov bl, byte [rsi + rcx]
    
    ; Проверка конца строки
    cmp bl, 0           
    je .done
    cmp bl, 10         
    je .done
    cmp bl, ' '        
    je .done
    cmp bl, 13         
    je .done
    
    ; Проверка, что символ - '0' или '1'
    cmp bl, '0'
    jl .error
    cmp bl, '1'
    jg .error
    
    ; Сдвигаем текущее значение на 1 бит влево и добавляем новый бит
    shl rax, 1
    sub bl, '0'         
    add rax, rbx
    
    ; Проверка на переполнение (если ввели больше 64 бит)
    test rax, rax
    js .overflow       
    
    inc rcx
    jmp .convert

.done:
    ; Проверяем, что была введена хотя бы одна цифра
    cmp rcx, 0
    je .error
    
    clc                 ; Успех - сбрасываем флаг переноса
    jmp .exit

.error:
    stc                 ; Ошибка формата
    jmp .exit

.overflow:
    stc                 ; Переполнение

.exit:
    pop rdx
    pop rcx
    pop rbx
    ret

; ===================== ВЫЧИСЛЕНИЕ ВЕСА БУЛЕВОГО ВЕКТОРА =====================
calculate_weight:

    push rbx
    push rcx
    
    mov rbx, rax        ; RBX = исходное число
    xor rax, rax        ; RAX = счетчик единичных битов (обнуляем)
    mov rcx, 64         

.count_loop:
    test rbx, rbx       ; Проверяем, не стало ли число нулем
    jz .done            
    
    ; Проверяем младший бит
    test rbx, 1         
    jz .bit_zero        
    
    ; Если бит = 1, увеличиваем счетчик
    inc rax

.bit_zero:
    shr rbx, 1          ; Сдвигаем число вправо на 1 бит
    dec rcx             ; Уменьшаем счетчик оставшихся битов
    jnz .count_loop     

.done:
    pop rcx
    pop rbx
    ret

; ===================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====================
; Функция вывода строки
print_string:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall
    ret

; Функция чтения строки
read_string:
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    syscall
    
    ; Проверка на ошибку (rax < 0)
    cmp rax, 0
    jl .error
    
    ; Добавляем нуль-терминатор
    mov rsi, input_buffer
    mov byte [rsi + rax], 0
    
    clc                 ; Сбрасываем флаг переноса (успех)
    ret

.error:
    stc                 ; Устанавливаем флаг переноса (ошибка)
    ret

; Функция вывода числа
print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Буфер для преобразования числа в строку
    mov rdi, input_buffer
    call int_to_string
    
    mov rsi, input_buffer
    call string_length
    mov rdx, rax
    
    call print_string
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; Функция вычисления длины строки
string_length:
    xor rcx, rcx
.length_loop:
    cmp byte [rsi + rcx], 0
    je .done
    inc rcx
    jmp .length_loop
.done:
    mov rax, rcx
    ret

; Функция преобразования числа в строку
int_to_string:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    test rax, rax
    jns .positive
    
    ; Обработка отрицательных чисел
    neg rax
    mov byte [rdi], '-'
    inc rdi

.positive:
    mov rbx, 10         ; Основание системы счисления
    mov rcx, 0          ; Счетчик цифр

.convert_loop:
    xor rdx, rdx
    div rbx             ; Делим RAX на 10
    add dl, '0'         ; Преобразуем остаток в символ
    push rdx            ; Сохраняем цифру в стек
    inc rcx             ; Увеличиваем счетчик цифр
    
    test rax, rax
    jnz .convert_loop   ; Продолжаем, если число не ноль

; Извлекаем цифры из стека в обратном порядке
.pop_loop:
    pop rax
    mov [rdi], al
    inc rdi
    loop .pop_loop
    
    mov byte [rdi], 0   ; Добавляем нуль-терминатор
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret