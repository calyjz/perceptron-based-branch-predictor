test2:
addi sp, sp, -20
sw s0, 0(sp)
sw s1, 4(sp)
sw s2, 8(sp)
sw s3, 12(sp)
sw ra, 16(sp)

li s0, 30
li s1, 0
outer_loop:
	beq s1, s0, end_outer_loop
	li s2, 0
	li s3, 10    # s3 = 10

	inner_loop:
		beq s2, s0, end_inner_loop
		# Arithmetic operations
		sub s3, s3, s2       # s3 = s3 - s2 (s3 = -5)
		addi s2, s2, 1
		j inner_loop
	
	end_inner_loop:
	addi s1, s1, 1
	j outer_loop


end_outer_loop:

lw s0, 0(sp)
lw s1, 4(sp)
lw s2, 8(sp)
lw s3, 12(sp)
lw ra, 16(sp)
addi sp, sp, 20
ret