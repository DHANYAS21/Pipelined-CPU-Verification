`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.10.2026 15:32:24
// Design Name: 
// Module Name: Alu_control
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



module Alu_control(
    input [2:0] func3,
    input [6:0] func7,
    input [1:0] AluOp,
    output reg [3:0] AluControl
);

always @(*) begin
    case (AluOp)

        // Load, Store, and ADDI: ADD
        2'b00: AluControl = 4'b0010;

        // R-type instructions
        2'b10: begin
            if (func3 == 3'b000 && func7 == 7'b0000000)
                AluControl = 4'b0010; // ADD

            else if (func3 == 3'b000 && func7 == 7'b0100000)
                AluControl = 4'b0110; // SUB

            else if (func3 == 3'b111 && func7 == 7'b0000000)
                AluControl = 4'b0000; // AND

            else if (func3 == 3'b110 && func7 == 7'b0000000)
                AluControl = 4'b0001; // OR

            else
                AluControl = 4'b0010; // Default: ADD
        end

        default: AluControl = 4'b0010;

    endcase
end

endmodule
