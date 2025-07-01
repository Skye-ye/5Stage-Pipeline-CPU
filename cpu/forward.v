// ========== Forwarding Unit ==========
// Handles data hazards through data forwarding
module forward(
    // EX Stage Registers
    input [4:0] rs1_EX,              // source register 1 in EX stage
    input [4:0] rs2_EX,              // source register 2 in EX stage
    
    // ID Stage Registers (for branches/jumps)
    input [4:0] rs1_ID,              // source register 1 in ID stage
    input [4:0] rs2_ID,              // source register 2 in ID stage
    
    // MEM Stage Registers
    input [4:0] rs2_MEM,             // source register 2 in MEM stage (for stores)
    
    // Destination Registers
    input [4:0] rd_EX,               // destination register in EX stage
    input [4:0] rd_MEM,              // destination register in MEM stage
    input [4:0] rd_WB,               // destination register in WB stage
    
    // Register Write Enables
    input RegWrite_EX,               // register write enable in EX stage
    input RegWrite_MEM,              // register write enable in MEM stage
    input RegWrite_WB,               // register write enable in WB stage
    
    // Forwarding Control Outputs
    output reg [1:0] forwardA,       // ALU input A forwarding control
    output reg [1:0] forwardB,       // ALU input B forwarding control
    output reg [1:0] forwardA_branch, // branch input A forwarding control
    output reg [1:0] forwardB_branch, // branch input B forwarding control
    output reg       forwardMEM     // MEM stage store data forwarding control
);

    // ========== Forwarding Control Encoding ==========
    // 00: No forwarding (use data from register file)
    // 01: Forward from WB stage (MEM/WB register)
    // 10: Forward from MEM stage (EX/MEM register)
    // 11: Forward from EX stage (ID/EX register) - for branch/JALR instructions

    // Helper function for forwarding detection
    function [1:0] check_forwarding;
        input reg_write_mem, reg_write_wb;
        input [4:0] rd_mem, rd_wb, rs_target;
        begin
            if (reg_write_mem && (rd_mem != 0) && (rd_mem == rs_target)) begin
                check_forwarding = 2'b10; // Forward from MEM
            end else if (reg_write_wb && (rd_wb != 0) && (rd_wb == rs_target)) begin
                check_forwarding = 2'b01; // Forward from WB
            end else begin
                check_forwarding = 2'b00; // No forwarding
            end
        end
    endfunction
    
    always @(*) begin
        // Default: no forwarding
        forwardA = 2'b00;
        forwardB = 2'b00;
        forwardA_branch = 2'b00;
        forwardB_branch = 2'b00;
        forwardMEM = 1'b0;
        
        // EX stage forwarding (MEM and WB to EX)
        forwardA = check_forwarding(RegWrite_MEM, RegWrite_WB, rd_MEM, rd_WB, rs1_EX);
        forwardB = check_forwarding(RegWrite_MEM, RegWrite_WB, rd_MEM, rd_WB, rs2_EX);
        
        // Branch forwarding (EX, MEM, WB to ID) with priority
        // EX has highest priority, then MEM, then WB
        if (RegWrite_EX && (rd_EX != 0) && (rd_EX == rs1_ID)) begin
            forwardA_branch = 2'b11; // Forward from EX
        end else if (RegWrite_MEM && (rd_MEM != 0) && (rd_MEM == rs1_ID)) begin
            forwardA_branch = 2'b10; // Forward from MEM
        end else if (RegWrite_WB && (rd_WB != 0) && (rd_WB == rs1_ID)) begin
            forwardA_branch = 2'b01; // Forward from WB
        end
        
        if (RegWrite_EX && (rd_EX != 0) && (rd_EX == rs2_ID)) begin
            forwardB_branch = 2'b11; // Forward from EX
        end else if (RegWrite_MEM && (rd_MEM != 0) && (rd_MEM == rs2_ID)) begin
            forwardB_branch = 2'b10; // Forward from MEM
        end else if (RegWrite_WB && (rd_WB != 0) && (rd_WB == rs2_ID)) begin
            forwardB_branch = 2'b01; // Forward from WB
        end
        
        // ========== WB-to-MEM Forwarding ==========
        // Forward WB data to MEM stage for store instructions
        forwardMEM = RegWrite_WB && (rd_WB != 0) && (rd_WB == rs2_MEM);
    end

endmodule
