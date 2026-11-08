`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2026 01:26:27 PM
// Design Name: 
// Module Name: datamem
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


module datamem(
    input [31:0] addr,
    input wire[31:0] write_data,
    input memory_read,
    input memory_write,
    input clk,
    output reg [31:0] read_data_mem
    );
    reg [31:0] mem [0:255];
    // synthesis translate_off

integer i;

initial begin
    for (i = 0; i < 256; i = i + 1) begin
        mem[i] = 32'b0;
    end
end

// synthesis translate_on
    wire [31:0] index;
    assign index = (addr-1000) >> 2;
    always@(*)
    if(memory_read)
     read_data_mem=mem[index];
   else
        read_data_mem = 1'b0;
                 
    always@(posedge clk)
        if(memory_write)
                mem[index]<=write_data;
        
    
endmodule
