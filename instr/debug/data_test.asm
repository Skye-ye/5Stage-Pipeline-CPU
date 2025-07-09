# data_test.asm - Test program with data section similar to morse program
# This tests if the data section is causing PC corruption issues

.text
.globl _start

_start:
    # Set up stack pointer (same as morse program)
    li sp, 0x0C00
    
    # Test 1: Access data section (similar to morse program accessing morse table)
    la t0, test_data      # Load address of data section
    lw t1, 0(t0)          # Load first word from data section
    lw t2, 4(t0)          # Load second word
    lw t3, 8(t0)          # Load third word
    
    # Test 2: Function call while accessing data section
    jal ra, data_function
    
    # Test 3: Stack operations with data section access
    addi sp, sp, -16      # Allocate stack space
    la t0, test_data      # Load data address again
    lw t1, 12(t0)         # Load from data section
    sw t1, 0(sp)          # Store to stack
    sw t1, 4(sp)          # Store to stack
    lw t2, 0(sp)          # Load from stack
    lw t3, 4(sp)          # Load from stack
    addi sp, sp, 16       # Deallocate stack
    
    # Test 4: Complex function call with large stack frame (like morse main)
    addi sp, sp, -176     # Same stack allocation as morse main
    
    # Copy data from data section to stack (similar to morse main)
    la t0, test_data      # Load base address
    lw a0, 0(t0)          # Load data
    lw a1, 4(t0)
    lw a2, 8(t0)
    lw a3, 12(t0)
    lw a4, 16(t0)
    
    # Store to stack (similar to morse main pattern)
    sw a0, 136(sp)        # Same offsets as morse program
    sw a1, 140(sp)
    sw a2, 144(sp)
    sw a3, 148(sp)
    sw a4, 152(sp)
    
    # Call function that accesses both data section and stack
    jal ra, complex_function
    
    # Restore stack
    addi sp, sp, 176
    
    # Test 5: Byte access to data section (like morse program)
    la t0, byte_data
    lbu t1, 0(t0)         # Load byte (unsigned)
    lbu t2, 1(t0)         # Load next byte
    lbu t3, 2(t0)         # Load third byte
    
    # Infinite loop - should stay here if no corruption
halt:
    j halt

data_function:
    # Function that accesses data section
    addi sp, sp, -8       # Small stack frame
    sw ra, 4(sp)          # Save return address
    sw s0, 0(sp)          # Save s0
    
    # Access data section multiple times
    la s0, test_data
    lw t0, 0(s0)          # Load from data section
    lw t1, 20(s0)         # Load from different offset
    
    # Store back to memory
    li t2, 0x1000         # Data memory address
    sw t0, 0(t2)          # Store to dmem
    sw t1, 4(t2)          # Store to dmem
    
    # Restore and return
    lw s0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

complex_function:
    # Function with nested calls and data access
    addi sp, sp, -16      # Stack frame
    sw ra, 12(sp)         # Save return address
    sw s0, 8(sp)          # Save s0
    sw s1, 4(sp)          # Save s1
    sw s2, 0(sp)          # Save s2
    
    # Access data from stack (copied earlier)
    lw s0, 136(sp)        # Load from stack (note: sp offset changed due to this function's frame)
    lw s1, 140(sp)
    
    # Access original data section
    la s2, test_data
    lw t0, 0(s2)
    lw t1, 4(s2)
    
    # Call nested function
    jal ra, nested_data_function
    
    # More data operations
    la t0, byte_data
    lbu t1, 0(t0)
    lbu t2, 1(t0)
    
    # Restore and return
    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

nested_data_function:
    # Nested function that also accesses data
    la t0, test_data
    lw t1, 0(t0)
    lw t2, 8(t0)
    lw t3, 16(t0)
    
    # Store to data memory
    li t4, 0x1010
    sw t1, 0(t4)
    sw t2, 4(t4)
    sw t3, 8(t4)
    
    ret

# Data section - similar to morse program's morse table
.data
test_data:
    .word 0x12345678      # Test data similar to morse table
    .word 0x9ABCDEF0
    .word 0x11111111
    .word 0x22222222
    .word 0x33333333
    .word 0x44444444
    .word 0xDEADBEEF
    .word 0xCAFEBABE
    .word 0x55555555
    .word 0x66666666

byte_data:
    .byte 0x41, 0x42, 0x43, 0x44    # 'A', 'B', 'C', 'D'
    .byte 0x45, 0x46, 0x47, 0x48    # 'E', 'F', 'G', 'H'
    .byte 0x00                       # Null terminator

.align 4
padding_data:
    .word 0x00000000
    .word 0x00000000