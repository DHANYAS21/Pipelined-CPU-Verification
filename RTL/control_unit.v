`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.10.2026 17:12:26
// Design Name: 
// Module Name: control_unit
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


module control_unit(
input [6:0]op_code,

output reg[1:0] Alu_Op,
output reg MemRead,
output reg MemWrite,
output reg MemtoReg,

output reg RegWrite,
output reg AluSrc
);
localparam R=7'b0110011;
localparam ADDI=7'b0010011;
localparam LW=7'b0000011;
localparam SW=7'b0100011;

always @(*) begin
Alu_Op=0;
MemWrite=0;
MemRead=0;
MemtoReg=0;

RegWrite=0;
AluSrc=0;

case(op_code)
R:begin
    RegWrite=1; Alu_Op=2'b10;
    AluSrc=0;
    MemWrite=0;
    MemRead=0;
  MemtoReg=0;
    
end
    

ADDI: begin
    RegWrite = 1;
    AluSrc   = 1;
    Alu_Op   = 2'b00;
    MemRead  = 0;
    MemWrite = 0;
    MemtoReg = 0;
end

LW: begin 
RegWrite= 1; AluSrc=1; Alu_Op=2'b00; MemRead=1;
MemtoReg=1; MemWrite=0;
end
SW: begin 
RegWrite= 0; AluSrc=1; Alu_Op=2'b00; MemWrite=1;
MemRead=0;
MemtoReg=0;
end
default : begin
Alu_Op=0;
MemWrite=0;
MemRead=0;
MemtoReg=0;

RegWrite=0;
AluSrc=0;
end
endcase
end
endmodule

