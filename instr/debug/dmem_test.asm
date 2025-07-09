# dmem_test.asm - Test data memory operations and stack behavior
# This program tests if dmem operations are causing PC corruption

.text
.globl _start

_start:
    # Set up stack pointer (same as morse program)
    li sp, 0x0C00
    
    # Test 1: Basic data memory operations
    li t0, 0x1000        # Data memory base address
    li t1, 0xDEADBEEF    # Test pattern
    sw t1, 0(t0)         # Store word
    lw t2, 0(t0)         # Load word back
    
    # Test 2: Stack operations (push/pop)
    addi sp, sp, -4      # Allocate stack space
    li t3, 0x12345678    # Test value
    sw t3, 0(sp)         # Push to stack
    lw t4, 0(sp)         # Pop from stack
    addi sp, sp, 4       # Deallocate stack space
    
    # Test 3: Function call with return address
    jal ra, test_function
    
    # Test 4: More complex stack operations
    addi sp, sp, -16     # Allocate 16 bytes
    li t5, 0xCAFEBABE    # Test data
    sw t5, 0(sp)         # Store at sp+0
    sw t5, 4(sp)         # Store at sp+4  
    sw t5, 8(sp)         # Store at sp+8
    sw t5, 12(sp)        # Store at sp+12
    
    # Read back
    lw t6, 0(sp)         # Load from sp+0
    lw s0, 4(sp)         # Load from sp+4
    lw s1, 8(sp)         # Load from sp+8
    lw s2, 12(sp)        # Load from sp+12
    addi sp, sp, 16      # Deallocate
    
    # Test 5: Simulate morse program's stack usage pattern
    addi sp, sp, -176    # Same as morse main function
    li a0, 0x2FC         # Similar to morse program
    sw a0, 136(sp)       # Store at offset 136 (like morse)
    sw a0, 140(sp)       # Store at offset 140
    sw a0, 144(sp)       # Store at offset 144
    
    # Call nested function (similar to morse)
    jal ra, nested_function
    
    # Clean up
    addi sp, sp, 176     # Restore stack
    
    # Infinite loop - should stay here if no corruption
halt:
    j halt

test_function:
    # Simple function that returns
    li a0, 0x11111111    # Load test value
    ret                  # Return to caller

nested_function:
    # Function that uses stack and calls another function
    addi sp, sp, -8      # Allocate local stack
    sw ra, 4(sp)         # Save return address
    sw s0, 0(sp)         # Save s0
    
    # Do some work
    li s0, 0x22222222    # Test value
    li t0, 0x1004        # Load address
    sw s0, 0(t0)         # Store to dmem
    lw s0, 0(t0)         # Load back
    
    # Call another function
    jal ra, leaf_function
    
    # Restore and return
    lw s0, 0(sp)         # Restore s0
    lw ra, 4(sp)         # Restore return address
    addi sp, sp, 8       # Deallocate stack
    ret                  # Return

leaf_function:
    # Leaf function - no stack operations
    li t0, 0x33333333    # Test value
    li t1, 0x1008        # Load address
    sw t0, 0(t1)         # Store to dmem
    lw t1, 0(t1)         # Load back
    ret                  # Return

# Add some padding to make sure we don't have address issues
.align 4
padding:
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000