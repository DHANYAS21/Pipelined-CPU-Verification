`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 20:57:33
// Design Name: 
// Module Name: fowarding_unit
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


module fowarding_unit (
input wire [4:0] ID_EX_RS1,
input wire [4:0] ID_EX_RS2,

input wire [4:0] EX_MEM_RD,
input wire [4:0] MEM_WB_RD,

input wire EX_MEM_RegWrite,
input wire MEM_WB_RegWrite,
input wire EX_MEM_MemRead,

output reg [1:0] FA,
output reg [1:0] FB
);

always @(*) begin

// Default: use values from the register file
FA = 2'b00;
FB = 2'b00;

// Forward operand A (rs1)
// EX/MEM has priority over MEM/WB.
if (EX_MEM_RegWrite &&
!EX_MEM_MemRead &&
(EX_MEM_RD != 5'd0) &&
(EX_MEM_RD == ID_EX_RS1)) begin

FA = 2'b10;

end
else if (MEM_WB_RegWrite &&
(MEM_WB_RD != 5'd0) &&
(MEM_WB_RD == ID_EX_RS1)) begin

FA = 2'b01;

end

// Forward operand B (rs2)
if (EX_MEM_RegWrite &&
!EX_MEM_MemRead &&
(EX_MEM_RD != 5'd0) &&
(EX_MEM_RD == ID_EX_RS2)) begin

FB = 2'b10;

end
else if (MEM_WB_RegWrite &&
(MEM_WB_RD != 5'd0) &&
(MEM_WB_RD == ID_EX_RS2)) begin

FB = 2'b01;

end

end

endmodule