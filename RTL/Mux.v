`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.10.2026 17:00:13
// Design Name: 
// Module Name: Mux
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


module Mux(
input [31:0] a,
input [31:0] b,
input sel,
output reg [31:0]c
    );
    always @(*) begin
    case(sel)
    1'b0:c=a;
    1'b1:c =b;
    default:c=1'b0;
    endcase
end 
endmodule
