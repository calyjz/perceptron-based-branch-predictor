simple_loop:
	addi sp, sp, -20
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw ra, 16(sp)

    	addi s3, zero, 70
    loop_start:
        beq s3, zero, end_loop
        andi s0, s3, 1
        beq s0, zero, even_case
        addi s2, s2, 1
        j loop_continue

    even_case:
        addi s2, s2, -1

    loop_continue:
        addi s3, s3, -1
        j loop_start

    end_loop:

	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw ra, 16(sp)
	addi sp, sp, 20
	ret