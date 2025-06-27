// Hazard Detection Unit
// Handles load-use hazards and control hazards
module hazard_detection_unit(
    input [4:0] rs1_ID,           // source register 1 in ID stage
    input [4:0] rs2_ID,           // source register 2 in ID stage  
    input [4:0] rd_EX,            // destination register in EX stage
    input [4:0] rd_MEM,           // destination register in MEM stage
    input RegWrite_EX,            // register write enable in EX stage
    input RegWrite_MEM,           // register write enable in MEM stage
    input MemRead_EX,             // memory read in EX stage (load instruction)
    input MemWrite_ID,            // memory write in ID stage (store instruction)
    input BranchTaken,            // branch taken signal
    input IsBranch_ID,            // indicates if current ID instruction is a branch
    
    output reg stall,             // stall the pipeline
    output reg flush_IFID,        // flush IF/ID register
    output reg flush_IDEX         // flush ID/EX register
);

    // Load-use hazard detection
    // For store instructions, WB→MEM forwarding can resolve hazards on rs2 (store data)
    // Only stall if:
    // 1. It's a load instruction in EX stage
    // 2. Next instruction depends on the load result
    // 3. Either it's not a store, or it depends on rs1 (can't forward address calculation)
    wire load_use_hazard;
    wire rs1_hazard = (rd_EX == rs1_ID);
    wire rs2_hazard = (rd_EX == rs2_ID);
    wire rs2_can_forward = MemWrite_ID && rs2_hazard && !rs1_hazard;
    
    assign load_use_hazard = MemRead_EX && RegWrite_EX && rd_EX != 0 &&
                            (rs1_hazard || (rs2_hazard && !rs2_can_forward));
    
    // Branch-load hazard detection (branch depends on load result)
    wire branch_load_hazard;
    assign branch_load_hazard = IsBranch_ID && MemRead_EX && RegWrite_EX && rd_EX != 0 &&
                               ((rd_EX == rs1_ID) || (rd_EX == rs2_ID));

    always @(*) begin
        // Default values
        stall = 1'b0;
        flush_IFID = 1'b0;
        flush_IDEX = 1'b0;
        
        // Handle load-use hazard (regular instructions)
        if (load_use_hazard && !IsBranch_ID) begin
            stall = 1'b1;        // Stall IF and ID stages
            flush_IDEX = 1'b1;   // Insert bubble in EX stage
        end
        
        // Handle branch-load hazard (branch depends on load)
        if (branch_load_hazard) begin
            stall = 1'b1;        // Stall IF and ID stages
            flush_IDEX = 1'b1;   // Insert bubble in EX stage
        end
        
        // Handle control hazard (branch taken)
        // Since branch now resolves in ID stage, only flush IF/ID
        if (BranchTaken) begin
            flush_IFID = 1'b1;   // Flush wrong instruction in IF/ID
        end
    end

endmodule
