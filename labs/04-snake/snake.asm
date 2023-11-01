;	set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; button state
.equ    BUTTON_NONE,    0
.equ    BUTTON_LEFT,    1
.equ    BUTTON_UP,      2
.equ    BUTTON_DOWN,    3
.equ    BUTTON_RIGHT,   4
.equ    BUTTON_CHECKPOINT,    5

; array state
.equ    DIR_LEFT,       1       ; leftward direction
.equ    DIR_UP,         2       ; upward direction
.equ    DIR_DOWN,       3       ; downward direction
.equ    DIR_RIGHT,      4       ; rightward direction
.equ    FOOD,           5       ; food

; constants
.equ    NB_ROWS,        8       ; number of rows
.equ    NB_COLS,        12      ; number of columns
.equ    NB_CELLS,       96      ; number of cells in GSA
.equ    RET_ATE_FOOD,   1       ; return value for hit_test when food was eaten
.equ    RET_COLLISION,  2       ; return value for hit_test when a collision was detected
.equ    ARG_HUNGRY,     0       ; a0 argument for move_snake when food wasn't eaten
.equ    ARG_FED,        1       ; a0 argument for move_snake when food was eaten

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;
; return values
;     This procedure should never return.
; BEGIN:main
main:
    ; Initialize the snake's position at the upper left corner (0, 0)
    addi a0, zero, 0  ; Set head x-coordinate
    addi a1, zero, 0  ; Set head y-coordinate
    stw a0, HEAD_X(zero)
    stw a1, HEAD_Y(zero)
    stw a0, TAIL_X(zero)
    stw a1, TAIL_Y(zero)

    ; Set snake's initial direction to rightwards
    addi t0, zero, DIR_RIGHT
    stw t0, GSA(zero)  ; Store direction in the first cell of GSA

    ; Start the game loop
    game_loop:
        ; Clear the display
        call clear_leds

        ; Get player input
        call get_input

        ; Move the snake based on the current direction and input
        call move_snake

        ; Draw the updated game state
        call draw_array

        ; Loop back to continue the game using bne for infinite loop
        addi t1, zero, 0
        addi t2, zero, 1
        bne t1, t2, game_loop

; END:main


; Arguments:
;     none
; Return values:
;     none
; BEGIN:clear_leds
clear_leds:
    stw zero, LEDS(zero)        ; Store 0 to LEDS(0)
    stw zero, LEDS+4(zero)      ; Store 0 to LEDS(1)          
    stw zero, LEDS+8(zero)      ; Store 0 to LEDS(2)
    ret                         ; Return
; END: clear_leds

; Arguments:
;     a0: x-coordinate
;     a1: y-coordinate
; Return values:
;     none
; BEGIN:set_pixel
set_pixel:
    addi sp, sp, -20            ; push 5 registers
    stw s0, 0(sp)               ; save s0
    stw s1, 4(sp)               ; save s1
    stw s2, 8(sp)               ; save s2
    stw s3, 12(sp)              ; save s3
    stw s4, 16(sp)              ; save s4

    andi s1, a0, 12             ; s1 = x & 12 (12 = 0b1100, mask the 2 MSB)) (s1 selects the LEDS register to write to)
    slli s0, a0, 3              ; s0 = x << 3 (8*x)
    andi s2, s0, 31             ; s2 = s0 & 31 (31 = 0b11111, mask the 5 LSB)
    add s2, s2, a1              ; s2 = s2 + y
    addi s3, zero, 1            ; s3 = 1
    sll s3, s3, s2              ; s3 = 1 << s2
    ldw s4, LEDS(s1)            ; s4 = LEDS(s1)
    or s3, s4, s3               ; s3 = s4 | s3
    stw s3, LEDS(s1)            ; LEDS(s1) = s3

    ldw s4, 16(sp)              ; restore s4
    ldw s3, 12(sp)              ; restore s3
    ldw s2, 8(sp)               ; restore s2
    ldw s1, 4(sp)               ; restore s1
    ldw s0, 0(sp)               ; restore s0
    addi sp, sp, 20             ; pop 5 registers
    ret                         ; Return
; END:set_pixel

; BEGIN:wait
wait:
    stw s0, 0(sp)               ; save s0

    addi s0, zero, 1            ; s0 = 1
    slli s0, s0, 20             ; s0 = 0x100000

    wait_loop:                  ; wait_loop:
        addi s0, s0, -1         ;   s0 = s0 - 1
        bne s0, zero, wait_loop
    ;   if s0 != 0, goto wait_loop


    ldw s0, 0(sp)               ; restore s0
    addi sp, sp, 4              ; pop s0
    ret                         ; Return
; END:wait

; BEGIN: display_score
display_score:

; END: display_score


; BEGIN: init_game
init_game:

; END: init_game


; BEGIN: create_food
create_food:

; END: create_food


; BEGIN: hit_test
hit_test:

; END: hit_test

;Arguments:
    ;None
;Return values:
    ;register v0: button state (0 -> None, 1 -> Left, 2 -> Up, 3 -> Down, 4 -> Right, 5 -> Checkpoint)
; BEGIN: get_input
get_input:
    ldw t0, BUTTONS+4(zero)     ; t0 = BUTTONS(1)
    stw zero, BUTTONS+4(zero)   ; BUTTONS(1) = 0
    ; We start with b5 because we want it to have precedence over the other buttons
    andi t1, t0, 32             ; t1 = t0 & (100000)b
    bne t1, zero, onlyb5        ; if t1 != 0, goto onlyb5
    andi t1, t0, 1              ; t1 = t0 & (1)b 
    bne t1, zero, onlyb0        ; if t1 != 0, goto onlyb0
    andi t1, t0, 2              ; t1 = t0 & (10)b
    bne t1, zero, onlyb1        ; if t1 != 0, goto onlyb1
    andi t1, t0, 4              ; t1 = t0 & (100)b
    bne t1, zero, onlyb2        ; if t1 != 0, goto onlyb2
    andi t1, t0, 8              ; t1 = t0 & (1000)b
    bne t1, zero, onlyb3        ; if t1 != 0, goto onlyb3
    andi t1, t0, 16             ; t1 = t0 & (10000)b
    bne t1, zero, onlyb4        ; if t1 != 0, goto onlyb4
    onlyb0:
        addi v0, zero, BUTTON_NONE  ; v0 = BUTTON_NONE
        ret
    onlyb1:
        addi v0, zero, BUTTON_LEFT  ; v0 = BUTTON_LEFT
        ret
    onlyb2:
        addi v0, zero, BUTTON_UP    ; v0 = BUTTON_UP
        ret
    onlyb3:
        addi v0, zero, BUTTON_DOWN  ; v0 = BUTTON_DOWN
        ret
    onlyb4:
        addi v0, zero, BUTTON_RIGHT ; v0 = BUTTON_RIGHT
        ret
    onlyb5:
        addi v0, zero, BUTTON_CHECKPOINT ; v0 = BUTTON_CHECKPOINT
        ret
; END: get_input


; BEGIN:draw_array
draw_array:
    ; Clear the display
    call clear_leds

    ; Initialize loop counters
    addi t0, zero, 0        ; t0 = i (Row counter, initialized to 0)
    addi t1, zero, 0        ; t1 = j (Column counter, initialized to 0)
    addi t2, zero, NB_ROWS  ; t2 = Total number of rows
    addi t3, zero, NB_COLS  ; t3 = Total number of columns

    draw_array_loop_row:
        ; Check if all rows are processed
        beq t0, t2, end_draw_array

        ; Reset column counter for new row
        addi t1, zero, 0

    draw_array_loop_col:
        ; Check if all columns in the current row are processed
        beq t1, t3, update_row_counter

        ; Calculate index in GSA without using mul
        ; index = i * NB_COLS + j
        add t4, t0, t0           ; t4 = 2 * i
        add t4, t4, t4           ; t4 = 4 * i
        add t4, t4, t4           ; t4 = 8 * i
        add t4, t4, t1           ; t4 = t4 + j

        ; Load cell value from GSA
        ldw t5, GSA(t4)

        ; Check if the cell is part of the snake or food
        addi t6, zero, FOOD
        beq t5, t6, draw_pixel     ; If cell is food, draw pixel
        beq t5, zero, skip_pixel   ; If cell is empty, skip to next column

        ; Otherwise, it's part of the snake, so draw pixel
    draw_pixel:
        addi a0, t1, 0   ; a0 = t1 (Set x-coordinate)
        addi a1, t0, 0   ; a1 = t0 (Set y-coordinate)
        call set_pixel

    skip_pixel:
        ; Move to the next column
        addi t1, t1, 1
        bne t1, t3, draw_array_loop_col

    update_row_counter:
        ; Move to the next row
        addi t0, t0, 1
        bne t0, t2, draw_array_loop_row

end_draw_array:
    ret
; END:draw_array


; BEGIN:move_snake
move_snake:
    ; Load head and tail coordinates
    ldw t0, HEAD_X(zero)  ; t0 = head's x-coordinate
    ldw t1, HEAD_Y(zero)  ; t1 = head's y-coordinate
    ldw t2, TAIL_X(zero)  ; t2 = tail's x-coordinate
    ldw t3, TAIL_Y(zero)  ; t3 = tail's y-coordinate

    ; Load direction and ARG_FED into registers
    addi t5, zero, DIR_RIGHT
    addi t6, zero, DIR_LEFT
    addi t7, zero, DIR_UP
    ; Note: We'll load DIR_DOWN and ARG_FED on-the-fly when required

    ; Determine the direction of the snake from the head's position in the GSA
    ldw t4, GSA(t0)       ; t4 = direction of the snake's head

    ; Save current head position as it will become the new tail if the snake ate food
    add t2, t0, zero      ; t2 = previous head's x-coordinate (reusing t2 temporarily)
    add t3, t1, zero      ; t3 = previous head's y-coordinate (reusing t3 temporarily)

    ; Update head's position based on direction
    beq t4, t5, move_right
    beq t4, t6, move_left
    beq t4, t7, move_up
    addi t4, zero, DIR_DOWN  ; Load DIR_DOWN value
    beq t4, t4, move_down   ; Always take this branch as it's the last option

    move_right:
        addi t0, t0, 1        ; Move right
        bne zero, zero, update_snake_position
    move_left:
        addi t0, t0, -1       ; Move left
        bne zero, zero, update_snake_position
    move_up:
        addi t1, t1, -1       ; Move up
        bne zero, zero, update_snake_position
    move_down:
        addi t1, t1, 1        ; Move down

    update_snake_position:
        ; Update the head's position in memory
        stw t0, HEAD_X(zero)
        stw t1, HEAD_Y(zero)

        ; Check if the snake ate food
        addi t4, zero, ARG_FED  ; Load ARG_FED value
        beq a0, t4, snake_ate_food
        ; If the snake did not eat food, clear the tail's previous position
        stw zero, GSA(t2)       ; Clear the GSA cell at tail's position
        ; Update tail's position to previous head's position
        stw t2, TAIL_X(zero)
        stw t3, TAIL_Y(zero)

    snake_ate_food:
    ret
; END:move_snake


; BEGIN: save_checkpoint
save_checkpoint:

; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:

; END: restore_checkpoint


; BEGIN: blink_score
blink_score:

; END: blink_score
