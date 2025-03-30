#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2024 University of Alberta
# Copyright 2024 Sarah Thomson and Ayokunle Amodu
#
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
#
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# -----------------------------------------------------------------------------
# Lab - Perceptron Based Branch Predictor
#
# Date: August 14th, 2024
#
# This common.s file is for students.
#
# This code populates the original instructions array and runs unit tests on solution.s.
# -----------------------------------------------------------------------------
.data
.align 2
originalInstructionsArray:		.space	1024 # max of 255 words for instructions + sentinel
.align 2
modifiedInstructionsArray:		.space	6000
.align 2
instructionIndicatorsArray:		.space	256 # max of 255 bytes for instructions + sentinel
.align 2
numPriorInsertionsArray:		.space	1024 # max of 255 words for instructions + sentinel
.align 2

# strings for error messages
noFileStr:			.asciz "\nERROR: Couldn't open file.\n"
noArguments:    		.asciz "\nERROR: No arguments given. Provide the full path to a binary file of an assembled RISC-V function."
cannotParseMessage:		.asciz "\n\nERROR: Couldn't parse data structures - at least one data structure does not end with a sentinel.\n"
cannotParseMessagePredecessors:	.asciz "\n\nERROR: Couldn't parse data structures - invalid pointer in the predecessorsArray or missing sentinel in a block's predecessorsList.\n"

# mock inputs for the unit tests
.align 2
mockModifiedInstructionsArray:		.space	6000
.align 2
mockInstructionIndicatorsArray:		.space	1028	# max of 256 words for instructions + sentinel
.align 2
mockNumPriorInsertionsArray:		.space	1028	# max of 256 words for instructions + sentinel

# Strings for testing:
running_fill_instructionIndicatorsArray: 	.asciz "\nRunning test for fill_instructionIndicatorsArray --------- "
running_fill_numPriorInsertionsArray: 		.asciz "\nRunning test for fill_numPriorInsertionsArray  --------- "
running_fill_modifiedInstructionsArray: 	.asciz "\nRunning test for fill_modifiedInstructionsArray  ------- "
running_makePrediction: 			.asciz "\nRunning test for makePrediction  ----------------------- "
running_trainPredictor: 			.asciz "\nRunning test for trainPredictor  ----------------------- "

testPass:	.asciz "Test Passed :D\n"
testFail:	.asciz "Test Failed :(\n"
expected:	.asciz "\nExpected output: "
actual:		.asciz "\nActual output:   "
space:		.asciz " "
newline:	.asciz "\n"
percent:	.asciz "%"
colon:		.asciz ":"
openBracket:	.asciz " [ "
closeBracket:	.asciz "]\n"

# String for printing results:
start_predictorStr:			.asciz "\n---------------Running branch predictor now---------------"
end_predictorStr:			.asciz "\nBranch Predictor has finished running."
end_modifiedArrayStr:			.asciz "\nThis is your modifiedInstructionsArray:"
end_perceptronWeights:			.asciz "\nThese are your final perceptron weights:"
end_accuracy:				.asciz "% accurate"
branchStr:				.asciz "\nBranch id "
total_branchStr:			.asciz "Total branch instructions executed: "
total_correctBranchStr:			.asciz "\nTotal correct predictions: "
accuracyStr:				.asciz "\nBranch predictor accuracy: "

.align 2
mockOriginalInstructionsArray:	
				# demo:
	.word 0xfec10113	# addi sp, sp, -20
	.word 0x00812023	# sw s0, 0(sp)
	.word 0x00912223	# sw s1, 4(sp)
	.word 0x01212423 	# sw s2, 8(sp)
	.word 0x01312623 	# sw s3, 12(sp)
	.word 0x00112823	# sw ra, 16(sp)

	.word 0x01900413	# addi s0, zero, 25	
	.word 0x00000493	# addi s1, zero, 0
	.word 0x00000913	# addi s2, zero, 0
	.word 0x02805263	# bge zero, s0, 32
				
				# loop:
	.word 0x0014f993	# andi s3, s1, 1	
	.word 0x00999663	# bne s3, s1, 12
	.word 0x00990933	# add s2, s2, s1	
	.word 0x00c0006f	# j 12
	
				# label1:
	.word 0x01240463	# beq s0, s2, 8
	.word 0x00190913	# addi s2, s2, 1
	
				# label2:
	.word 0x00148493	# addi s1, s1, 1
	.word 0xfe84c2e3	# blt s1, s0, -28
								
				# done:	
	.word 0x00012403	# lw s0, 0(sp)
	.word 0x00412483	# lw s1, 4(sp)
	.word 0x00812903	# lw s2, 8(sp)
	.word 0x00c12983	# lw s3, 12(sp)
	.word 0x01012083	# lw ra, 16(sp)
	.word 0x01410113	# addi sp, sp, 20
	.word 0x00008067	# jalr zero, ra, 0
	.word 0xffffffff	# sentinel

# expected instructionIndicatorsArray for test_fill_instructionIndicatorsArray unit test
.align 2
expectedInstructionIndicatorsArray:
	# demo:	
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte 0

	.byte 0
	.byte 0
	.byte 0
	.byte 1
	
	# loop:
	.byte 2
	.byte 1
	.byte 0	
	.byte 0
	
	# label1:
	.byte 3
	.byte 0
	
	# label2:
	.byte 2
	.byte 1
				
	# done
	.byte 2
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte 0
	.byte 0

	# END
	.byte -1

# expected numPriorInsertionsArray for test_fill_numPriorInsertionsArray unit test
.align 2
expectedNumPriorInsertionsArray:
	# demo:	
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0
	.word 0
	.word 0
	.word 7 # +7 for branch setup
	
	# loop:
	.word 15 # +4 for branch fallthrough resolve +4 for target resolve
	.word 22 # +7 for branch setup
	.word 26 # +4 fallthrough resolve	
	.word 26
	
	# label1:
	.word 37 # +4 for target resolve +7 for branch setup
	.word 41 # +4 for branch fallthrough resolve
	
	# label2:
	.word 45 # +4 for target resolve
	.word 52 # +7 for branch setup
				
	# done
	.word 60 # +4 for branch fallthrough resolve + 4 for taraget resolve
	.word 60
	.word 60
	.word 60
	.word 60
	.word 60
	.word 60

	# END
	.word -1

.align 2
expectedModifiedInstructionsArray: # INCOMPLETE modifiedInstructionsArray for test_fill_modifiedInstructionsArray unit test

				# demo:	
	.word 0xfec10113	# addi sp, sp, -20
	.word 0x00812023	# sw s0, 0(sp)
	.word 0x00912223	# sw s1, 4(sp)
	.word 0x01212423 	# sw s2, 8(sp)
	.word 0x01312623 	# sw s3, 12(sp)
	.word 0x00112823	# sw ra, 16(sp)
		
	.word 0x01900413	# addi s0, zero, 25
	.word 0x00000493	# addi s1, zero, 0
	.word 0x00000913	# addi s2, zero, 0
	
	# Space for setup template
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0x0e805463	# bge zero, s0, 232

	# Space for fallthrough resolve template
	.word 0
	.word 0
	.word 0
	.word 0
				# loop:
	# Space for target resolve template
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0x0014f993	# andi s3, s1, 1	

	# Space for setup template
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0x00999e63	# bne s3, s1, 12 + 8*4

	# Space for fallthrough resolve template
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0x00990933	# add s2, s2, s1	
	.word 0x0580006f	# j 88

				# label1:

	# Space for target resolve template
	.word 0
	.word 0
	.word 0
	.word 0

	# Space for setup template
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0x01240c63	# beq s0, s2, 24

	# Space for fallthrough resolve template
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0x00190913	# addi s2, s2, 1

				# label2:

	# Space for target resolve template
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0x00148493	# addi s1, s1, 1

	# Space for setup template
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0xf484c0e3	# blt s1, s0, -116

	# Space for fallthrough resolve template
	.word 0
	.word 0
	.word 0
	.word 0				

				# done:

	# Space for target resolve template
	.word 0
	.word 0
	.word 0
	.word 0

	.word 0x00012403	# lw s0, 0(sp)
	.word 0x00412483	# lw s1, 4(sp)
	.word 0x00812903	# lw s2, 8(sp)
	.word 0x00c12983	# lw s3, 12(sp)
	.word 0x01012083	# lw ra, 16(sp)
	.word 0x01410113	# addi sp, sp, 20

	.word 0x00008067	# jalr zero, ra, 0
	.word 0xffffffff	# sentinel
.align 2

expectedModifiedArraySetupLocations: # Hardcoded locations for where in the expectedNumPriorInsertionsArray the templates need to be filled (for testing)
	.byte 9
	.byte 26
	.byte 44
	.byte 62

expectedModifiedArrayFallthroughLocations: # Hardcoded locations for where in the expectedNumPriorInsertionsArray the templates need to be filled (for testing)
	.byte 17
	.byte 34
	.byte 52
	.byte 70

expectedModifiedArrayTargetLocations: # Hardcoded locations for where in the expectedNumPriorInsertionsArray the templates need to be filled (for testing)
	.byte 21
	.byte 40
	.byte 57
	.byte 74	

# dereferenced perceptrons weights:
.align 2
mockPerceptron:
	.byte 9
	.byte 3
	.byte 0
	.byte -7
	.byte 4
	.byte 5
	.byte 2
	.byte 3
	.byte 3

expectedOutput:
	.word 16

expectedUpdatedPerceptron:
	.byte 10
	.byte 2
	.byte 1
	.byte -8
	.byte 3
	.byte 6
	.byte 3
	.byte 4
	.byte 2

.text
main:

	addi sp, sp, -12
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	mv s0, a0 # save number of program arguments
	mv s1, a1 # save the array of pointers to argument strings

	# validating program arguments
	beqz a1, invalidArguments
    	
	lw t0, 0(a1)
	beqz t0, invalidArguments
	j validArguments
		
	invalidArguments:
		la a0, noArguments
		j error

	validArguments:
	
	# Read the input file:
	lw a0, 0(s1) # pointer to a file path's string
	la a1, originalInstructionsArray # pointer to a buffer
	jal ra, readFileToBuffer

	jal ra, runTests

	la a0, start_predictorStr
	jal ra, printStr

	la a0, originalInstructionsArray
	la a1, modifiedInstructionsArray
	la a2, instructionIndicatorsArray
	la a3, numPriorInsertionsArray
	jal ra, perceptronPredictor
		
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	addi sp, sp, 12

	li	a0, 1			# exit code of 1
	li	a7, 93			# syscall number to terminate the program
	ecall

# -----------------------------------------------------------------------------
# runTests:
#
# Description:
#  	Runs a series of unit tests on the solution file.
#
# Arguments:
#	None
#
# Returns:
# 	None
# -----------------------------------------------------------------------------
runTests:
	addi sp, sp, -20
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw ra, 16(sp)

	# Test for fill_instructionIndicatorsArray function
	test_fill_instructionIndicatorsArray:
		la a0, running_fill_instructionIndicatorsArray
		jal ra, printStr
	
		la a0 mockOriginalInstructionsArray
		la a1 mockInstructionIndicatorsArray 
		jal ra, fill_instructionIndicatorsArray
	
		la a0 mockInstructionIndicatorsArray
		la a1 expectedInstructionIndicatorsArray
		li a2, -1
		jal ra, equals_byte
	
		beqz a0, test_fill_instructionIndicatorsArrayPass
	
		la a0, testFail
		li a7, 4
		ecall
	
		# Print expected vs actual:
		la a0, expected
		li a7, 4
		ecall
	
		la a0 expectedInstructionIndicatorsArray
		jal ra, printIntByteArray
		
		la a0, actual
		li a7, 4
		ecall
	
		la a0 mockInstructionIndicatorsArray
		jal ra, printIntByteArray
		j test_fill_numPriorInsertionsArray
		
		test_fill_instructionIndicatorsArrayPass:
		la a0, testPass
		li a7, 4
		ecall 

	# Test for fill_numPriorInsertionsArray function
	test_fill_numPriorInsertionsArray:
	
		la a0, running_fill_numPriorInsertionsArray
		jal ra, printStr
		
		la a0 expectedInstructionIndicatorsArray 
		la a1 mockNumPriorInsertionsArray
		jal ra, fill_numPriorInsertionsArray
		
		la a0 mockNumPriorInsertionsArray
		la a1 expectedNumPriorInsertionsArray
		li a2, -1
		jal ra, equals_word
	
		beqz a0, test_fill_numPriorIndicatorsArrayPass
	
		la a0, testFail
		li a7, 4
		ecall
	
		# Print expected vs actual:
		la a0, expected
		li a7, 4
		ecall
	
		la a0, expectedNumPriorInsertionsArray
		li a1, 0 # print in decimal format
		jal ra, printIntWordArray
		
		la a0, actual
		li a7, 4
		ecall
	
		la a0, mockNumPriorInsertionsArray
		li a1, 0 # print in decimal format
		jal ra, printIntWordArray
		j test_fill_modifiedInstructionsArray
		
		test_fill_numPriorIndicatorsArrayPass:
		la a0, testPass
		li a7, 4
		ecall

	test_fill_modifiedInstructionsArray:

		la a0, running_fill_modifiedInstructionsArray
		jal ra, printStr

		# First fill the templates in expectedModifiedInstructionsArray
		la s0, expectedModifiedArraySetupLocations
		la s1, expectedModifiedInstructionsArray

		li s2, 0 # iterator
		
		fill_setup_loop:	
			li t0, 4
			beq s2, t0, finish_fill_setup_loop
			add t0, s0, s2 # base address of expectedModifiedArraySetupLocations + i bytes
			lb t0, 0(t0) # index of start of a setup template in expectedModifiedInstructionsArray 
			slli t0, t0, 2 # index * 4
			add a0, t0, s1
			mv a1, s2 # branch id
			jal ra, insertSetupInstructions
			addi s2, s2, 1
			j fill_setup_loop
		
		finish_fill_setup_loop:

		la s0, expectedModifiedArrayFallthroughLocations
		li s2, 0 # iterator

		fill_fallthrough_loop:

			li t0, 4
			beq s2, t0, finish_fill_fallthrough_loop
			add t0, s0, s2 # base address of expectedModifiedArraySetupLocations + i bytes
			lb t0, 0(t0) # index of start of a setup template in expectedModifiedInstructionsArray 
			slli t0, t0, 2 # index * 4
			add a0, t0, s1
			li a1, 0 # resolve fallthrough 
			jal ra, insertResolveInstructions
			addi s2, s2, 1
			j fill_fallthrough_loop

		finish_fill_fallthrough_loop:
		la s0, expectedModifiedArrayTargetLocations
		li s2, 0 # iterator

		fill_target_loop:
			
			li t0, 4
			beq s2, t0, finish_fill_target_loop
			add t0, s0, s2 # base address of expectedModifiedArraySetupLocations + i bytes
			lb t0, 0(t0) # index of start of a setup template in expectedModifiedInstructionsArray 
			slli t0, t0, 2 # index * 4
			add a0, t0, s1
			li a1, 1 # resolve target
			jal ra, insertResolveInstructions
			addi s2, s2, 1
			j fill_target_loop

		finish_fill_target_loop:

		la s0, mockModifiedInstructionsArray
		la a0, mockOriginalInstructionsArray
		mv a1, s0
		la a2, expectedInstructionIndicatorsArray
		la a3, expectedNumPriorInsertionsArray
		jal ra, fill_modifiedInstructionsArray

		mv a0, s0 # mockModifiedInstructionsArray
		la a1 expectedModifiedInstructionsArray
		li a2, -1
		jal ra, equals_word

		beqz a0, test_fill_modifiedInstructionsArrayPass
		la a0, testFail
		li a7, 4
		ecall
	
		# Print expected vs actual:
		la a0, expected
		li a7, 4
		ecall
	
		la a0, expectedModifiedInstructionsArray
		li a1, 1 # print in hex format
		jal ra, printIntWordArray
		
		la a0, actual
		li a7, 4
		ecall
	
		mv a0, s0 # mockModifiedInstructionsArray
		li a1, 1 # print in decimal format
		jal ra, printIntWordArray
		j test_makePrediction
		
		test_fill_modifiedInstructionsArrayPass:
		la a0, testPass
		li a7, 4
		ecall

	# Test making a prediction with the fourth branch (branch id 3)
	test_makePrediction:

		la a0, running_makePrediction
		jal ra, printStr
		
		# load a test state into the global shift register: 01001110
		la t0, globalHistoryRegister
		li t1, 0x4E
		sb t1, 0(t0)
	
		# Add a pointer to the fourth element of preceptronPointersArray to mockPerceptron
		la t0, mockPerceptron
		la t1, patternHistoryTable
		sw t0, 12(t1)

		li a0, 3 
		jal ra, makePrediction

		# Check if output matches expectedOutput:
		lw t0, output
		lw t1, expectedOutput
		
		beq t0, t1, test_makePredictionPass

		# If test failed:
		la a0, testFail
		li a7, 4
		ecall
	
		# Print expected vs actual:
		la a0, expected
		li a7, 4
		ecall
	
		mv a0, t1
		li a7, 1 # print int
		ecall
		
		la a0, actual
		li a7, 4
		ecall

		mv a0, t0
		li a7, 1 # print int
		ecall
		
		j test_trainPredictor

	test_makePredictionPass:
		la a0, testPass
		li a7, 4
		ecall

	test_trainPredictor:

		la a0, running_trainPredictor
		jal ra, printStr

		# Provide the trainPredictor function with the previous expected output and the fourth branch's (branch id 3) 
		la t0, output
		lw t1, expectedOutput
		sw t1, 0(t0)
		la t0, activeBranch
		li t1, 3
		sw t1, 0(t0)
		li a0, 1 # branch taken

		jal ra, trainPredictor	

		# check if the weights have been correctly modified
		la a1, expectedUpdatedPerceptron
		la t1, patternHistoryTable
		lw a0, 12(t1) # load fourth perceptron
		li a2, 9 # number of weights
		li a3, 0
		
		jal ra, equals_perceptron
		
		beqz a0, test_trainPredictorPass

		# If test failed:
		la a0, testFail
		li a7, 4
		ecall
	
		# Print expected vs actual:
		la a0, expected
		li a7, 4
		ecall
	
		la a0, expectedUpdatedPerceptron

		jal ra, print_perceptron
		
		la a0, actual
		li a7, 4
		ecall

		la t1, patternHistoryTable
		lw a0, 12(t1) # load fourth perceptron

		jal ra, print_perceptron
		
		j finish_testing
	
		test_trainPredictorPass:
			la a0, testPass
			li a7, 4
			ecall

	finish_testing:
	# restore shift register
	la t0, globalHistoryRegister
	sb zero, 0(t0)

	# restore patternHistoryTable:
	la t1, patternHistoryTable
	sw zero, 12(t1) # set fourth perceptron pointer back to 0

	# restore activeBranch
	la t0, activeBranch
	li t1, -1
	sb t1, 0(t0)

	# restore numBranchesExecuted
	la t0, numBranchesExecuted
	sw zero, 0(t0)

	# restore numCorrectPredictions
	la t0, numCorrectPredictions
	sw zero, 0(t0)
	
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw ra, 16(sp)
	addi sp, sp, 20

	ret
# -----------------------------------------------------------------------------
# printIntWordArray:
#
# Description:
#  	Prints each byte from an array that ends in a sentinel of -1 to the terminal.
#
# Arguments:
#	a0: Address of the array
#
# Returns:
# 	None
#
# Register Usage:
# t1: current byte
# t2: sentinel
# -----------------------------------------------------------------------------
printIntByteArray:

	addi sp, sp, -8
	sw s0, 0(sp)
	sw ra, 4(sp)
		
	mv s0, a0
	li t3, 150 # print no more than 150
	li t4, 0

	print_byte_loop:
		
		lb t1, 0(s0)            # current element
		li t2, -1               # sentinel
		beq t1, t2, print_byte_done     
		bgt t4, t3, print_byte_done    
		
		# Print the integer in t1
		mv a0, t1              
		li a7, 1                # ecall for print integer 
		ecall                   # print
		
		# Print a space
		la a0, space          # load the address of a space
		li a7, 4              # ecall for print string
		ecall                 # print
		
		addi s0, s0, 1        # move to the next element in the array
		addi t4, t4, 1
		j print_byte_loop                  

	print_byte_done:
		
		lw s0, 0(sp)
		lw ra, 4(sp)
		addi sp, sp, 8
	    	ret                     # Return from the function

# -----------------------------------------------------------------------------
# printIntWordArray:
#
# Description:
#  	Prints each 32 bit integer from an array that ends in a sentinel of -1 to the terminal.
#
# Arguments:
#	a0: Address of the array
#	a1: 0 for decimal, 1 for hex print format
#
# Returns:
# 	None
#
# Register Usage:
# t1: current integer
# t2: sentinel
# -----------------------------------------------------------------------------
printIntWordArray:

	addi sp, sp, -12
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw ra, 8(sp)
		
	mv s0, a0
	mv s1, a1
	li t3, 150 # print no more than 150
	li t4, 0

	print_word_loop:
		
		lw t1, 0(s0)            # current element
		li t2, -1               # sentinel
		beq t1, t2, print_word_done    
		bgt t4, t3, print_word_done     
		
		beqz s1, print_decimal
		# Print a newline
		la a0, newline         # load the address of newline
		li a7, 4              # ecall for print string
		ecall                 # print

		# Print the integer in t1 in hex form
		mv a0, t1              
		li a7, 34                # ecall for print integer (hex)
		ecall                   # print
		
		j increment_print_word_loop

		print_decimal:
		# Print the integer in t1 in decimal form
		mv a0, t1              
		li a7, 1                # ecall for print integer 
		ecall                   # print

		# Print a space
		la a0, space          # load the address of a space
		li a7, 4              # ecall for print string
		ecall                 # print

		increment_print_word_loop:
		addi s0, s0, 4          # move to the next element in the array
		addi t4,t4,1
		j print_word_loop                  

	print_word_done:
		
		lw s0, 0(sp)
		lw s1, 4(sp)
		lw ra, 8(sp)
		addi sp, sp, 12
	    	ret                     # Return from the function

# -----------------------------------------------------------------------------
# readFileToBuffer:
#
# Description:
#  	Reads from a file into a buffer and stores a sentinel at the end of the buffer.
#
# Arguments:
# 	a0: pointer to a file
# 	a1: pointer to a buffer
#
# Returns:
# 	None
#
# Register Usage:
# 	a0: file descriptor or argument for system calls
# 	a1: pointer to the buffer or mode for file operations
# 	a2: mumber of bytes to read (for the read system call)
# 	s0: saved file descriptor (for file operations)
# 	s1: pointer to the buffer (saved for later use)
# 	t0: pointer to the end of the buffer (base address + number of bytes read)
# 	t1: sentinel
# -----------------------------------------------------------------------------
readFileToBuffer:
	addi 	sp, sp, -12
	sw 	s0, 0(sp)
	sw	s1, 4(sp)
	sw 	ra, 8(sp)
	
	mv	s1, a1			# pointer to the buffer	
	
	# a0 is already the file pointer (argument)
	
	li	a1, 0 			# read only
	li	a7, 1024 		# call number to open a file
	ecall
	
	bltz 	a0, noFileFound 	# branch if file decriptor is negative (error)
	j	fileFound
		
		noFileFound:
			la	a0, noFileStr
			j 	error
	
	fileFound:
		mv	s0, a0			# file descriptor (copy)
		
		
		# a0 is now the file descriptor	(argument)
		
		mv	a1, s1 			# pointer to buffer
		li	a2, 2048		# maximum number of bytes to read
		li	a7, 63			# call number to read from a file into a buffer
		ecall
		
		# a0 is now the number of bytes read into the buffer (argument)
		
		add	t0, s1, a0		# pointer to the end of the file (base address + number of bytes read)
		li	t1, -1			# sentinel
		
		sw	t1, 0(t0)		# storing sentinel after the last word
		
		la 	a0, originalInstructionsArray	# pointer to the buffer (argument)
		jal	killCr
		
		mv	a0, s0			# file descriptor (argument)
		li	a7, 57			# call number to close file
		ecall	
		
		lw 	s0, 0(sp)
		lw	s1, 4(sp)
		lw 	ra, 8(sp)
		addi 	sp, sp, 12
		ret

# -----------------------------------------------------------------------------
# equals_byte:
#
# Description:
#  	Checks if two byte arrays are entirely equal by comparing each element.
#
# Arguments:
# 	a0: pointer to the first array 
# 	a1: pointer to the second array (expected array)
# 	a2: sentinel (end of array marker)
#
# Returns:
# 	a0: 0 if both arrays are entirely equal, -1 if they are not
#
# Register Usage:
# 	t0: current element from the first array
# 	t1: current element from the second array
# 	t2: pointer to the first array (copied from a0)
# -----------------------------------------------------------------------------
equals_byte:
    	mv	t2, a0		# pointer to first array (copy)
    	li	a0, 0		# initialize result to 0 (pass)
    	
    	equals_byte_loop:
	    	lb 	t0, 0(t2)	# load current element from first array
	    	lb 	t1, 0(a1)	# load current element from second array
	
	    	bne 	t0, t1, equals_byte_fail	# exit loop if current elements do not match (fail)
	    	beq 	t1, a2, equals_byte_exit	# exit loop if end of second array reached (pass)
	
	    	addi 	t2, t2, 1	# go to next element in first array
		addi 	a1, a1, 1	# go to next element in second array
	    	j 	equals_byte_loop
	
	equals_byte_fail:
		li	a0, -1

	equals_byte_exit:
		ret

# -----------------------------------------------------------------------------
# equals_word:
#
# Description:
#  	Checks if two word arrays are entirely equal by comparing each element.
#
# Arguments:
# 	a0: pointer to the first array 
# 	a1: pointer to the second array (expected array)
# 	a2: sentinel (end of array marker)
#
# Returns:
# 	a0: 0 if both arrays are entirely equal, -1 if they are not
#
# Register Usage:
# 	t0: current element from the first array
# 	t1: current element from the second array
# 	t2: pointer to the first array (copied from a0)
# -----------------------------------------------------------------------------
equals_word:
	
    	mv	t2, a0		# pointer to first array (copy)	
    	li	a0, 0		# initialize result to 0 (pass)
    	
    	equals_word_loop:
	    	lw 	t0, 0(t2)	# load current element from first array
	    	lw 	t1, 0(a1)	# load current element from second array
	
	    	bne 	t0, t1, equals_word_fail	# exit loop if current elements do not match (fail)
	    	beq 	t1, a2, equals_word_exit	# exit loop if end of second array reached (pass)
	
	    	addi 	t2, t2, 4	# go to next element in first array
		addi 	a1, a1, 4	# go to next element in second array
	    	j 	equals_word_loop
	
	equals_word_fail:
		li	a0, -1

	equals_word_exit:
		ret

#------------------------------------------------------------------------------
# equals_perceptron:
# 	This function checks if two perceptron weight arrays are entirely equal.
#
# Args:
#    	a0: pointer to array 1
#  	a1: pointer to array 2
#    	a2: length of array 1
#   	a3: counter for recursion
# Returns:
#   	a0: 0 if both arrays are entirely equal, -1 if not.
#
# Register Usage:
#   	t0: current character to compare from string 1
#   	t1: current character to compare from string 2
#-----------------------------------------------------------------------------
equals_perceptron:

	# load byte from both arrays
	lb t0, 0(a0)
	lb t1, 0(a1)

	# check if we've reached the end of the array
	beq a3, a2, equal_pass
	    
	# check if it doesn't equal each other, fail
	bne t0, t1, equal_fail
	
	# increment for next iteration
	addi a0, a0, 1
	addi a1, a1, 1
	addi a3, a3, 1
	# jump to next iteration
	j equals_perceptron
	
	equal_fail:
	 
	# return -1 for a fail
	li a0, -1   
	ret
	
	equal_pass:
	
	# return 0 for a pass
	li a0, 0
	ret

#----------------------------------------------------------------------------------------------
# strToInt
# Prints a perceptron.
#
# Arguments:
#    a0: The pointer to the weights array
#
# Returns:
#     None
#----------------------------------------------------------------------------------------------
print_perceptron:

	li t0, 9              # 9 weights
	mv t3, a0
	
	
	print_loop:
		beqz t0, end_print    
		lb a0, 0(t3)   
		sb a0, 0(t3)      
		li a7, 1                        
		ecall
		la a0, space          # load the address of a space
		li a7, 4              # ecall for print string
		ecall                 # print
		addi t3, t3, 1        
		addi t0, t0, -1       
		j print_loop

end_print:
    ret

	

#----------------------------------------------------------------------------------------------
# strToInt
# Parses an ascii string representing an interger into that integer.
# Only 4 digit numbers may be parsed using this function.
#
# Arguments:
#    a0: The ascii representation of the number
#
# Returns:
#     a0: The parsed integer.
#----------------------------------------------------------------------------------------------
strToInt:
    li    a1, 0           	# Used to store intermediate results.
    li    t0, 0           	# Amount of bits to shift right.
    li    t1, 1           	# Used to store the place value of our current digit.
    li    t2, 24          	# Used to store the constant 24
    li    t3, 10          	# Used to store the constant 10
    li    t4, 0xFF        	# Bitmask to extract the lower 8 bits.

	strToIntLoop:
	    srl    t6, a0, t0    	# t6 <- a0 shifted by number of bits required to get the next 8 bits to the lower
	                    	  	# part of the register.
	    and    t5, t6, t4     	# t5 <- Lower 8 bits of t6
	    beqz    t5, strToIntLoopEnd # No more ascii representation of digits to convert.
	    addi    t5, t5, -48        	# Adjustment for ascii to integer values.
	    mul    t5, t5, t1        	# Multiply the number we just parsed by its placeholder value in the number.
	    add    a1, a1, t5        	# Add the number we just parsed to our intermediate result.
	    
	    addi    t0, t0, 8        	# Increment the number of shift to get the next ascii character.
	    mul    t1, t1, t3        	# Multiply our current placeholder value by 10 for the next iteration.
	    ble    t0, t2, strToIntLoop# Ensures that we run the loop at most 4 times. An ascii character takes 1 byte and since a word is
	                    		# 4 bytes, we can have at most 4 characters in a register.
	
	strToIntLoopEnd:
	    mv    a0, a1
	    ret

# -----------------------------------------------------------------------------
# printStr:
#
# Description:
#  	Prints a string to the standard output.
#
# Arguments:
# 	a0: pointer to a string (address of the integer to print)
#
# Returns:
# 	None
#
# Register Usage:
#	a7: system call number for printing a string
# -----------------------------------------------------------------------------		
printStr:
	addi sp, sp, -4
	sw ra, 0(sp)

    	li a7, 4
    	ecall

    	lw ra, 0(sp)
    	addi sp, sp, 4
    	ret
    	
# -----------------------------------------------------------------------------
# kill_cr:
#
# Convert DOS-style line terminators to UNIX-style ones. The conversion is
# performed in place.
#
# Arguments:
#  	a0: pointer to a string
#
# Return:
#	None
#	
# Register Usage:
#	t0: copy-to pointer
#	t1: loader char
#	t6: '\r' ascii value
# -----------------------------------------------------------------------------
killCr:
   	mv      t0, a0
    	li      t6, 0x0d	# t6 <- '\r'
	
	killCrLoop:
	    lbu	    t1, 0(a0)           # Read the next character
	    sb      t1, 0(t0)           # Copy the charcater
	    beqz    t1, killCrExit	# exit if end of array reached
	    addi    a0, a0, 1		# Move to the next character
	    beq     t1, t6, killCrLoop
	    addi    t0, t0, 1           # Skip the '\r'
	    j       killCrLoop
	
	killCrExit:
    		ret
					 							
# -----------------------------------------------------------------------------
# error:
#
# Description:
# 	Prints out an error message and terminates the program.
#
# Arguments:
# 	a0: pointer to the error message string
#
# Returns:
# 	None
#
# Register Usage:
# 	a7: system call number for program termination
# -----------------------------------------------------------------------------
error:
	
	# a0 is a pointer to the error message string (argument)
	
	jal 	printStr
	
	li	a0, -1			# exit code of -1
	li	a7, 93			# syscall number to terminate the program
	ecall
