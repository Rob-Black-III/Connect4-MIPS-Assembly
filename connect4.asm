# File:		connect4.asm
# Author:	Rob Black
# Contributors: Rob Black
#
# Description:	Project 1
#		This is an implementation of a Connect 4
#		game. 2 Player, standard ruleset.
#
#
# Name:		Constant Definitions
#		System Calls and Strings


# Constants used for syscalls
PRINT_INT	= 1	# OP Code for print int syscall
PRINT_STRING	= 4	# OP Code for print string syscall
READ_INT	= 5	# OP Code for read int syscall

	.data
	.align 2

# Data Segment for Strings and Stuff
# Define global imports and exports for Tables.
intro_msg:
	.ascii	"\n   ************************\n"
	.ascii	  "   **    Connect Four    **\n"
	.asciiz	  "   ************************\n\n"

newline:
	.asciiz "\n"

player_one_char:
	.asciiz "X"

player_two_char:
	.asciiz "O"

space:
	.asciiz " "

col_nums:
	.asciiz	"   0   1   2   3   4   5   6   \n"

outer_border_row:
	.asciiz	"+-----------------------------+\n"

inner_border_row:
	.asciiz	"|+---+---+---+---+---+---+---+|\n"

divider:
	.ascii	"|"

current_player:
	.word	1

#Standard Initial Board
board_array:
	.word	0, 0, 0, 0, 0, 0, 0
	.word	0, 0, 0, 0, 0, 0, 0
	.word	0, 0, 0, 0, 0, 0, 0
	.word	0, 0, 0, 0, 0, 0, 0
	.word	0, 0, 0, 0, 0, 0, 0
	.word	0, 0, 0, 0, 0, 0, 0

row_num_array:
	.word	0, 0, 0, 0, 0, 0, 0

col_num:
	.word 0

player_one_prompt:
	.asciiz "Player 1: select a row to place your coin (0-6 or -1 to quit):"

player_two_prompt:
	.asciiz "Player 2: select a row to place your coin (0-6 or -1 to quit):"

err_illegal_col_num:
	.asciiz "Illegal column number.\n"

err_full_col:
	.asciiz "Illegal move, no more room in that column.\n"

player_one_win:
	.asciiz "Player 1 wins!\n"

player_two_win:
	.asciiz "Player 2 wins!\n"

tie:
	.asciiz "The game ends in a tie.\n"

player_one_quit:
	.asciiz "Player 1 quit.\n"

player_two_quit:
	.asciiz "Player 2 quit.\n"

# Text Segment for Code. Starts at main entry point.
	.text		# Program code
	.align 2	# Word align code
	.globl main	# Global label for main


#
# Name:		MAIN PROGRAM
#
# Description	Main logic for the program
#
#		This is the driver program for Connect 4.
#		Starts the game_loop, after backing up
#		and restoring the stack. 
main:
A_FRAMESIZE = 36	# 4 + Last Register OffsetSaved
	# 
	# Backup Stack.
	# Save $ra and S registers
	#
	addi	$sp, $sp, -A_FRAMESIZE
	sw	$ra, -4+A_FRAMESIZE($sp)
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	# Print Welcome Message
	la	$a0, intro_msg
	jal	print_string

	# Print the board
	jal	game_loop_start
	
	# Restore stack
	j	end

end:
	# 
	# Increment Stack.
	# Restore $ra and S registers
	#
	lw	$ra, -4+A_FRAMESIZE($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, A_FRAMESIZE

	# Exit Program
	jr	$ra

#
# Name:		game_loop
#
# Description	Loop for the game, which spans the life of the game.
#
#		This loop prints the board, asks for input, and checks
#		for win conditions.
game_loop_start:
	# 
	# Backup Stack.
	# Save $ra and S registers
	#
	addi	$sp, $sp, -A_FRAMESIZE
	sw	$ra, -4+A_FRAMESIZE($sp)
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	jal	print_board

	j	game_loop

game_loop:
	# Prompt the user (and handle input)
	# Write input to board or kick out
	jal	handle_input_col

	# Print the current board
	jal	print_board

	# Check the current player (either 1 or 2)
	lw	$s0, current_player

	# Check for a Win/Tie
	jal	check_game_complete

	# Switch to the other player
	li	$s1, 1
	li	$s2, 2
	beq	$s0, $s2, set_to_player_1
	beq	$s0, $s1, set_to_player_2

set_to_player_1:
	sw	$s1, current_player
	j	game_loop

set_to_player_2:
	sw	$s2, current_player
	j	game_loop

game_loop_end:	
	# 
	# Increment Stack.
	# Restore $ra and S registers
	#
	lw	$ra, -4+A_FRAMESIZE($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, A_FRAMESIZE

	# Exit Program
	jr	$ra

#
# Name:		print_board
#
# Description	Prints the internal array in an aesthetically
#		pleasing format.
#
#		Prints alternating data and non data rows.
print_board:
	# 
	# Backup Stack.
	# Save $ra and S registers
	#
	addi	$sp, $sp, -A_FRAMESIZE
	sw	$ra, -4+A_FRAMESIZE($sp)
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	la	$a0, col_nums
	jal	print_string

	la	$a0, outer_border_row
	jal	print_string

	li	$s0, 13			# 12 Rows to print, exit on 13
	li	$s1, 0			# Current Data Row Offset as bits
	la	$s3, board_array
	jal	print_board_loop_start

	la	$a0, outer_border_row
	jal	print_string

	la	$a0, col_nums
	jal	print_string

	la	$a0, newline
	jal	print_string

	# 
	# Increment Stack.
	# Restore $ra and S registers
	#
	lw	$ra, -4+A_FRAMESIZE($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, A_FRAMESIZE

	# Exit Program
	jr	$ra

print_board_loop_start:
	# Backup the Stack
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	# Zero out the row counter register for beq 13
	move	$t0, $zero	

	j	print_board_loop

print_board_loop:
	beq	$t0, $s0, print_board_loop_end

	# Set t3 back to zero
	move	$t3, $zero

	# Check Parity and Branch Accordingly
	andi	$t1, $t0, 1
	beq	$t1, $zero, print_non_data_row
	bne	$t1, $zero, print_data_row

# IF
print_non_data_row:
	# Print Inner Border Row (No Data)
	la	$a0, inner_border_row
	jal	print_string
	j	print_board_loop_rest

# ELSE
print_data_row:
	# Print Data Row
	la	$a0, divider
	jal	print_string

	move	$t3, $zero
	li	$t2, 7
	j	print_data_row_loop

print_data_row_loop:
	beq	$t3, $t2, print_data_row_end

	# First Divider
	la	$a0, divider
	jal	print_string

	# Space
	la	$a0, space
	jal	print_string

	# Data
	move	$t7, $zero	# Zero out the temp register
	add	$t7, $s1, $s1	# Turn Cell Index into a bit offset
	add	$t7, $t7, $t7
	add	$t7, $s3, $t7	# Add Offset to Board Base Address
	lw	$t6, 0($t7)	# Load and Print

	move	$a0, $t6
	jal	int_to_c4_char
	#jal	print_int

	# Space
	la	$a0, space
	jal	print_string

	# Increment the Cell and Offset Counters (Local and Global)
	addi	$t3, $t3, 1
	addi	$s1, $s1, 1

	j	print_data_row_loop

#
# Name:		int_to_c4_char
#
# Description	Converts a backend interger representation
#		to the Connect 4 character representation
#
#		0 becomes space, 1 becomes x, and 2 becomes 0.
#
#		a0 is integer representing a player
int_to_c4_char:
	# 
	# Backup Stack.
	# Save $ra and S registers
	#
	addi	$sp, $sp, -A_FRAMESIZE
	sw	$ra, -4+A_FRAMESIZE($sp)
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	li	$s0, 0
	li	$s1, 1
	li	$s2, 2

	beq	$a0, $s0, print_space_char
	beq	$a0, $s1, print_player_one_char
	beq	$a0, $s2, print_player_two_char

print_space_char:
	la	$a0, space
	jal	print_string
	j	int_to_c4_char_end

print_player_one_char:
	la	$a0, player_one_char
	jal	print_string
	j	int_to_c4_char_end

print_player_two_char:
	la	$a0, player_two_char
	jal	print_string
	j	int_to_c4_char_end

int_to_c4_char_end:
	# 
	# Increment Stack.
	# Restore $ra and S registers
	#
	lw	$ra, -4+A_FRAMESIZE($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, A_FRAMESIZE

	# Exit Program
	jr	$ra

print_data_row_end:
	# Print Data Row End
	la	$a0, divider
	jal	print_string

	# Print Data Row End
	la	$a0, divider
	jal	print_string

	la	$a0, newline
	jal	print_string

	j	print_board_loop_rest

print_board_loop_rest:
	addi	$t0, $t0, 1		# Increment Row Count
	j	print_board_loop	# Run another loop iteration

print_board_loop_end:
	# Restore Stack and Exit Subroutine
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

#
# Name:		handle_input_col
#
# Description	Handles all input for the player. Includes exiting 
#		the game, handling invalid input, and places a token
#		in the corresponding valid column inputted.
handle_input_col:
	# 
	# Backup Stack.
	# Save $ra and S registers
	#
	addi	$sp, $sp, -A_FRAMESIZE
	sw	$ra, -4+A_FRAMESIZE($sp)
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	# Check the current player (either 1 or 2)
	lw	$s0, current_player

	# Get the current player (CURRENT_PLAYER Global Variable)
	li	$s1, 1	# Constant for Player 1
	li	$s2, 2	# Constant for Player 2

	beq	$s0, $s1, handle_input_player_one
	beq	$s0, $s2, handle_input_player_two
	
	# Not supposed to happen
	j	handle_input_end

# IF Player 1 is Current Player
handle_input_player_one:
	la	$a0, player_one_prompt
	jal	print_string

	j	handle_input_process

# IF Player 2 is Current Player
handle_input_player_two:
	la	$a0, player_two_prompt
	jal	print_string

	j	handle_input_process

#
# Driver program for program described above
#
handle_input_process:

	# Read Integer for Col Index
	jal	read_int
	move	$s3, $v0

	li	$t0, -1		# Check for exit input
	li	$t1, 1		# Check for less than 1
	li	$t2, 6		# Check for greater than 6

	beq	$s3, $t0, quit_game		# If -1, call exit subroutine

	slt	$t4, $s3, $zero			# IF input < zero
	beq	$t4, $t1, illegal_col_input	# Throw illegal_col

	sgt	$t4, $s3, $t2			# IF input < zero
	beq	$t4, $t1, illegal_col_input	# Throw illegal_col

	# Get Board Array Base Address
	la	$s4, board_array

	# Get Height Array Base Address
	la	$s5, row_num_array

	# Load Constants for Equation
	# 7 * (5 - height) + col
	li	$s6, 7
	li	$s7, 5

	# Zero out the t registers used
	move	$t0, $zero
	move	$t1, $zero	
	move	$t2, $zero
	move	$t3, $zero
	move	$t4, $zero
	move	$t5, $zero

	# Get corresponding height at above offset
	move	$t0, $s3		# Store col index as temp
	move	$t1, $s5		# Store heights array base address as temp

	add	$t0, $t0, $t0		# Convert from byte --> bit offset
	add	$t0, $t0, $t0

	add	$t2, $t0, $t1		# Add row base array to bit offset of col
	lw	$t3, 0($t2)		# Load the height[col] as an integer	

	# IF Col is Full, Branch to retry
	li	$t0, 6			# Col Height
	beq	$t3, $t0, full_col_input

	# Plug Numbers into the Equation to get byte offset
	sub	$t4, $s7, $t3		# 5 - height
	mul	$t0, $s6, $t4		# 7 * (5 - height)
	add	$t0, $t0, $s3		# 7 * (5 - height) + col

	# Incement Heights Array
	addi	$t3, $t3, 1
	sw	$t3, 0($t2)

	# Convert byte offset to bit offset and store in board array
	add	$t5, $t0, $t0		# Convert column number and heights to bit offset
	add	$t5, $t5, $t5
	add	$t6, $s4, $t5		# Combine base address and offset

	# Store the current player in the array 
	# s4 is address of array
	lw	$t7, current_player
	sw	$t7, 0($t6)		# Store the piece at the appropriate place in the array	

	# Print newline
	la	$a0, newline
	jal	print_string

	# Store number in array
	j	handle_input_end

illegal_col_input:
	la	$a0, err_illegal_col_num
	jal	print_string

	# 
	# Increment Stack.
	# Restore $ra and S registers
	#
	lw	$ra, -4+A_FRAMESIZE($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, A_FRAMESIZE

	j	handle_input_col

full_col_input:
	la	$a0, err_full_col
	jal	print_string

	# 
	# Increment Stack.
	# Restore $ra and S registers
	#
	lw	$ra, -4+A_FRAMESIZE($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, A_FRAMESIZE

	j	handle_input_col

#
# Name:		quit_game
#
# Description	Prints a message that the current player quit
#		the game.
quit_game:
	beq	$s0, $s1, quit_game_player_one
	beq	$s0, $s2, quit_game_player_two
	
quit_game_player_one:
	la	$a0, player_one_quit
	jal	print_string

	j	exit

quit_game_player_two:
	la	$a0, player_two_quit
	jal	print_string

	j	exit

handle_input_end:
	# 
	# Increment Stack.
	# Restore $ra and S registers
	#
	lw	$ra, -4+A_FRAMESIZE($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, A_FRAMESIZE

	# Exit Program
	jr	$ra

#
# Name:		check_game_complete
#
# Description	Checks if a game is complete. 
#
#		Checks for a tie or various possible win cases
#		in all directions
check_game_complete:
	# 
	# Backup Stack.
	# Save $ra and S registers
	#
	addi	$sp, $sp, -A_FRAMESIZE
	sw	$ra, -4+A_FRAMESIZE($sp)
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	# Zero out the temp registers (in case i forget later)
	move	$t0, $zero
	move	$t1, $zero
	move	$t2, $zero
	move	$t3, $zero
	move	$t4, $zero
	move	$t5, $zero
	move	$t6, $zero
	move	$t7, $zero

	# Put some inital data in the s registers (use later)
	lw	$s0, current_player
	la	$s1, board_array	# 
	li	$s2, 41		# Number of Cells in Board (0 Index)
	move	$s3, $zero	# Max Row Index
	move	$s4, $zero	# Max Col Index
	li	$s5, 4		# Number of Cells to check for win

	jal	check_tie

	# Cell offset to next cell
	# +04 = Horizontal Right
	# +28 = Vertical Down
	# +32 = Down Right
	# -24 = Up Right

	# Check Horizontal Right
	li	$a0, 5			# MAX BASE ROW CHECKED
	li	$a1, 3			# MAX COL CHECKED
	li	$a2, 4			# Cell offset to next cell
	li	$a3, 0			# MIN ROW
	jal	check_win

	# Check Vertical Down
	li	$a0, 2			# MAX BASE ROW CHECKED
	li	$a1, 6			# MAX COL CHECKED
	li	$a2, 28			# Cell offset to next cell
	li	$a3, 0			# MIN ROW
	jal	check_win

	# Check Down Right
	li	$a0, 2			# MAX BASE ROW CHECKED
	li	$a1, 3			# MAX COL CHECKED
	li	$a2, 32			# Cell offset to next cell
	li	$a3, 0			# MIN ROW
	jal	check_win

	# Check Up Right
	li	$a0, 5			# MAX BASE ROW CHECKED
	li	$a1, 3			# MAX COL CHECKED
	li	$a2, -24		# Cell offset to next cell
	li	$a3, 3			# MIN ROW
	jal	check_win

	# 
	# Increment Stack.
	# Restore $ra and S registers
	#
	lw	$ra, -4+A_FRAMESIZE($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, A_FRAMESIZE

	# Exit Program
	jr	$ra

#
# Name:		check_tie
#
# Description	Checks for a tie, in the game.
#
#		A tie occurs when the board has no remaining
#		zeros in the underlying data structure
#
check_tie:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	move	$t0, $zero
	j	check_tie_loop

check_tie_loop:
	# Iterate through all the squares
	bgt	$t0, $s2, game_over_tie

	move	$t1, $zero	# Zero out the offset
	add	$t1, $t0, $t0	# Convert index to offset
	add	$t1, $t1, $t1

	add	$t2, $s1, $t1	# Add offset to board_array
	lw	$t3, 0($t2)

	# Exit condtion - break if 0 found (empty square)
	beq	$t3, $zero, check_tie_end

	addi	$t0, $t0, 1
	j	check_tie_loop

game_over_tie:
	# Print Tie Message
	la	$a0, tie
	jal print_string
	j	exit

check_tie_end:
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4

	jr	$ra

#
# Name:		check_win
#
# Description	Checks if a player one with corresponding paramters.
#
#
#		These parameters allow the user to change the direction,
#		and base array positions to check various combinations
#		of win conditions.
#
#		a0 - Max Rows to Check
#		a1 - Max Cols to Check
#		a2 - Offset to check in (direction difference destination)
#		a3 - Min Row (starting row)
check_win:
	# 
	# Backup Stack.
	# Save $ra and S registers
	#
	addi	$sp, $sp, -A_FRAMESIZE
	sw	$ra, -4+A_FRAMESIZE($sp)
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)

	move	$t0, $zero	# Row Loop counter
	move	$t1, $zero	# Col Loop Counter
	move	$t2, $zero	# Used for offse calculation
	move	$t3, $zero	# Current Cell
	move	$t4, $zero	# Adjacency Iteration Counter
	move	$t5, $zero	# Adjacency Counter = 4 win
	move	$t6, $zero
	move	$t7, $zero

	#s3 = row
	#s4 = col
	move	$s3, $a0	# (0-5 rows to check)
	move	$s4, $a1	# (0-3 cols to check)
	move	$t0, $a3	# MIN ROW
	#li	$s3, 5		# (0-5 rows to check)
	#li	$s4, 3		# (0-3 cols to check)
	j	check_win_row_loop

check_win_row_loop:
	bgt	$t0, $s3, check_win_exit
	addi	$t0, $t0, 1	# row++
	move	$t1, $zero	# resets col
	j	check_win_col_loop

check_win_col_loop:
	bgt	$t1, $s4, check_win_row_loop
	addi	$t0, $t0, -1	# Decrement Row for Calculation
	
	#Calculation for index
	# 7 * row + col
	li	$t2, 7
	mul	$t2, $t2, $t0
	add	$t2, $t2, $t1

	# Convert to offset and add to board_array
	add	$t2, $t2, $t2
	add	$t2, $t2, $t2
	add	$t2, $t2, $s1
	lw	$t3, 0($t2)	# Base Cell used for adjacency calculation

	move	$t4, $zero	# iteration counter
	move	$t5, $zero	# Adjacency Counter 4 = win
	j	check_adjacent

check_adjacent:
	beq	$t4, $s5, check_win_col_loop_rest

	# If this cell is current player cell, increment
	beq	$s0, $t3, increment_adjacency
	j	check_adjacent_rest
	
increment_adjacency:
	addi	$t5, $t5, 1
	j	check_adjacent_rest

check_adjacent_rest:
	# If this cell makes 4, branch to win
	beq	$t5, $s5, game_over_win

	# Increment Cell Horizontally + 1
	add	$t2, $t2, $a2	# Change here for other direction was 4
	lw	$t3, 0($t2)

	# Increment Iteraton Counter
	addi	$t4, $t4, 1
	j	check_adjacent

check_win_col_loop_rest:
	addi	$t0, $t0, 1	# Put row back after Calculation
	addi	$t1, $t1, 1	# col ++
	j	check_win_col_loop

check_win_exit:
	# 
	# Increment Stack.
	# Restore $ra and S registers
	#
	lw	$ra, -4+A_FRAMESIZE($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, A_FRAMESIZE

	# Exit Subroutine
	jr	$ra
#
# Name:		game_over_win
#
# Description	Prints a win message based on the player who one
game_over_win:
	li	$t0, 1
	li	$t1, 2

	la	$t2, current_player	
	lw	$t2, 0($t2)

	beq	$t0, $t2, game_over_win_player_one
	beq	$t0, $t2, game_over_win_player_two

game_over_win_player_one:
	# Print P1 Win Message
	la	$a0, player_one_win
	jal print_string
	j	exit

game_over_win_player_two:
	# Print P2 Win Message
	la	$a0, player_two_win
	jal print_string
	j	exit
#
# System Call to exit the program cleanly.
#


exit:	
	# Syscall to Quit Game
	li	$v0, 10
	syscall

#
# Various helper functions below, called throughout the program.
#

print_int:
	li	$v0, PRINT_INT
	syscall
	jr	$ra

print_string:
	li	$v0, PRINT_STRING
	syscall
	jr	$ra

read_int:
	li	$v0, READ_INT
	syscall
	jr	$ra
