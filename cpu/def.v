// NPC control signal
`define NPC_PLUS4   3'b000
`define NPC_BRANCH  3'b001
`define NPC_JUMP    3'b010
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

