
// instruction memory
module im #(
    parameter INSTR_FILE = "../instr/non_data_sim5.dat"
)(
    input  [8:2]  addr,
    output [31:0] dout 
);

  reg  [31:0] ROM[0:127];

    // added
    initial begin
        $readmemh(INSTR_FILE, ROM);
    end

  assign dout = ROM[addr]; // word aligned
endmodule  
