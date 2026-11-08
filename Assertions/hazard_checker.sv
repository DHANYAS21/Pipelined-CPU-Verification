
`timescale 1ns/1ps
// load-use stall checks
module hazard_checker (
    input logic        clk, reset, stall,
    input logic [31:0] pc,
    input logic        memread_ex, regwrite_ex, memwrite_ex,
    input logic [4:0]  rd_ex, rs1_id, rs2_id,
    input logic        uses_rs1_id, uses_rs2_id
);
    wire load_use = memread_ex && rd_ex != 0 &&
                    ((uses_rs1_id && rs1_id == rd_ex) || (uses_rs2_id && rs2_id == rd_ex));

    a_stall_on_load_use: assert property (@(posedge clk) disable iff (reset) stall == load_use)
        else begin cpu_pkg::hazard_stall_fails++; $error("stall=%b but load-use=%b", stall, load_use); end

    a_pc_hold: assert property (@(posedge clk) disable iff (reset) stall |=> pc == $past(pc))
        else begin cpu_pkg::hazard_pc_fails++; $error("PC changed during stall"); end

    a_bubble: assert property (@(posedge clk) disable iff (reset)
        stall |=> !regwrite_ex && !memread_ex && !memwrite_ex)
        else begin cpu_pkg::hazard_bubble_fails++; $error("no bubble after stall"); end

    a_one_cycle: assert property (@(posedge clk) disable iff (reset) stall |=> !stall)
        else begin cpu_pkg::hazard_cycle_fails++; $error("stall longer than 1 cycle"); end

    c_stall: cover property (@(posedge clk) disable iff (reset) stall);
endmodule
