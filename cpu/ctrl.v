module ctrl(
    input  [6:0] Op,       // opcode
    input  [6:0] Funct7,   // funct7
    input  [2:0] Funct3,   // funct3
    input        Zero,     // zero flag (unused in current implementation)
    
    output       RegWrite, // control signal for register write
    output       MemWrite, // control signal for memory write
    output [5:0] EXTOp,    // control signal for immediate extension
    output [4:0] ALUOp,    // ALU operation code
    output       ALUSrc,   // ALU source selection
    output [2:0] DMType,   // data memory access type
    output [1:0] WDSel,    // write data selection
    output       IsBranch, // branch instruction indicator
    output       IsJAL,    // JAL instruction indicator
    output       IsJALR,   // JALR instruction indicator
    
    // CSR instruction support
    output       CSRWrite, // CSR write enable
    output       CSRRead,  // CSR read enable
    output [2:0] CSROp,    // CSR operation
    output       IsCSR,    // CSR instruction indicator
    output       IsMRET    // MRET instruction indicator
);
   
    // ========== Instruction Format Detection ==========
    wire rtype   = (Op == 7'b0110011);  // R-type: register-register operations
    wire itype_l = (Op == 7'b0000011);  // I-type: load instructions
    wire itype_r = (Op == 7'b0010011);  // I-type: immediate arithmetic
    wire stype   = (Op == 7'b0100011);  // S-type: store instructions
    wire sbtype  = (Op == 7'b1100011);  // SB-type: branch instructions
    wire i_jal   = (Op == 7'b1101111);  // UJ-type: jump and link
    wire i_jalr  = (Op == 7'b1100111);  // I-type: jump and link register
    wire i_auipc = (Op == 7'b0010111);  // U-type: add upper immediate to PC
    wire i_lui   = (Op == 7'b0110111);  // U-type: load upper immediate
    wire csrtype = (Op == `CSR_OPCODE);  // CSR instructions
    
    // ========== R-type Instructions ==========
    wire i_add  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b000);  // ADD
    wire i_sub  = rtype & (Funct7 == 7'b0100000) & (Funct3 == 3'b000);  // SUB
    wire i_or   = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b110);  // OR
    wire i_and  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b111);  // AND
    wire i_sll  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b001);  // SLL
    wire i_slt  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b010);  // SLT
    wire i_sltu = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b011);  // SLTU
    wire i_xor  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b100);  // XOR
    wire i_srl  = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b101);  // SRL
    wire i_sra  = rtype & (Funct7 == 7'b0100000) & (Funct3 == 3'b101);  // SRA

    // ========== Load Instructions ==========
    wire i_lb  = itype_l & (Funct3 == 3'b000);  // LB - load byte
    wire i_lh  = itype_l & (Funct3 == 3'b001);  // LH - load halfword
    wire i_lw  = itype_l & (Funct3 == 3'b010);  // LW - load word
    wire i_lbu = itype_l & (Funct3 == 3'b100);  // LBU - load byte unsigned
    wire i_lhu = itype_l & (Funct3 == 3'b101);  // LHU - load halfword unsigned

    // ========== I-type Arithmetic Instructions ==========
    wire i_addi  = itype_r & (Funct3 == 3'b000);                        // ADDI
    wire i_ori   = itype_r & (Funct3 == 3'b110);                        // ORI
    wire i_andi  = itype_r & (Funct3 == 3'b111);                        // ANDI
    wire i_xori  = itype_r & (Funct3 == 3'b100);                        // XORI
    wire i_slti  = itype_r & (Funct3 == 3'b010);                        // SLTI
    wire i_sltiu = itype_r & (Funct3 == 3'b011);                        // SLTIU
    wire i_slli  = itype_r & (Funct3 == 3'b001);                        // SLLI
    wire i_srli  = itype_r & (Funct7 == 7'b0000000) & (Funct3 == 3'b101); // SRLI
    wire i_srai  = itype_r & (Funct7 == 7'b0100000) & (Funct3 == 3'b101); // SRAI

    // ========== Store Instructions ==========
    wire i_sw = stype & (Funct3 == 3'b010);  // SW - store word
    wire i_sb = stype & (Funct3 == 3'b000);  // SB - store byte
    wire i_sh = stype & (Funct3 == 3'b001);  // SH - store halfword
    
    // ========== Branch Instructions ==========
    wire i_beq  = sbtype & (Funct3 == 3'b000);  // BEQ - branch if equal
    wire i_bne  = sbtype & (Funct3 == 3'b001);  // BNE - branch if not equal
    wire i_blt  = sbtype & (Funct3 == 3'b100);  // BLT - branch if less than
    wire i_bge  = sbtype & (Funct3 == 3'b101);  // BGE - branch if greater or equal
    wire i_bltu = sbtype & (Funct3 == 3'b110);  // BLTU - branch if less than unsigned
    wire i_bgeu = sbtype & (Funct3 == 3'b111);  // BGEU - branch if greater or equal unsigned
    
    // ========== CSR Instructions ==========
    wire i_csrrw  = csrtype & (Funct3 == `CSR_CSRRW);   // CSRRW - CSR read/write
    wire i_csrrs  = csrtype & (Funct3 == `CSR_CSRRS);   // CSRRS - CSR read/set
    wire i_csrrc  = csrtype & (Funct3 == `CSR_CSRRC);   // CSRRC - CSR read/clear
    wire i_csrrwi = csrtype & (Funct3 == `CSR_CSRRWI);  // CSRRWI - CSR read/write immediate
    wire i_csrrsi = csrtype & (Funct3 == `CSR_CSRRSI);  // CSRRSI - CSR read/set immediate
    wire i_csrrci = csrtype & (Funct3 == `CSR_CSRRCI);  // CSRRCI - CSR read/clear immediate
    wire i_mret   = csrtype & (Funct3 == 3'b000) & (Funct7 == 7'b0011000); // MRET

    // ========== Control Signal Generation ==========
    // Register write enable
    assign RegWrite = rtype | itype_l | itype_r | i_jalr | i_jal | i_lui | i_auipc | 
                      (csrtype & !i_mret); // CSR instructions write to register (except MRET)
    
    // Memory write enable
    assign MemWrite = stype;
    
    // ALU source selection (0: register, 1: immediate)
    assign ALUSrc = itype_l | itype_r | stype | i_jal | i_jalr | i_auipc | i_lui;
    
    // Write data selection (00: ALU, 01: Memory, 10: PC+4, 11: CSR)
    assign WDSel[0] = itype_l | csrtype;      // Memory data or CSR data
    assign WDSel[1] = i_jal | i_jalr | csrtype; // PC+4 for jumps or CSR data    

    // ALU operation encoding (5-bit operation code)
    assign ALUOp[0] = i_jal | i_jalr | itype_l | stype | i_addi | i_ori | i_add | i_or |
                      | i_sltiu | i_sltu | i_slli | i_sll | i_sra | i_srai | i_lui;
                      
    assign ALUOp[1] = i_jal | i_jalr | itype_l | stype | i_addi | i_add | i_and | i_andi |
                      i_auipc | i_slt | i_slti | i_sltiu | i_sltu | i_slli | i_sll;
                      
    assign ALUOp[2] = i_andi | i_and | i_ori | i_or | i_sub | i_xor | i_xori 
                      | i_sll | i_slli;
                      
    assign ALUOp[3] = i_andi | i_and | i_ori | i_or | i_slt | i_slti |
                      i_sltiu | i_sltu | i_xor | i_xori | i_sll | i_slli;
                      
    assign ALUOp[4] = i_srl | i_sra | i_srli | i_srai;

    // Immediate extension control (6-bit operation code)
    assign EXTOp[0] = i_jal;                                              // J-type immediate
    assign EXTOp[1] = i_auipc | i_lui;                                    // U-type immediate
    assign EXTOp[2] = sbtype;                                             // Branch immediate
    assign EXTOp[3] = stype;                                              // Store immediate
    assign EXTOp[4] = itype_l | i_addi | i_slti | i_sltiu | i_xori | i_ori | i_andi | i_jalr; // I-type immediate
    assign EXTOp[5] = i_slli | i_srli | i_srai;                          // Shift amount (5-bit)
    
    // Data memory access type
    assign DMType[0] = i_lb | i_lh | i_sb | i_sh;                        // Byte/halfword access
    assign DMType[1] = i_lhu | i_lb | i_sb;                              // Unsigned/byte access
    assign DMType[2] = i_lbu;                                            // Unsigned byte
    
    // Branch instructions indicator
    assign IsBranch = sbtype;
    
    // JAL instruction indicator
    assign IsJAL = i_jal;
    
    // JALR instruction indicator
    assign IsJALR = i_jalr;
    
    // ========== CSR Control Signal Generation ==========
    // CSR write enable
    assign CSRWrite = csrtype & !i_mret;
    
    // CSR read enable  
    assign CSRRead = csrtype;
    
    // CSR operation
    assign CSROp = Funct3;
    
    // CSR instruction indicator
    assign IsCSR = csrtype;
    
    // MRET instruction indicator
    assign IsMRET = i_mret;

endmodule
