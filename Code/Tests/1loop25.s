test1:
addi sp, sp, -12
sw s0, 0(sp)
sw s1, 4(sp)
sw ra, 8(sp)

li s0, 0
li s1, 25
loop:
	addi s0, s0, 1
	beq s0, s1, end_loop
	j loop
	
end_loop:
lw s0, 0(sp)
lw s1, 4(sp)
lw ra, 8(sp)
addi sp, sp, 12
ret