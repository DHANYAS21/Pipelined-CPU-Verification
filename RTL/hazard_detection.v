`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 20:16:49
// Design Name: 
// Module Name: hazard_detection
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



`timescale 1ns / 1ps

module hazard_detection (
    input wire ID_EX_MemRead,
    input wire [4:0] ID_EX_RD,

    input wire [4:0] IF_ID_RS1,
    input wire [4:0] IF_ID_RS2,

    input wire IF_ID_UsesRs1,
    input wire IF_ID_UsesRs2,

    output reg PCWrite,
    output reg IFIDWrite,
    output reg ST
);

    always @(*) begin

        // Default: normal execution, no stall
        PCWrite  = 1'b1;
        IFIDWrite = 1'b1;
        ST = 1'b0;

        // Load-use hazard:
        // A load in EX produces its data only after MEM.
        // The following instruction must wait if it needs
        // the loaded destination register.

        if (ID_EX_MemRead &&
            (ID_EX_RD != 5'd0) &&
            (
                (IF_ID_UsesRs1 && (ID_EX_RD == IF_ID_RS1)) ||
                (IF_ID_UsesRs2 && (ID_EX_RD == IF_ID_RS2))
            )
        ) begin
            PCWrite   = 1'b0;
            IFIDWrite = 1'b0;
            ST        = 1'b1;
        end

    end

endmodule
