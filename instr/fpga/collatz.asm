            lui		x31, 0xFFFF0
main:       lw      x2, 0x004(x31)  # load n from SW[14:10]
            srli    x2, x2, 10
            andi    x2, x2, 0x01F
            jal     x3, collatz
            jal     x0, main
collatz:    addi    x5, x0, 0       # steps = 0
loop:       addi    x6, x0, 1
            beq     x2, x6, done    # if current == 1, done
            andi    x6, x2, 1       # x6 = current & 1
            beq     x6, x0, even    # if even, divide by 2
            add     x7, x2, x2      # x7 = 2n
            add     x2, x7, x2      # x2 = 3n
            addi    x2, x2, 1       # x2 = 3n + 1
            jal     x0, continue
even:       srli    x2, x2, 1       # x2 = current >> 1
continue:   addi    x5, x5, 1       # steps++
            jal     x0, loop
done:       sw      x5, 0x00C(x31)
            jalr    x0, x3, 0
# RISC-V 32-bit Collatz Conjecture (3n+1 problem)
# Rule: if even, divide by 2; if odd, multiply by 3 and add 1
# collatz(n) = steps to reach 1
# check 7SEG for result
#################################################
#	x2		n = SW[14:10]
#	x3		return addr
#	x5		collatz(n)
#	x31		0xFFFF0000
#################################################