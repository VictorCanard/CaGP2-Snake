	calculate_next_in_hit_test: ; need strange name because of duplication of code
		slli t6, t6, 2 ; we multiply by 4 because we use words
		ldw t6, GSA(t6) ; we get the head vector direction


		; initialization of t1 = dx
		; we cannot use t6 here to store temp values

		andi t1, t6, 2;  ; t1 := dx ; t1 = p(1)
		xori t1, t1, 1; t1 := dx ; t1 = !p(1)
		andi t2, t6, 1 ; t2 = p(0)
		and t2, t2, t1 ; t2 = a
		sub t1, t1, t2
		sub t1, t1, t2

		; t1 completely initialized

		; initialization of t2 = dy (HOW DOES THIS CALCULATE THE NEXT Y )
		; we cannot use t1 here to store temp values

		andi t2, t6, 2 ; t1 := dy ; t2 = p(1)
		andi t3, t6, 1 ; t3 = p(0)
		xori t3, t3, 1 ; t3 = !p(0)
		and t3, t2, t3 ; t3 = a
		sub t2, t2, t3
		sub t2, t2, t3

		; t2 completely initialized
