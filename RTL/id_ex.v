`timescale 1ns / 1ps
module id_ex (
    input clk,
    input reset,
    input bubble,

    // Control Inputs (ID stage)
    input RegWrite_in,
    input MemtoReg_in,
    input MemRead_in,
    input MemWrite_in,
    input AluSrc_in,
    input [1:0] Alu_Op_in,

    // Data Inputs (ID stage)
    input [31:0] read_d1_in,
    input [31:0] read_d2_in,
    input [31:0] immediate_in,
    input [2:0]  func3_in,
    input [6:0]  func7_in,
    input [4:0]  rd_in,
    input [4:0] rs1_in,
     input [4:0] rs2_in,

    // Control Outputs (EX stage)
    output reg RegWrite_out,
    output reg MemtoReg_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg AluSrc_out,
    output reg [1:0] Alu_Op_out,

    // Data Outputs (EX stage)
    output reg [31:0] read_d1_out,
    output reg [31:0] read_d2_out,
    output reg [31:0] immediate_out,
    output reg [2:0]  func3_out,
    output reg [6:0]  func7_out,
    output reg [4:0]  rd_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWrite_out  <= 1'b0;
            MemtoReg_out  <= 1'b0;
            MemRead_out   <= 1'b0;
            MemWrite_out  <= 1'b0;
            AluSrc_out    <= 1'b0;
            Alu_Op_out    <= 2'b0;
            read_d1_out   <= 32'b0;
            read_d2_out   <= 32'b0;
            immediate_out <= 32'b0;
            func3_out     <= 3'b0;
            func7_out     <= 7'b0;
            rd_out        <= 5'b0;
            rs1_out<= 5'b0;
            rs2_out<=5'b0;
        end 
        else if(bubble==1)begin
             RegWrite_out  <= 1'b0;
            MemtoReg_out  <= 1'b0;
            MemRead_out   <= 1'b0;
            MemWrite_out  <= 1'b0;
            AluSrc_out    <= 1'b0;
            Alu_Op_out    <= 2'b0;
            rd_out        <= 5'b0;
            rs1_out<= 5'b0;
            rs2_out<=5'b0;
            read_d1_out   <= 32'b0;
read_d2_out   <= 32'b0;
immediate_out <= 32'b0;
func3_out     <= 3'b0;
func7_out     <= 7'b0;
            
        end
        
        else begin
            RegWrite_out  <= RegWrite_in;
            MemtoReg_out  <= MemtoReg_in;
            MemRead_out   <= MemRead_in;
            MemWrite_out  <= MemWrite_in;
            AluSrc_out    <= AluSrc_in;
            Alu_Op_out    <= Alu_Op_in;
            read_d1_out   <= read_d1_in;
            read_d2_out   <= read_d2_in;
            immediate_out <= immediate_in;
            func3_out     <= func3_in;
            func7_out     <= func7_in;
            rd_out        <= rd_in;
            rs1_out<= rs1_in;
            rs2_out<=rs2_in;
        end
    end

endmodule