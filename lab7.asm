section .data
    ; Определить, является ли заданная целочисленная квадратная матрица 
    ; симметричной относительно побочной диагонали
    task_msg        db "ЗАДАЧА: Определить, является ли квадратная матрица симметричной относительно побочной диагонали", 10, 0
    len_task_msg    equ $ - task_msg
    input_n_msg      db "Введите размер матрицы n: ", 0
    len_n_msg        equ $ - input_n_msg
    input_matrix_msg db "Введите элементы матрицы:", 10, 0
    len_matrix_msg   equ $ - input_matrix_msg
    element_msg      db "Элемент [", 0
    len_element_msg  equ $ - element_msg
    comma_msg        db ", ", 0
    len_comma        equ $ - comma_msg
    close_bracket    db "]: ", 0
    len_close_bracket equ $ - close_bracket
    current_matrix_msg db 10, "Текущее состояние матрицы:", 10, 0
    len_current_matrix equ $ - current_matrix_msg
    your_matrix_msg  db 10, "Итоговая матрица:", 10, 0
    len_your_matrix  equ $ - your_matrix_msg
    symmetric_msg    db "Матрица симметрична относительно побочной диагонали", 10, 0
    len_symmetric    equ $ - symmetric_msg
    not_symmetric_msg db "Матрица НЕ симметрична относительно побочной диагонали", 10, 0
    len_not_symmetric equ $ - not_symmetric_msg
    empty_cell_msg   db "-", 0                    ; "-"
    len_empty_cell   equ $ - empty_cell_msg
    error_msg        db "Ошибка: введите корректное целое число!", 10, 0
    len_error_msg    equ $ - error_msg
    error_size_msg   db "Ошибка: размер матрицы должен быть от 1 до 10!", 10, 0
    len_error_size_msg equ $ - error_size_msg
    newline          db 10, 0
    space            db " ", 0
    
    buffer           times 21 db 0

section .bss
    n_value          resq 1
    matrix           resq 100  ; Максимум 10x10 матрица
    filled           resb 100  ; Флаги заполнения ячеек

section .text
    global _start

_start:
    ; Вывод условия задачи
    mov rax, 1
    mov rdi, 1
    mov rsi, task_msg
    mov rdx, len_task_msg
    syscall

    ; Ввод размера матрицы n
    mov rax, 1
    mov rdi, 1
    mov rsi, input_n_msg
    mov rdx, len_n_msg
    syscall

    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 20
    syscall

    mov rsi, buffer
    call string_to_int
    jc .error_input
    mov [n_value], rax

    ; Проверка корректности размера
    cmp qword [n_value], 1
    jl .error_size
    cmp qword [n_value], 10
    jg .error_size

    ; Инициализация матрицы (помечаем все ячейки как пустые)
    call init_matrix

    ; Ввод матрицы
    mov rax, 1
    mov rdi, 1
    mov rsi, input_matrix_msg
    mov rdx, len_matrix_msg
    syscall

    call input_matrix_interactive

    ; Вывод итоговой матрицы
    mov rax, 1
    mov rdi, 1
    mov rsi, your_matrix_msg
    mov rdx, len_your_matrix
    syscall

    call print_matrix

    ; Проверка симметричности относительно побочной диагонали
    call check_secondary_diagonal_symmetry
    test rax, rax
    jz .not_symmetric

    ; Вывод сообщения о симметричности
    mov rax, 1
    mov rdi, 1
    mov rsi, symmetric_msg
    mov rdx, len_symmetric
    syscall
    jmp .exit

.not_symmetric:
    ; Вывод сообщения о несимметричности
    mov rax, 1
    mov rdi, 1
    mov rsi, not_symmetric_msg
    mov rdx, len_not_symmetric
    syscall
    jmp .exit

.error_input:
    call print_error
    jmp .exit

.error_size:
    ; Вывод ошибки размера матрицы
    mov rax, 1
    mov rdi, 1
    mov rsi, error_size_msg
    mov rdx, len_error_size_msg
    syscall
    jmp .exit

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

; =============================================
; Назначение: Вывод сообщения об ошибке
; =============================================
print_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, len_error_msg
    syscall
    ret


;====================================================================================================================================================================================
;                                                                         ВВОД И ВЫВОД МАТРИЦЫ 
;====================================================================================================================================================================================

; Назначение: Инициализация матрицы
init_matrix:
    push r12
    push r13
    push r14
    
    mov r12, 0                  ; Счетчик элементов
    mov r13, [n_value]          ; Размер матрицы
    imul r13, r13               ; Количество элементов

; обнуление флагов и значений матрицы    
.init_loop:
    cmp r12, r13                
    jge .init_done              ; Если прошли все элементы - выход            
    
    ; Помечаем ячейку как пустую
    mov byte [filled + r12], 0   ; 0 = не заполнено
    mov qword [matrix + r12*8], 0; Обнуляем значение в матрице
    
    inc r12                    
    jmp .init_loop             
    
.init_done:
    pop r14
    pop r13
    pop r12
    ret

; Интерактивный ввод элементов матрицы с отображением текущего состояния
input_matrix_interactive:
    push r12
    push r13
    push r14
    push r15
    
    mov r12, 0                  ; r12 = i (строка) = 0
    mov r13, [n_value]          ; r13 = n
    
.outer_loop:
    cmp r12, r13
    jge .input_done
    
    mov r14, 0                  ; r14 = j (столбец) = 0 
    
.inner_loop:   ; цикл по столбцам
    cmp r14, r13
    jge .inner_done

; Вывод "Элемент [i, j]: "
.input_retry:    
    ; Вывод "[ "
    mov rax, 1
    mov rdi, 1
    mov rsi, element_msg
    mov rdx, len_element_msg
    syscall
    
    ; Вывод номера строки (i+1)
    mov rax, r12
    inc rax
    call print_number
    
    ; Вывод ", "
    mov rax, 1
    mov rdi, 1
    mov rsi, comma_msg
    mov rdx, len_comma
    syscall
    
    ; Вывод номера столбца (j+1)
    mov rax, r14
    inc rax
    call print_number
    
    ; Вывод "] "
    mov rax, 1
    mov rdi, 1
    mov rsi, close_bracket
    mov rdx, len_close_bracket
    syscall
    
    ; Ввод элемента матрицы
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 20
    syscall
    
    ; Очистка буфера от лишних символов
    mov rdi, buffer
    call clean_buffer
    
    mov rsi, buffer
    call string_to_int
    jnc .input_ok
    
    ; Ошибка ввода - выводим сообщение и повторяем
    call print_error
    jmp .input_retry

.input_ok:
    ; Сохранение элемента в матрицу: matrix[i*n + j]
    mov r15, r12                ; i
    imul r15, r13               ; i × n
    add r15, r14                ; i×n + j
    mov [matrix + r15*8], rax
    mov byte [filled + r15], 1  ; Помечаем как заполненное
    
    ; Вывод текущего состояния матрицы
    mov rax, 1
    mov rdi, 1
    mov rsi, current_matrix_msg
    mov rdx, len_current_matrix
    syscall
    
    call print_current_matrix
    
    inc r14
    jmp .inner_loop

.inner_done:
    inc r12
    jmp .outer_loop

.input_done:
    pop r15
    pop r14
    pop r13
    pop r12
    ret
;  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
; Вывод текущего состояния матрицы (заполненные и пустые ячейки)
print_current_matrix:
    push r12
    push r13
    push r14
    push r15
    
    mov r12, 0                  ; r12 = i
    mov r13, [n_value]          ; r13 = n
    
.outer_loop:
    cmp r12, r13
    jge .print_done
    
    mov r14, 0                  ; r14 = j
    
.inner_loop:
    cmp r14, r13
    jge .inner_done
    
    ; Проверяем, заполнена ли ячейка
    mov r15, r12
    imul r15, r13
    add r15, r14
    
    cmp byte [filled + r15], 0
    je .empty_cell
    
    ; Заполненная ячейка - выводим число
    mov rax, [matrix + r15*8]
    call print_number
    jmp .next_element

.empty_cell:
    ; Пустая ячейка - выводим "-" 
    mov rax, 1
    mov rdi, 1
    mov rsi, empty_cell_msg ; "-" 
    mov rdx, len_empty_cell
    syscall

.next_element:
    ; Печатаем пробел 
    mov rax, r14
    inc rax
    cmp rax, r13
    jge .no_space
    call print_space

.no_space:
    inc r14
    jmp .inner_loop

.inner_done:
    ; Переход на новую строку
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    inc r12
    jmp .outer_loop

.print_done:
    pop r15
    pop r14
    pop r13
    pop r12
    ret

; Назначение: Вывод итоговой матрицы
print_matrix:
    push r12
    push r13
    push r14
    push r15
    
    mov r12, 0                  ; r12 = i
    mov r13, [n_value]          ; r13 = n
    
.outer_loop:
    cmp r12, r13
    jge .print_done
    
    mov r14, 0                  ; r14 = j
    
.inner_loop:
    cmp r14, r13
    jge .inner_done
    
    ; Получаем элемент матрицы matrix[i][j]
    mov r15, r12
    imul r15, r13
    add r15, r14
    mov rax, [matrix + r15*8]
    call print_number

.next_element:
    ; Печатаем пробел между элементами (кроме последнего в строке)
    mov rax, r14
    inc rax
    cmp rax, r13
    jge .no_space
    call print_space

.no_space:
    inc r14
    jmp .inner_loop

.inner_done:
    ; Переход на новую строку
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    inc r12
    jmp .outer_loop

.print_done:
    pop r15
    pop r14
    pop r13
    pop r12
    ret

; Назначение: Очистка буфера от символов новой строки
clean_buffer:
    push rcx
    mov rcx, 0
.clean_loop:
    cmp byte [rdi + rcx], 0
    je .done
    cmp byte [rdi + rcx], 10
    jne .next
    mov byte [rdi + rcx], 0
.next:
    inc rcx
    cmp rcx, 20
    jl .clean_loop
.done:
    pop rcx
    ret



; ====================================================================================================================================================================================
;                                                                                      ФУНКЦИИ
; ====================================================================================================================================================================================



; =============================================
; Назначение: Проверка симметричности относительно побочной диагонали
; Выход: RAX = 1 (симметрична), 0 (не симметрична)
; =============================================
check_secondary_diagonal_symmetry:
    push r12
    push r13
    push r14
    push r15
    
    mov r12, 0                  ; r12 = i
    mov r13, [n_value]          ; r13 = n
    
.outer_loop:
    cmp r12, r13
    jge .symmetric
    
    mov r14, 0                  ; r14 = j
    
.inner_loop:
    cmp r14, r13
    jge .inner_done

    ; Пропускаем элементы на побочной диагонали и выше нее
    ; Для побочной диагонали: i + j = n - 1
    mov rax, r12
    add rax, r14
    mov rbx, r13
    dec rbx
    cmp rax, rbx
    jge .next_element
    ;=================================================================================
    ; Сравниваем matrix[i][j] и matrix[n-1-j][n-1-i]
    ;=================================================================================
    ; Вычисляем индексы симметричного элемента
    mov r15, r13
    dec r15                     ; r15 = n-1
    
    mov rax, r15
    sub rax, r14                ; sym_i = n-1-j
    
    mov rbx, r15
    sub rbx, r12                ; sym_j = n-1-i
    
    ; Получаем matrix[i][j]
    mov rcx, r12
    imul rcx, r13
    add rcx, r14
    mov rdx, [matrix + rcx*8]   ; rdx = matrix[i][j]
    
    ; Получаем matrix[sym_i][sym_j]
    mov rcx, rax
    imul rcx, r13
    add rcx, rbx
    mov r8, [matrix + rcx*8]    ; r8 = matrix[sym_i][sym_j]
    
    ; Сравниваем элементы
    cmp rdx, r8
    jne .not_symmetric
    
.next_element:
    inc r14
    jmp .inner_loop

.inner_done:
    inc r12
    jmp .outer_loop

.symmetric:
    mov rax, 1
    jmp .done

.not_symmetric:
    mov rax, 0

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    ret

; =============================================
;                    функции
; =============================================

print_space:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print_number:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rdi, buffer
    call int_to_string
    
    mov rsi, buffer
    call string_length
    mov rdx, rax
    
    mov rax, 1
    mov rdi, 1
    syscall
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

string_length:
    xor rcx, rcx
.count_loop:
    cmp byte [rsi + rcx], 0
    je .done
    inc rcx
    jmp .count_loop
.done:
    mov rax, rcx
    ret

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

string_to_int:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx
    mov rdx, 1
    
    ; Пропускаем начальные пробелы
.skip_spaces:
    mov bl, byte [rsi + rcx]
    cmp bl, ' '
    je .skip_char
    cmp bl, 9    ; TAB
    je .skip_char
    jmp .check_sign
.skip_char:
    inc rcx
    jmp .skip_spaces

.check_sign:
    mov bl, byte [rsi + rcx]
    cmp bl, '-'
    jne .check_plus
    mov rdx, -1
    inc rcx
    jmp .check_digit
    
.check_plus:
    cmp bl, '+'
    jne .check_digit
    inc rcx

.check_digit:
    mov bl, byte [rsi + rcx]
    cmp bl, 0
    je .apply_sign
    cmp bl, 10   ; newline
    je .apply_sign
    cmp bl, ' '
    je .apply_sign
    cmp bl, 13   ; carriage return
    je .apply_sign
    
    cmp bl, '0'
    jl .error
    cmp bl, '9'
    jg .error
    
    sub bl, '0'
    imul rax, 10
    jo .error
    add rax, rbx
    jo .error
    
    inc rcx
    jmp .check_digit

.apply_sign:
    imul rax, rdx
    jo .error
    
    clc
    jmp .exit

.error:
    stc

.exit:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret


;Строка 0: i=0 → индексы 0,1,2,3
;  [0,0]: 0×4 + 0 = 0
;  [0,1]: 0×4 + 1 = 1
;  [0,2]: 0×4 + 2 = 2
;  [0,3]: 0×4 + 3 = 3

;Строка 1: i=1 → индексы 4,5,6,7  
;  [1,0]: 1×4 + 0 = 4
;  [1,1]: 1×4 + 1 = 5
;  [1,2]: 1×4 + 2 = 6
;  [1,3]: 1×4 + 3 = 7

;Строка 2: i=2 → индексы 8,9,10,11
;  [2,0]: 2×4 + 0 = 8
;  [2,1]: 2×4 + 1 = 9
;  [2,2]: 2×4 + 2 = 10
;  [2,3]: 2×4 + 3 = 11

;Строка 3: i=3 → индексы 12,13,14,15
;  [3,0]: 3×4 + 0 = 12
;  [3,1]: 3×4 + 1 = 13  
;  [3,2]: 3×4 + 2 = 14
;  [3,3]: 3×4 + 3 = 15