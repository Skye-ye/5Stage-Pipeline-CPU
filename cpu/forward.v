// Forwarding Unit
// Handles data hazards through forwarding
module forward(
    input [4:0] rs1_EX,          // source register 1 in EX stage
    input [4:0] rs2_EX,          // source register 2 in EX stage
    input [4:0] rs1_ID,          // source register 1 in ID stage (for branches)
    input [4:0] rs2_ID,          // source register 2 in ID stage (for branches)
    input [4:0] rs2_MEM,         // source register 2 in MEM stage (for stores)
    input [4:0] rd_EX,           // destination register in EX stage
    input [4:0] rd_MEM,          // destination register in MEM stage
    input [4:0] rd_WB,           // destination register in WB stage
    input RegWrite_EX,           // register write enable in EX stage
    input RegWrite_MEM,          // register write enable in MEM stage
    input RegWrite_WB,           // register write enable in WB stage
    
    output reg [1:0] forwardA,   // forwarding control for ALU input A
    output reg [1:0] forwardB,   // forwarding control for ALU input B
    output reg [1:0] forwardA_branch, // forwarding control for branch input A
    output reg [1:0] forwardB_branch, // forwarding control for branch input B
    output reg forwardMEM        // forwarding control for MEM stage store data
);

    // Forward control encoding:
    // 00: No forwarding (use data from register file)
    // 01: Forward from WB stage (MEM/WB register)
    // 10: Forward from MEM stage (EX/MEM register)
    // 11: Forward from EX stage (ID/EX register) - for branch/JALR instructions

    always @(*) begin
        // Default: no forwarding
        forwardA = 2'b00;
        forwardB = 2'b00;
        forwardA_branch = 2'b00;
        forwardB_branch = 2'b00;
        forwardMEM = 1'b0;

        // ========== ALU Forwarding (Priority: MEM > WB) ==========
        // Check highest priority first
        if (RegWrite_MEM && (rd_MEM != 0) && (rd_MEM == rs1_EX)) begin
            forwardA = 2'b10;  // Forward from MEM
        end
        else if (RegWrite_WB && (rd_WB != 0) && (rd_WB == rs1_EX)) begin
            forwardA = 2'b01;  // Forward from WB
        end

        if (RegWrite_MEM && (rd_MEM != 0) && (rd_MEM == rs2_EX)) begin
            forwardB = 2'b10;  // Forward from MEM
        end
        else if (RegWrite_WB && (rd_WB != 0) && (rd_WB == rs2_EX)) begin
            forwardB = 2'b01;  // Forward from WB
        end

        // ========== Branch Forwarding (Priority: EX > MEM > WB) ==========
        // Check highest priority first
        if (RegWrite_EX && (rd_EX != 0) && (rd_EX == rs1_ID)) begin
            forwardA_branch = 2'b11;  // Forward from EX
        end
        else if (RegWrite_MEM && (rd_MEM != 0) && (rd_MEM == rs1_ID)) begin
            forwardA_branch = 2'b10;  // Forward from MEM
        end
        else if (RegWrite_WB && (rd_WB != 0) && (rd_WB == rs1_ID)) begin
            forwardA_branch = 2'b01;  // Forward from WB
        end

        if (RegWrite_EX && (rd_EX != 0) && (rd_EX == rs2_ID)) begin
            forwardB_branch = 2'b11;  // Forward from EX
        end
        else if (RegWrite_MEM && (rd_MEM != 0) && (rd_MEM == rs2_ID)) begin
            forwardB_branch = 2'b10;  // Forward from MEM
        end
        else if (RegWrite_WB && (rd_WB != 0) && (rd_WB == rs2_ID)) begin
            forwardB_branch = 2'b01;  // Forward from WB
        end

        // ========== Store Data Forwarding ==========
        if (RegWrite_WB && (rd_WB != 0) && (rd_WB == rs2_MEM)) begin
            forwardMEM = 1'b1;
        end
    end

endmodule