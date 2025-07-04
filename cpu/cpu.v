`include "def.v"

module cpu(
    // Clock and Reset
    input        clk,         // system clock
    input        reset,       // active high reset
    
    // Memory Interface
    input  [31:0] Inst_in,    // instruction from instruction memory
    input  [31:0] Data_in,    // data from data memory
    output        mem_w,      // memory write enable
    output [2:0]  DMType_out, // data memory access type
    output [31:0] PC_out,     // PC address for instruction memory
    output [31:0] Addr_out,   // address for data memory
    output [31:0] Data_out,   // data to data memory
    
    // Interrupt Interface
    input        external_int, // External interrupt request
    input        timer_int,    // Timer interrupt request
    input        software_int, // Software interrupt request
    
    // Debug Interface
    input  [4:0]  reg_sel,    // register selection for debug
    output [31:0] reg_data    // selected register data for debug
);

    // ========== Pipeline Register Declarations ==========
    
    // IF/ID Pipeline Register
    reg [31:0] IFID_PC, IFID_PCPLUS4, IFID_inst;
    reg        IFID_valid;
    
    // ID/EX Pipeline Register
    reg [31:0] IDEX_PC, IDEX_PCPLUS4, IDEX_RD1, IDEX_RD2, IDEX_imm;
    reg [4:0]  IDEX_rs1, IDEX_rs2, IDEX_rd;
    reg [4:0]  IDEX_ALUOp;
    reg [2:0]  IDEX_DMType, IDEX_CSROp;
    reg [1:0]  IDEX_WDSel;
    reg        IDEX_RegWrite, IDEX_MemWrite, IDEX_ALUSrc;
    reg        IDEX_CSRWrite, IDEX_CSRRead, IDEX_IsCSR, IDEX_IsMRET;
    reg [11:0] IDEX_CSRAddr;
    reg        IDEX_valid;
    
    // EX/MEM Pipeline Register
    reg [31:0] EXMEM_PCPLUS4, EXMEM_ALUOut, EXMEM_RD2, EXMEM_csr_rdata;
    reg [4:0]  EXMEM_rd, EXMEM_rs2;
    reg [2:0]  EXMEM_DMType, EXMEM_CSROp;
    reg [1:0]  EXMEM_WDSel;
    reg        EXMEM_RegWrite, EXMEM_MemWrite, EXMEM_Zero;
    reg        EXMEM_CSRWrite, EXMEM_CSRRead, EXMEM_IsCSR, EXMEM_IsMRET;
    reg [11:0] EXMEM_CSRAddr;
    reg        EXMEM_valid;
    
    // MEM/WB Pipeline Register
    reg [31:0] MEMWB_PCPLUS4, MEMWB_ALUOut, MEMWB_MemData, MEMWB_CSRData;
    reg [4:0]  MEMWB_rd;
    reg [1:0]  MEMWB_WDSel;
    reg        MEMWB_RegWrite;
    reg        MEMWB_IsCSR, MEMWB_IsMRET;
    reg        MEMWB_valid;

    // ========== Control and Data Path Signals ==========
    
    // Hazard Detection and Forwarding
    wire       stall, flush_IFID, flush_IDEX, flush_EXMEM, flush_MEMWB;
    wire [1:0] forwardA, forwardB;
    wire [1:0] forwardA_branch, forwardB_branch;
    wire       forwardMEM;
    wire       branch_taken ;
    wire       interrupt_taken;
    
    // Control Signals from ID Stage
    wire       RegWrite_ID, MemWrite_ID, ALUSrc_ID;
    wire [4:0] ALUOp_ID;
    wire [1:0] WDSel_ID;
    wire [5:0] EXTOp_ID;
    wire       IsBranch_ID, IsJAL_ID, IsJALR_ID;
    
    // CSR control signals
    wire       CSRWrite_ID, CSRRead_ID, IsCSR_ID, IsMRET_ID;
    wire [2:0] CSROp_ID;
    
    // Interrupt and CSR signals
    wire        interrupt_req;
    wire [31:0] interrupt_cause;
    wire [31:0] mstatus, mtvec, mepc, mcause, mie, mip;
    wire        global_int_enable;
    wire        mret_taken;
    
    // Data Path Signals
    reg  [31:0] PC_IF;                    // Program Counter
    reg  [31:0] NPC;                      // Next PC
    wire [31:0] IF_PCPLUS4;               // PC+4
    wire [31:0] RD1_ID, RD2_ID, imm_ID;   // Register data and immediate
    wire [4:0]  rs1_ID, rs2_ID, rd_ID;    // Register addresses
    wire [31:0] ALU_B, ALUOut_EX;         // ALU inputs and output
    reg  [31:0] ALU_A;                    // ALU input A (with forwarding)
    reg  [31:0] WriteData_WB;             // Write back data
    wire        Zero_EX;                  // ALU zero flag

    // CSR signals
    wire [11:0] csr_addr_ID;              // CSR address

    // ========== Instruction Field Extraction ==========
    assign rs1_ID = IFID_inst[19:15];     // Source register 1
    assign rs2_ID = IFID_inst[24:20];     // Source register 2
    assign rd_ID  = IFID_inst[11:7];      // Destination register

    assign csr_addr_ID = IFID_inst[31:20]; // CSR address
    
    // ========== PC Logic ==========
    assign IF_PCPLUS4 = PC_IF + 4;            // PC + 4
    
    // Next PC selection with interrupt handling
    always @(*) begin
        if (interrupt_taken) begin
            NPC = mtvec;                   // Jump to interrupt vector
        end else if (mret_taken) begin
            NPC = mepc;                    // Return from interrupt
        end else if (branch_taken) begin
            NPC = branch_target;           // Branch/jump target
        end else begin
            NPC = IF_PCPLUS4;              // Sequential execution
        end
    end
    
    assign PC_out = PC_IF;                // Output PC to instruction memory

    // ========== 1 IF Stage ==========
    
    // Program Counter Register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC_IF <= `RESET_PC;
        end else if (!stall || branch_taken || interrupt_taken || mret_taken) begin
            PC_IF <= NPC;
        end
    end
    
    // IF/ID Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset || flush_IFID) begin
            IFID_PC <= `RESET_PC;
            IFID_PCPLUS4 <= `PC_INCREMENT;
            IFID_inst <= `NOP_INSTRUCTION;
            IFID_valid <= 1'b0;
        end else if (!stall) begin
            IFID_PC <= PC_IF;
            IFID_PCPLUS4 <= IF_PCPLUS4;
            IFID_inst <= Inst_in;
            IFID_valid <= 1'b1;
        end
    end

    // ========== 2 ID Stage ==========
    // Control Unit Instance
    wire [2:0] DMType_ID;
    ctrl U_CTRL(
        .Op(IFID_inst[6:0]), 
        .Funct7(IFID_inst[31:25]), 
        .Funct3(IFID_inst[14:12]),
        .Zero(1'b0), 
        .RegWrite(RegWrite_ID), 
        .MemWrite(MemWrite_ID),
        .EXTOp(EXTOp_ID), 
        .ALUOp(ALUOp_ID), 
        .ALUSrc(ALUSrc_ID), 
        .WDSel(WDSel_ID),  
        .DMType(DMType_ID),
        .IsBranch(IsBranch_ID),
        .IsJAL(IsJAL_ID),
        .IsJALR(IsJALR_ID),
        .CSRWrite(CSRWrite_ID),
        .CSRRead(CSRRead_ID),
        .CSROp(CSROp_ID),
        .IsCSR(IsCSR_ID),
        .IsMRET(IsMRET_ID)
    );

    // Register File Instance
    rf U_RF(
        .clk(clk), 
        .rst(reset),
        .RFWr(MEMWB_RegWrite & MEMWB_valid), 
        .A1(rs1_ID), 
        .A2(rs2_ID), 
        .A3(MEMWB_rd), 
        .WD(WriteData_WB), 
        .RD1(RD1_ID), 
        .RD2(RD2_ID)
    );
    
    // Interrupt Controller Instance
    interrupt U_INTERRUPT(
        .clk(clk),
        .reset(reset),
        .external_int(external_int),
        .timer_int(timer_int),
        .software_int(software_int),
        .mie(mie),
        .mstatus(mstatus),
        .global_int_enable(global_int_enable),
        .interrupt_req(interrupt_req),
        .interrupt_cause(interrupt_cause),
        .mip(mip)
    );
    
    // CSR Unit Instance
    wire [31:0] csr_rdata;
    assign mret_taken = MEMWB_IsMRET & MEMWB_valid;
    
    csr U_CSR(
        .clk(clk),
        .reset(reset),
        .csr_write(EXMEM_CSRWrite & EXMEM_valid),
        .csr_read(EXMEM_CSRRead & EXMEM_valid),
        .csr_addr(EXMEM_CSRAddr),
        .csr_wdata(EXMEM_ALUOut), // Use ALU output as CSR write data
        .csr_op(EXMEM_CSROp),
        .csr_rdata(csr_rdata),
        .interrupt_taken(interrupt_taken),
        .interrupt_cause(interrupt_cause),
        .interrupt_pc(PC_IF), // Current PC when interrupt occurs
        .mret_taken(mret_taken),
        .mip_in(mip),
        .mstatus(mstatus),
        .mtvec(mtvec),
        .mepc(mepc),
        .mcause(mcause),
        .mie(mie),
        .mip(mip),
        .global_int_enable(global_int_enable)
    );

    // Immediate Extension
    wire [4:0] iimm_shamt = IFID_inst[24:20];
    wire [11:0] iimm = IFID_inst[31:20];
    wire [11:0] simm = {IFID_inst[31:25], IFID_inst[11:7]};
    wire [11:0] bimm = {IFID_inst[31], IFID_inst[7], IFID_inst[30:25], IFID_inst[11:8]};
    wire [19:0] uimm = IFID_inst[31:12];
    wire [19:0] jimm = {IFID_inst[31], IFID_inst[19:12], IFID_inst[20], IFID_inst[30:21]};

    ext U_EXT(
        .iimm_shamt(iimm_shamt), 
        .iimm(iimm), 
        .simm(simm), 
        .bimm(bimm),
        .uimm(uimm), 
        .jimm(jimm),
        .EXTOp(EXTOp_ID), 
        .immout(imm_ID)
    );

    // Branch forwarding mux for register A
    reg [31:0] branch_A;
    always @(*) begin
        case (forwardA_branch)
            2'b00: branch_A = RD1_ID;              // No forwarding
            2'b01: branch_A = WriteData_WB;        // Forward from WB stage
            2'b10: branch_A = (EXMEM_WDSel == `WDSel_FromMEM) ? Data_in : EXMEM_ALUOut;  // Forward from MEM stage (use current memory data)
            2'b11: branch_A = ALUOut_EX;           // Forward from EX stage
            default: branch_A = RD1_ID;
        endcase
    end
    
    // Branch forwarding mux for register B
    reg [31:0] branch_B;
    always @(*) begin
        case (forwardB_branch)
            2'b00: branch_B = RD2_ID;              // No forwarding
            2'b01: branch_B = WriteData_WB;        // Forward from WB stage
            2'b10: branch_B = (EXMEM_WDSel == `WDSel_FromMEM) ? Data_in : EXMEM_ALUOut;  // Forward from MEM stage (use current memory data)
            2'b11: branch_B = ALUOut_EX;           // Forward from EX stage
            default: branch_B = RD2_ID;
        endcase
    end
    
    // ========== Branch Condition Evaluation ==========
    wire branch_result;
    branch U_BRANCH(
        .A(branch_A),
        .B(branch_B),
        .funct3(IFID_inst[14:12]),
        .branch_result(branch_result)
    );
    
    // Branch target calculation
    wire [31:0] branch_target = IsJALR_ID ? (branch_A + imm_ID) : (IFID_PC + imm_ID);

    // ID/EX Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset || flush_IDEX) begin
            IDEX_PC <= 32'h00000000;
            IDEX_PCPLUS4 <= 32'h00000004;
            IDEX_RD1 <= 32'h00000000;
            IDEX_RD2 <= 32'h00000000;
            IDEX_imm <= 32'h00000000;
            IDEX_rs1 <= 5'b00000;
            IDEX_rs2 <= 5'b00000;
            IDEX_rd <= 5'b00000;
            IDEX_ALUOp <= 5'b00000;
            IDEX_DMType <= 3'b000;
            IDEX_CSROp <= 3'b000;
            IDEX_WDSel <= 2'b00;
            IDEX_RegWrite <= 1'b0;
            IDEX_MemWrite <= 1'b0;
            IDEX_ALUSrc <= 1'b0;
            IDEX_CSRWrite <= 1'b0;
            IDEX_CSRRead <= 1'b0;
            IDEX_IsCSR <= 1'b0;
            IDEX_IsMRET <= 1'b0;
            IDEX_CSRAddr <= 12'h000;
            IDEX_valid <= 1'b0;
        end else if (!stall) begin
            IDEX_PC <= IFID_PC;
            IDEX_PCPLUS4 <= IFID_PCPLUS4;
            IDEX_RD1 <= RD1_ID;
            IDEX_RD2 <= RD2_ID;
            IDEX_imm <= imm_ID;
            IDEX_rs1 <= rs1_ID;
            IDEX_rs2 <= rs2_ID;
            IDEX_rd <= rd_ID;
            IDEX_ALUOp <= ALUOp_ID;
            IDEX_DMType <= DMType_ID;
            IDEX_CSROp <= CSROp_ID;
            IDEX_WDSel <= WDSel_ID;
            IDEX_RegWrite <= RegWrite_ID;
            IDEX_MemWrite <= MemWrite_ID;
            IDEX_ALUSrc <= ALUSrc_ID;
            IDEX_CSRWrite <= CSRWrite_ID;
            IDEX_CSRRead <= CSRRead_ID;
            IDEX_IsCSR <= IsCSR_ID;
            IDEX_IsMRET <= IsMRET_ID;
            IDEX_CSRAddr <= csr_addr_ID;
            IDEX_valid <= IFID_valid;
        end
    end

    // ========== 3 EX Stage ==========

    // Forwarding Mux for ALU input A
    always @(*) begin
        case (forwardA)
            2'b00: ALU_A = IDEX_RD1;           // No forwarding
            2'b01: ALU_A = WriteData_WB;       // Forward from WB stage  
            2'b10: ALU_A = EXMEM_ALUOut;       // Forward from MEM stage
            default: ALU_A = IDEX_RD1;
        endcase
    end

    // Forwarding Mux for ALU input B
    reg [31:0] ALU_B_forwarded;
    always @(*) begin
        case (forwardB)
            2'b00: ALU_B_forwarded = IDEX_RD2;      // No forwarding
            2'b01: ALU_B_forwarded = WriteData_WB;  // Forward from WB stage
            2'b10: ALU_B_forwarded = EXMEM_ALUOut;  // Forward from MEM stage  
            default: ALU_B_forwarded = IDEX_RD2;
        endcase
    end

    assign ALU_B = IDEX_ALUSrc ? IDEX_imm : ALU_B_forwarded;

    // ALU Instance
    alu U_ALU(
        .A(ALU_A), 
        .B(ALU_B), 
        .ALUOp(IDEX_ALUOp), 
        .C(ALUOut_EX), 
        .Zero(Zero_EX), 
        .PC(IDEX_PC)
    );


    // EX/MEM Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset || flush_EXMEM) begin
            EXMEM_PCPLUS4 <= 32'h00000004;
            EXMEM_ALUOut <= 32'h00000000;
            EXMEM_RD2 <= 32'h00000000;
            EXMEM_csr_rdata <= 32'h00000000;
            EXMEM_rd <= 5'b00000;
            EXMEM_rs2 <= 5'b00000;
            EXMEM_DMType <= 3'b000;
            EXMEM_CSROp <= 3'b000;
            EXMEM_WDSel <= 2'b00;
            EXMEM_RegWrite <= 1'b0;
            EXMEM_MemWrite <= 1'b0;
            EXMEM_Zero <= 1'b0;
            EXMEM_CSRWrite <= 1'b0;
            EXMEM_CSRRead <= 1'b0;
            EXMEM_IsCSR <= 1'b0;
            EXMEM_IsMRET <= 1'b0;
            EXMEM_CSRAddr <= 12'h000;
            EXMEM_valid <= 1'b0;
        end else begin
            EXMEM_PCPLUS4 <= IDEX_PCPLUS4;
            EXMEM_ALUOut <= ALUOut_EX;
            EXMEM_RD2 <= ALU_B_forwarded; // Use forwarded data for store
            EXMEM_csr_rdata <= csr_rdata;
            EXMEM_rd <= IDEX_rd;
            EXMEM_rs2 <= IDEX_rs2;
            EXMEM_DMType <= IDEX_DMType;
            EXMEM_CSROp <= IDEX_CSROp;
            EXMEM_WDSel <= IDEX_WDSel;
            EXMEM_RegWrite <= IDEX_RegWrite;
            EXMEM_MemWrite <= IDEX_MemWrite;
            EXMEM_Zero <= Zero_EX;
            EXMEM_CSRWrite <= IDEX_CSRWrite;
            EXMEM_CSRRead <= IDEX_CSRRead;
            EXMEM_IsCSR <= IDEX_IsCSR;
            EXMEM_IsMRET <= IDEX_IsMRET;
            EXMEM_CSRAddr <= IDEX_CSRAddr;
            EXMEM_valid <= IDEX_valid;
        end
    end

    // ========== 4 MEM Stage ==========
    // Memory interface
    assign Addr_out = EXMEM_ALUOut;
    assign Data_out = forwardMEM ? WriteData_WB : EXMEM_RD2;
    assign DMType_out = EXMEM_DMType;
    assign mem_w = EXMEM_MemWrite & EXMEM_valid;

    // MEM/WB Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset || flush_MEMWB) begin
            MEMWB_PCPLUS4 <= 32'h00000004;
            MEMWB_ALUOut <= 32'h00000000;
            MEMWB_MemData <= 32'h00000000;
            MEMWB_CSRData <= 32'h00000000;
            MEMWB_rd <= 5'b00000;
            MEMWB_WDSel <= 2'b00;
            MEMWB_RegWrite <= 1'b0;
            MEMWB_IsCSR <= 1'b0;
            MEMWB_IsMRET <= 1'b0;
            MEMWB_valid <= 1'b0;
        end else begin
            MEMWB_PCPLUS4 <= EXMEM_PCPLUS4;
            MEMWB_ALUOut <= EXMEM_ALUOut;
            MEMWB_MemData <= Data_in;
            MEMWB_CSRData <= EXMEM_csr_rdata;
            MEMWB_rd <= EXMEM_rd;
            MEMWB_WDSel <= EXMEM_WDSel;
            MEMWB_RegWrite <= EXMEM_RegWrite;
            MEMWB_IsCSR <= EXMEM_IsCSR;
            MEMWB_IsMRET <= EXMEM_IsMRET;
            MEMWB_valid <= EXMEM_valid;
        end
    end

    // ========== 5 WB Stage ==========
    // Write back data selection
    always @(*) begin
        case(MEMWB_WDSel)
            `WDSel_FromALU: WriteData_WB = MEMWB_ALUOut;
            `WDSel_FromMEM: WriteData_WB = MEMWB_MemData;
            `WDSel_FromPC:  WriteData_WB = MEMWB_PCPLUS4;
            `WDSel_FromCSR: WriteData_WB = MEMWB_CSRData;
            default:        WriteData_WB = MEMWB_ALUOut;
        endcase
    end

    // ==== Hazard Detection and Forwarding Units ====
    // Hazard Detection Unit
    hazard U_HAZARD(
        .rs1_ID(rs1_ID),
        .rs2_ID(rs2_ID),
        .rd_EX(IDEX_rd),
        .rd_MEM(EXMEM_rd),
        .RegWrite_EX(IDEX_RegWrite),
        .RegWrite_MEM(EXMEM_RegWrite),
        .MemRead_EX(IDEX_WDSel == `WDSel_FromMEM),
        .MemRead_MEM(EXMEM_WDSel == `WDSel_FromMEM),
        .MemWrite_ID(MemWrite_ID),
        .branch_result(branch_result),
        .IsBranch_ID(IsBranch_ID),
        .IsJAL_ID(IsJAL_ID),
        .IsJALR_ID(IsJALR_ID),
        .interrupt_req(interrupt_req),
        .mret_taken(mret_taken),
        .stall(stall),
        .flush_IFID(flush_IFID),
        .flush_IDEX(flush_IDEX),
        .flush_EXMEM(flush_EXMEM),
        .flush_MEMWB(flush_MEMWB),
        .branch_taken(branch_taken),
        .interrupt_taken(interrupt_taken)
    );

    // Forwarding Unit
    forward U_FORWARD(
        .rs1_EX(IDEX_rs1),
        .rs2_EX(IDEX_rs2),
        .rs1_ID(rs1_ID),
        .rs2_ID(rs2_ID),
        .rs2_MEM(EXMEM_rs2),
        .rd_EX(IDEX_rd),
        .rd_MEM(EXMEM_rd),
        .rd_WB(MEMWB_rd),
        .RegWrite_EX(IDEX_RegWrite),
        .RegWrite_MEM(EXMEM_RegWrite),
        .RegWrite_WB(MEMWB_RegWrite),
        .forwardA(forwardA),
        .forwardB(forwardB),
        .forwardA_branch(forwardA_branch),
        .forwardB_branch(forwardB_branch),
        .forwardMEM(forwardMEM)
    );

    // Debug register output
    assign reg_data = (reg_sel != 0) ? U_RF.rf[reg_sel] : 0;

endmodule
