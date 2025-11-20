global _start

section .data
    userStartMsg:           db "Найти K - количество простых чисел в диапазоне от A до B методом квадратичного решета",10
    lenUserStartMsg         equ $-userStartMsg
    strNumberEntrenceMsg:   db "Введите число: "
    lenstrNumberEntrenceMsg equ $-strNumberEntrenceMsg
    resultMsg:              db "Количество простых чисел: "
    lenResultMsg            equ $-resultMsg
    rangeMsg:               db "Диапазон поиска: от "
    lenRangeMsg             equ $-rangeMsg
    toMsg:                  db " до "
    lenToMsg                equ $-toMsg
    primesFoundMsg:         db "Найденные простые числа: ", 10
    lenPrimesFoundMsg       equ $-primesFoundMsg
    newline                 db 10
    errorMsg:               db "Ошибка: ", 0
    lenErrorMsg             equ $-errorMsg
    invalidNumberMsg:       db "неверный формат числа", 10, 0
    lenInvalidNumberMsg     equ $-invalidNumberMsg
    overflowMsg:            db "переполнение числа", 10, 0
    lenOverflowMsg          equ $-overflowMsg
    readErrorMsg:           db "ошибка чтения", 10, 0
    lenReadErrorMsg         equ $-readErrorMsg
    strNumsSize             equ 256
    numsSize                equ 8
    space                   db " "
    buffer                  times 21 db 0
    sieveSize               equ 1000000  ; Максимальный размер решета

section .bss
    numA        resq numsSize
    numB        resq numsSize
    strNumA     resb strNumsSize
    strNumB     resb strNumsSize
    primeCount  resq numsSize
    sieve       resb sieveSize  ; Буфер для решета (1 байт на число)

section .text

_start:
    ; Вывод стартового сообщения
    mov rsi, userStartMsg
    mov rdx, lenUserStartMsg
    call FuncPrintMsg

    ; Ввод числа A
    mov rsi, strNumberEntrenceMsg
    mov rdx, lenstrNumberEntrenceMsg
    call FuncPrintMsg
    mov rsi, strNumA
    mov rdx, strNumsSize
    call FuncReadString
    jc .read_error

    ; Ввод числа B
    mov rsi, strNumberEntrenceMsg
    mov rdx, lenstrNumberEntrenceMsg
    call FuncPrintMsg
    mov rsi, strNumB
    mov rdx, strNumsSize
    call FuncReadString
    jc .read_error

    ; Конвертация строк в числа
    mov rsi, strNumA
    call FuncStrToInt
    jc .conversion_error
    mov [numA], rax

    mov rsi, strNumB
    call FuncStrToInt
    jc .conversion_error
    mov [numB], rax

    ; Проверка корректности диапазона
    mov rax, [numA]
    mov rbx, [numB]
    cmp rax, rbx
    jg .invalid_range
    cmp rax, 0
    jl .invalid_range
    cmp rbx, sieveSize
    jg .range_too_large

    ; Вывод информации о диапазоне
    mov rsi, rangeMsg
    mov rdx, lenRangeMsg
    call FuncPrintMsg
    
    mov rax, [numA]
    call FuncPrintNumber
    
    mov rsi, toMsg
    mov rdx, lenToMsg
    call FuncPrintMsg
    
    mov rax, [numB]
    call FuncPrintNumber
    
    mov rsi, newline
    mov rdx, 1
    call FuncPrintMsg

    ; Подсчет простых чисел методом квадратичного решета
    mov rax, [numA]
    mov rbx, [numB]
    call FuncQuadraticSieve
    mov [primeCount], rax

    ; Вывод найденных простых чисел
    mov rsi, primesFoundMsg
    mov rdx, lenPrimesFoundMsg
    call FuncPrintMsg
    
    mov rax, [numA]
    mov rbx, [numB]
    call FuncPrintPrimes
    
    ; Вывод результата количества
    mov rsi, resultMsg
    mov rdx, lenResultMsg
    call FuncPrintMsg
    
    mov rax, [primeCount]
    call FuncPrintNumber
    
    ; Перевод строки
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

.invalid_range:
    mov rsi, errorMsg
    mov rdx, lenErrorMsg
    call FuncPrintError
    mov rsi, invalidNumberMsg
    mov rdx, lenInvalidNumberMsg
    call FuncPrintError
    jmp .exit_error

.range_too_large:
    mov rsi, errorMsg
    mov rdx, lenErrorMsg
    call FuncPrintError
    mov rsi, overflowMsg
    mov rdx, lenOverflowMsg
    call FuncPrintError

.exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

; ===================== МЕТОД КВАДРАТИЧНОГО РЕШЕТА =====================
FuncQuadraticSieve:
;   sieve[0] = 0   (0 - составное)
;   sieve[1] = 0   (1 - составное)  
;   sieve[2] = 1   (2 - простое)
;   ......
;   sieve[19] = 1  (19 - простое)
;   sieve[20] = 0  (20 - составное)

; Подсчет простых чисел в диапазоне [A, B] методом квадратичного решета
; Вход: RAX - число A, RBX - число B

    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    push r12
    
    mov r8, rax         ; r8 = A
    mov r9, rbx         ; r9 = B
    xor r10, r10        ; r10 = счетчик простых чисел
    
    ; Инициализация решета (1 - простое)
    call FuncInitSieve
    
    ; Отметить 0 и 1 составные
    mov byte [sieve], 0
    mov byte [sieve + 1], 0
    
    ; Вычисление sqrt(B)
    mov rax, r9
    call FuncSqrt
    mov r11, rax        ; r11 = sqrt(B)
    
    ; БАЗАААААААА
    mov rcx, 2          ; rcx = текущее простое число

.sieve_loop:
    cmp rcx, r11
    jg .count_primes    ; Если прошли sqrt(B) =>>> СЧИТАЕМ
    
    ; Проверяем, является ли текущее число простым
    cmp byte [sieve + rcx], 1
    jne .next_sieve
    
    ; Отмечаем кратные числа как составные
    mov rax, rcx
    mul rax             ; rax = rcx * rcx
    mov r12, rax        ; r12 = текущее число для отметки
    
.mark_composites:
    cmp r12, r9
    jg .next_sieve      ; Если вышли за границу
    
    ; Отметить число как составное
    mov byte [sieve + r12], 0
    
    ; Перейти к следующему кратному
    add r12, rcx
    jmp .mark_composites

.next_sieve:
    inc rcx
    jmp .sieve_loop

.count_primes:
    ; Подсчет простых чисел в диапазоне [A, B]
    mov rcx, r8         ; rcx = текущее число (начинаем с A)
.count_loop:
    cmp rcx, r9
    jg .done_counting
    
    ; Проверяем, простое ли число
    cmp byte [sieve + rcx], 1
    jne .not_prime
    
    ; Увеличиваем счетчик простых чисел
    inc r10
    
.not_prime:
    inc rcx
    jmp .count_loop

.done_counting:
    mov rax, r10        ; Возвращаем количество простых чисел
    
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

; ===================== ВЫВОД ПРОСТЫХ ЧИСЕЛ =====================
FuncPrintPrimes:
;Вывод всех простых чисел в диапазоне [A, B]
; Вход: RAX - число A, RBX - число B

    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rcx, rax        ; rcx = текущее число (начинаем с A)
.print_loop:
    cmp rcx, rbx
    jg .done_printing
    
    ; Проверяем, простое ли число
    cmp byte [sieve + rcx], 1
    jne .not_prime_print
    
    ; Вывод простого числа
    push rcx
    push rbx
    mov rax, rcx
    call FuncPrintNumber
    mov rsi, space
    mov rdx, 1
    call FuncPrintMsg
    pop rbx
    pop rcx
    
.not_prime_print:
    inc rcx
    jmp .print_loop

.done_printing:
    ; Перевод строки после вывода всех простых чисел
    mov rsi, newline
    mov rdx, 1
    call FuncPrintMsg
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; ===================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====================
FuncInitSieve:
; Инициализация решета (заполнение единицами)

    push rcx
    push rdi
    
    mov rdi, sieve      ; Адрес начала решета
    mov rcx, sieveSize  ; Размер решета
    mov al, 1           ; Заполняем единицами
    
.init_loop:
    mov [rdi], al
    inc rdi
    loop .init_loop
    
    pop rdi
    pop rcx
    ret

FuncSqrt:
; Функция: FuncSqrt
; Назначение: Вычисление целочисленного квадратного корня
; Вход: RAX - число
; Выход: RAX - целочисленный квадратный корень

    push rbx
    push rcx
    push rdx
    
    test rax, rax
    jz .zero
    cmp rax, 1
    je .one
    
    ; Начальное приближение
    mov rbx, rax
    shr rbx, 1          ; rbx = n / 2
    
.newton_loop:
    ; x_{k+1} = (x_k + n/x_k) / 2
    mov rcx, rax
    xor rdx, rdx
    div rbx             ; rax = n / x_k
    
    add rax, rbx        ; rax = x_k + n/x_k
    shr rax, 1          ; rax = (x_k + n/x_k) / 2
    
    ; Проверка сходимости
    mov rdx, rax
    sub rdx, rbx
    jz .done
    cmp rdx, 1
    je .done
    cmp rdx, -1
    je .done
    
    mov rbx, rax
    mov rax, rcx        ; Восстанавливаем исходное число
    jmp .newton_loop

.zero:
    xor rax, rax
    jmp .done
.one:
    mov rax, 1
.done:
    pop rdx
    pop rcx
    pop rbx
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