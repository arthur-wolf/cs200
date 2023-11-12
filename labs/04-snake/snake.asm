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
    ; Initialize the game state
    ; Set the snake's head and tail positions to the upper left corner (0, 0)
    addi a0, zero, 0  ; a0 = 0, x-coordinate for head and tail
    addi a1, zero, 0  ; a1 = 0, y-coordinate for head and tail
    call set_pixel    ; Set the pixel at (0, 0) to 1
    stw a0, HEAD_X(zero)  ; Store head x-coordinate at HEAD_X
    stw a1, HEAD_Y(zero)  ; Store head y-coordinate at HEAD_Y
    stw a0, TAIL_X(zero)  ; Store tail x-coordinate at TAIL_X
    stw a1, TAIL_Y(zero)  ; Store tail y-coordinate at TAIL_Y

    ; Set the snake's initial direction to rightwards
    addi t0, zero, DIR_RIGHT  ; t0 = DIR_RIGHT
    slli t0, t0, 2            ; t0 = t0 * 4 (shift left by 2 bits) to get the correct word in the GSA
    stw t0, GSA(zero)         ; 

    ; Start the game loop
    game_loop:
        ; Clear the display
        ;call clear_leds

        ; Get player input
        ;call get_input

        ; Move the snake based on the current direction and input
        ;call move_snake

        ; Draw the updated game state
        ;call draw_array

        ; Display the score
        call display_score

        ; Loop back to continue the game using beq for infinite loop
        addi t1, zero, 0
        beq t1, t1, game_loop

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

; BEGIN: set_pixel
; Arguments:
;     a0: x-coordinate
;     a1: y-coordinate
; Return values:
;     none
set_pixel:
    addi sp, sp, -16            ; Make room on the stack for 4 registers
    stw ra, 0(sp)               ; Save ra
    stw s0, 4(sp)               ; Save s0
    stw s1, 8(sp)               ; Save s1
    stw s2, 12(sp)              ; Save s2

    ; Calculate linear index (y * NB_COLS + x) without using 'mul'
    slli s0, a1, 2              ; s0 = y << 2 (equivalent to y * 4)
    add s0, s0, s0              ; s0 = s0 * 2 (equivalent to y * 8)
    add s0, s0, a0              ; s0 = y * NB_COLS + x

    ; Calculate the address offset for the LED array
    srai s1, s0, 5              ; s1 = s0 / 32 (find the LED array index)
    slli s1, s1, 2              ; s1 = s1 * 4 (find the memory offset)

    ; Calculate the bit position within the selected LED register
    andi s2, s0, 0x1F           ; s2 = s0 & 31 (bit position in the register)
    addi s0, zero, 1            ; s0 = 1 (starting bit)

    loop_shift:
        beq s2, zero, end_shift ; If s2 is 0, end the loop
        slli s0, s0, 1          ; s0 = s0 << 1
        addi s2, s2, -1         ; s2 = s2 - 1
        br loop_shift
    end_shift:

    ; Set the bit in the appropriate LED register
    ldw s2, LEDS(s1)            ; Load the current value of the LED register
    or s0, s0, s2               ; Set the appropriate bit
    stw s0, LEDS(s1)            ; Update the LED register

    ; Restore registers and return
    ldw s2, 12(sp)              ; Restore s2
    ldw s1, 8(sp)               ; Restore s1
    ldw s0, 4(sp)               ; Restore s0
    ldw ra, 0(sp)               ; Restore ra
    addi sp, sp, 16             ; Free up the stack space
    ret                         ; Return
; END: set_pixel


; BEGIN:wait
wait:
    addi sp, sp, -4             ; push s0
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
    addi sp, sp, -32
    stw ra, 0(sp)       ; Save ra
    stw t0, 4(sp)       ; Save t0
    stw t1, 8(sp)       ; Save t1
    stw t2, 12(sp)      ; Save t2
    stw t3, 16(sp)      ; Save t3
    stw t4, 20(sp)      ; Save t4
    stw t5, 24(sp)      ; Save t5
    stw t6, 28(sp)      ; Save t6

    ldw t0, SCORE(zero)  ; Load the score into register t0

    ; Display 0 on the two leftmost 7-segment displays (displays 0 and 1)
    addi t1, zero, SEVEN_SEGS
    addi t2, zero, 0xFC  ; 7-segment code for 0
    stw t2, 0(t1)        ; Display 0 on display 0
    stw t2, 4(t1)        ; Display 0 on display 1

    ; Extract the value of the tens from the score
    addi t3, zero, 10    ; t3 = 10
    addi t4, zero, 0     ; t4 will be the tens digit
    addi t5, zero, 0     ; t5 will be the ones digit

    tens_loop:               ; count the number of tens in t0
        sub t6, t0, t3       ; t6 = t0 - 10
        bge t6, zero, tens_update
        br ones_digit        ; tens have been counted and their amount is stored in t4
    tens_update:
        addi t4, t4, 1       ; Increment tens digit
        addi t0, t0, -10     ; Subtract 10 from score
        br tens_loop

    ones_digit:
        add t5, t0, zero     ; t5 = t0 (ones digit) (t0 now is between 0 and 9 from the tens step)

    display_tens:
        slli t4, t4, 2          ; t4 = t4 * 4 (shift left by 2 bits) to get the correct word offset
        ldw t6, digit_map(t4)   ; t6 = 7-segment code for tens digit
        stw t6, SEVEN_SEGS+8(zero)      ; Display tens digit on the 3rd display
        
    display_ones:
        slli t5, t5, 2          ; t5 = t5 * 4 (shift left by 2 bits) to get the correct word offset
        ldw t6, digit_map(t5)  ; t6 = 7-segment code for ones digit
        stw t6, SEVEN_SEGS+12(zero)     ; Display ones digit on the 4th display
        br end_display_score

    digit_map:
    .word 0xFC  ; 0
    .word 0x60  ; 1
    .word 0xDA  ; 2
    .word 0xF2  ; 3
    .word 0x66  ; 4
    .word 0xB6  ; 5
    .word 0xBE  ; 6
    .word 0xE0  ; 7
    .word 0xFE  ; 8
    .word 0xF6  ; 9

    end_display_score:
        ldw t6, 28(sp)      ; Restore t6
        ldw t5, 24(sp)      ; Restore t5
        ldw t4, 20(sp)      ; Restore t4
        ldw t3, 16(sp)      ; Restore t3
        ldw t2, 12(sp)      ; Restore t2
        ldw t1, 8(sp)       ; Restore t1
        ldw t0, 4(sp)       ; Restore t0
        ldw ra, 0(sp)       ; Restore ra
        addi sp, sp, 32     ; Pop registers

        ret
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

; BEGIN: get_input
; Arguments:
;     none
; Return values:
;     none, but updates the game state array with the new direction if needed
get_input:
    addi v0, zero, 0            ; v0 = 0 (default return value)
    
    ; Read the edgecapture register to find out which buttons were pressed
    ldw t0, BUTTONS+4(zero)     ; t0 = edgecapture value
    ; Clear the edgecapture register by writing back its value
    stw zero, BUTTONS+4(zero)     ; Clear edgecapture

    ; Check each direction button and update the game state accordingly
    ; Make sure not to change direction if it's the opposite of the current movement
    ; The direction is stored in the first cell of the GSA

    ; Load current direction
    ldw t1, GSA(zero)           ; t1 = current direction

    check_checkpoint:
        ; Check for checkpoint button press, i.e. is the 4th bit set?
        addi t2, zero, 16           ; t2 = 0b00010000
        and t2, t0, t2              ; t2 = t0 & t2 (is the 4th bit set?)
        ; at this point if t2 is 0, then checkpoint button is not pressed
        beq t2, zero, check_left    ; if t2 is 0, go to check left button
        br is_checkpoint            ; if t2 is not 0, go to is_checkpoint 

    is_checkpoint:
        stw t2, GSA(zero)               ; update direction to checkpoint
        addi v0, zero, 5                ; set v0 to 5 to indicate checkpoint
        br get_input_done               ; skip other checks and end procedure

    check_left:
        ; Check for left button press, i.e. is the 0th bit pressed
        addi t2, zero, 1            ; t2 = 0b00000001
        and t2, t0, t2              ; t2 = t0 & t2 (is the 0th bit set?)
        ; at this point if t2 is 0, then left button is not pressed
        beq t2, zero, check_up      ; if t2 is 0, go to check up button
        br is_left                  ; if t2 is not 0, go to is_left

    is_left:
        addi t3, zero, DIR_RIGHT    ; t3 = right direction
        beq t1, t3, check_up        ; if current direction is right, ignore left button
        stw t2, GSA(zero)           ; update direction to left
        addi v0, zero, 1            ; set v0 to 1 to indicate left
        br get_input_done           ; skip other checks and end procedure

    check_up:
        ; Check for up button press, i.e. is the 1st bit set?
        addi t2, zero, 2            ; t2 = 0b00000010
        and t2, t0, t2              ; t2 = t0 & t2 (is the 1st bit set?)
        ; at this point if t2 is 0, then up button is not pressed
        beq t2, zero, check_down    ; if t2 is 0, go to check down button
        br is_up                    ; if t2 is not 0, go to is_up

    is_up:
        addi t3, zero, DIR_DOWN     ; t3 = down direction
        beq t1, t3, check_down      ; if current direction is down, ignore up button
        stw t2, GSA(zero)           ; update direction to up
        addi v0, zero, 2            ; set v0 to 2 to indicate up
        br get_input_done           ; skip other checks and end procedure

    check_down:
        ; Check for down button press, i.e. is the 2nd bit set?
        addi t2, zero, 4            ; t2 = 0b00000100
        and t2, t0, t2              ; t2 = t0 & t2 (is the 2nd bit set?)
        ; at this point if t2 is 0, then down button is not pressed
        beq t2, zero, check_right   ; if t2 is 0, go to check right button
        br is_down                  ; if t2 is not 0, go to is_down

    is_down:
        addi t3, zero, DIR_UP       ; t3 = up direction
        beq t1, t3, check_right     ; if current direction is up, ignore down button
        stw t2, GSA(zero)           ; update direction to down
        addi v0, zero, 3            ; set v0 to 3 to indicate down
        br get_input_done           ; skip other checks and end procedure

    check_right:
        ; Check for right button press, i.e. is the 3rd bit set?
        addi t2, zero, 8            ; t2 = 0b00001000
        and t2, t0, t2              ; t2 = t0 & t2 (is the 3rd bit set?)
        ; at this point if t2 is 0, then right button is not pressed
        beq t2, zero, none_pressed  ; if t2 is 0, go to none_pressed
        br is_right                 ; if t2 is not 0, go to is_right

    is_right:
        addi t3, zero, DIR_LEFT     ; t3 = left direction
        beq t1, t3, get_input_done  ; if current direction is left, ignore right button
        addi v0, zero, 4            ; set v0 to 4 to indicate right
        stw t2, GSA(zero)           ; update direction to right
        br get_input_done           ; skip other checks and end procedure

    none_pressed:
        addi v0, zero, 0            ; set v0 to 0 to indicate no button was pressed
        br get_input_done           ; end procedure

    get_input_done:
        ret
; END: get_input


; BEGIN:draw_array
; Arguments:
;     none
; Return values:
;     none, but updates the LEDs to reflect the current game state
; BEGIN: draw_array
draw_array:
    addi sp, sp, -4
    stw ra, 0(sp)       ; Save ra

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

        ; Calculate index in GSA as (i * NB_COLS + j)
        ; Since NB_COLS is 12, we use the approach: index = (i * 10 + i * 2) + j
        slli t4, t0, 1           ; t4 = i * 2
        add t5, t4, t0           ; t5 = i * 2 + i = i * 3
        slli t5, t5, 2           ; t5 = i * 3 * 4 = i * 12
        add t4, t5, t1           ; t4 = (i * 12) + j

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
    ldw ra, 0(sp)       ; Restore ra
    addi sp, sp, 4      ; Pop ra
    ret                 ; Return from the procedure
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
        beq zero, zero, update_snake_position
    move_left:
        addi t0, t0, -1       ; Move left
        beq zero, zero, update_snake_position
    move_up:
        addi t1, t1, -1       ; Move up
        beq zero, zero, update_snake_position
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
    addi sp, sp, -16            ; Push ra, t0, t1
    stw ra, 0(sp)               ; Save ra
    stw t0, 4(sp)               ; Save t0
    stw t1, 8(sp)               ; Save t1
    stw t2, 12(sp)              ; Save t2

    ldw t0, SEVEN_SEGS(zero)    ; Load the address of the 7-segment display
    addi t1, zero, 0            ; t1 = 0 (loop counter)   

    blink_loop:                     ; blinks 3 times
        addi t2, zero, 3            ; t2 = 3
        beq t1, t2, end_blink_score  ; If t1 is 3, end the loop
        call blink                  ; Blink the score once
        addi t1, t1, 1              ; Increment loop counter
        br blink_loop               ; Loop back to blink_loop

    blink:                      ; blinks once
        call turn_displays_off  ; Turn off all displays
        call wait               ; Wait for 1 second
        call turn_displays_on   ; Turn on all displays
        call wait               ; Wait for 1 second
        ret                     ; Return from the procedure
    
    turn_displays_off:
        stw zero, 0(t0)     ; Turn off the 1st display
        stw zero, 4(t0)     ; Turn off the 2nd display
        stw zero, 8(t0)     ; Turn off the 3rd display
        stw zero, 12(t0)    ; Turn off the 4th display

    turn_displays_on:
        call display_score  ; Display the score

    end_blink_score:
        ldw t2, 12(sp)      ; Restore t2
        ldw t1, 8(sp)       ; Restore t1
        ldw t0, 4(sp)       ; Restore t0
        ldw ra, 0(sp)        ; Restore ra
        addi sp, sp, 16     ; Pop ra, t0, t1

        ret                 ; Return from the procedure
; END: blink_score