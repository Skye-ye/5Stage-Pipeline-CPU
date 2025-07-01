// ========== Hazard Detection Unit ==========
// Handles load-use hazards and control hazards
module hazard(
    // ID Stage Registers
    input [4:0] rs1_ID,              // source register 1 in ID stage
    input [4:0] rs2_ID,              // source register 2 in ID stage
    
    // Pipeline Destination Registers
    input [4:0] rd_EX,               // destination register in EX stage
    input [4:0] rd_MEM,              // destination register in MEM stage
    
    // Pipeline Control Signals
    input RegWrite_EX,               // register write enable in EX stage
    input RegWrite_MEM,              // register write enable in MEM stage
    input MemRead_EX,                // memory read in EX stage (load instruction)
    input MemRead_MEM,               // memory read in MEM stage (load instruction)
    input MemWrite_ID,               // memory write in ID stage (store instruction)
    input BranchTaken,               // branch taken signal
    input IsBranch_ID,               // indicates if current ID instruction is a branch
    input IsJALR_ID,                 // indicates if current ID instruction is a JALR
    
    // Hazard Control Outputs
    output reg stall,                // stall the pipeline
    output reg flush_IFID,           // flush IF/ID register
    output reg flush_IDEX            // flush ID/EX register
);

    // Helper function for register dependency check
    function check_dependency;
        input [4:0] rd, rs;
        input reg_write;
        begin
            check_dependency = reg_write && (rd != 0) && (rd == rs);
        end
    endfunction
    
    // Load-use hazard detection
    wire rs1_hazard = check_dependency(rd_EX, rs1_ID, RegWrite_EX);
    wire rs2_hazard = check_dependency(rd_EX, rs2_ID, RegWrite_EX);
    wire rs2_can_forward = MemWrite_ID && rs2_hazard && !rs1_hazard;
    
    wire load_use_hazard = MemRead_EX && (rs1_hazard || (rs2_hazard && !rs2_can_forward));
    
    // Branch-load hazard detection
    wire branch_load_hazard_EX = IsBranch_ID && MemRead_EX && 
                                 (check_dependency(rd_EX, rs1_ID, RegWrite_EX) || 
                                  check_dependency(rd_EX, rs2_ID, RegWrite_EX));
                                  
    wire branch_load_hazard_MEM = IsBranch_ID && MemRead_MEM &&
                                  (check_dependency(rd_MEM, rs1_ID, RegWrite_MEM) || 
                                   check_dependency(rd_MEM, rs2_ID, RegWrite_MEM));
                                   
    wire branch_load_hazard = branch_load_hazard_EX || branch_load_hazard_MEM;

    // Branch-arithmetic hazard detection
    wire branch_arith_hazard = IsBranch_ID && !MemRead_EX &&
                              (check_dependency(rd_EX, rs1_ID, RegWrite_EX) || 
                               check_dependency(rd_EX, rs2_ID, RegWrite_EX));

    // JALR hazard detection (only depends on rs1)
    wire jalr_load_hazard = IsJALR_ID && MemRead_EX && 
                           check_dependency(rd_EX, rs1_ID, RegWrite_EX);
                           
    wire jalr_arith_hazard = IsJALR_ID && !MemRead_EX && 
                           check_dependency(rd_EX, rs1_ID, RegWrite_EX);

    // ========== Hazard Detection Logic ==========
    always @(*) begin
        // Default values - no hazard
        stall      = 1'b0;
        flush_IFID = 1'b0;
        flush_IDEX = 1'b0;
        
        // ========== Load-Use Hazard ==========
        // Stall for regular load-use dependencies
        if (load_use_hazard && !IsBranch_ID) begin
            stall      = 1'b1;   // Stall IF and ID stages
            flush_IDEX = 1'b1;   // Insert bubble in EX stage
        end
        
        // ========== Branch Hazards ==========
        // Branch depends on load result - need to stall
        if (branch_load_hazard) begin
            stall      = 1'b1;   // Stall IF and ID stages
            flush_IDEX = 1'b1;   // Insert bubble in EX stage
        end
        
        // Branch depends on arithmetic result - stall but allow forwarding
        if (branch_arith_hazard) begin
            stall = 1'b1;        // Stall IF and ID stages
            // No flush - allow EX stage to advance for forwarding
        end
        
        // ========== JALR Hazards ==========
        // JALR depends on load result
        if (jalr_load_hazard) begin
            stall      = 1'b1;   // Stall IF and ID stages
            flush_IDEX = 1'b1;   // Insert bubble in EX stage
        end
        
        // JALR depends on arithmetic result
        if (jalr_arith_hazard) begin
            stall = 1'b1;        // Stall IF and ID stages
            // No flush - allow EX stage to advance for forwarding
        end
        
        // ========== Control Hazard ==========
        // Branch taken - flush incorrectly fetched instruction
        if (BranchTaken) begin
            flush_IFID = 1'b1;   // Flush wrong instruction in IF/ID
        end
    end

endmodule
