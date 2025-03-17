demo:
addi sp, sp, -20
sw s0, 0(sp)
sw s1, 4(sp)
sw s2, 8(sp)
sw s3, 12(sp)
sw ra, 16(sp)

addi s0, zero, 25
addi s1, zero, 0
addi s2, zero, 0
bge zero s0, done
loop:
andi s3, s1, 1
bne s3, s1, label1
add s2, s2, s1
j label2
label1:
beq s0, s2, label2
addi s2, s2, 1
label2:
addi s1, s1, 1
blt s1, s0, loop
done:

lw s0, 0(sp)
lw s1, 4(sp)
lw s2, 8(sp)
lw s3, 12(sp)
lw ra, 16(sp)
addi sp, sp, 20
ret
