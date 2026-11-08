
`timescale 1ns/1ps
// data actually moving through the pipeline: store data, load data, no early use of a load
module pipeline_checker (
    input logic        clk, reset,
    input logic        memwrite_ex, memread_mem, regwrite_mem, regwrite_ex, alusrc_ex,
    input logic [4:0]  rd_mem, rs1_ex, rs2_ex,
    input logic [31:0] fwd_b,
    input logic        dmem_write,
    input logic [31:0] dmem_wdata, dmem_rdata,
    input logic        wb_en,
    input logic [31:0] wb_data
);
    // store writes the forwarded rs2 value, not the stale register-file value
    a_store_data: assert property (@(posedge clk) disable iff (reset)
        memwrite_ex |=> dmem_write && dmem_wdata == $past(fwd_b))
        else begin cpu_pkg::pipe_store_fails++; $error("store data is not the forwarded value"); end

    // loaded data is written back in the next cycle
    a_load_data: assert property (@(posedge clk) disable iff (reset)
        (memread_mem && regwrite_mem && rd_mem != 0) |=> wb_en && wb_data == $past(dmem_rdata))
        else begin cpu_pkg::pipe_load_fails++; $error("load data not written back"); end

    // an instruction never reaches EX while the load it depends on is still in MEM
    wire uses_rs2_ex = (regwrite_ex && !alusrc_ex) || memwrite_ex;
    a_no_early_use: assert property (@(posedge clk) disable iff (reset)
        !(memread_mem && rd_mem != 0 && (rs1_ex == rd_mem || (uses_rs2_ex && rs2_ex == rd_mem))))
        else begin cpu_pkg::pipe_early_use_fails++; $error("x%0d used while its load is still in MEM", rd_mem); end
endmodule
