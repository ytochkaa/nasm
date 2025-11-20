global _start

section .data
    userStartMsg:           db "Найти среднее арифметическое всех элементов массива, кроме A[i]",10
    lenUserStartMsg         equ $-userStartMsg
    prompt_size:            db "Введите количество элементов в массиве: ", 0
    len_prompt_size         equ $-prompt_size
    prompt_element:         db "Введите элемент ", 0
    len_prompt_element      equ $-prompt_element
    prompt_colon:           db ": ", 0
    len_prompt_colon        equ $-prompt_colon
    prompt_index:           db "Введите индекс i (0-based): ", 0
    len_prompt_index        equ $-prompt_index
    resultMsg:              db "Среднее арифметическое: ", 0
    lenResultMsg            equ $-resultMsg
    errorMsg:               db "Ошибка: ", 0
    lenErrorMsg             equ $-errorMsg
    invalidNumberMsg:       db "неверный формат числа", 10, 0
    lenInvalidNumberMsg     equ $-invalidNumberMsg
    overflowMsg:            db "переполнение числа", 10, 0
    lenOverflowMsg          equ $-overflowMsg
    readErrorMsg:           db "ошибка чтения", 10, 0
    lenReadErrorMsg         equ $-readErrorMsg
    error_size_msg:         db "Ошибка: массив должен содержать хотя бы 2 элемента", 10, 0
    len_error_size_msg      equ $-error_size_msg
    error_index_msg:        db "Ошибка: индекс вне диапазона", 10, 0
    len_error_index_msg     equ $-error_index_msg
    strNumsSize             equ 256
    numsSize                equ 8
    space                   db " "
    newline                 db 10
    buffer                  times 21 db 0

section .bss
    array_size      resq numsSize
    index_i         resq numsSize
    sum             resq numsSize
    average         resq numsSize
    array           resq 100          ; Максимум 100 элементов
    strNum          resb strNumsSize
    temp_counter    resq numsSize     ; Для хранения счетчика

section .text

_start:
    ; Вывод стартового сообщения
    mov rsi, userStartMsg
    mov rdx, lenUserStartMsg
    call FuncPrintMsg

    ; Ввод размера массива
    mov rsi, prompt_size
    mov rdx, len_prompt_size
    call FuncPrintMsg
    
    mov rsi, strNum
    mov rdx, strNumsSize
    call FuncReadString
    jc .read_error
    
    mov rsi, strNum
    call FuncStrToInt
    jc .conversion_error
    mov [array_size], rax
    
    ; Проверка размера массива
    cmp rax, 2
    jl .error_size
    
    ; Ввод элементов массива
    call InputArray
    
    ; Ввод индекса i
    mov rsi, prompt_index
    mov rdx, len_prompt_index
    call FuncPrintMsg
    
    mov rsi, strNum
    mov rdx, strNumsSize
    call FuncReadString
    jc .read_error
    
    mov rsi, strNum
    call FuncStrToInt
    jc .conversion_error
    mov [index_i], rax
    
    ; Проверка корректности индекса
    mov rax, [index_i]
    cmp rax, 0
    jl .error_index
    mov rbx, [array_size]
    cmp rax, rbx
    jge .error_index
    
    ; Вычисление суммы всех элементов кроме A[i]
    call CalculateSum
    
    ; Вычисление среднего арифметического
    call CalculateAverage
    
    ; Вывод результата
    mov rsi, resultMsg
    mov rdx, lenResultMsg
    call FuncPrintMsg
    
    mov rax, [average]
    call FuncPrintNumber
    
    mov rsi, newline
    mov rdx, 1
    call FuncPrintMsg
    
    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall

; ===================== ОШИБКИ =====================
.read_error:
    mov rsi, errorMsg
    mov rdx, lenErrorMsg
    call FuncPrintError
    mov rsi, readErrorMsg
    mov rdx, lenReadErrorMsg
    call FuncPrintError
    jmp .exit_error

.conversion_error:
    mov rsi, errorMsg
    mov rdx, lenErrorMsg
    call FuncPrintError
    cmp rax, 1
    je .invalid_number
    cmp rax, 2
    je .overflow_error

.invalid_number:
    mov rsi, invalidNumberMsg
    mov rdx, lenInvalidNumberMsg
    call FuncPrintError
    jmp .exit_error

.overflow_error:
    mov rsi, overflowMsg
    mov rdx, lenOverflowMsg
    call FuncPrintError
    jmp .exit_error

.error_size:
    mov rsi, error_size_msg
    mov rdx, len_error_size_msg
    call FuncPrintMsg
    jmp .exit_error

.error_index:
    mov rsi, error_index_msg
    mov rdx, len_error_index_msg
    call FuncPrintMsg
    jmp .exit_error

.exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

; ===================== ВВОД МАССИВА =====================
InputArray:
    push rcx
    push rsi
    push rdi
    push r8
    
    mov rcx, [array_size]     ; Счетчик элементов
    mov rdi, array            ; Указатель на массив
    xor r8, r8                ; Текущий индекс элемента
    
.input_loop:
    ; Проверяем, не закончились ли элементы
    cmp r8, [array_size]
    jge .input_done
    
    ; Сохраняем регистры
    push rcx
    push rdi
    push r8
    
    ; Вывод приглашения для ввода элемента
    mov rsi, prompt_element
    mov rdx, len_prompt_element
    call FuncPrintMsg
    
    ; Вывод номера элемента
    mov rax, r8
    call FuncPrintNumber
    
    ; Вывод ": "
    mov rsi, prompt_colon
    mov rdx, len_prompt_colon
    call FuncPrintMsg
    
    ; Чтение элемента
    mov rsi, strNum
    mov rdx, strNumsSize
    call FuncReadString
    jc .read_error
    
    ; Преобразование строки в число
    mov rsi, strNum
    call FuncStrToInt
    jc .conversion_error
    
    ; Восстанавливаем регистры
    pop r8
    pop rdi
    pop rcx
    
    ; Сохраняем число в массиве
    mov [rdi + r8*8], rax
    
    ; Переходим к следующему элементу
    inc r8
    
    ; Уменьшаем счетчик и проверяем завершение
    dec rcx
    jnz .input_loop
    
.input_done:
    pop r8
    pop rdi
    pop rsi
    pop rcx
    ret

.read_error:
    ; Восстанавливаем стек и переходим к обработке ошибки
    pop r8
    pop rdi
    pop rcx
    jmp _start.read_error

.conversion_error:
    ; Восстанавливаем стек и переходим к обработке ошибки
    pop r8
    pop rdi
    pop rcx
    jmp _start.conversion_error

; ===================== ВЫЧИСЛЕНИЕ СУММЫ =====================
CalculateSum:
    push rcx
    push rsi
    push r8
    push r9
    
    xor r8, r8                ; R8 = сумма
    mov rcx, [array_size]     ; RCX = размер массива
    mov rsi, array            ; RSI = указатель на массив
    
    ; Суммируем все элементы
    xor r9, r9 ; R9 = индекс текущего элемента (0)
.sum_loop:
    cmp r9, [array_size]
    jge .sum_done
    
    mov rax, [rsi + r9*8]
    add r8, rax
    inc r9
    jmp .sum_loop
    
.sum_done:
    ; Вычитаем элемент A[i]
    mov rax, [index_i]
    mov rax, [array + rax*8]  ; RAX = A[i]
    sub r8, rax               ; Вычитаем A[i] из общей суммы
    
    mov [sum], r8             ; Сохраняем сумму
    
    pop r9
    pop r8
    pop rsi
    pop rcx
    ret

; ===================== ВЫЧИСЛЕНИЕ СРЕДНЕГО =====================
CalculateAverage:
    push rbx
    push rdx
    
    mov rax, [sum]            ; RAX = сумма
    mov rbx, [array_size]
    dec rbx                   ; RBX = количество элементов (n-1)
    
    ; Целочисленное деление
    xor rdx, rdx
    div rbx                   ; RAX = сумма / (n-1)
    
    mov [average], rax        ; Сохраняем результат
    
    pop rdx
    pop rbx
    ret

; ===================== ФУНКЦИИ ИЗ ПРЕДЫДУЩИХ ПРОГРАММ =====================
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

FuncPrintError:
    mov rax, 1
    mov rdi, 2
    syscall
    ret

FuncReadString:
    mov rax, 0
    mov rdi, 0
    syscall
    
    cmp rax, 0
    jl .error
    jmp .success
    
.error:
    stc
    ret
    
.success:
    clc
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