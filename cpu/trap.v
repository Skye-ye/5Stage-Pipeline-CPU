module trap(
    input         exception_req,
    input  [31:0] exception_cause,
    input         interrupt_req,
    input  [31:0] interrupt_cause,
    input         mem_wb_valid,
    input         global_int_enable,

    output        trap_taken,
    output [31:0] trap_cause
);

    // Exceptions (like ecall) are always taken regardless of mstatus.MIE
    // Interrupts are only taken when global_int_enable (mstatus.MIE) is set
    assign trap_taken = (exception_req & mem_wb_valid) | (interrupt_req & mem_wb_valid & global_int_enable);
    assign trap_cause = interrupt_req ? interrupt_cause : exception_cause; // Interrupt has higher priority

endmodule