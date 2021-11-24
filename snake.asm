;    set game state memory location
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

main:
	stw zero, CP_VALID(zero)

	main_nocp:
		call init_game

		game_cycle:
			wait_game_main:
					addi t1, zero, 0x0FFF
					slli t1, t1, 8 ;made it slower.
					addi t1, t1, 0x0FFF
					loop_game_main:
						addi t1, t1, -1 ;1 cc
						bne  t1, zero, loop_game_main
	
			call get_input

			addi t1, zero, BUTTON_CHECKPOINT 
			bne v0, t1, no_checkpoint

			call restore_checkpoint ; Is cp saved the same as cp valid ? I think so.
			beq v0, zero, no_checkpoint ; if no checkpoint available

			call clear_leds
			call draw_array

			call blink_score
			br end_cycle

			no_checkpoint:
				call hit_test

				addi t1, zero, RET_ATE_FOOD
				beq v0, t1, food_eaten			
				
				wait_game_main_nocp: ;added this one for some more latency after a loss.
					addi t1, zero, 0x0FFF
					slli t1, t1, 8 ;made it slower.
					addi t1, t1, 0x0FFF
					loop_game_main_no_cp:
						addi t1, t1, -1 ;1 cc
						bne  t1, zero, loop_game_main_no_cp

				addi t1, zero, RET_COLLISION
				beq v0, t1, main_nocp 

				addi a0, zero, ARG_HUNGRY
				call move_snake
				br end_cycle

			food_eaten: 
				ldw t1, SCORE(zero)
				addi t1, t1, 1
				stw t1, SCORE(zero)
				call display_score	

				addi a0, zero, ARG_FED
				call move_snake
				call create_food

				call save_checkpoint

				beq v0, zero, end_cycle

				call blink_score

				br end_cycle

			end_cycle:
				add a0, zero, zero
				add a1, zero, zero

				call clear_leds
				call draw_array
			
				br game_cycle


wait:
	addi t1, zero, 0x61A8 ;25000 in decimal, should make each iteration of the game last 0.5 secs.
	loop:
		addi t1, t1, -1
		bne  t1, zero, loop
	
		ret
; BEGIN: clear_leds
clear_leds:	
	addi t1, zero, 0
	stw zero, LEDS(t1) ; store zero in LEDS[0]

	addi t1, zero, 4
	stw zero, LEDS(t1) ; store zero in LEDS[1]

	addi t1, zero, 8
	stw zero, LEDS(t1) ; store zero in LEDS[2]

	ret
; END: clear_leds


; BEGIN: set_pixel
set_pixel:
	; register a0 : the pixel s x-coordinate
	; register a1 : the pixel s y-coordinate

	; LEDS[0]_x : (0, 1,  2,  3) = (0000, 0001, 0010, 0011)
	; LEDS[1]_x : (4, 5,  6,  7) = (0100, 0101, 0110, 0111)
	; LEDS[2]_x : (8, 9, 10, 11) = (1000, 1001, 1010, 1011)

	; LEDS[i]_x determined by the 4 bits this way :
	; 
	; 1xxx => i = 2
	; 01xx => i = 1
	; 00xx => i = 0
	;
	; t2 := x(3) or x(2)
	; 
	;
	; => i = 0 add t2
	;    i = i << x(3)
	;
	; t1 := i
	; 
	; 0  : 00000   (0 : 0000, 4 : 0100,  8 : 1000)
	; 8  : 01000   (1 : 0001, 5 : 0101,  9 : 1001) 
	; 16 : 10000   (2 : 0010, 6 : 0110, 10 : 1010)
	; 24 : 11000   (3 : 0011, 7 : 0111, 11 : 1011)
	;
	; In word index :
	;   n = x(1 downto 0) && "000" + y
	;
	; t2 := n
	;
	; Procedure goal :
	;   LEDS[i][n] = '1'
	; 
	; (needs to be checked : little endian definition)
	; 1 bit activator mask : m = 1 << n
	; 
	; => LEDS[i][n] = '1' <=> LEDS[i] = LEDS[i] or m

	addi t3, zero, 1

	slli t4, t3, 3   ; mask for x(3)
	and t4, t4, a0   ; get x(3) << 3
	srli t4, t4, 3   ; x(3)

	slli t5, t3, 2   ; mask for x(2)
	and t6, t5, a0   ; get x(2) << 2
	srli t6, t6, 2   ; x(2)

	or t2, t4, t6    ; x(3) or x(2)

	add t1, zero, t2
	sll t1, t1, t4     ; i << x(3) ; t1 := i index in the LEDS array

	addi t3, zero, 3   ; two LSBs active
	and t4, t3, a0     ; x(1 downto 0)
	slli t4, t4, 3     ; x(1 downto 0) & "000"
	add t4, t4, a1     ; x(1 downto 0) & "000" + y ; t4 := n

	; get LEDS[i]
	; set LEDS[i][n]

	addi t3, zero, 1
	sll t3, t3, t4     ; t3 := m

	slli t1, t1, 2 ; i = i * 4 ; because we use words

	ldw t5, LEDS(t1)
	or t5, t5, t3    ; set bit to 1
	stw t5, LEDS(t1)

	ret

; END: set_pixel


; BEGIN: display_score
display_score:
	; Constants:	
	; - SEVEN_SEGS
	; - SCORE
	
	; -score
	ldw t1, SCORE(zero)
	
	; t1 is in binary


	; display zeros on first two segment displays
	ldw t4, digit_map(zero)
	stw t4, SEVEN_SEGS(zero)

	addi t6, zero, 4 ; 1 * 4 (because of word indexing)
	stw t4, SEVEN_SEGS(t6)
	; ...

	add t3, zero, zero
	addi t6, zero, 9

	get_mod10_loop:
		sub t7, t1, t3 ; full nbr - mod to check
		addi t2, zero, 1 ; boolean variable (1 = not ok, 0 = ok)
		addi t5, zero, 10 ; constant 10
		addi t4, zero, 100 ; start value
		get_mod10_loop_check:
			sub t4, t4, t5 ; change comparator
			beq t7, t4, success_check ; if a multiple of 10 has been reached
			beq t4, zero, end_loop_check
			br get_mod10_loop_check
		success_check:
		add t2, zero, zero ; success (mod ok)
		end_loop_check:
		beq t2, zero, second_digit ; if is mod10

		addi t3, t3, 1 ; increment the tested number
		beq t3, t6, second_digit ; must be the mod since all other possibilities have been tested
		br get_mod10_loop


	second_digit:
		add t7, zero, t3
		addi t6, zero, 3 ; show on the right most display
		
		addi sp, sp, -4
		stw ra, 0(sp)
		
		call show
		
		ldw ra, 0(sp)
		addi sp, sp, 4
	
		sub t5, t1, t3 ; score minus last digit (equiv. to score modulo 10)
		
	divide_t5_by_ten:
		addi t6, zero, 10
		add t7, zero, zero

		beq t5, t7, when_0
		add t7, t7, t6
		beq t5, t7, when_10
		add t7, t7, t6
		beq t5, t7, when_20
		add t7, t7, t6
		beq t5, t7, when_30
		add t7, t7, t6
		beq t5, t7, when_40
		add t7, t7, t6
		beq t5, t7, when_50
		add t7, t7, t6
		beq t5, t7, when_60
		add t7, t7, t6
		beq t5, t7, when_70
		add t7, t7, t6
		beq t5, t7, when_80
		add t7, t7, t6
		beq t5, t7, when_90

		when_0:
			addi t5, zero, 0
			br end_divide
		when_10:
			addi t5, zero, 1
			br end_divide
		when_20:
			addi t5, zero, 2
			br end_divide
		when_30:
			addi t5, zero, 3
			br end_divide
		when_40:
			addi t5, zero, 4
			br end_divide
		when_50:
			addi t5, zero, 5
			br end_divide
		when_60:
			addi t5, zero, 6
			br end_divide
		when_70:
			addi t5, zero, 7
			br end_divide
		when_80:
			addi t5, zero, 8
			br end_divide
		when_90:	
			addi t5, zero, 9
			br end_divide

	end_divide:
		add t7, zero, t5
		addi t6, zero, 2 ; show on second display
		
		addi sp, sp, -4
		stw ra, 0(sp)
		
		call show
		
		ldw ra, 0(sp)
		addi sp, sp, 4
		
		ret

	show: ; show t7 in SEVEN_SEGS(t6)
		slli t7, t7, 2
		ldw t4, digit_map(t7)
		slli t6, t6, 2
		stw t4, SEVEN_SEGS(t6)
		ret

; END: display_score


; BEGIN: init_game
init_game:
	; The initial state of the game is defined by the snake of length one, appearing at the top left corner
    ; of the LED screen and moving towards right, while the food is appearing at a random location, and
    ; the score is all zeros.

	stw zero, HEAD_X(zero)
	stw zero, HEAD_Y(zero)

	stw zero, TAIL_X(zero)
	stw zero, TAIL_Y(zero)

	stw zero, SCORE(zero)

	; clear GSA
  
	add t1, zero, zero
	addi t2, zero, 384 ; 96*4
	loop_init_clear_GSA:
		addi t3, t1, GSA
		stw zero, 0(t3)
		addi t1, t1, 4
		bne t1, t2, loop_init_clear_GSA

	; 4 for going right
	addi t1, zero, DIR_RIGHT
	stw t1, GSA(zero)

	addi sp, sp, -4
	stw ra, 0(sp)

	call create_food
	call clear_leds
	call draw_array
	call display_score

	ldw ra, 0(sp)
	addi sp, sp, 4

	ret

; END: init_game


; BEGIN: create_food
create_food:
	; In this section you will write procedure create_food, which creates a new food item at a random location on the screen.
	; The food size is always one (a single LED pixel), while its location must not overlap
	; with the snake. You can differentiate between a snake and the food easily: GSA element representing
	; the food has the value 5, while the GSA elements representing the snake have values 1-4. To display the
	; food, draw_array can be used

	until_valid:
		; 0 : empty
		; 1-4 : snake
		; 5 : food

		ldw t1, RANDOM_NUM(zero)
		addi t2, zero, 0xFF ; mask to get the first byte

		and t4, t1, t2 ; get the first byte

		; drawn food must be with index between 0 and 96 (excluded)

		blt t4, zero, until_valid ; index < 0

		addi t6, zero, NB_CELLS

		bge t4, t6, until_valid ; index >= 96

		slli t4, t4, 2 ; * 4 since we will use words

		; end test for boundaries

		; check if empty spot

		ldw t5, GSA(t4)

		bne t5, zero, until_valid ; if not empty

		; end test for empty spot
		
		addi t5, zero, FOOD

		stw t5, GSA(t4)

		ret


; END: create_food


; BEGIN: hit_test
hit_test:
	; v0 : 1 for score increment, 2 for the game end, and 0 when no collision.

	add v0, zero, zero ; initialize with a value: always a good thing to do

	; in v0 after call to get_input
	; 1 leftwards    0001
	; 2 upwards      0010
	; 3 downwards    0011
	; 4 rightwards   0100

	ldw t5, HEAD_X(zero) ; t5 = x
	slli t6, t5, 3 ; t6 = x * 8
		
	ldw t7, HEAD_Y(zero) ; t7 = y
	add t6, t6, t7 ; t6 = t6 + y = x * 8 + y

	slli t6, t6, 2 ; we multiply by 4 because we use words
	ldw t6, GSA(t6) ; we get the head vector direction

	addi t3, zero, DIR_LEFT ;t3 is the comparator
	beq t6, t3, left

	addi t3, zero, DIR_UP 
	beq t6, t3, up

	addi t3, zero, DIR_DOWN
	beq t6, t3, down

	br right

	left:
		addi t1, zero, -1
		addi t2, zero, 0 
		br conclude
	up:
		addi t1, zero, 0
		addi t2, zero, -1 
		br conclude
		
	down:
		addi t1, zero, 0
		addi t2, zero, 1 
		br conclude
	right:
		addi t1, zero, 1
		addi t2, zero, 0
	


	conclude:
		add t5, t5, t1 ; new_x = x + dx
		add t7, t7, t2 ; new_y = y + dy (How is it that y + dy = 

		; Outside if :
		; x < 0 or
		; x > 11 or
		; y < 0 or
		; y > 7	

		blt t5, zero, outside ; if new_x < 0
		blt t7, zero, outside ; if new_y < 0

		addi t3, zero, NB_COLS

		bge t5, t3, outside ; if new_x >= 12
		
		addi t3, zero, NB_ROWS

		bge t7, t3, outside ; if new_y >= 8

		; need to check if snake collide with its own tail
		; need to check when snake collide with food
		
		slli t4, t5, 3 ; t4 = 8*new_x
		add t4, t4, t7 ; t4 = 8*new_x + new_y
		slli t4, t4, 2 ; t4 = 4*(8*new_x + new_y) (because of word indexing)
		ldw t4, GSA(t4)

		; next head vector in t4

		; Recall: 1 for score increment, 2 for the game end, and 0 when no collision.

		bne t4, zero, with_element_in_the_cell ; when there is an element in the cell
		ret
			
		with_element_in_the_cell: ; element : number inside t4
			addi t1, zero, FOOD
			beq t4, t1, hit_food
			
			br hit_tail

		hit_food:
			addi v0, zero, RET_ATE_FOOD
			ret

		hit_tail:
			addi v0, zero, RET_COLLISION
			ret

		; v0 : 1 for score increment, 2 for the game end, and 0 when no collision.
		; Outside if :
		; x < 0 or
		; x > 11 or
		; y < 0 or
		; y > 7	
		outside:
			addi v0, zero, RET_COLLISION
			ret

	
; END: hit_test


; BEGIN: get_input
get_input:
	; return values :
	;   register v0 : Which button is pressed. The return value is indicated in table 4 

	addi t1, zero, 4
	ldw t2, BUTTONS(t1) ; edgecapture starts from this address (4 bytes as well)

	addi t3, zero, 1
	slli t3, t3, 5

	addi v0, zero, 6 ; Checking which Button was pressed 5 downto 1 (5 = CP, 4-> 1 for directions)

	check: 
		addi v0, v0, -1
		srli t3, t3, 1

		and t1, t2, t3 ; check if bit i is active
		addi t5, v0, -1
		srl t1, t1, t5

		beq v0, zero, end_check

		addi t4, zero, 1
		bne t4, t1, check

		end_check:

		addi t1, zero, BUTTON_NONE
		beq v0, t1, end ;if nothing was pressed

		addi t1, zero, 4
		stw zero, BUTTONS(t1);clear edgecapture

		;If CP button pressed
		addi t1, zero, BUTTON_CHECKPOINT
		beq v0, t1, end	
						;If checkpoint was pressed then go directly to ret

		

		;Else: Direction button was pressed
		;change snake's head direction

		ldw t1, HEAD_X(zero) ;get current posx, 
		ldw t2, HEAD_Y(zero) ;get posy of snake (head)

		slli t1, t1, 3    ; x = x*8
		add t1, t1, t2    ; pos = 8*x + y

		slli t1, t1, 2 ;for words
	
		ldw t3, GSA(t1) ;get dir value (8x + y)
		add t3, t3, v0
	
		addi t2, zero, 5
		beq t3, t2, end ;Check if the new direction value is not directly opposite to the snake's current direction value. (ie if it is = to 5 or not, 1+4 or 2+3
                   ; are opposite directions)
	
		stw v0, GSA(t1) ; else we change the direction

		end:
		ret

; END: get_input


; BEGIN: draw_array
draw_array:
	addi sp, sp, -24; -4 * 6

	stw ra, 20(sp)
	stw s1, 16(sp)
	stw s2, 12(sp)
	stw s3, 8(sp)
	stw s5, 4(sp)
	stw s6, 0(sp)
	

	addi s1, zero, -1 ; s1 := x
	addi s6, zero, 11 ; upper bound 
	for_x: ; x := s1
		addi s1, s1, 1 ; x++

		addi s2, zero, -1 ; s2 := y
		addi s5, zero, 8 ; upper bound
		for_y: ; y := s2
			addi s2, s2, 1 ; y++
			bge s2, s5, exit_y ; if y >= s5 = 8 => stop

			slli t3, s1, 3
			add t3, t3, s2 ; t3 := i = (x * 8 + y)
			
			slli t3, t3, 2 ; we multiply by 4 since we use words				

			ldw t4, GSA(t3)
			
			beq t4, zero, for_y
				
			add a0, zero, s1
			add a1, zero, s2

			call set_pixel
		br for_y
		exit_y:

		blt s1, s6, for_x ; s1 = x < s6 = 11

	ldw ra, 20(sp)
	ldw s1, 16(sp)
	ldw s2, 12(sp)
	ldw s3, 8(sp)
	ldw s5, 4(sp)
	ldw s6, 0(sp)
	addi sp, sp, 24; 24 = 4 * 6
	
	ret
; END: draw_array


; BEGIN: move_snake
move_snake:
	;calculate new head position (with old head pos and the direction vector)

	; recall constants:
	; .equ    HEAD_X,         0x1000  ; Snake head's position on x
    ; .equ    HEAD_Y,         0x1004  ; Snake head's position on y
    ; .equ    TAIL_X,         0x1008  ; Snake tail's position on x
    ; .equ    TAIL_Y,         0x100C  ; Snake tail's position on Y

	; 1 left    0001
	; 2 up      0010
	; 3 down    0011
	; 4 right   0100

	; dx (change in x) = !p(1) = p(1) xor 1
	; a = (dx and p(0))
	; dx = dx - a
	; dx = dx - a

	; dy (change in y) = - p(1)
	; a = dy and !p(0)
	; dy = dy + a
	; dy = dy + a

	addi sp, sp, -4
	stw ra, 0(sp)

	ldw t5, HEAD_X(zero)						; t5 <- HEAD_X
	slli t6, t5, 3 ; t6 = x * 8					; t6 <- 8 * HEAD_X
		
	ldw t7, HEAD_Y(zero)						; t7 <- HEAD_Y
	add t6, t6, t7 ; t6 = t6 + y = x * 8 + y	; t6 <- GSA Index / 4

	call calculate

	;update hx and hy
	
	add t5, t5, t1 ; new_x = x + dx				; t5 <- new HEAD_X
	stw t5, HEAD_X(zero)

	add t7, t7, t2 ; new_y = y + dy				; t7 <- nez HEAD_Y
	stw t7, HEAD_Y(zero)

	slli t5, t5, 3
	add t5, t5, t7
	slli t5, t5, 2								; t5 <- new HEAD GSA Index

	stw t6, GSA(t5) ; store the same direction to the new head

	;if collision with food then jmp to food.
	
	addi t7, zero, ARG_FED
	beq a0, t7, move_snake_end

	;calculate old tail pos (with tx and ty)

	ldw t6, TAIL_X(zero)						; t6 <- TAIL_X
	add t4, t6, zero							; t4 <- TAIL_X
	slli t6, t6, 3 ; t6 = x * 8

	ldw t5, TAIL_Y(zero)						; t5 <- TAIL_Y
	add t6, t6, t5 ; t6 = t6 + y = x * 8 + y	; t6 <- GSA Index / 4

	slli t7, t6, 2								; t7 <- TAIL GSA Index

	;calculate new tail elem (with tail dir with gsa and tx and ty)

	call calculate

	;clear old tail elem
	
	stw zero, GSA(t7)

	;update tx and ty

	add t4, t4, t1 ; new_x = x + dx				; t4 <- new TAIL_X
	stw t4, TAIL_X(zero)

	add t5, t5, t2 ; new_y = y + dy				; t5 <- new TAIL_Y
	stw t5, TAIL_Y(zero)

	
	move_snake_end:
	ldw ra, 0(sp)
	addi sp, sp, 4 ;Why do we store the ra?
	ret

calculate:
	slli t6, t6, 2
	ldw t6, GSA(t6)

	addi t3, zero, DIR_LEFT ;t3 is the comparator
	beq t6, t3, left_mv

	addi t3, zero, DIR_UP 
	beq t6, t3, up_mv

	addi t3, zero, DIR_DOWN
	beq t6, t3, down_mv

	br right_mv

	left_mv:
		addi t1, zero, -1
		addi t2, zero, 0 
		br conclude_mv
	up_mv:
		addi t1, zero, 0
		addi t2, zero, -1 
		br conclude_mv
		
	down_mv:
		addi t1, zero, 0
		addi t2, zero, 1 
		br conclude_mv
	right_mv:
		addi t1, zero, 1
		addi t2, zero, 0
	


	conclude_mv:

	ret

; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:
	; This procedure will first check whether the score is a multiple of 10 and then, if it is, set the CP_VALID
	; to one and save the current game state to the checkpoint memory region specified in Table 1

	; v0: 1 if a checkpoint is created. Otherwise, 0.

	add v0, zero, zero


	ldw t1, SCORE(zero)
	
	; t1 is in binary

	add t3, zero, zero
	addi t6, zero, 9

	save_checkpoint_get_mod10_loop:
		sub t7, t1, t3 ; full nbr - mod to check
		addi t2, zero, 1 ; boolean variable (1 = not ok, 0 = ok)
		addi t5, zero, 10 ; constant 10
		addi t4, zero, 100 ; start value
		save_checkpoint_get_mod10_loop_check:
			sub t4, t4, t5 ; change comparator
			beq t7, t4, save_checkpoint_success_check ; if a multiple of 10 has been reached
			beq t4, zero, save_checkpoint_end_loop_check
			br save_checkpoint_get_mod10_loop_check
		save_checkpoint_success_check:
		add t2, zero, zero ; success (mod ok)
		save_checkpoint_end_loop_check:
		beq t2, zero, save_checkpoint_next ; if is mod10

		addi t3, t3, 1 ; increment the tested number
		beq t3, t6, save_checkpoint_next ; must be the mod since all other possibilities have been tested
		br save_checkpoint_get_mod10_loop


	save_checkpoint_next:
		bne t3, zero, end_save_checkpoint	
		addi v0, zero, 1 ; if mod 10 is 0, equiv. to score = multiple of 10
		stw v0, CP_VALID(zero)
		
		addi a0, zero, HEAD_X
		addi a1, zero, CP_HEAD_X
		addi a2, zero, 101 ; how many elements? HEAD_X, HEAD_Y, TAIL_X, TAIL_Y, SCORE, GSA = 1+1+1+1+1+96 = 101
		
		addi sp, sp, -4
		stw ra, 0(sp)

		call copy_array_save

		ldw ra, 0(sp)
		addi sp, sp, 4
	
	end_save_checkpoint:
		ret

	copy_array_save:
		; a0: source address
		; a1: destination address
		; a2: length of the array

		addi t1, zero, 0
		loop_copy_array_save:
			slli t5, t1, 2 ; multiply by 4 since we are using words
			add t3, a0, t5
			add t4, a1, t5
			ldw t2, 0(t3)
			stw t2, 0(t4)
			addi t1, t1, 1
			bne t1, a2, loop_copy_array_save
		ret

; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:
	add v0, zero, zero
	ldw t1, CP_VALID(zero)
	beq t1, zero, restore_end

	addi v0, zero, 1

	addi a0, zero, CP_HEAD_X
	addi a1, zero, HEAD_X
	addi a2, zero, 101 ; how many elements? HEAD_X, HEAD_Y, TAIL_X, TAIL_Y, SCORE, GSA = 1+1+1+1+1+96 = 101
		
	addi sp, sp, -4
	stw ra, 0(sp)

	call copy_array_restore

	ldw ra, 0(sp)
	addi sp, sp, 4
	
	br restore_end

	copy_array_restore:
	; a0: source address
	; a1: destination address
	; a2: length of the array

	addi t1, zero, 0
		loop_copy_array_restore:
			slli t5, t1, 2 ; multiply by 4 since we are using words
			add t3, a0, t5
			add t4, a1, t5
			ldw t2, 0(t3)
			stw t2, 0(t4)
			addi t1, t1, 1
			bne t1, a2, loop_copy_array_restore
	ret

	restore_end:
	ret
; END: restore_checkpoint


; BEGIN: blink_score
blink_score:
	addi sp, sp, -12
	stw ra, 8(sp)
	stw s2, 4(sp)
	stw s3, 0(sp)

	add s2, zero, zero
	addi s3, zero, 4
	loop_blink_score:
		; clear score	
		addi t1, zero, 0
		stw zero, SEVEN_SEGS(t1)

		addi t1, zero, 4
		stw zero, SEVEN_SEGS(t1)

		addi t1, zero, 8
		stw zero, SEVEN_SEGS(t1)

		addi t1, zero, 12
		stw zero, SEVEN_SEGS(t1)
		; ...

		wait_blink_score:
			addi t1, zero, 0x0FFF
			slli t1, t1, 7
			addi t1, t1, 0x0FFF
			loop_of_wait_blink_score:
				addi t1, t1, -1
				bne  t1, zero, loop_of_wait_blink_score

		call display_score

		wait_blink_score2:
			addi t1, zero, 0x0FFF
			slli t1, t1, 7
			addi t1, t1, 0x0FFF
			loop_of_wait_blink_score2:
				addi t1, t1, -1
				bne  t1, zero, loop_of_wait_blink_score2
		
		addi s2, s2, 1
		bne s2, s3, loop_blink_score
	
	ldw ra, 8(sp)
	ldw s2, 4(sp)
	ldw s3, 0(sp)
	addi sp, sp, 12

	ret

; END: blink_score

digit_map:
	.word 0xFC ; 0
	.word 0x60 ; 1
	.word 0xDA ; 2
	.word 0xF2 ; 3
	.word 0x66 ; 4
	.word 0xB6 ; 5
	.word 0xBE ; 6
	.word 0xE0 ; 7
	.word 0xFE ; 8
	.word 0xF6 ; 9