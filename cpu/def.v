// NPC control signal
`define NPC_BRANCH  3'b001
`define NPC_JAL     3'b010
`define NPC_JALR    3'b100

//EXT CTRL itype, stype, btype, utype, jtype
`define EXT_CTRL_ITYPE_SHAMT 6'b100000
`define EXT_CTRL_ITYPE	     6'b010000
`define EXT_CTRL_STYPE	     6'b001000
`define EXT_CTRL_BTYPE	     6'b000100
`define EXT_CTRL_UTYPE	     6'b000010
`define EXT_CTRL_JTYPE	     6'b000001

// Write data selection
`define WDSel_FromALU 2'b00
`define WDSel_FromMEM 2'b01
`define WDSel_FromPC 2'b10
`define WDSel_FromCSR 2'b11

// ALU control signal
`define ALUOp_nop 5'b00000
`define ALUOp_lui 5'b00001
`define ALUOp_auipc 5'b00010
`define ALUOp_add 5'b00011
`define ALUOp_sub 5'b00100
`define ALUOp_slt 5'b01010
`define ALUOp_sltu 5'b01011
`define ALUOp_xor 5'b01100
`define ALUOp_or 5'b01101
`define ALUOp_and 5'b01110
`define ALUOp_sll 5'b01111
`define ALUOp_srl 5'b10000
`define ALUOp_sra 5'b10001

// Common constants
`define NOP_INSTRUCTION 32'h00000013  // addi x0, x0, 0
`define RESET_PC 32'h00000000
`define PC_INCREMENT 32'h00000004
`define REG_ZERO 5'b00000

// CSR addresses (Machine Mode)
`define CSR_MSTATUS  12'h300  // Machine status register
`define CSR_MIE      12'h304  // Machine interrupt enable
`define CSR_MTVEC    12'h305  // Machine trap vector
`define CSR_MEPC     12'h341  // Machine exception program counter
`define CSR_MCAUSE   12'h342  // Machine trap cause
`define CSR_MIP      12'h344  // Machine interrupt pending

// CSR instruction opcodes
`define CSR_CSRRW    3'b001  // CSR Read/Write
`define CSR_CSRRS    3'b010  // CSR Read/Set
`define CSR_CSRRC    3'b011  // CSR Read/Clear
`define CSR_CSRRWI   3'b101  // CSR Read/Write Immediate
`define CSR_CSRRSI   3'b110  // CSR Read/Set Immediate
`define CSR_CSRRCI   3'b111  // CSR Read/Clear Immediate

// Exception and interrupt causes
`define CAUSE_TIMER_INTERRUPT    32'h80000007  // Machine timer interrupt
`define CAUSE_EXTERNAL_INTERRUPT 32'h8000000B  // Machine external interrupt
`define CAUSE_ECALL_M            32'h0000000B  // Environment call from M-mode

// Machine Interrupt Enable (MIE) and Pending (MIP) register bit positions
// Machine-level only implementation according to RISC-V spec
// Machine software interrupt is not implemented
`define MIE_MTIE    7   // Machine timer interrupt enable
`define MIE_MEIE   11   // Machine external interrupt enable

// MIP register bit positions (same as MIE)
`define MIP_MTIP    7   // Machine timer interrupt pending
`define MIP_MEIP   11   // Machine external interrupt pending

// Status register bits
`define MSTATUS_MIE      3   // Machine interrupt enable
`define MSTATUS_MPIE     7   // Previous interrupt enable

