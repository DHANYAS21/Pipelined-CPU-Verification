`timescale 1ns / 1ps
// Instruction memory (behavioural model - not part of the synthesised core).
// Simulation: loads a hex file given on the command line with  +HEX=<file>
// (all other locations hold NOPs, so the pipeline never fetches X).
module instr_mem(
    input  wire [31:0] next_pc,
    output reg  [31:0] instr
);
    wire [31:0] index;
    reg  [31:0] mem [0:255];            // ascending range: word 0 is mem[0]
    assign index = next_pc >> 2;

    always @(*) instr = mem[index];

    // synthesis translate_off
    integer k;
    reg [8*128-1:0] hexfile;
    initial begin
        for (k = 0; k < 256; k = k + 1) mem[k] = 32'h0000_0013;      // NOP = addi x0,x0,0
        if ($value$plusargs("HEX=%s", hexfile)) $readmemh(hexfile, mem);
    end
    // synthesis translate_on
endmodule
