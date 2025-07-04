`include "def.v"

module alu(
    input  signed [31:0] A,      // ALU input A
    input  signed [31:0] B,      // ALU input B
    input         [4:0]  ALUOp,  // ALU operation code
    input         [31:0] PC,     // Program counter (for AUIPC)
    output reg signed [31:0] C,  // ALU result
    output               Zero    // Zero flag
);
    
    // ========== ALU Operation Logic ==========
    always @(*) begin
        case (ALUOp)
            `ALUOp_nop:   C = A;                                          // No operation
            `ALUOp_lui:   C = B;                                          // Load upper immediate
            `ALUOp_auipc: C = PC + B;                                     // Add upper immediate to PC
            `ALUOp_add:   C = A + B;                                      // Addition
            `ALUOp_sub:   C = A - B;                                      // Subtraction
            `ALUOp_bne:   C = {31'b0, (A == B)};                        // Branch equal comparison
            `ALUOp_blt:   C = {31'b0, (A >= B)};                        // Branch less than comparison
            `ALUOp_bge:   C = {31'b0, (A < B)};                         // Branch greater equal comparison
            `ALUOp_bltu:  C = {31'b0, ($unsigned(A) >= $unsigned(B))};  // Branch less than unsigned
            `ALUOp_bgeu:  C = {31'b0, ($unsigned(A) < $unsigned(B))};   // Branch greater equal unsigned
            `ALUOp_slt:   C = {31'b0, (A < B)};                         // Set less than
            `ALUOp_sltu:  C = {31'b0, ($unsigned(A) < $unsigned(B))};   // Set less than unsigned
            `ALUOp_xor:   C = A ^ B;                                     // Bitwise XOR
            `ALUOp_or:    C = A | B;                                     // Bitwise OR
            `ALUOp_and:   C = A & B;                                     // Bitwise AND
            `ALUOp_sll:   C = A << B;                                    // Shift left logical
            `ALUOp_srl:   C = A >> B;                                    // Shift right logical
            `ALUOp_sra:   C = A >>> B;                                   // Shift right arithmetic
            default:      C = 32'b0;                                     // Default case
        endcase
    end
   
    // Zero flag generation
    assign Zero = (C == 32'b0);
    
endmodule
    
