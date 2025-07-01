// Branch evaluation unit
// Consolidates branch condition logic
module branch(
    input [31:0] A, B,
    input [2:0] funct3,
    output reg branch_result
);
    
    always @(*) begin
        case (funct3)
            3'b000: branch_result = (A == B);                           // BEQ
            3'b001: branch_result = (A != B);                           // BNE  
            3'b100: branch_result = ($signed(A) < $signed(B));          // BLT
            3'b101: branch_result = ($signed(A) >= $signed(B));         // BGE
            3'b110: branch_result = (A < B);                            // BLTU
            3'b111: branch_result = (A >= B);                           // BGEU
            default: branch_result = 1'b0;
        endcase
    end
    
endmodule