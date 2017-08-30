#############################################################################################
#
# Adam Fish
# COMP 541
# Apr 12, 2017
#
# This is a MIPS program that which lets you draw basic shapes and lines on the VGA display.
#
# This program assumes the memory-IO map introduced in class specifically for the final
# projects.  In MARS, please select:  Settings ==> Memory Configuration ==> Default.
#
#############################################################################################


.data 0x10010000 			# Start of data memory
a_sqr:	.space 4
a:	.word 3

.text 0x00400000			# Start of instruction memory
main:
	lui	$sp, 0x1001		# Initialize stack pointer to the 64th location above start of data
	ori 	$sp, $sp, 0x0100	# top of the stack is the word at address [0x100100fc - 0x100100ff]	
	li	$a1, 20			# initialize to middle screen col (X=20)
	li	$a2, 15			# initialize to middle screen row (Y=15)
	li	$s0, 2			# initialize the color to blue
	li	$s1, 0			# start with toggle off

animate_loop:	
	add	$a0, $0, $s0
	beq 	$s1, 1, skip
	jal	putChar_atXY 		# $a0 is char, $a1 is X, $a2 is Y
	li	$a0, 20			# pause for 1/5 second
	jal	pause
	j	key_loop
	
skip:
	jal	getChar_atXY
	addi	$a0, $0, 4
	jal	putChar_atXY
	addi	$a0, $0, 10			# pause for 1/10 second
	jal	pause
	add	$a0, $0, $v0
	jal	putChar_atXY
	addi	$a0, $0, 10			# pause for 1/10 second
	jal	pause

	#############################################################################################
	#
	# Key loop is used to determine the key that was pressed on the keyboard an do the appropiate
	# command.
	#
	#############################################################################################
	
key_loop:	
	jal 	get_key			# get a key (if available)
	beq	$v0, $0, no_key		# 0 means no valid key
	
key1:
	bne	$v0, 1, key2
	addi	$a1, $a1, -1 		# move left
	slt	$1, $a1, $0		# make sure X >= 0
	beq	$1, $0, animate_loop
	li	$a1, 0			# else, set X to 0
	j	animate_loop

key2:
	bne	$v0, 2, key3
	addi	$a1, $a1, 1 		# move right
	slti	$1, $a1, 40		# make sure X < 40
	bne	$1, $0, animate_loop
	li	$a1, 39			# else, set X to 39
	j	animate_loop

key3:
	bne	$v0, 3, key4
	addi	$a2, $a2, -1 		# move up
	slt	$1, $a2, $0		# make sure Y >= 0
	beq	$1, $0, animate_loop
	li	$a2, 0			# else, set Y to 0
	j	animate_loop

key4:
	bne	$v0, 4, key5		# read key again
	addi	$a2, $a2, 1 		# move down
	slti	$1, $a2, 30		# make sure Y < 30
	bne	$1, $0, animate_loop
	li	$a2, 29			# else, set Y to 29
	j	animate_loop

key5:
	bne	$v0, 5, key6		# read key again
	beq	$s1, 1, key7
	addi	$s0, $s0, 1
	bne	$s0, 4, animate_loop
	add	$s0, $0, $0
	j	animate_loop

key6:
	bne	$v0, 6, key7
	beq	$s1, 1, key7
	
	add	$t3, $0, $a1
	add	$t4, $0, $a2
	add	$t5, $0, $a0
	
	li 	$t1, 0			# col number to 0
	li 	$t2, 0			# row number to 0
loop:
	add 	$a0, $0, $s0		# color
	add	$a1, $0, $t1		# $a1 = col
	add	$a2, $0, $t2		# $a2 = row
	jal	putChar_atXY
	addi	$t1, $t1, 1		# col = col + 1
	bne	$t1, 40, loop	
	addi	$t1, $0, 0		# set col to 0
	addi	$t2, $t2, 1		# row = row + 1
	bne	$t2, 30, loop
	
	add	$a1, $0, $t3
	add	$a2, $0, $t4
	add	$a0, $0, $t5
	jal	putChar_atXY
	
	j	animate_loop
	
key7:
	bne	$v0, 7, key8
	beq	$s1, 1,	toggle_on	# check if already toggled
	addi	$s1, $0, 1		# turn toggle on
	addi	$s3, $0, 1
	j	animate_loop
	
toggle_on:

	addi	$s1, $0, 0		# turn toggle off
	add	$a0, $0, $s0
	addi	$s3, $0, 0
	jal	putChar_atXY
	jal	unping
	j	animate_loop	
	
key8:
	bne	$v0, 8, key_loop	
	bne	$s1, 1, key_loop	# check for toggle on
	beq	$s3, $0, point_2	# check if point one has been set
	
	addi	$s3, $0, 0		# set point one
	add	$s4, $0, $a1		# save x0 to s4
	add	$s5, $0, $a2		# save y0 to s5
	
	jal	ping			# ping to confirm point one
	j	animate_loop		# return to key_loop

	#############################################################################################
	#
	# Keys 7/8 are used to set the endpoints when drawing lines using the Bresenham algorithm
	# The following block outlines the algorithm with C-like comments.
	#
	#############################################################################################
	
	
point_2:
	addi	$s3, $0, 1		# set point one off
	add	$s6, $0, $a1		# save x1 to s6
	add	$s7, $0, $a2		# save y1 to s7
	
	add	$k0, $0, $s6		# back up x1
	add	$k1, $0, $s7		# back up y1
	
	addi	$t0, $0, 0		# t0 = false
	
	sub	$t1, $s4, $s6		# t1 = x0 - x1
	add	$a0, $0, $t1		# move t1 to a0
	jal	my_abs			# find abs(t1)
	add	$t1, $0, $v1		# move abs(t1) into t1
	
	sub	$t2, $s5, $s7		# t2 = y0 - y1
	add	$a0, $0, $t2		# move t2 to a0
	jal	my_abs			# find abs(t2)
	add	$t2, $0, $v1		# move abs(t2) into t2

	slt	$t3, $t1, $t2		# test if abs(t1) < abs(t2)
	beq	$t3, $0, not_steep	# skip if not true
	
	add	$t3, $0, $s4		# swap x0 and y0
	add	$s4, $0, $s5
	add	$s5, $0, $t3
	
	add	$t3, $0, $s6		# swap x1 and y1
	add	$s6, $0, $s7
	add	$s7, $0, $t3
	
	addi	$t0, $0, 1		# steep = true
	
not_steep:
	
	slt	$t3, $s6, $s4		# test if x1 < x0
	beq	$t3, $0, no_invert	# skip if not true
	
	add	$t3, $0, $s4		# swap x0 and x1
	add	$s4, $0, $s6
	add	$s6, $0, $t3
	
	add	$t3, $0, $s5		# swap y0 and y1
	add	$s5, $0, $s7
	add	$s7, $0, $t3
	
no_invert:

	sub	$t1, $s6, $s4		# t1 = dx
	sub	$t2, $s7, $s5		# t2 = dy
	
	add	$a0, $0, $t2		# move dy to a0
	jal	my_abs			# find abs(dy)
	add	$t3, $0, $v1		# move abs(dy) to t3
	sll	$t3, $t3, 1		# t3 = 2 * abs(dy)
	
	add	$t4, $0, $0		# t4 = 0
	
	add	$t5, $0, $s4		# t5 = x
	add	$t6, $0, $s5		# t6 = y
	
	slt	$t8, $s5, $s7		# test if y0 < y1
	beq	$t8, $0, y_branch
	
	addi	$t8, $0, 1		# sx = 1
	j	for_loop
	
y_branch:
	
	addi	$t8, $0, -1		# sx = -1
	
for_loop:

	beq	$t5, $s6, end_loop
	slt	$t7, $t5, $s6		# test if x < x1
	beq	$t7, $0, end_loop	# branch if not true

	
	beq	$t0, $0, else_j		# branch if not steep
	
	add	$a1, $0, $t6
	add	$a2, $0, $t5
	add	$a0, $0, $s0
	
	jal	putChar_atXY
	
	j	end_if
	
else_j:
	
	add	$a1, $0, $t5
	add	$a2, $0, $t6
	add	$a0, $0, $s0
	
	jal	putChar_atXY

end_if:
	
	add	$t4, $t4, $t3		# error2 += derror2
	
	slt	$t7, $t1, $t4		# check if dx < error2
	beq	$t7, $0, no_error	# branch if false
	
	sll	$t7, $t1, 1		# t7 = dx * 2
	sub	$t4, $t4, $t7		# error2 -= dx * 2
	
	add	$t6, $t6, $t8		# y += sy
	
no_error:
	
	addi	$t5, $t5, 1		# x++
	j	for_loop
	
end_loop:

	add	$a1, $0, $k0
	add	$a2, $0, $k1
	
	jal	unping
	j	animate_loop
	
no_key:
	bne	$s1, 1, key_loop
	jal	getChar_atXY
	addi	$a0, $0, 4
	jal	putChar_atXY
	addi	$a0, $0, 10		# pause for 1/10 second
	jal	pause
	add	$a0, $0, $v0
	jal	putChar_atXY
	addi	$a0, $0, 10		# pause for 1/10 second
	jal	pause
	j	key_loop
	
					
	###############################
	# END using infinite loop     #
	###############################
	
				# program won't reach here, but have it for safety
end:
	j	end          	# infinite loop "trap" because we don't have syscalls to exit


######## END OF MAIN #################################################################################


.include "procs_board.asm"
