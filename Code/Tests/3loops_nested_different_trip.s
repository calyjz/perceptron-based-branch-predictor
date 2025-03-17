    addi sp, sp, -36
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    sw s4, 16(sp)
    sw ra, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)

    li s1, 3
    li s2, 0

outer_loop:
    beq s2, s1, end_outer_loop
    li s3, 2
    li s4, 0

middle_loop:
    beq s4, s3, end_middle_loop
    li s5, 4
    li s6, 0

inner_loop:
    beq s6, s5, end_inner_loop
    li s7, 4
    addi s6, s6, 1
    j inner_loop

end_inner_loop:
    addi s4, s4, 1
    j middle_loop

end_middle_loop:
    addi s2, s2, 1
    j outer_loop

end_outer_loop:
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    lw s4, 16(sp)
    lw ra, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    addi sp, sp, 36
ret