`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.10.2026 00:02:49
// Design Name: 
// Module Name: Alu
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


module Alu(
input [31:0] a,
input [31:0] b,
output reg [31:0] out,
input [3:0]sel
 );
 localparam ADD=4'b0010;
 localparam SUB=4'b0110;
 localparam AND=4'b0000;
 localparam OR=4'b0001;
 
 
 
 always @(*) begin
 case(sel)
    ADD: out =a+b;
    SUB: out =a-b;
    AND: out=a&b;
    OR: out = a|b;
    default: out=32'b0;
    
    endcase 
    end
    
endmodule
