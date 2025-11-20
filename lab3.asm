section .data
    ; Сообщения из предыдущей программы
    userStartMsg:           db "Введите 3 числа (длины сторон треугольника)",10
    lenUserStartMsg         equ $-userStartMsg
    strNumberEntrenceMsg:   db "Введите число: "
    lenstrNumberEntrenceMsg equ $-strNumberEntrenceMsg
    errorMsg:               db "Ошибка: ", 0
    lenErrorMsg             equ $-errorMsg
    invalidNumberMsg:       db "неверный формат числа", 10, 0
    lenInvalidNumberMsg     equ $-invalidNumberMsg
    overflowMsg:            db "переполнение числа", 10, 0
    lenOverflowMsg          equ $-overflowMsg
    readErrorMsg:           db "ошибка чтения", 10, 0
    lenReadErrorMsg         equ $-readErrorMsg
    
    notTriangleMsg:         db "Треугольник невозможно построить", 10
    lenNotTriangleMsg       equ $-notTriangleMsg
    equilateralMsg:         db "Треугольник равносторонний", 10
    lenEquilateralMsg       equ $-equilateralMsg
    isoscelesMsg:           db "Треугольник равнобедренный", 10
    lenIsoscelesMsg         equ $-isoscelesMsg
    scaleneMsg:             db "Треугольник разносторонний", 10
    lenScaleneMsg           equ $-scaleneMsg
    
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

section .text
global _start

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
    jc .conversion_error
    mov [numA], rax

    mov rsi, strNumB
    call FuncStrToInt
    jc .conversion_error
    mov [numB], rax

    mov rsi, strNumC
    call FuncStrToInt
    jc .conversion_error
    mov [numC], rax

    ; Проверка возможности построения треугольника
    call FuncCheckTriangle
    cmp rax, 0 
    jz .not_triangle

    ; Определение типа треугольника
    call FuncDetermineTriangleType
    
    ; Вывод результата в зависимости от типа
    cmp rax, 0
    je .equilateral
    cmp rax, 1
    je .isosceles
    jmp .scalene


; ===================== СООБЩЕНИЕ КАКОЙ У НАС ТРЕУГОЛЬНИЧИК =====================
.equilateral:
    mov rsi, equilateralMsg
    mov rdx, lenEquilateralMsg
    call FuncPrintMsg
    jmp .exit_success

.isosceles:
    mov rsi, isoscelesMsg
    mov rdx, lenIsoscelesMsg
    call FuncPrintMsg
    jmp .exit_success

.scalene:
    mov rsi, scaleneMsg
    mov rdx, lenScaleneMsg
    call FuncPrintMsg
    jmp .exit_success


; ===================== ОШИБКА =====================
.not_triangle:
    mov rsi, notTriangleMsg
    mov rdx, lenNotTriangleMsg
    call FuncPrintMsg
    jmp .exit_success

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

.exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

.exit_success:
    mov rax, 60
    xor rdi, rdi
    syscall

; =====================  ТРЕУГОЛЬНИКУ БЫТЬ ИЛИ НЕ БЫТЬ  =====================
FuncCheckTriangle:
    push rbx
    push rcx
    
    ; Проверяем a + b > c
    mov rax, [numA]
    mov rbx, [numB]
    add rax, rbx
    cmp rax, [numC]
    jle .not_triangle ; меньше либо равно 
    
    ; Проверяем a + c > b
    mov rax, [numA]
    mov rbx, [numC]
    add rax, rbx
    cmp rax, [numB]
    jle .not_triangle
    
    ; Проверяем b + c > a
    mov rax, [numB]
    mov rbx, [numC]
    add rax, rbx
    cmp rax, [numA]
    jle .not_triangle
    
    ; Все условия выполнены
    mov rax, 1
    jmp .done
    
.not_triangle:
    mov rax, 0
    
.done:
    pop rcx
    pop rbx
    ret

; ====================== КАКОЙ УКРОВЕНЬ КРУТОСТИ У НАШЕГО СУЩЕСТВУЮЩЕГО ТРЕУГОЛЬНИКА ФУНКЦИЯ ======================
; Выход: RAX = 0 (равносторонний), 1 (равнобедренный), 2 (разносторонний)
FuncDetermineTriangleType:
    push rbx
    push rcx
    
    ; Проверяем равносторонний треугольник (все стороны равны)
    mov rax, [numA]
    mov rbx, [numB]
    mov rcx, [numC]
    
    cmp rax, rbx
    jne .check_isosceles
    cmp rax, rcx
    jne .check_isosceles
    
    ; Все стороны равны - равносторонний
    mov rax, 0
    jmp .done
    
.check_isosceles:
    ; Проверяем равнобедренный треугольник (две стороны равны)
    cmp rax, rbx
    je .isosceles
    cmp rax, rcx
    je .isosceles
    cmp rbx, rcx
    je .isosceles
    
    ; Все стороны разные - разносторонний
    mov rax, 2
    jmp .done
    
.isosceles:
    ; Две стороны равны - равнобедренный
    mov rax, 1
    
.done:
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

