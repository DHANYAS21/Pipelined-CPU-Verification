`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 10:19:24
// Design Name: 
// Module Name: mem_wb
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


module mem_wb (
    input clk,
    input reset,

    // Control Inputs (MEM stage)
    input RegWrite_in,
    input MemtoReg_in,

    // Data Inputs (MEM stage)
    input [31:0] read_data_mem_in,
    input [31:0] alu_out_in,
    input [4:0]  rd_in,

    // Control Outputs (WB stage)
    output reg RegWrite_out,
    output reg MemtoReg_out,

    // Data Outputs (WB stage)
    output reg [31:0] read_data_mem_out,
    output reg [31:0] alu_out_out,
    output reg [4:0]  rd_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWrite_out      <= 1'b0;
            MemtoReg_out      <= 1'b0;
            read_data_mem_out <= 32'b0;
            alu_out_out       <= 32'b0;
            rd_out            <= 5'b0;
        end else begin
            RegWrite_out      <= RegWrite_in;
            MemtoReg_out      <= MemtoReg_in;
            read_data_mem_out <= read_data_mem_in;
            alu_out_out       <= alu_out_in;
            rd_out            <= rd_in;
        end
    end

endmodule
