nested_loops:
    addi sp, sp, -24
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    sw s4, 16(sp)
    sw ra, 20(sp)
    li s0, 3           # Set outer loop counter (3 iterations)
    li s1, 4           # Set second loop counter (4 iterations)
    li s2, 5           # Set third loop counter (5 iterations)
    li s3, 6           # Set innermost loop counter (6 iterations)
    li s4, 0           # Initialize sum/result to 0

    outer_loop:
        beq s0, zero, end_function  # If s0 == 0, exit the function
        addi s0, s0, -1             # Decrement outer loop counter

        # Second Loop
        li s1, 4                   # Reset second loop counter
        second_loop:
            beq s1, zero, outer_loop_continue  # If s1 == 0, continue outer loop
            addi s1, s1, -1                     # Decrement second loop counter

            # Third Loop
            li s2, 5                # Reset third loop counter
            third_loop:
                beq s2, zero, second_loop_continue  # If s2 == 0, continue second loop
                addi s2, s2, -1                     # Decrement third loop counter

                # Innermost Loop
                li s3, 6            # Reset innermost loop counter
                innermost_loop:
                    beq s3, zero, third_loop_continue  # If s3 == 0, continue third loop
                    addi s3, s3, -1                   # Decrement innermost loop counter

                    # Example Operation
                    addi s4, s4, 1   # Increment s4 to count the number of innermost loop iterations

                    j innermost_loop # Continue innermost loop

                third_loop_continue:
                j third_loop         # Continue third loop

            second_loop_continue:
            j second_loop            # Continue second loop

        outer_loop_continue:
        j outer_loop                # Continue outer loop

    end_function:
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    lw s4, 16(sp)
    lw ra, 20(sp)
    addi sp, sp, 24
ret