`timescale 1ns / 1ps

module ex_mem (
    input clk,
    input reset,

    // Control Inputs (EX stage)
    input RegWrite_in,
    input MemtoReg_in,
    input MemRead_in,
    input MemWrite_in,

    // Data Inputs (EX stage)
    input [31:0] alu_out_in,
    input [31:0] write_data_in, // read_d2 passed through for SW
    input [4:0]  rd_in,

    // Control Outputs (MEM stage)
    output reg RegWrite_out,
    output reg MemtoReg_out,
    output reg MemRead_out,
    output reg MemWrite_out,

    // Data Outputs (MEM stage)
    output reg [31:0] alu_out_out,
    output reg [31:0] write_data_out,
    output reg [4:0]  rd_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWrite_out   <= 1'b0;
            MemtoReg_out   <= 1'b0;
            MemRead_out    <= 1'b0;
            MemWrite_out   <= 1'b0;
            alu_out_out    <= 32'b0;
            write_data_out <= 32'b0;
            rd_out         <= 5'b0;
        end else begin
            RegWrite_out   <= RegWrite_in;
            MemtoReg_out   <= MemtoReg_in;
            MemRead_out    <= MemRead_in;
            MemWrite_out   <= MemWrite_in;
            alu_out_out    <= alu_out_in;
            write_data_out <= write_data_in;
            rd_out         <= rd_in;
        end
    end

endmodule