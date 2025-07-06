`include "def.v"

module cpu(
    // Clock and Reset
    input        clk,         // system clock
    input        reset,       // active high reset
    
    // Memory Interface
    input  [31:0] Inst_in,    // instruction from instruction memory
    input  [31:0] Data_in,    // data from data memory
    output        mem_w,      // memory write enable
    output        mem_r,      // memory read enable
    output [2:0]  DMType_out, // data memory access type
    output [31:0] PC_out,     // PC address for instruction memory
    output [31:0] Addr_out,   // address for data memory
    output [31:0] Data_out,   // data to data memory
    
    // Interrupt Interface
    input         external_int, // External interrupt request
    input         timer_int,    // Timer interrupt request
    output        timer_int_ack,// Timer interrupt acknowledge
    output        ext_int_ack,  // External interrupt acknowledge
    
    // Debug Interface
    input  [4:0]  reg_sel,    // register selection for debug
    output [31:0] reg_data    // selected register data for debug
);

    // ========== Pipeline Register Declarations ==========
    
    // IF/ID Pipeline Register
    reg [31:0] IFID_PC, IFID_inst;
    reg        IFID_valid;
    
    // ID/EX Pipeline Register
    reg [31:0] IDEX_PC, IDEX_RD1, IDEX_RD2, IDEX_imm;
    reg [4:0]  IDEX_rs1, IDEX_rs2, IDEX_rd;
    reg [4:0]  IDEX_ALUOp;
    reg [2:0]  IDEX_DMType, IDEX_CSROp;
    reg [1:0]  IDEX_WDSel;
    reg        IDEX_RegWrite, IDEX_MemWrite, IDEX_MemRead, IDEX_ALUSrc;
    reg        IDEX_CSRWrite, IDEX_CSRRead, IDEX_IsCSR, IDEX_IsMRET;
    reg [11:0] IDEX_CSRAddr;
    reg        IDEX_valid;
    reg        IDEX_Exception;
    reg [31:0] IDEX_ExceptionCause;
    
    // EX/MEM Pipeline Register
    reg [31:0] EXMEM_ALUOut, EXMEM_RD2, EXMEM_PC;
    reg [4:0]  EXMEM_rd, EXMEM_rs2;
    reg [2:0]  EXMEM_DMType, EXMEM_CSROp;
    reg [1:0]  EXMEM_WDSel;
    reg        EXMEM_RegWrite, EXMEM_MemWrite, EXMEM_MemRead;
    reg        EXMEM_CSRWrite, EXMEM_CSRRead, EXMEM_IsCSR, EXMEM_IsMRET;
    reg [11:0] EXMEM_CSRAddr;
    reg        EXMEM_valid;
    reg        EXMEM_Exception;
    reg [31:0] EXMEM_ExceptionCause;
    
    // MEM/WB Pipeline Register
    reg [31:0] MEMWB_ALUOut, MEMWB_MemData, MEMWB_PC, MEMWB_CSRData;
    reg [4:0]  MEMWB_rd;
    reg [1:0]  MEMWB_WDSel;
    reg        MEMWB_RegWrite;
    reg        MEMWB_IsCSR, MEMWB_IsMRET;
    reg        MEMWB_valid;
    reg        MEMWB_Exception;
    reg [31:0] MEMWB_ExceptionCause;

    // IF Stage Signals and Data
    reg  [31:0] PC_IF;                    // Program Counter
    reg  [31:0] NPC;                      // Next PC
    wire [31:0] PCPLUS4_IF;               // PC+4

    // ID Stage Signals and Data
    wire [31:0] RD1_ID, RD2_ID, imm_ID;   // Register data and immediate
    wire [4:0]  rs1_ID, rs2_ID, rd_ID;    // Register addresses
    wire [2:0]  DMType_ID;                // Data memory access type
    wire        RegWrite_ID, MemWrite_ID, MemRead_ID, ALUSrc_ID;
    wire [4:0]  ALUOp_ID;
    wire [1:0]  WDSel_ID;
    wire [5:0]  EXTOp_ID;
    wire        IsBranch_ID, IsJAL_ID, IsJALR_ID;
    wire [11:0] csr_addr_ID;              // CSR address
    wire        CSRWrite_ID, CSRRead_ID, IsCSR_ID, IsMRET_ID;
    wire [2:0]  CSROp_ID;
    wire        Exception_ID;
    wire [31:0] ExceptionCause_ID;

    // EX Stage Signals and Data
    wire [31:0] ALU_B, ALUOut_EX;         // ALU inputs and output
    reg  [31:0] ALU_A;                    // ALU input A (with forwarding)

    // MEM Stage Signals and Data
    wire [31:0] csr_rdata;

    // WB Stage Signals and Data
    reg  [31:0] WriteData_WB;             // Write back data
    wire        trap_taken_WB;
    wire [31:0] trap_pc_WB;
    wire [31:0] trap_cause_WB;

    // Hazard Detection and Forwarding
    wire       stall, flush_IFID, flush_IDEX, flush_EXMEM, flush_MEMWB;
    wire [1:0] forwardA, forwardB;
    wire [1:0] forwardA_branch, forwardB_branch;
    wire       forwardMEM;
    wire       branch_taken;
    
    // Interrupt and CSR signals
    wire        interrupt_req;
    wire [31:0] interrupt_cause;
    wire [31:0] mstatus, mtvec, mepc, mcause, mie, mip;
    wire        global_int_enable;
    wire        mret_taken;
    
    // Interrupt acknowledge signals: signal when specific interrupt is taken
    assign timer_int_ack = trap_taken_WB && (trap_cause_WB == `CAUSE_TIMER_INTERRUPT);
    assign ext_int_ack = trap_taken_WB && (trap_cause_WB == `CAUSE_EXTERNAL_INTERRUPT);
    

    // ========== 1 IF Stage ==========
    assign PCPLUS4_IF = PC_IF + 4;            // PC + 4
    
    // Next PC selection with interrupt handling
    always @(*) begin
        if (trap_taken_WB) begin
            NPC = mtvec;                   // Jump to interrupt vector
        end else if (mret_taken) begin
            NPC = mepc;                    // Return from interrupt
        end else if (branch_taken) begin
            NPC = branch_target;           // Branch/jump target
        end else begin
            NPC = PCPLUS4_IF;              // Sequential execution
        end
    end
    
    // Program Counter Register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC_IF <= `RESET_PC;
        end else if (!stall || branch_taken || trap_taken_WB || mret_taken) begin
            PC_IF <= NPC;
        end
    end

    assign PC_out = PC_IF;                // Output PC to instruction memory
    
    // IF/ID Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset || flush_IFID) begin
            IFID_PC <= `RESET_PC;
            IFID_inst <= `NOP_INSTRUCTION;
            IFID_valid <= 1'b0;
        end else if (!stall) begin
            IFID_PC <= PC_IF;
            IFID_inst <= Inst_in;
            IFID_valid <= 1'b1;
        end
    end

    // ========== 2 ID Stage ==========
    // Control Unit Instance
    ctrl U_CTRL(
        .Inst(IFID_inst),
        .rs1(rs1_ID),
        .rs2(rs2_ID),
        .rd(rd_ID),
        .csr_addr(csr_addr_ID),
        .RegWrite(RegWrite_ID), 
        .MemWrite(MemWrite_ID),
        .MemRead(MemRead_ID),
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
        .IsMRET(IsMRET_ID),
        .Exception(Exception_ID),
        .ExceptionCause(ExceptionCause_ID)
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
        .mie(mie),
        .mip(mip),
        .global_int_enable(global_int_enable),
        .interrupt_req(interrupt_req),
        .interrupt_cause(interrupt_cause)
    );

    ext U_EXT(
        .iimm_shamt(IFID_inst[24:20]), 
        .iimm(IFID_inst[31:20]), 
        .simm({IFID_inst[31:25], IFID_inst[11:7]}), 
        .bimm({IFID_inst[31], IFID_inst[7], IFID_inst[30:25], IFID_inst[11:8]}),
        .uimm(IFID_inst[31:12]), 
        .jimm({IFID_inst[31], IFID_inst[19:12], IFID_inst[20], IFID_inst[30:21]}),
        .EXTOp(EXTOp_ID), 
        .immout(imm_ID)
    );

    // Branch forwarding mux for register A
    reg [31:0] branch_A;
    always @(*) begin
        case (forwardA_branch)
            2'b00: branch_A = RD1_ID;              // No forwarding
            2'b01: branch_A = WriteData_WB;        // Forward from WB stage
            2'b10: begin                           // Forward from MEM stage
                case (EXMEM_WDSel)
                    `WDSel_FromMEM: branch_A = Data_in;      // Memory data
                    `WDSel_FromCSR: branch_A = csr_rdata;    // CSR data
                    default:        branch_A = EXMEM_ALUOut; // ALU data
                endcase
            end
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
            2'b10: begin                           // Forward from MEM stage
                case (EXMEM_WDSel)
                    `WDSel_FromMEM: branch_B = Data_in;      // Memory data
                    `WDSel_FromCSR: branch_B = csr_rdata;    // CSR data
                    default:        branch_B = EXMEM_ALUOut; // ALU data
                endcase
            end
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
            IDEX_MemRead <= 1'b0;
            IDEX_ALUSrc <= 1'b0;
            IDEX_CSRWrite <= 1'b0;
            IDEX_CSRRead <= 1'b0;
            IDEX_IsCSR <= 1'b0;
            IDEX_IsMRET <= 1'b0;
            IDEX_CSRAddr <= 12'h000;
            IDEX_Exception <= 1'b0;
            IDEX_ExceptionCause <= 32'h00000000;
            IDEX_valid <= 1'b0;
        end else if (!stall) begin
            IDEX_PC <= IFID_PC;
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
            IDEX_MemRead <= MemRead_ID;
            IDEX_ALUSrc <= ALUSrc_ID;
            IDEX_CSRWrite <= CSRWrite_ID;
            IDEX_CSRRead <= CSRRead_ID;
            IDEX_IsCSR <= IsCSR_ID;
            IDEX_IsMRET <= IsMRET_ID;
            IDEX_CSRAddr <= csr_addr_ID;
            IDEX_Exception <= Exception_ID;
            IDEX_ExceptionCause <= ExceptionCause_ID;
            IDEX_valid <= IFID_valid;
        end
    end

    // ========== 3 EX Stage ==========

    // Forwarding Mux for ALU input A
    always @(*) begin
        case (forwardA)
            2'b00: ALU_A = IDEX_RD1;           // No forwarding
            2'b01: ALU_A = WriteData_WB;       // Forward from WB stage  
            2'b10: begin                       // Forward from MEM stage
                case (EXMEM_WDSel)
                    `WDSel_FromMEM: ALU_A = Data_in;      // Memory data
                    `WDSel_FromCSR: ALU_A = csr_rdata;    // CSR data
                    default:        ALU_A = EXMEM_ALUOut; // ALU data
                endcase
            end
            default: ALU_A = IDEX_RD1;
        endcase
    end

    // Forwarding Mux for ALU input B
    reg [31:0] ALU_B_forwarded;
    always @(*) begin
        case (forwardB)
            2'b00: ALU_B_forwarded = IDEX_RD2;      // No forwarding
            2'b01: ALU_B_forwarded = WriteData_WB;  // Forward from WB stage
            2'b10: begin                            // Forward from MEM stage
                case (EXMEM_WDSel)
                    `WDSel_FromMEM: ALU_B_forwarded = Data_in;      // Memory data
                    `WDSel_FromCSR: ALU_B_forwarded = csr_rdata;    // CSR data
                    default:        ALU_B_forwarded = EXMEM_ALUOut; // ALU data
                endcase
            end
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
        .PC(IDEX_PC)
    );


    // EX/MEM Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset || flush_EXMEM) begin
            EXMEM_ALUOut <= 32'h00000000;
            EXMEM_RD2 <= 32'h00000000;
            EXMEM_PC <= 32'h00000000;
            EXMEM_rd <= 5'b00000;
            EXMEM_rs2 <= 5'b00000;
            EXMEM_DMType <= 3'b000;
            EXMEM_CSROp <= 3'b000;
            EXMEM_WDSel <= 2'b00;
            EXMEM_RegWrite <= 1'b0;
            EXMEM_MemWrite <= 1'b0;
            EXMEM_MemRead <= 1'b0;
            EXMEM_CSRWrite <= 1'b0;
            EXMEM_CSRRead <= 1'b0;
            EXMEM_IsCSR <= 1'b0;
            EXMEM_IsMRET <= 1'b0;
            EXMEM_CSRAddr <= 12'h000;
            EXMEM_Exception <= 1'b0;
            EXMEM_ExceptionCause <= 32'h00000000;
            EXMEM_valid <= 1'b0;
        end else begin
            EXMEM_ALUOut <= ALUOut_EX;
            EXMEM_RD2 <= ALU_B_forwarded; // Use forwarded data for store
            EXMEM_PC <= IDEX_PC;
            EXMEM_rd <= IDEX_rd;
            EXMEM_rs2 <= IDEX_rs2;
            EXMEM_DMType <= IDEX_DMType;
            EXMEM_CSROp <= IDEX_CSROp;
            EXMEM_WDSel <= IDEX_WDSel;
            EXMEM_RegWrite <= IDEX_RegWrite;
            EXMEM_MemWrite <= IDEX_MemWrite;
            EXMEM_MemRead <= IDEX_MemRead;
            EXMEM_CSRWrite <= IDEX_CSRWrite;
            EXMEM_CSRRead <= IDEX_CSRRead;
            EXMEM_IsCSR <= IDEX_IsCSR;
            EXMEM_IsMRET <= IDEX_IsMRET;
            EXMEM_CSRAddr <= IDEX_CSRAddr;
            EXMEM_Exception <= IDEX_Exception;
            EXMEM_ExceptionCause <= IDEX_ExceptionCause;
            EXMEM_valid <= IDEX_valid;
        end
    end

    // ========== 4 MEM Stage ==========
    // Memory interface
    assign Addr_out = EXMEM_ALUOut;
    assign Data_out = forwardMEM ? WriteData_WB : EXMEM_RD2;
    assign DMType_out = EXMEM_DMType;
    assign mem_w = EXMEM_MemWrite & EXMEM_valid;
    assign mem_r = EXMEM_MemRead & EXMEM_valid;

    // CSR signals
    assign mret_taken = MEMWB_IsMRET & MEMWB_valid;

    // CSR Unit Instance
    csr U_CSR(
        .clk(clk),
        .reset(reset),
        .csr_write(EXMEM_CSRWrite & EXMEM_valid),
        .csr_read(EXMEM_CSRRead & EXMEM_valid),
        .csr_addr(EXMEM_CSRAddr),
        .csr_wdata(EXMEM_ALUOut), // Use ALU output as CSR write data
        .csr_op(EXMEM_CSROp),
        .csr_rdata(csr_rdata),
        .trap_taken(trap_taken_WB),
        .trap_cause(trap_cause_WB),
        .trap_pc(MEMWB_PC), // PC of instruction completing in WB
        .mret_taken(mret_taken),
        .external_interrupt(external_int),
        .timer_interrupt(timer_int),
        .mstatus(mstatus),
        .mtvec(mtvec),
        .mepc(mepc),
        .mcause(mcause),
        .mie(mie),
        .mip(mip),
        .global_int_enable(global_int_enable)
    );

    // MEM/WB Pipeline Register
    always @(posedge clk or posedge reset) begin
        if (reset || flush_MEMWB) begin
            MEMWB_ALUOut <= 32'h00000000;
            MEMWB_MemData <= 32'h00000000;
            MEMWB_PC <= 32'h00000000;
            MEMWB_CSRData <= 32'h00000000;
            MEMWB_rd <= 5'b00000;
            MEMWB_WDSel <= 2'b00;
            MEMWB_RegWrite <= 1'b0;
            MEMWB_IsCSR <= 1'b0;
            MEMWB_IsMRET <= 1'b0;
            MEMWB_Exception <= 1'b0;
            MEMWB_ExceptionCause <= 32'h00000000;
            MEMWB_valid <= 1'b0;
        end else begin
            MEMWB_ALUOut <= EXMEM_ALUOut;
            MEMWB_MemData <= Data_in;
            MEMWB_PC <= EXMEM_PC;
            MEMWB_CSRData <= csr_rdata;
            MEMWB_rd <= EXMEM_rd;
            MEMWB_WDSel <= EXMEM_WDSel;
            MEMWB_RegWrite <= EXMEM_RegWrite;
            MEMWB_IsCSR <= EXMEM_IsCSR;
            MEMWB_IsMRET <= EXMEM_IsMRET;
            MEMWB_Exception <= EXMEM_Exception;
            MEMWB_ExceptionCause <= EXMEM_ExceptionCause;
            MEMWB_valid <= EXMEM_valid;
        end
    end

    // ========== 5 WB Stage ==========
    // Write back data selection
    always @(*) begin
        case(MEMWB_WDSel)
            `WDSel_FromALU: WriteData_WB = MEMWB_ALUOut;
            `WDSel_FromMEM: WriteData_WB = MEMWB_MemData;
            `WDSel_FromPC:  WriteData_WB = MEMWB_PC + 4;
            `WDSel_FromCSR: WriteData_WB = MEMWB_CSRData;
            default:        WriteData_WB = MEMWB_ALUOut;
        endcase
    end
    
    // Trap Unit Instance
    trap U_TRAP(
        .exception_req(MEMWB_Exception),
        .exception_cause(MEMWB_ExceptionCause),
        .interrupt_req(interrupt_req),
        .interrupt_cause(interrupt_cause),
        .mem_wb_valid(MEMWB_valid),
        .global_int_enable(global_int_enable),
        .trap_taken(trap_taken_WB),
        .trap_cause(trap_cause_WB)
    );

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
        .trap_taken(trap_taken_WB),
        .mret_taken(mret_taken),
        .stall(stall),
        .flush_IFID(flush_IFID),
        .flush_IDEX(flush_IDEX),
        .flush_EXMEM(flush_EXMEM),
        .flush_MEMWB(flush_MEMWB),
        .branch_taken(branch_taken)
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
