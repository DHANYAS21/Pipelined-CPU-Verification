`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.10.2026 11:52:05
// Design Name: 
// Module Name: if_id
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


module if_id(
    input clk,
    input reset,
    input [31:0] inst,
    input [31:0] pc1,
    input ifid_write,
    output reg [31:0] ifid_inst,
    output reg [31:0] ifid_pc
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ifid_inst <= 32'b0;
            ifid_pc   <= 32'b0;
        end
        else if (ifid_write) begin
            ifid_inst <= inst;
            ifid_pc   <= pc1;
        end
    end

endmodule