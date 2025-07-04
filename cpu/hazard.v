// ========== Hazard Detection Unit ==========
// Handles load-use hazards, control hazards, and interrupt handling
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
    input branch_result,             // branch result signal
    input IsBranch_ID,               // indicates if current ID instruction is a branch
    input IsJAL_ID,                  // indicates if current ID instruction is a jal
    input IsJALR_ID,                 // indicates if current ID instruction is a jalr
    
    // Interrupt handling
    input interrupt_req,             // interrupt request
    input mret_taken,                // MRET instruction in WB stage
    
    // Hazard Control Outputs
    output reg stall,                // stall the pipeline
    output reg flush_IFID,           // flush IF/ID register
    output reg flush_IDEX,           // flush ID/EX register
    output reg flush_EXMEM,          // flush EX/MEM register
    output reg flush_MEMWB,          // flush MEM/WB register
    output reg branch_taken,         // branch taken signal
    output reg interrupt_taken       // interrupt taken signal
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
    wire rs1_hazard_EX = check_dependency(rd_EX, rs1_ID, RegWrite_EX);
    wire rs2_hazard_EX = check_dependency(rd_EX, rs2_ID, RegWrite_EX);
    wire rs1_hazard_MEM = check_dependency(rd_MEM, rs1_ID, RegWrite_MEM);
    wire rs2_hazard_MEM = check_dependency(rd_MEM, rs2_ID, RegWrite_MEM);

    // Special case:
    // lw x1, 0(x2)
    // sw x1, 0(x3)
    // If we have a MemWrite in ID stage, but rs2 is used in MEM stage,
    // we don't need to stall since rs2's value can later be forwarded from WB to MEM
    wire load_use_hazard = MemRead_EX && (rs1_hazard_EX || (rs2_hazard_EX && !MemWrite_ID));
    
    // Branch-load hazard detection
    wire branch_load_hazard_EX = IsBranch_ID && MemRead_EX && (rs1_hazard_EX || rs2_hazard_EX);
                            
    wire branch_load_hazard_MEM = IsBranch_ID && MemRead_MEM && (rs1_hazard_MEM || rs2_hazard_MEM);
                                   
    wire branch_load_hazard = branch_load_hazard_EX || branch_load_hazard_MEM;

    // JALR hazard detection (only depends on rs1)
    wire jalr_load_hazard = IsJALR_ID && MemRead_EX && rs1_hazard_EX;

    // ========== Hazard Detection Logic ==========
    always @(*) begin
        // Default values - no hazard
        stall           = 1'b0;
        flush_IFID      = 1'b0;
        flush_IDEX      = 1'b0;
        flush_EXMEM     = 1'b0;
        flush_MEMWB     = 1'b0;
        interrupt_taken = 1'b0;
        branch_taken    = 1'b0;
        
        // ========== Interrupt Handling ==========
        // Interrupt has highest priority - flush entire pipeline
        if (interrupt_req) begin
            interrupt_taken = 1'b1;  // Signal interrupt taken
            flush_IFID      = 1'b1;  // Flush all pipeline stages
            flush_IDEX      = 1'b1;
            flush_EXMEM     = 1'b1;
            flush_MEMWB     = 1'b1;
        end
        
        // ========== MRET Handling ==========
        // MRET instruction - flush pipeline after return
        else if (mret_taken) begin
            flush_IFID  = 1'b1;      // Flush fetch and decode stages
            flush_IDEX  = 1'b1;      // Flush execute stage
            flush_EXMEM = 1'b1;      // Flush memory stage
        end
        
        // ========== Regular Hazard Detection (only if no interrupt/mret) ==========
        else begin
            branch_taken = (IsBranch_ID & !branch_load_hazard & branch_result) 
                         | IsJAL_ID
                         | (IsJALR_ID & !jalr_load_hazard);

            // ========== Load-Use Hazard ==========
            // Stall for load-use dependencies
            if (load_use_hazard || branch_load_hazard || jalr_load_hazard) begin
                stall      = 1'b1;   // Stall IF and ID stages
                flush_IDEX = 1'b1;   // Insert bubble in EX stage
            end
            
            // ========== Control Hazard ==========
            // Branch taken - flush incorrectly fetched instruction
            if (branch_taken) begin
                flush_IFID = 1'b1;   // Flush wrong instruction in IF/ID
            end
        end
    end

endmodule
