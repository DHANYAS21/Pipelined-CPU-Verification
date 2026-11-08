`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.10.2026 00:39:37
// Design Name: 
// Module Name: regfile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module regfile(
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] write_data,
    input         regWrite, clk, reset,        // reset added
    output [31:0] read_d1, read_d2
);
    reg [31:0] register [0:31];
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) register[i] <= 32'b0;
        end else if (regWrite && rd != 5'd0)
            register[rd] <= write_data;
    end
    assign read_d1 = (rs1 == 5'd0) ? 32'b0 :
                     (regWrite && rd == rs1) ? write_data : register[rs1];
    assign read_d2 = (rs2 == 5'd0) ? 32'b0 :
                     (regWrite && rd == rs2) ? write_data : register[rs2];
endmodule
 
