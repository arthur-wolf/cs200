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
addi sp, zero, LEDS
addi t0, zero, 0xff
stw t0, LEDS+12(zero)


; BEGIN:main
main:
	; checkpoint initialization
	stw zero, CP_VALID(zero)
    
	m_init_game:
    	call init_game

	m_game_loop:
		call wait
    	call get_input

		addi t0, zero, 5
		beq v0, t0, m_game_restore

	m_game_continue:
		call hit_test
    	addi t0, zero, 1
		beq v0, t0, m_game_increment_score
		addi t0, zero, 2
		beq v0, t0, m_init_game;

		addi a0, zero, 0
		call move_snake

	m_clear_and_draw:
		call clear_leds
		call draw_array
    
		br m_game_loop

	m_game_increment_score:
		ldw t0, SCORE(zero)
		addi t0, t0, 1
		stw t0, SCORE(zero)

		call display_score

		addi a0, zero, 1
		call move_snake

		call create_food

		call save_checkpoint

		addi t0, zero, 0
		beq v0, t0, m_clear_and_draw
		addi t0, zero, 1
		beq v0, t0, m_blink

	m_blink:
		call blink_score
		br m_clear_and_draw
	

	m_game_restore:
		call restore_checkpoint

		beq v0, zero, m_game_loop
		call clear_leds
		call draw_array
		addi t0, zero, 1
		beq v0, t0, m_blink

; END:main


; BEGIN:clear_leds
clear_leds:
    stw zero, LEDS(zero)        ; Store 0 to LEDS(0)
    stw zero, LEDS+4(zero)      ; Store 0 to LEDS(1)          
    stw zero, LEDS+8(zero)      ; Store 0 to LEDS(2)
    ret                         ; Return
; END:clear_leds


; BEGIN:set_pixel
set_pixel:
addi sp, sp, -20
stw s0, 0(sp)
stw s1, 4(sp)
stw s2, 8(sp)
stw s3, 12(sp)
stw s4, 16(sp)

andi s1, a0, 12     ; s1 = le nombre du LED (0, 4 ou 8)
slli s0, a0, 3      ; s0 = 8*x
andi s2, s0, 31     ; mask les 5 derniers bits => (8*x) % 32
add s2, s2, a1      ; bit = ((8*x)%32) + y 

addi s3, zero, 1
sll s3, s3, s2      ; s3 = s3 << s2
ldw s4, LEDS(s1)    ; load the led
or s3, s4, s3       ; s3 = s3 || s4
stw s3, LEDS(s1)

ldw s4, 16(sp)
ldw s3, 12(sp)
ldw s2, 8(sp)
ldw s1, 4(sp)
ldw s0, 0(sp)
addi sp, sp, 20
ret
; END:set_pixel


; BEGIN:wait
wait:              
    addi t0, zero, 1
	slli t0, t0, 21

    wait_loop:
        addi t0, t0, -1             ; t1--
        bne t0, zero, wait_loop 
    ; waits approx. 0.5 seconds
    ret
; END:wait


; BEGIN:display_score
display_score:
    addi sp, sp, -4      ; Push ra
    stw ra, 0(sp)       ; Save ra

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

    end_display_score:
        ldw ra, 0(sp)       ; Restore ra
        addi sp, sp, 4     ; Pop registers

        ret
; END:display_score


; BEGIN:init_game
init_game:
    addi sp, sp, -4
    stw ra, 0(sp)       ; Save ra

    clean_up:
        ; Clear the game state array
        addi t0, zero, 0
        addi t1, zero, 4
        addi t2, zero, NB_CELLS
        clean_up_loop:
            beq t0, t2, end_clean_up
            stw zero, GSA(t1)
            addi t0, t0, 1
            addi t1, t1, 4
            br clean_up_loop
        end_clean_up:

    ; Initialize the snake's position at the upper left corner (0, 0)
    addi t0, zero, 0  ; Set head x-coordinate to 0
    addi t1, zero, 0  ; Set head y-coordinate to 0
    stw t0, HEAD_X(zero)
    stw t1, HEAD_Y(zero)
    stw t0, TAIL_X(zero)
    stw t1, TAIL_Y(zero)

    ; Set snake's initial direction to rightwards
    addi t0, zero, DIR_RIGHT
    stw t0, GSA(zero)  ; Store direction in the first cell of GSA since it's the head's position

    ; Make a piece of food appear on the display
    call create_food

    ; Initialize score to 0
    addi t0, zero, 0
    stw t0, SCORE(zero)

    call display_score

    ; Clear the display
    call clear_leds

    ; Draw the initial game state
    call draw_array

    end_init_game:
        ldw ra, 0(sp)       ; Restore ra
        addi sp, sp, 4     ; Pop registers

        ret  ; Return from init_game
; END:init_game


; BEGIN:create_food
create_food:
    addi sp, sp, -4
    stw ra, 0(sp)       ; Save ra

	addi t3, zero, NB_CELLS
    
    get_random_index:
        ; Load a random number
        ldw t0, RANDOM_NUM(zero) 

        ; Extract the lowest byte to use as the index in GSA
        slli t1, t0, 24       ; Shift left by 24 bits, moving the lowest byte to the highest
        srli t1, t1, 24       ; Shift right by 24 bits, moving the byte back to its original position

        ; Check if the index is within the bounds of the game state array
        bge t1, t3, get_random_index    ; If t1 >= NB_CELLS, get a new random number
        slli t2, t1, 2                  ; t2 = t1 * 4 (shift left by 2 bits to get the correct word offset)
        ldw t4, GSA(t2)                 ; Load the value at the calculated index
        beq t4, zero, valid_index       ; If the cell is empty, go to valid_index
        br get_random_index             ; Otherwise, get a new random number

    valid_index:
        ; Store the food location in the game state array (GSA)
        addi t4, zero, FOOD  ; t2 = FOOD
        stw t4, GSA(t2)      ; Place food in GSA at the calculated index
        br end_create_food

    end_create_food:
    ldw ra, 0(sp)       ; Restore ra
    addi sp, sp, 4     ; Pop registers

    ret  ; Return from create_food
; END:create_food


; BEGIN:hit_test
hit_test:
    addi sp, sp, -4        ; Push registers onto stack
    stw ra, 0(sp)           ; Save ra

    addi v0, zero, 0        ; v0 = 0 (default return value)

    ; Load the current direction and head position
    ldw t0, HEAD_X(zero)  ; Load head's x-coordinate
    ldw t1, HEAD_Y(zero)  ; Load head's y-coordinate
	
	slli t3, t0, 3
    add t3, t3, t1           ; t3 = t3 + x (index in GSA)
	slli t3, t3, 2
    ldw t2, GSA(t3)       ; Load current direction from GSA

    ; Calculate the next position of the head based on the direction
    addi t3, zero, DIR_LEFT
    beq t2, t3, test_left
    addi t3, zero, DIR_UP
    beq t2, t3, test_up
    addi t3, zero, DIR_DOWN
    beq t2, t3, test_down
    addi t3, zero, DIR_RIGHT
    beq t2, t3, test_right

    test_left:
        addi t0, t0, -1  ; Move left
        br check_collision

    test_up:
        addi t1, t1, -1  ; Move up
        br check_collision

    test_down:
        addi t1, t1, 1   ; Move down
        br check_collision

    test_right:
        addi t0, t0, 1   ; Move right
        br check_collision

    check_collision:
        ; Check for screen boundary collision
        blt t0, zero, end_game      ; x-coordinate out of bounds
        blt t1, zero, end_game      ; y-coordinate out of bounds
        addi t5, zero, 12           ; t5 = 12
        bge t0, t5, end_game        ; NB_COLS = 12
        addi t6, zero, 8            ; t6 = 8
        bge t1, t6, end_game        ; NB_ROWS = 8

    compute_next_cell:
		addi t3, zero, 0
		slli t3, t0, 3
        add t3, t3, t1           ; t3 = t3 + x (index in GSA)
		slli t3, t3, 2

    ; Check for collision with food or body
    ldw t4, GSA(t3)      ; Load content at next position
    addi t5, zero, FOOD  ; t5 = FOOD
    beq t4, t5, eat_food  ; FOOD = 5
    bne t4, zero, end_game  ; Non-zero and not food implies body collision

    ; No collision
    addi v0, zero, 0
    br exit_hit_test

    eat_food:
        addi v0, zero, 1  ; Collision with food
        br exit_hit_test

    end_game:
        addi v0, zero, 2  ; Collision with boundary or body
        br exit_hit_test

exit_hit_test:
    ldw ra, 0(sp)       ; Restore ra
    addi sp, sp, 4     ; Pop registers

    ret
; END:hit_test


; BEGIN:get_input
get_input:
    addi sp, sp, -4
    stw ra, 0(sp)       ; Save ra

    addi v0, zero, 0            ; v0 = 0 (default return value)
    
    ; Read the edgecapture register to find out which buttons were pressed
    ldw t0, BUTTONS+4(zero)     ; t0 = edgecapture value
    ; Clear the edgecapture register by writing back its value
    stw zero, BUTTONS+4(zero)     ; Clear edgecapture

    ; Check each direction button and update the game state accordingly
    ; Make sure not to change direction if it's the opposite of the current movement
    ; The direction is stored in the first cell of the GSA

    ; Load current direction
	ldw t2, HEAD_X(zero)
	ldw t1, HEAD_Y(zero)
	slli t3, t2, 3
    add t3, t3, t1           ; t3 = t3 + x (index in GSA)
	slli t7, t3, 2
    ldw t1, GSA(t7)           ; t1 = current direction

    check_checkpoint:
        ; Check for checkpoint button press, i.e. is the 4th bit set?
        addi t2, zero, 16           ; t2 = 0b00010000
        and t2, t0, t2              ; t2 = t0 & t2 (is the 4th bit set?)
        ; at this point if t2 is 0, then checkpoint button is not pressed
        beq t2, zero, check_left    ; if t2 is 0, go to check left button
        br is_checkpoint            ; if t2 is not 0, go to is_checkpoint 

    is_checkpoint:
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
        addi v0, zero, 1            ; set v0 to 1 to indicate left
		stw v0, GSA(t7)           ; update direction to left
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
		addi v0, zero, 2            ; set v0 to 2 to indicate up
        stw v0, GSA(t7)           ; update direction to up
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
		addi v0, zero, 3            ; set v0 to 3 to indicate down
        stw v0, GSA(t7)           ; update direction to down
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
        stw v0, GSA(t7)           ; update direction to right
        br get_input_done           ; skip other checks and end procedure

    none_pressed:
        addi v0, zero, 0            ; set v0 to 0 to indicate no button was pressed
        br get_input_done           ; end procedure

    get_input_done:
        ldw ra, 0(sp)       ; Restore ra
        addi sp, sp, 4     ; Pop registers

        ret
; END:get_input


; BEGIN:draw_array
draw_array:
    addi sp, sp, -4     ; Push ra
    stw ra, 0(sp)       ; Save ra


    addi t0, zero, 0            ; t0 = 0 (counter for cells) -> t0 is the cell number
    addi t1, zero, 0            ; t1 = 0 (index in GSA) -> t1 is the index of the cell in GSA
    addi t2, zero, NB_CELLS     ; t2 = NB_CELLS

    loop_array:
        beq t0, t2, end_draw_array  ; If counter equals NB_CELLS, end the loop
        ldw t3, GSA(t1)             ; Load the value at the calculated index
        beq t3, zero, next_pixel    ; If the cell is empty, skip drawing
        br draw_pixel               ; Otherwise, draw the pixel

    draw_pixel:
        srli a0, t0, 3              ; a0 = t0 / 8 (find the LED array index) -> a0 = x coordinate
        andi a1, t0, 0x7            ; a1 = t0 & 7 (bit position in the register) -> a1 = y coordinate
        call set_pixel              ; Set the pixel at the calculated coordinates
        br next_pixel               ; Continue to the next pixel

    next_pixel:
        addi t0, t0, 1              ; Increment counter for cells
        addi t1, t1, 4              ; Increment counter for GSA
        br loop_array               ; Loop back to loop_array

    end_draw_array:
        ldw ra, 0(sp)       ; Restore ra
        addi sp, sp, 4     ; Pop registers

        ret    
; END:draw_array


; BEGIN:move_snake
move_snake:
    addi sp, sp, -4     ; Push ra
    stw ra, 0(sp)       ; Save ra

    head:
        ldw t0, HEAD_X(zero)  ; Load head's x-coordinate
        ldw t1, HEAD_Y(zero)  ; Load head's y-coordinate

        slli t2, t0, 3
        add t2, t2, t1        ; t2 = y * 12 + x (index in GSA) -> t2 is the index of the head in the GSA
        slli t2, t2, 2        ; t2 = t2 * 4 (shift left by 2 bits to get the correct word offset)

        ldw t3, GSA(t2)       ; Load current head direction from GSA

        addi t4, zero, DIR_LEFT
        beq t3, t4, move_head_left

        addi t4, zero, DIR_UP
        beq t3, t4, move_head_up

        addi t4, zero, DIR_DOWN
        beq t3, t4, move_head_down

        addi t4, zero, DIR_RIGHT
        beq t3, t4, move_head_right

    move_head_left:
        addi t0, t0, -1         ; Move x-coordinate left by 1
        stw t0, HEAD_X(zero)    ; Store the new head x-coordinate
        addi t2, t2, -32        ; Move GSA index left by 1
        stw t3, GSA(t2)         ; Update direction in GSA
        br tail
    
    move_head_up:
        addi t1, t1, -1         ; Move y-coordinate up by 1
        stw t1, HEAD_Y(zero)    ; Store the new head y-coordinate
        addi t2, t2, -4         ; Move GSA index up by 1
        stw t3, GSA(t2)         ; Update direction in GSA
        br tail

    move_head_down:
        addi t1, t1, 1         ; Add one to y-coordinate
        stw t1, HEAD_Y(zero)   ; Store the new head y-coordinate
        addi t2, t2, 4         ; Move GSA index down by 1
        stw t3, GSA(t2)        ; Update direction in GSA
        br tail
    
    move_head_right:
        addi t0, t0, 1          ; Move x-coordinate right by 1
        stw t0, HEAD_X(zero)    ; Store the new head x-coordinate
        addi t2, t2, 32         ; Move GSA index right by 1
        stw t3, GSA(t2)         ; Update direction in GSA
        br tail

    tail:
        bne a0, zero, end_move_snake    ; If there is food, i.e. a0 = 1, the tail doesn't move
                                        ; Else, we need to move the tail:

        ldw t0, TAIL_X(zero)  ; Load tail's x-coordinate
        ldw t1, TAIL_Y(zero)  ; Load tail's y-coordinate

        slli t2, t0, 3
        add t2, t2, t1        ; t2 = y * 12 + x (index in GSA) -> t2 is the index of the head in the GSA
        slli t2, t2, 2        ; t2 = t2 * 4 (shift left by 2 bits to get the correct word offset)

        ldw t3, GSA(t2)       ; Load current tail direction from GSA

        addi t4, zero, DIR_LEFT         ; DIR_LEFT = 1
        beq t3, t4, move_tail_left

        addi t4, zero, DIR_UP           ; DIR_UP = 2
        beq t3, t4, move_tail_up

        addi t4, zero, DIR_DOWN         ; DIR_DOWN = 3
        beq t3, t4, move_tail_down

        addi t4, zero, DIR_RIGHT        ; DIR_RIGHT = 4
        beq t3, t4, move_tail_right

    move_tail_left:
        stw zero, GSA(t2)       ; Clear the cell in GSA
        addi t0, t0, -1         ; Move x-coordinate left by 1
        stw t0, TAIL_X(zero)    ; Store
        br end_move_snake

    move_tail_up:
        stw zero, GSA(t2)       ; Clear the cell in GSA
        addi t1, t1, -1         ; Move y-coordinate up by 1
        stw t1, TAIL_Y(zero)    ; Store
        br end_move_snake

    move_tail_down:
        stw zero, GSA(t2)       ; Clear the cell in GSA
        addi t1, t1, 1          ; Move y-coordinate down by 1
        stw t1, TAIL_Y(zero)    ; Store
        br end_move_snake
    
    move_tail_right:
        stw zero, GSA(t2)       ; Clear the cell in GSA
        addi t0, t0, 1         ; Move x-coordinate right by 1
        stw t0, TAIL_X(zero)    ; Store
        br end_move_snake    

    end_move_snake:
        ldw ra, 0(sp)       ; Restore ra
        addi sp, sp, 4     ; Pop registers

        ret
; END:move_snake


; BEGIN:save_checkpoint
save_checkpoint:
    ldw t0, SCORE(zero) ; Load the score into register t0
    addi t1, zero, 10   ; t1 = minimum checkpoint score

    checkpoint_mod:
        blt t0, t1, checkpoint_check ; If score < 10, don't save checkpoint
        addi t0, t0, -10             ; Subtract 10 from score
        br checkpoint_mod            ; Loop back until score < 10

    checkpoint_check:  
        ldw t3, SCORE(zero)               ; Load the score into register t3
        beq t3, zero, checkpoint_no_save  ; If score is 0, don't save checkpoint
        beq t0, zero, checkpoint_save     ; If score is a multiple of 10, save checkpoint
        br checkpoint_no_save             ; Otherwise, don't save checkpoint

    checkpoint_save:
        addi t4, zero, 1        ; t4 = 1 (save checkpoint)
        stw t4, CP_VALID(zero)  ; Store 1 in CP_VALID to indicate that a checkpoint is saved

        ldw t3, HEAD_X(zero)    ; Load head's x-coordinate
        stw t3, CP_HEAD_X(zero) ; Store the new head x-coordinate
        ldw t3, HEAD_Y(zero)    ; Load head's y-coordinate
        stw t3, CP_HEAD_Y(zero) ; Store the new head y-coordinate

        ldw t3, TAIL_X(zero)    ; Load tail's x-coordinate
        stw t3, CP_TAIL_X(zero) ; Store the new tail x-coordinate
        ldw t3, TAIL_Y(zero)    ; Load tail's y-coordinate
        stw t3, CP_TAIL_Y(zero) ; Store the new tail y-coordinate

        ldw t3, SCORE(zero)     ; Load the score into register t3
        stw t3, CP_SCORE(zero)  ; Store the score

        addi t0, zero, 0        ; t0 = 0 (counter for cells) -> t0 is the cell number
        addi t1, zero, 0        ; t1 = 0 (counter for GSA index)
        addi t2, zero, NB_CELLS ; t2 = NB_CELLS

    checkpoint_gsa:
        ldw t3, GSA(t0)             ; Load the value at the GSA index
        stw t3, CP_GSA(t0)          ; Store the value in the checkpoint GSA
        addi t0, t0, 4              ; Increment counter for cells
        addi t1, t1, 1              ; Increment counter for GSA index
        blt t1, t2, checkpoint_gsa  ; while counter < NB_CELLS, loop back to checkpoint_gsa

        addi v0, zero, 1    ; v0 = 1 (checkpoint saved)
        ret

    checkpoint_no_save:
        addi v0, zero, 0    ; v0 = 0 (no checkpoint saved)
        ret
; END:save_checkpoint


; BEGIN:restore_checkpoint
restore_checkpoint:
        addi t0, zero, 1                ; t0 = 1 (restore checkpoint)
        ldw t1, CP_VALID(zero)          ; Load the value at CP_VALID
        beq t1, t0, restore_valid       ; If CP_VALID is 1, restore checkpoint
        beq t1, zero, restore_invalid   ; If CP_VALID is 0, don't restore checkpoint

    restore_valid:
        ldw t3, CP_HEAD_X(zero)     ; Load head's x-coordinate
        stw t3, HEAD_X(zero)        ; Store the saved head x-coordinate
        ldw t3, CP_HEAD_Y(zero)     ; Load head's y-coordinate
        stw t3, HEAD_Y(zero)        ; Store the saved head y-coordinate
        
        ldw t3, CP_TAIL_X(zero)     ; Load tail's x-coordinate
        stw t3, TAIL_X(zero)        ; Store the saved tail x-coordinate
        ldw t3, CP_TAIL_Y(zero)     ; Load tail's y-coordinate
        stw t3, TAIL_Y(zero)        ; Store the saved tail y-coordinate

        ldw t3, CP_SCORE(zero)      ; Load the score into register t3
        stw t3, SCORE(zero)         ; Store the score

        addi t0, zero, 0            ; t0 = 0 (counter for cells) -> t0 is the cell number
        addi t1, zero, 0            ; t1 = 0 (counter for GSA index)
        addi t2, zero, NB_CELLS     ; t2 = NB_CELLS
    restore_gsa:
        ldw t3, CP_GSA(t0)      ; Load the value at the checkpoint GSA index
        stw t3, GSA(t0)         ; Store the value in the GSA
        addi t0, t0, 4          ; Increment counter for cells
        addi t1, t1, 1          ; Increment counter for GSA index
        blt t1, t2, restore_gsa ; while counter < NB_CELLS, loop back to restore_gsa

        addi v0, zero, 1    ; v0 = 1 (checkpoint restored)
        ret

    restore_invalid:
        addi v0, zero, 0    ; v0 = 0 (no checkpoint restored)
        ret
; END:restore_checkpoint


; BEGIN:blink_score
blink_score:
	addi sp, sp, -4
	stw ra, 0(sp)

	addi t7, zero, 3

	blink_loop:
        beq t7, zero, blink_score_end

        ; clear the score
        stw zero, SEVEN_SEGS(zero)
        stw zero, SEVEN_SEGS+4(zero)
        stw zero, SEVEN_SEGS+8(zero)
        stw zero, SEVEN_SEGS+12(zero)

        call wait

        call display_score

        call wait

        addi t7, t7, -1
        br blink_loop

	blink_score_end:
        ldw ra, 0(sp)
        addi sp, sp, 4

        ret
; END:blink_score

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