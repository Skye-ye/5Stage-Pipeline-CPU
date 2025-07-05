`include "def.v"

// Control and Status Register (CSR) Unit
// Implements Machine-mode CSRs for interrupt handling
module csr(
    input        clk,
    input        reset,
    
    // CSR instruction interface
    input        csr_write,        // CSR write enable
    input        csr_read,         // CSR read enable
    input [11:0] csr_addr,         // CSR address
    input [31:0] csr_wdata,        // CSR write data
    input [2:0]  csr_op,           // CSR operation (CSRRW, CSRRS, CSRRC)
    output reg [31:0] csr_rdata,   // CSR read data
    
    // Interrupt handling interface
    input        trap_taken,        // Trap taken signal
    input [31:0] trap_cause,        // Trap cause
    input [31:0] trap_pc,           // PC when trap occurred
    input        mret_taken,        // MRET instruction executed
    
    // External interrupt sources
    input        external_interrupt,  // External interrupt request
    input        timer_interrupt,     // Timer interrupt request
    
    // CSR outputs
    output [31:0] mstatus,         // Machine status register
    output [31:0] mtvec,           // Machine trap vector
    output [31:0] mepc,            // Machine exception program counter
    output [31:0] mcause,          // Machine trap cause
    output [31:0] mie,             // Machine interrupt enable
    output [31:0] mip,             // Machine interrupt pending
    output        global_int_enable // Global interrupt enable (mstatus.MIE)
);

    // CSR registers
    reg [31:0] csr_mstatus;
    reg [31:0] csr_mtvec;
    reg [31:0] csr_mepc;
    reg [31:0] csr_mcause;
    reg [31:0] csr_mie;
    reg [31:0] csr_mip;
    
    // CSR register assignments
    assign mstatus = csr_mstatus;
    assign mtvec = csr_mtvec;
    assign mepc = csr_mepc;
    assign mcause = csr_mcause;
    assign mie = csr_mie;
    assign mip = csr_mip;
    assign global_int_enable = csr_mstatus[`MSTATUS_MIE];
    
    // CSR initialization
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            csr_mstatus <= 32'h0;
            csr_mtvec   <= 32'h0;
            csr_mepc    <= 32'h0;
            csr_mcause  <= 32'h0;
            csr_mie     <= 32'h0;
            csr_mip     <= 32'h0;
        end else begin
            // Update MIP register according to RISC-V spec
            // MTIP is read-only and set by timer interrupt
            csr_mip[`MIP_MTIP] <= timer_interrupt;
            
            // MEIP is read-only and set by external interrupt controller
            csr_mip[`MIP_MEIP] <= external_interrupt;
            
            // Handle interrupt entry
            if (trap_taken) begin
                // Save current status
                csr_mstatus[`MSTATUS_MPIE] <= csr_mstatus[`MSTATUS_MIE];
                csr_mstatus[`MSTATUS_MIE] <= 1'b0; // Disable interrupts
                
                // Save interrupted PC and cause
                csr_mepc <= trap_pc;
                csr_mcause <= trap_cause;
            end
            
            // Handle MRET instruction
            if (mret_taken) begin
                // Restore interrupt enable
                csr_mstatus[`MSTATUS_MIE] <= csr_mstatus[`MSTATUS_MPIE];
                csr_mstatus[`MSTATUS_MPIE] <= 1'b1; // Set MPIE to 1
            end
            
            // Handle CSR instructions
            if (csr_write) begin
                case (csr_addr)
                    `CSR_MSTATUS: begin
                        case (csr_op)
                            `CSR_CSRRW: csr_mstatus <= csr_wdata;
                            `CSR_CSRRS: csr_mstatus <= csr_mstatus | csr_wdata;
                            `CSR_CSRRC: csr_mstatus <= csr_mstatus & ~csr_wdata;
                        endcase
                    end
                    `CSR_MTVEC: begin
                        case (csr_op)
                            `CSR_CSRRW: csr_mtvec <= csr_wdata;
                            `CSR_CSRRS: csr_mtvec <= csr_mtvec | csr_wdata;
                            `CSR_CSRRC: csr_mtvec <= csr_mtvec & ~csr_wdata;
                        endcase
                    end
                    `CSR_MEPC: begin
                        case (csr_op)
                            `CSR_CSRRW: csr_mepc <= csr_wdata;
                            `CSR_CSRRS: csr_mepc <= csr_mepc | csr_wdata;
                            `CSR_CSRRC: csr_mepc <= csr_mepc & ~csr_wdata;
                        endcase
                    end
                    `CSR_MCAUSE: begin
                        case (csr_op)
                            `CSR_CSRRW: csr_mcause <= csr_wdata;
                            `CSR_CSRRS: csr_mcause <= csr_mcause | csr_wdata;
                            `CSR_CSRRC: csr_mcause <= csr_mcause & ~csr_wdata;
                        endcase
                    end
                    `CSR_MIE: begin
                        // MIE register - all bits are writable for machine mode
                        case (csr_op)
                            `CSR_CSRRW: csr_mie <= csr_wdata;
                            `CSR_CSRRS: csr_mie <= csr_mie | csr_wdata;
                            `CSR_CSRRC: csr_mie <= csr_mie & ~csr_wdata;
                        endcase
                    end
                    `CSR_MIP: begin
                        // MIP register - not writable (since software interrupt is not implemented)
                        case (csr_op)
                            `CSR_CSRRW: ;
                            `CSR_CSRRS: ;
                            `CSR_CSRRC: ;
                        endcase
                    end
                endcase
            end
        end
    end
    
    // CSR read logic
    always @(*) begin
        csr_rdata = 32'h0;
        if (csr_read) begin
            case (csr_addr)
                `CSR_MSTATUS: csr_rdata = csr_mstatus;
                `CSR_MTVEC:   csr_rdata = csr_mtvec;
                `CSR_MEPC:    csr_rdata = csr_mepc;
                `CSR_MCAUSE:  csr_rdata = csr_mcause;
                `CSR_MIE:     csr_rdata = csr_mie;
                `CSR_MIP:     csr_rdata = csr_mip;
                default:      csr_rdata = 32'h0;
            endcase
        end
    end

endmodule