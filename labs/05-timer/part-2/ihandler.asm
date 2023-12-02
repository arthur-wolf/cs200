.equ LEDS, 0x2000 		 ; LEDS address
.equ pulsewidth, 0x200C  ; Intensity of the LEDS
.equ TIMER, 0x2020 		 ; timer address
.equ edgecapture, 0x2034 ; Falling edge detection

_start:
	br main ; jump to the main function

interrupt_handler:

	addi sp, sp, -36 ; save the registers to the stack
	stw s0, 0(sp)
	stw s1, 4(sp)
	stw s2, 8(sp)
	stw s3, 12(sp)
	stw t0, 16(sp)
	stw t1, 24(sp)
	stw s4, 28(sp)
	stw ea, 32(sp)

	addi s0, zero, 1 ; set the timer interrupt bit
	rdctl s1, ctl4 	 ; read the cause register
	addi s2, zero, 3 ; set the buttons interrupt bit
	addi s3, zero, 2 ; set the buttons interrupt bit
	addi s4, zero, 4 ; set the buttons interrupt bit

;--------------- Checking interrupts ---------------

	check_timer_interrupt:
		
		and t0, s0, s1 				; check if the timer interrupt bit is set
		beq t0, s0, timer_interrupt ; if it is, jump to the timer interrupt

	check_buttons_interrupt:

		slli t0, s0, 2 				  ; shift the timer interrupt bit to the buttons interrupt bit
		and t1, t0, s1 				  ; check if the buttons interrupt bit is set
		beq t1, s4, buttons_interrupt ; if it is, jump to the buttons interrupt
		br finish 					  ; if it isn't, finish the interrupt

;--------------- Interrupts ---------------

	timer_interrupt:											

		ldw t0, LEDS+4(zero) ; load the LEDS address
		addi t0, t0, 1 		 ; increment the LEDS address
		stw t0, LEDS+4(zero) ; store the LEDS address
		
		stw zero, TIMER+12(zero)   ; reset the timer
		
		br check_buttons_interrupt ; go to check if the buttons interrupt is set

	buttons_interrupt:
		
		ldw t0, edgecapture(zero) ; load the edgecapture address
		
		and t1, s2, t0 					  ; check if both buttons are pressed
		beq t1, s2, both_buttons_pressed  ; if they are, jump to the both buttons pressed interrupt

		and t1, s0, t0 					  ; check if the first button is pressed
		beq t1, s0, first_button_pressed  ; if it is, jump to the first button pressed interrupt

		and t1, s3, t0					  ; check if the second button is pressed
		beq t1, s3, second_button_pressed ; if it is, jump to the second button pressed interrupt

		br finish_buttons_interrupt		  ; if none of the buttons are pressed, finish the interrupt
		
		both_buttons_pressed:
			br finish_buttons_interrupt ; if both buttons are pressed, finish the interrupt
	
		first_button_pressed:
			ldw t0, LEDS(zero) 			; load the LEDS address
			addi t0, t0, -1   			; decrement the LEDS address
			stw t0, LEDS(zero) 			; store the LEDS address
			br finish_buttons_interrupt ; finish the interrupt

		second_button_pressed:
			ldw t0, LEDS(zero) 			; load the LEDS address
			addi t0, t0, 1 	   			; increment the LEDS address
			stw t0, LEDS(zero) 			; store the LEDS address
			br finish_buttons_interrupt ; finish the interrupt

		finish_buttons_interrupt:
			stw zero, edgecapture(zero) ; reset the edgecapture register
			br finish 					; finish the interrupt

;--------------- Finish ---------------

	finish:
		ldw s0, 0(sp)
		ldw s1, 4(sp)
		ldw s2, 8(sp)
		ldw s3, 12(sp)
		ldw t0, 16(sp)
		ldw t1, 24(sp)
		ldw s4, 28(sp)
		ldw ea, 32(sp)
		addi sp, sp, 36 ; restore the registers from the stack

		addi ea, ea, -4 ; correct the exception return address
		eret 			;return from exception

main:

	addi s0, zero, 11 		; set the pulsewidth to 11
	addi s1, zero, 0xFF 	; set the pulsewidth to 0xFF
	addi s2, zero, 0x2000 	; set the LEDS address
	addi s3, zero, 999  	; set the timer to 999
	addi s4, zero, 1 		; set the timer interrupt bit

	add sp, zero, s2 ; set the stack pointer to the LEDS address

	addi t0, zero, 5 ; set the timer to 5
	wrctl ctl3, t0 	 ; interrupt enable
	wrctl ctl0, s4 	 ; PIE

	stw zero, LEDS(zero) 	 ; set the LEDS to zero
	stw zero, LEDS+4(zero) 	 ; set the LEDS to zero
	stw zero, LEDS+8(zero) 	 ; set the LEDS to zero
	stw s1, pulsewidth(zero) ; set brightness

	stw s3, TIMER+4(zero)		; set the timer
	stw s0, TIMER+8(zero)		; set the timer

	loop:
		ldw t0, LEDS+8(zero) ; load the LEDS address
		addi t0, t0, 1 		 ; increment the LEDS address
		stw t0, LEDS+8(zero) ; store the LEDS address
		br loop 			 ; loop