global _start

section .data
    userStartMsg:           db "Введите 3 числа для поиска максимума и вывода разницы с другими числами",10
    lenUserStartMsg         equ $-userStartMsg
    strNumberEntrenceMsg:   db "Введите число: "
    lenstrNumberEntrenceMsg equ $-strNumberEntrenceMsg
    differenceMsg:          db "Разницы: "
    lenDifferenceMsg        equ $-differenceMsg
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
    newline                 db 10
    buffer                  times 21 db 0

section .bss
    numA    resq numsSize
    numB    resq numsSize
    numC    resq numsSize
    strNumA resb strNumsSize
    strNumB resb strNumsSize
    strNumC resb strNumsSize
    maxNum  resq numsSize

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
    jc .read_error         ; Проверка ошибки чтения

    ; Ввод числа B
    mov rsi, strNumberEntrenceMsg
    mov rdx, lenstrNumberEntrenceMsg
    call FuncPrintMsg
    mov rsi, strNumB
    mov rdx, strNumsSize
    call FuncReadString
    jc .read_error

    ; Ввод числа C
    mov rsi, strNumberEntrenceMsg
    mov rdx, lenstrNumberEntrenceMsg
    call FuncPrintMsg
    mov rsi, strNumC
    mov rdx, strNumsSize
    call FuncReadString
    jc .read_error

    ; Конвертация строк в числа
    mov rsi, strNumA
    call FuncStrToInt
    jc .conversion_error   ; Проверка ошибки конвертации
    mov [numA], rax

    mov rsi, strNumB
    call FuncStrToInt
    jc .conversion_error
    mov [numB], rax

    mov rsi, strNumC
    call FuncStrToInt
    jc .conversion_error
    mov [numC], rax

    ; Поиск максимума из трех чисел
    mov rax, [numA]
    mov rbx, [numB]
    call FuncMax              ; rax = max(A, B)
    
    mov rbx, [numC]
    call FuncMax              ; rax = max(max(A, B), C)
    mov [maxNum], rax         ; Сохраняем максимум

    ; Вычисление и вывод разниц
    mov rsi, differenceMsg
    mov rdx, lenDifferenceMsg
    call FuncPrintMsg

    ; Разница между числом A и максимумом
    mov rax, [numA]
    cmp rax, [maxNum]
    je .simple_printA
    sub rax, [maxNum]
.simple_printA:
    call FuncPrintNumber
    
    ; Разница между числом B и максимумом
    mov rax, [numB]
    cmp rax, [maxNum]
    je .simple_printB
    sub rax, [maxNum]
.simple_printB:
    call FuncPrintNumber
    
    ; Разница между числом C и максимумом
    mov rax, [numC]
    cmp rax, [maxNum]
    je .simple_printC
    sub rax, [maxNum]
.simple_printC:
    call FuncPrintNumber

    ; Завершение программы с успехом
    mov rax, 60
    xor rdi, rdi
    syscall

.read_error:
    ; Обработка ошибки чтения
    mov rsi, errorMsg
    mov rdx, lenErrorMsg
    call FuncPrintError
    mov rsi, readErrorMsg
    mov rdx, lenReadErrorMsg
    call FuncPrintError
    jmp .exit_error

.conversion_error:
    ; Обработка ошибки конвертации
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

.exit_error:
    ; Завершение программы с ошибкой
    mov rax, 60
    mov rdi, 1
    syscall


; ===================== ФУНКЦИИ =====================
FuncPrintNumber:
; Функция: FuncPrintNumber
; Назначение: Печать числа в десятичном формате
; Вход: RAX - число для печати
; Используемые регистры: RAX, RBX, RCX, RDX, RSI, RDI
; Сохраняемые регистры: Все (push/pop)

    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rdi, buffer
    call FuncIntToStr
    
    ; Вычисляем длину строки
    mov rsi, buffer
    call FuncStrLen
    mov rdx, rax
    
    mov rsi, buffer
    call FuncPrintMsg
    
    ; Вывод пробела
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
; Функция: FuncStrLen
; Назначение: Вычисление длины строки
; Вход: RSI - указатель на строку (нуль-терминированную)
; Выход: RAX - длина строки
; Используемые регистры: RAX, RCX

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
; Функция: FuncPrintMsg
; Назначение: Вывод сообщения на экран (stdout)
; Вход: RSI - указатель на сообщение, RDX - длина сообщения
; Используемые регистры: RAX, RDI
    mov rax, 1
    mov rdi, 1
    syscall
    ret

FuncPrintError:
; Функция: FuncPrintError
; Назначение: Вывод сообщения об ошибке (stderr)
; Вход: RSI - указатель на сообщение, RDX - длина сообщения
; Используемые регистры: RAX, RDI
    mov rax, 1
    mov rdi, 2
    syscall
    ret

FuncReadString:
; Функция: FuncReadString
; Назначение: Чтение строки из stdin
; Вход: RSI - буфер для строки, RDX - размер буфера
; Выход: CF = 1 если ошибка, CF = 0 если успех
; Используемые регистры: RAX, RDI
    mov rax, 0
    mov rdi, 0
    syscall
    
    ; Проверка на ошибку чтения
    cmp rax, 0
    jl .error
    jmp .success
    
.error:
    stc                    ; Установка флага переноса (CF = 1)
    ret
    
.success:
    clc                    ; Сброс флага переноса (CF = 0)
    ret

FuncStrToInt:
; Функция: FuncStrToInt
; Назначение: Преобразование строки в целое число
; Вход: RSI - указатель на строку
; Выход: RAX - преобразованное число, CF = 0 если успех
;         RAX = 1 если неверный формат, RAX = 2 если переполнение, CF = 1 если ошибка
; Используемые регистры: RAX, RBX, RCX, RDX, R8, R9
    xor rax, rax
    xor rcx, rcx
    mov r8, 1               ; Флаг знака: 1 - положительное, -1 - отрицательное
    mov r9, 0               ; Счетчик цифр

    ; Пропускаем пробелы в начале
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
    ; Проверка на пустую строку
    mov bl, byte [rsi + rcx]
    cmp bl, 0xA         ; Новая строка
    je .invalid_format
    cmp bl, 0           ; Конец строки
    je .invalid_format
    cmp bl, ' '         ; Пробел
    je .invalid_format

.convert_loop:
    mov bl, byte [rsi + rcx]
    cmp bl, 0xA         ; Проверка на символ новой строки
    je .done
    cmp bl, 0           ; Проверка на конец строки
    je .done
    cmp bl, ' '         ; Пробел - конец числа
    je .done
    
    ; Проверка на валидность цифры
    cmp bl, '0'
    jl .invalid_format
    cmp bl, '9'
    jg .invalid_format
    
    inc r9              ; Увеличиваем счетчик цифр
    sub bl, '0'         ; Преобразование символа в цифру
    
    ; Проверка на переполнение перед умножением
    push rdx
    mov rdx, 10
    imul rax, rdx
    pop rdx
    jo .overflow        ; Проверка переполнения умножения
    
    ; Проверка на переполнение перед сложением
    movzx rdx, bl
    add rax, rdx
    jo .overflow        ; Проверка переполнения сложения
    
    inc rcx
    jmp .convert_loop

.done:
    ; Проверка что было хотя бы одна цифра
    cmp r9, 0
    je .invalid_format
    
    imul rax, r8        ; Умножение на знак
    jo .overflow        ; Проверка переполнения при умножении на -1
    
    clc                 ; CF = 0 - успех
    ret

.invalid_format:
    mov rax, 1
    stc                 ; CF = 1 - ошибка
    ret

.overflow:
    mov rax, 2
    stc                 ; CF = 1 - ошибка
    ret

FuncMax:
; Функция: FuncMax
; Назначение: Поиск максимального из двух чисел
; Вход: RAX - первое число, RBX - второе число
; Выход: RAX - максимальное число
; Используемые регистры: RAX, RBX
    cmp rax, rbx
    jge .no_swap
    mov rax, rbx
.no_swap:
    ret

FuncIntToStr:
; Функция: FuncIntToStr
; Назначение: Преобразование целого числа в строку
; Вход: RAX - число для преобразования, RDI - буфер для строки
; Используемые регистры: RAX, RBX, RCX, RDX, RSI, RDI
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
