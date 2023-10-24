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
    ; Call clear_leds to initialize the display
    call clear_leds

    ; Call set_pixel with different parameters to turn on some pixels

    ; Turn on pixel at (2, 3)
    li a0, 2          ; x-coordinate
    li a1, 3          ; y-coordinate
    call set_pixel

    ; Turn on pixel at (5, 5)
    li a0, 5          ; x-coordinate
    li a1, 5          ; y-coordinate
    call set_pixel

    ; Turn on pixel at (7, 2)
    li a0, 7          ; x-coordinate
    li a1, 2          ; y-coordinate
    call set_pixel

    ; ... Add more calls to set_pixel as needed ...

    ; End of main procedure
    ret
; END:main

; Arguments:
;     none
; Return values:
;     none
; BEGIN: clear_leds
clear_leds:
    ; Set all three 32-bit words in the LED array to 0
    li t0, 0          ; Load immediate value 0 into temporary register t0

    stw t0, LEDS(0)   ; Store 0 to LEDS[0]
    stw t0, LEDS(4)   ; Store 0 to LEDS[1]
    stw t0, LEDS(8)   ; Store 0 to LEDS[2]

    ret
; END: clear_leds

; Arguments:
;     a0: x-coordinate
;     a1: y-coordinate
; Return values:
;     none
; BEGIN: set_pixel
set_pixel:
    ; Calculate the LED index based on x and y coordinates
    ; index = y * 12 + x
    mul a2, a1, #12   ; a2 = y * 12
    add a2, a2, a0    ; a2 = y * 12 + x

    ; Determine which 32-bit word the pixel belongs to
    div a3, a2, #32   ; a3 = index / 32 (word index)
    rem a4, a2, #32   ; a4 = index % 32 (bit position in the word)

    ; Load the current value of the word
    ldw t0, LEDS(a3)  ; t0 = LEDS[word index]

    ; Set the bit corresponding to the pixel
    li t1, 1          ; t1 = 1
    sll t1, t1, a4    ; shift left to set the bit at position a4
    or t0, t0, t1     ; set the bit in t0

    ; Store the updated value back to memory
    stw t0, LEDS(a3)

    ret
; END: set_pixel

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


; BEGIN: get_input
get_input:

; END: get_input


; BEGIN: draw_array
draw_array:

; END: draw_array


; BEGIN: move_snake
move_snake:

; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:

; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:

; END: restore_checkpoint


; BEGIN: blink_score
blink_score:

; END: blink_score
