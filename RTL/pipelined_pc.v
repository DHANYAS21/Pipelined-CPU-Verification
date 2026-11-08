
`timescale 1ns / 1ps

module pipelined_pc(
    input wire clk,
    input wire reset,
    input wire stall,
    input wire [31:0] next_pc,
    output reg [31:0] curr_pc
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            curr_pc <= 32'd0;
        else if (stall)
            curr_pc <= curr_pc;
        else
            curr_pc <= next_pc;
    end

endmodule
