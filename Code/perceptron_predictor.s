#
# CMPUT 229 Student Submission License
# Version 1.0
#
# Copyright 2025 <student name>
#
# Redistribution is forbidden in all circumstances. Use of this
# software without explicit authorization from the author or CMPUT 229
# Teaching Staff is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential 
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including 
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca
#
#------------------------------------------------------------------------------
# CCID: cjzheng
# Lecture Section: B1
# Instructor: J Nelson Amaral
# Lab Section: H02
# Teaching Assistant: Patrick Zijlstra
#-----------------------------------------------------------------------------
.data 

activeBranch: 				.byte -1 # This is either the id of the currently executing branch or 0
.align 2							# Indexed by the id of the branch.
patternHistoryTable: 			.space  132	# pointers to the dynamically allocated arrays of weights for each branch instruction, max of 32 pointers + sentinel
globalHistoryRegister: 			.byte   0	
.align 2	
output: 				.word 	0
threshold: 				.byte 	127
.align 2	
numBranches:				.word 0
.align 2	
numBranchesExecuted:			.word 0
.align 2	
numCorrectPredictions:			.word 0

.include "common.s"

.text
# -----------------------------------------------------------------------------
# perceptronPredictor:
#
# Description:
#  	The primary function that prepares the input function to run with branch prediction.
#
# Arguments:
#	a0: Pointer to originalInstructionsArray
#	a1: Pointer to modifiedInstructionsArray
# 	a2: Pointer to instructionIndicatorsArray
#	a3: Pointer to numPriorInsertionsArray
#	
# Returns:
# 	None
#
# Register Usage:
#
# -----------------------------------------------------------------------------	
perceptronPredictor:
	#set instruction indicatiors, numpriors, and modified instructions array to 0
ret
# -----------------------------------------------------------------------------
# fill_instructionIndicatorsArray:
#
# Description:
#  	This function is responsible for filling insertionsIndicatorsArray.
#
# Arguments:
# 	a0: Pointer to originalInstructionsArray
#	a1: Pointer to instructionIndicatorsArray
# Returns:
# 	None
#
# Register Usage:
# 	s0: Pointer to originalInstructionsArray
#	s1: Pointer to instructionIndicatorsArray
#	s2: index i
#	
# -----------------------------------------------------------------------------		
fill_instructionIndicatorsArray:
	addi sp, sp, -36
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s3, 16(sp)
	sw s4, 20(sp)
	sw s5, 24(sp)
	sw s6, 28(sp)
	sw s7, 32(sp)
	
	mv s0, a0 #s0 <- Pointer to originalInstructionsArray
	mv s1, a1 #s1 <- Pointer to instructionIndicatorsArray
	li s3, -1

	#set all values to 0
	mv s2, s0
	mv s4, s1
	fillInstructionZeroLoop:
	lw s5, 0(s2) #check if value == -1
	beq s3, s5, fillInstructionZeroLoopEnd

	sb zero, 0(s4) #store zero in instructionindicator array
	addi s2, s2, 4
	addi s4, s4, 1
	j fillInstructionZeroLoop
	fillInstructionZeroLoopEnd:
	

	li s4, 99 #s4 <- opcode for branch

	lw s2, 0(s0)
	beq s2, s3, fillInstructionEnd

	#iterate through the original instructions array
	fillInstructionLoop:
		addi s0, s0, 4
		addi s1, s1, 1

		#end condition: if originalInstructions[i] == -1
		lw s2, 0(s0)
		beq s2, s3, fillInstructionEnd
		
		#break: if not branch instruction
		li s5, 0x7F
		and s5, s5, s2
		bne s5, s4, fillInstructionLoop


		lb s5, 0(s1)
		addi s5, s5, 1
		sb s5, 0(s1)

		mv a0, s2
		jal ra, getBranchImm
		mv s6, a0 #s5 <- immediate of branch instruction
		
		add s7, s6, s0
		lw s7, 0(s7)
		
		srai s6, s6, 2 #s6 <- s6 //4
		add s6, s6, s1 #s5 <- &instructionIndicator[i] + immediate
		lb s5, 0(s6)
		addi s5, s5, 2
		sb s5, 0(s6)
		
		j fillInstructionLoop


	fillInstructionEnd:
	sb s3, 0(s1) #store -1 at the end of instructionIndicator Array
	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s3, 16(sp)
	lw s4, 20(sp)
	lw s5, 24(sp)
	lw s6, 28(sp)
	lw s7, 32(sp)
	addi sp, sp, 36
	ret
# -----------------------------------------------------------------------------
# fill_numPriorInsertionsArray:
#
# Description:
#  	This function is responsible for filling numPriorInsertionsArray.
#
# Arguments:
# 	a0: Pointer to instructionIndicatorsArray
#	a1: Pointer to numPriorInsertionsArray
#	
# Returns:
# 	None
#
# Register Usage:
# 	s0: Pointer to instructionIndicatorsArray
#	s1: Pointer to numPriorInsertionsArray
# 	s2: cumulative value
#	s3: branch previous 
#	s4: -1
#	s5: instructionindicator[i]
#	s6: Intermediate values
#
# -----------------------------------------------------------------------------		
fill_numPriorInsertionsArray:
	addi sp, sp, -36
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s3, 16(sp)
	sw s4, 20(sp)
	sw s5, 24(sp)
	sw s6, 28(sp)
	sw s7, 32(sp)

	mv s0, a0
	mv s1, a1

	li s2, 0 #s2 <- current value
	li s3, 0 #s3 <- branch previous (4 if true, 0 if false)
	li s4, -1 #s4 <- end condition

	fillNumPriorLoop:
		lb s5, 0(s0) #s4 <- instructionindicator[i]
		beq s4, s5, fillNumPriorEnd

		add s2, s2, s3 ##s2 <- s2 + 0 or s2 + 4, accounts for fallthrough resolve
		li s3, 0 #reset branch previous

		li s6, 1
		beq s5, s6, fillBranch
		li s6, 2
		beq s5, s6, fillTarget
		li s6, 3
		beq s5, s6, fillBranchAndTarget
		j storePrior
		
		fillBranch:
			addi s2, s2, 7
			li s3, 4
			j storePrior
		fillTarget:
			addi s2, s2, 4
			j storePrior
		fillBranchAndTarget:
			addi s2, s2, 11
			li s3, 4
			j storePrior
		
		storePrior:
		sw s2, 0(s1) #numPrior[i] = last value

		addi s0, s0, 1
		addi s1, s1, 4
		j fillNumPriorLoop
	
	fillNumPriorEnd:
	sw s4, 0(s1)
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s3, 16(sp)
	lw s4, 20(sp)
	lw s5, 24(sp)
	lw s6, 28(sp)
	lw s7, 32(sp)
	addi sp, sp, 36
ret
# -----------------------------------------------------------------------------
# fill_modifiedInstructionsArray:
#
# Description:
#  	This function is responsible for filling modifiedInstructionsArray.
#	it copies instructions from originalInstructionsArray and adds newly created ones into modifiedInstructionsArray
#	by calling insertSetupInstructions and insertResolveInstructions
#
# Arguments:
#	a0: Pointer to originalInstructionsArray
#	a1: Pointer to modifiedInstructionsArray
#	a2: Pointer to instructionIndicatorsArray
# 	a3: Pointer to numPriorInsertionsArray 
#	
# Returns:
# 	None
#
# Register Usage:
#
# -----------------------------------------------------------------------------		
fill_modifiedInstructionsArray:
	addi sp, sp, -44
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s3, 16(sp)
	sw s4, 20(sp)
	sw s5, 24(sp)
	sw s6, 28(sp)
	sw s7, 32(sp)
	sw s8, 36(sp)
	sw s9, 40(sp)
	
	mv s0, a0 #pointer to original
	mv s1, a1 #pointer to modified
	mv s2, a2 #pointer to indicator
	mv s3, a3 #pointer to start of numprior

	li s9, 0 #branch ID

	fillModifiedLoop:
		lb s5, 0(s2) #s5 <- indicator[i]
		li s4, -1
		beq s4, s5, fillModifiedEnd
		
		lw s6, 0(s0) #originalinstruction[i]
		
		li s7, 1
		beq s5, s7, insertBranch
		li s7, 2
		beq s5, s7, insertTarget
		li s7, 3
		beq s5, s7, insertTarget

		#check if instruction is a jal
		andi s4, s6, 0x7F #s4 <- opcode of instruction
		li s7, 0x6f
		beq s4, s7, insertJAL

		j insertNone
		
		insertBranch:
		mv a0, s1 #a0 <- Pointer to the location in modifiedInstructionsArray to store the sequence of setup instructions
		mv a1, s9 #a1 <- Branch id
		jal ra, insertSetupInstructions
		addi s1, s1, 28 #increment modified pointer by 28 (7 instructions)

		#get immediate
		mv a0, s6 #a0 <- branch instruction
		jal ra, getBranchImm
		
		#calculate inserted instructions
		add s8, s3, a0 #s8 <- &numprior[target] = numprior[branch] + immediate
		lw s8, 0(s8) 
		lw s7, 0(s3)
		sub s8, s8, s7 #s8 <- numprior[target] - numprior[branch]
		addi s8, s8, -4	#s8 <- subtract 4 instructions for resolve(1)
		
		#subtract setup instructions if branch
		srai s4, a0, 2 #s4 <- immediate //4
		add s4, s4, s2 #s4 <- instructionindicator[i] +/- immediate//4
		lb s4, 0(s4) #s4 <- instrunctionindicator[target]
		li s7, 3
		bne s4, s7, skipSubtractSetup
		addi s8, s8, -7
		skipSubtractSetup:
		
		slli s8, s8, 2 #s8 <- (total instructions inserted)*4 = added offset

		add a1, a0, s8 #s8 <- new immediate = immediate + added offset
		mv a0, s6
		jal ra, setBranchImm
		
		#insert branch instruction
		sw a0, 0(s1)
		addi s1, s1, 4 #increment modified pointer
		addi s9, s9, 1 #increment branch ID

		#insert resolve(-1)
		mv a0, s1
		li a1, 0
		jal ra, insertResolveInstructions
		addi s1, s1, 16 #increment modified pointer by 16 (4 instructions)
		
		j insertDone

		insertTarget:
		#insert resolve(1)
		mv a0, s1
		li a1, 1
		jal ra, insertResolveInstructions
		addi s1, s1, 16 #increment modified pointer by 16 (4 instructions)
		
		li s7, 3
		beq s5, s7, insertBranch
		
		#insert target instruction
		sw s6, 0(s1) 
		addi s1, s1, 4
			
		j insertDone

		insertJAL:
		#get immediate
		mv a0, s6 #a0 <- branch instruction
		jal ra, getJalImm
		
		#calculate inserted instructions
		add s8, s3, a0 #s8 <- &numprior[target] = numprior[branch] + immediate
		lw s8, 0(s8) 
		lw s7, 0(s3)
		sub s8, s8, s7 #s8 <- numprior[target] - numprior[branch]
		#addi s8, s8, -4	#s8 <- subtract 4 instructions for resolve(1)
		
		#subtract setup instructions if branch
		#srai s4, a0, 2 #s4 <- immediate //4
		#add s4, s4, s2 #s4 <- instructionindicator[i] +/- immediate//4
		#lb s4, 0(s4) #s4 <- instrunctionindicator[target]
		#li s7, 3
		#bne s4, s7, skipSubtractSetup2
		#addi s8, s8, -7
		skipSubtractSetup2:
		
		
		slli s8, s8, 2 #s8 <- (total instructions inserted)*4 = added offset

		add a1, a0, s8 #s8 <- new immediate = immediate + added offset
		mv a0, s6
		
		jal ra, setJalImm
		
		#insert jal instruction
		sw a0, 0(s1)
		addi s1, s1, 4 #increment modified pointer

		j insertDone

		insertNone:
		#insert instruction
		sw s6, 0(s1) 
		addi s1, s1, 4
			
		
		insertDone:
		addi s0, s0, 4 #increments originalinstruction array
		addi s2, s2, 1 #increments instruction indicator byte array
		addi s3, s3, 4 #increments num prior array
		j fillModifiedLoop
	

#for a target, the offset would be branch immediate//4 + numPriorInsertions[target] - numPriorInstructions[branch]

	fillModifiedEnd:
	li s4, -1
	sw s4, 0(s1)
	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s3, 16(sp)
	lw s4, 20(sp)
	lw s5, 24(sp)
	lw s6, 28(sp)
	lw s7, 32(sp)
	lw s8, 36(sp)
	addi sp, sp, 40
	ret
# -----------------------------------------------------------------------------
# makePrediction:
#
# Description:
#  	Makes a prediction on whether a particular branch will be taken or not taken given a branch id
#	Stores prediction in output global variable
#
# Arguments:
# 	a0: Branch id
#	
# Returns:
# 	None
#
# Register Usage:
#	
# -----------------------------------------------------------------------------			
makePrediction:

ret
# -----------------------------------------------------------------------------
# trainPredictor:
#
# Description:
#  	Trains the perceptron corresponding to the branch id stored in activeBranch.
#
# Arguments:
#	a0: Actual branch outcome (1 if taken, else -1)
#	
# Returns:
# 	None
#
# Register Usage:
#
# -----------------------------------------------------------------------------		
trainPredictor:

ret
# -----------------------------------------------------------------------------
# insertSetupInstructions (helper):
#
# Description:
#  	Creates and loads the following pre-branch setup instructions into the modified array for a given branch id:
#	addi a0, zero, BRANCH ID - load the branch id of this instruction as an argument
#	lui a1, a1, activeBranch[31:12] - provide upper half of the absolute address of the active_branch global variable
#	addi a1, zero, activeBranch[11:0] - provide lower half of the absolute address of the active_branch global variable  
#	sw a0, 0(a1) - store the branch id to the active_branch global variable
#	lui t0,  makePrediction[31:12] - provide upper half of the absolute address of the makePrediction label
#	addi t0, t0, makePrediction[11:0] - provide lower half of the absolute address of the makePrediction label
#	jalr t0 - jump to make_prediction label
#
# Arguments:
# 	a0: Pointer to the location in modifiedInstructionsArray to store the sequence of setup instructions
#	a1: Branch id
#	
# Returns:
# 	None
#
# Register Usage:
#	t0, t1: Instruction bases/ intermediate values
#	t2: leftmost 20 bits of an address
#	t3: rightmost 12 bits of an address
#	a0: address in  modifiedInstructionsArray to store instruction to
#	
# -----------------------------------------------------------------------------		
insertSetupInstructions:

	# create the addi instruction to load the branch id into a0: 0x[3 byte id]00513
	li t1, 0x00000513 # addi base for rd = a0, r1 = zero
	slli t0, a1, 20
	or t0, t1, t0
	sw t0, 0(a0)
	addi a0, a0, 4 # move to next word in the modified instructions array

	# Create lui and addi instruction combination for the activeBranch function label
	la t0, activeBranch
	srli t2, t0, 12 # cut off the rightmost 12 bits of activeBranch address for lui
	slli t3, t0, 20 # cut off the leftmost 20 bits of activeBranch address for addi

	# Check if there is a 1 in the 11 bit of t3 (the sign bit)
	li t0, 0x80000000
	and t0, t0, t3
	beqz t0, continue_active_branch

	# If there is a sign bit, modify the lui instruction so that the addition results in the correct address when the addi immediate is negative
	addi t2, t2, 1

	continue_active_branch:
	slli t2, t2, 12 #shift lui immediate into position
	li t1 0x000005b7 # lui base for rd = a1
	or t0, t1, t2 # create full lui instruction
	sw t0, 0(a0) # store lui instruction
	addi a0, a0, 4 # move to next word in the modified instructions array

	li t1, 0x00058593 # addi base for rd = a1, r1 = a1
	or t0, t3, t1 # create full addi instruction
	sw t0, 0(a0) # store addi instruction
	addi a0, a0, 4 # move to next word in the modified instructions array

	# Create store instruction to store branch id (in a0) into active_branch global variable (in a1)
	li t0, 0x00a5a023 # sw a0, 0(a1)
	sw t0, 0(a0)
	addi a0, a0, 4 # move to next word in the modified instructions array

	# Create lui and addi instruction combination for the makePrediction function label
	la t0, makePrediction
	srli t2, t0, 12 # cut off the rightmost 12 bits of makePrediction address for lui
	slli t3, t0, 20 # cut off the leftmost 20 bits of makePrediction address for addi

	# Check if there is a 1 in the 11 bit of t3 (the sign bit)
	li t0, 0x80000000
	and t0, t0, t3
	beqz t0, continue_make_prediction

	# If there is a sign bit, modify the lui instruction so that the addition results in the correct address when the addi immediate is negative
	addi t2, t2, 1

	continue_make_prediction:
	slli t2, t2, 12 #shift lui immediate into position
	li t1 0x000002b7 # lui base for rd = t0
	or t0, t1, t2 # create full lui instruction
	sw t0, 0(a0) # store lui instruction
	addi a0, a0, 4 # move to next word in the modified instructions array

	li t1, 0x00028293 # addi base for rd = t0, r1 = t0
	or t0, t3, t1 # create full addi instruction
	sw t0, 0(a0) # store addi instruction
	addi a0, a0, 4 # move to next word in the modified instructions array

	# create jalr (jump and link register) to absolute address of the makePrediction function
	li t0 0x000280e7 # jalr, t0
	sw t0, 0(a0)
	
	ret

	
# -----------------------------------------------------------------------------
# insertResolveInstructions (helper):
#
# Description:
#  	Creates and loads branch fallthrough OR branch target instructions into the modified array for a given branch id:
# 	if branch fallthrough: addi a0, zero, 0 - indicate branch not taken, OR if branch target: addi a0, zero, 1 - indicate branch taken
# 	lui t0, trainPredictor[31:12] - provide upper half of the absolute address of the trainPredictor label
# 	addi t0, t0, trainPredictor[11:0] - provide lower half of the absolute address of the trainPredictor label
# 	jalr t0 - jump to trainPredictor label
#
# Arguments:
# 	a0: Pointer to the location in modifiedInstructionsArray to store the sequence of fallthrough OR target instructions
#	a1: 0 if resolving a fallthrough or 1 if resolving a branch target
#	
# Returns:
# 	None
#
# Register Usage:
#	t0, t1: Instruction bases/ intermediate values
#	t2: leftmost 20 bits of an address
#	t3: rightmost 12 bits of an address
#	a0: address in  modifiedInstructionsArray to store instruction to
#	
# -----------------------------------------------------------------------------		
insertResolveInstructions:

	bnez a1, target_addi
	# Create addi a0, zero, -1 instruction to indicate branch not taken
	li t0, 0xfff00513 # addi a0, zero, -1
	sw t0, 0(a0)
	addi a0, a0, 4
	j end_addi

	target_addi:
	# Create addi a0, zero, 1 instruction to indicate branch taken
	li t0, 0x00100513 # addi a0, zero, 1
	sw t0, 0(a0)
	addi a0, a0, 4

	end_addi:
	# Create lui and addi instruction combination for the trainPredictor function label
	la t0, trainPredictor
	srli t2, t0, 12 # cut off the rightmost 12 bits of trainPredictor address for lui
	slli t3, t0, 20 # cut off the leftmost 20 bits of trainPredictor address for addi

	# Check if there is a 1 in the 11 bit of t3 (the sign bit)
	li t0, 0x80000000
	and t0, t0, t3
	beqz t0, continue_train_predictor

	# If there is a sign bit, modify the lui instruction so that the addition results in the correct address when the addi immediate is negative
	addi t2, t2, 1

	continue_train_predictor:
	slli t2, t2, 12 #shift lui immediate into position
	li t1 0x000002b7 # lui base for rd = t0
	or t0, t1, t2 # create full lui instruction
	sw t0, 0(a0) # store lui instruction
	addi a0, a0, 4 # move to next word in the modified instructions array

	li t1, 0x00028293 # addi base for rd = t0, r1 = t0
	or t0, t3, t1 # create full addi instruction
	sw t0, 0(a0) # store addi instruction
	addi a0, a0, 4 # move to next word in the modified instructions array

	# create jalr (jump and link register) to absolute address of the trainPredictor function
	li t0 0x000280e7 # jalr, t0
	sw t0, 0(a0)
	
	ret

# ----------------------------------------------------------------------------
# getJalImm (helper):
#
# Description:
# 	Takes a UJ-type jump instruction (jal), and extracts the sign-extended immediate.
#
# Arguments:
# 	a0: a UJ (jal) instruction word
#
# Returns:
#	a0: sign extended immediate
#
# Register Usage:
#
# -----------------------------------------------------------------------------
getJalImm:
	li t6, 0
	
	li t5, 0xF0000000
	and t0, a0, t5 #20
	srli t0, t0, 11
	or t6, t6, t0 
	
	li t5, 0x8FE00000
	and t1, a0, t5 #10:1
	srli t1, t1, 20
	or t6, t6, t1
	
	li t5, 0x00100000
	and t2, a0, t5 #11
	srli t2, t2, 9
	or t6, t6, t2
	
	li t5, 0x000FF000
	and t3, a0, t5 #19:12
	or t6, t6, t3

	mv a0, t6

	ret
# ----------------------------------------------------------------------------
# setJalImm (helper):
#
# Description:
# 	Takes an immediate value and UJ-type jal instruction and sets the immediate in the instruction.
#
# Arguments:
# 	a0: a UJ (jal) instruction word
# 	a1: the immediate value to set
#
# Returns:
#	a0: the modified jal instruction with the new immediate
#
# Register Usage:
#
# -----------------------------------------------------------------------------
setJalImm:
	li t5, 0xFFF
	and a0, a0, t5 #set immediate to 0
	
	li t5, 0x7FE
	and t0, a1, t5 #10:1
	slli t0, t0, 20
	or a0, a0, t0
	
	li t5, 0x800
	and t1, a1, t5 #11
	slli t1, t1, 9
	or a0, a0, t1
	
	li t5, 0xFF000
	and t2, a1, t5 #19:12
	or a0, a0, t2
	
	li t5, 0x00100000
	and t3, a1, t5 #20
	slli t3, t3, 11
	or a0, a0, t2

ret	
# ----------------------------------------------------------------------------
# getBranchImm (helper):
#
# Description:
# 	Takes a SB-type branch instruction and extracts the sign-extended immediate.
#
# Arguments:
# 	a0: an SB (branch) instruction word
#
# Returns:
#	a0: a sign extended immediate
#
# Register Usage:
#	t0: immediate value accumulator
#	t1: mask register
#	t2: temporary storage for masked values
#	t3: temporary storage for shifted values
# -----------------------------------------------------------------------------
getBranchImm:
	li	t0, 0		# initial immediate value
	
	li	t1, 0xF00	# mask for imm[4:1]
	and	t2, a0, t1	# get bit 1-4 for immediate value
	srli	t3, t2, 7	# put bit 1-4 in place to set
	or	t0, t0, t3	# set bit 1-4 in immediate value
	
	li	t1, 0x7E000000	# mask for imm[10:5]
	and	t2, a0, t1	# get bit 5-10 for immediate value
	srli	t3, t2, 20	# put bit 5-10 in place to set
	or	t0, t0, t3	# set bit 5-10 in immediate value
	
	li 	t1, 0x80	# mask for imm[11]
	and	t2, a0, t1	# get bit 11 for immediate value
	slli	t3, t2, 4	# put bit 11 in place to set
	or	t0, t0, t3	# set bit 11 in immediate value
	
	li 	t1, 0x80000000	# mask for imm[12]
	and	t2, a0, t1	# get bit 12 for immediate value
	srli	t3, t2, 19	# put bit 12 in place to set
	or	t0, t0, t3	# set bit 12 in immediate value
	
	srli	t2, t2, 31	# getting left most bit as a value
	beqz 	t2, getBranchImmExit # branch if left most bit is not set
	
	li	t1, 0xFFFFE000	# mask for sign extension
	or	t0, t0, t1	# sign extend immediate value if left most bit is set
	
	getBranchImmExit:
	mv	a0, t0	# sign extended immediate as return value
	ret


# ----------------------------------------------------------------------------
# setBranchImm (helper):
#
# Description:
# 	Takes an immediate value and SB-type branch instruction and sets the immediate in the instruction.
#
# Arguments:
# 	a0: an SB (branch) instruction word
# 	a1: the immediate value to set
#
# Returns:
#	a0: the modified instruction with the new immediate value
#
# Register Usage:
#	t0: immediate value accumulator
#	t1: mask register
#	t2: temporary storage for masked values
#	t3: temporary storage for shifted values
# -----------------------------------------------------------------------------
setBranchImm:
	# Clear existing immediate bits in the instruction
	li 	t1, 0xF00		# mask for imm[4:1]
	not	t1, t1		# invert mask to clear imm[4:1]
	and	a0, a0, t1	# clear imm[4:1] in instruction
	
	li 	t1, 0x7E000000	# mask for imm[10:5]
	not	t1, t1		# invert mask to clear imm[10:5]
	and	a0, a0, t1	# clear imm[10:5] in instruction
	
	li 	t1, 0x80		# mask for imm[11]
	not	t1, t1		# invert mask to clear imm[11]
	and	a0, a0, t1	# clear imm[11] in instruction
	
	li 	t1, 0x80000000	# mask for imm[12]
	not	t1, t1		# invert mask to clear imm[12]
	and	a0, a0, t1	# clear imm[12] in instruction

	# Set new immediate bits in the instruction
	li 	t1, 0x1E	# mask for imm[4:1] in immediate value
	and	t2, a1, t1	# get imm[4:1] from immediate value
	slli	t2, t2, 7	# shift to position 7-10
	or	a0, a0, t2	# set imm[4:1] in instruction
	
	li 	t1, 0x7E0	# mask for imm[10:5] in immediate value
	and	t2, a1, t1	# get imm[10:5] from immediate value
	slli	t2, t2, 20	# shift to position 25-30
	or	a0, a0, t2	# set imm[10:5] in instruction
	
	li 	t1, 0x800	# mask for imm[11] in immediate value
	and	t2, a1, t1	# get imm[11] from immediate value
	srli	t2, t2, 4	# shift to position 7
	or	a0, a0, t2	# set imm[11] in instruction
	
	li 	t1, 0x1000	# mask for imm[12] in immediate value
	and	t2, a1, t1	# get imm[12] from immediate value
	slli	t2, t2, 19	# shift to position 31
	or	a0, a0, t2	# set imm[12] in instruction
	
	ret			# return modified instruction

# ----------------------------------------------------------------------------
# printResults (helper):
#
# Description:
#	Prints the modifiedInstructionsArray, the weights for each branch, and accuracy 
#	statistics. Should be called as the final step in the solution.
#
# Arguments:
# 	a0: Pointer to modifiedInstructionsArray 
# 	a1: Max branch Id
#	a2: Total branch instructions executed
#	a3: Total correct predictions
#
# Returns:
#	None
#
# Register Usage:
#	s0-s3: Saving arguments
#	s4: patternHistoryTable
#	s5: branch id
#	t0: -1
#	f0, f1, f2, f3, fa0: floating point registers used to calculate and print branch accuracy
#	
# -----------------------------------------------------------------------------
printResults:
	addi sp, sp, -28
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw ra 24(sp)

	mv s0, a0
	mv s1, a1
	mv s2, a2
	mv s3, a3

	la a0, end_modifiedArrayStr
	jal ra, printStr

	mv a0, s0
	li a1, 1 # print the modified instructions array in hex form 
	jal ra, printIntWordArray

	la a0, end_perceptronWeights
	jal ra, printStr

	la s4, patternHistoryTable
	li s5, 0 # branch id
	print_weights_loop:
		li t0, -1
		lw s0, 0(s4) # load a perceptron
		beq t0, s0, end_print_weights_loop
		
		la a0, branchStr		
		jal ra, printStr 

		mv a0, s5
		li a7, 1 # code for print int
		ecall

		la a0, colon
		jal ra, printStr
		
		la a0, openBracket
		jal ra, printStr

		mv a0, s0
		jal ra, printWeights # call helper function in common.s

		la a0, closeBracket
		jal ra, printStr

		addi s4, s4, 4
		addi s5, s5, 1 # increase branch id
		j print_weights_loop

	end_print_weights_loop:
	
	la a0, total_branchStr
	jal ra, printStr
	
	mv a0, s2
	li a7, 1 # code for print int
	ecall # print total branches executed

	la a0, total_correctBranchStr
	jal ra, printStr

	mv a0, s3
	li a7, 1 # code for print int
	ecall # print total branches correctly predicted

	la a0, accuracyStr
	jal ra, printStr

	fcvt.s.w  f1, s3  # Convert correct predictions (numerator) to a float, store in f1
        fcvt.s.w  f2, s2  # Convert total predictions (denominator) to a float, store in f2

        # Calculate accuracy 
        fdiv.s f0, f1, f2  # Divide f1 by f2, store the result in f0
	li t0, 100
	fcvt.s.w  f3, t0  # Convert 100 to a float, store in f3
	fmul.s fa0, f3, f0 # product is the accuracy percentage
	
	li a7, 2 # code for print float 
	ecall 

	la a0, percent
	jal ra, printStr

	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	ret

# ----------------------------------------------------------------------------
# printWeights (helper):
#
# Description:
#	Prints an array or weights.
#
# Arguments:
# 	a0: Pointer to an array of weights.
#
# Returns:
#	None
#
# Register Usage:
#	s0: Pointer to the array of weights
#	s1: Iterator
#	s2: Stop condition
#	t0: Location of current weight in array
#	a0: Weight value
# -----------------------------------------------------------------------------
printWeights:

	addi sp, sp, -16
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw ra, 12(sp)
	
	mv s0, a0
	li s1, 0 # iterator
	li s2, 9 # stop condition

	print_weight_loop:

	beq s1, s2, end_print_weight_loop
	
	# load weight from weight array
	add t0, s0, s1
	lb a0, 0(t0)

	li a7, 1 # code for print int
	ecall # print the weight
	
	la a0, space
	li a7, 4 # code for print string
	ecall

	addi s1, s1, 1
	j print_weight_loop

	end_print_weight_loop:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw ra, 12(sp)
	addi sp, sp, 16

	ret

