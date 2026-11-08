`timescale 1ns/1ps
interface cpu_if (input logic clk);
    logic        reset;
    logic        wb_en;
    logic [4:0]  wb_rd;
    logic [31:0] wb_data;
    logic        dmem_write;
    logic [31:0] dmem_addr, dmem_wdata;
    // internal hazard signals
    logic        stall;
    logic [1:0]  fa, fb;
    logic        regwrite_ex, memread_ex, memwrite_ex, alusrc_ex;
endinterface
