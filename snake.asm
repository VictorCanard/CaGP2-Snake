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

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;
; return values
;     This procedure should never return.
main:
    ; TODO: Finish this procedure.

    ret


; BEGIN: clear_leds
clear_leds:
	addi t1, zero, 0
	stw zero, LEDS(t1) ;store zero in LEDS[0]

	addi t1, zero, 1
	stw zero, LEDS(t1) ;store zero in LEDS[1]

	addi t1, zero, 2
	stw zero, LEDS(t1) ;store zero in LEDS[2]
; END: clear_leds


; BEGIN: set_pixel
set_pixel:
	; register a0 : the pixel s x-coordinate
	; register a1 : the pixel s y-coordinate

	; LEDS[0]_x : (0, 1,  2,  3) = (  00,   01,   10,   11)
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
	; => i = 0 and t2
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

	andi t3, zero, 1

	srli t4, t3, 4
	and t4, t4, x

	srli t5, t3, 3
	and t6, t5, x

	or t2, t4, t6

	and t1, zero, t2
	srl t1, t1, t5     ; index in the LEDS array

	andi t1, t1, 1 ;find position in word = 8x+y, so sll 3 and add y.
	andi zero, zero, 4
	;bge a0, zero, comp2 ;x >= 4
		;if x < 4 then in leds[0]
		;store_0:
		
	comp2:
	andi zero, zero, 9
	;bge a0, zero, store_2 ;x >= 9

		;if x >= 4 & x < 8 then in leds[1]
		;store_1:

	;if x >= 8 then in leds[2]
	store_2:



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
