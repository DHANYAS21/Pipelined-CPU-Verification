
`timescale 1ns/1ps
`include "uvm_macros.svh"

package cpu_pkg;
    import uvm_pkg::*;

    // Independent assertion failure counters
    int fwd_fa_fails          = 0;
    int fwd_fb_fails          = 0;
    int fwd_rs1_x0_fails      = 0;
    int fwd_rs2_x0_fails      = 0;

    int hazard_stall_fails   = 0;
    int hazard_pc_fails      = 0;
    int hazard_bubble_fails  = 0;
    int hazard_cycle_fails   = 0;

    int pipe_store_fails     = 0;
    int pipe_load_fails      = 0;
    int pipe_early_use_fails = 0;

    // Return total assertion failures
    function automatic int get_assert_fails();
        return fwd_fa_fails
             + fwd_fb_fails
             + fwd_rs1_x0_fails
             + fwd_rs2_x0_fails
             + hazard_stall_fails
             + hazard_pc_fails
             + hazard_bubble_fails
             + hazard_cycle_fails
             + pipe_store_fails
             + pipe_load_fails
             + pipe_early_use_fails;
    endfunction

    `include "cpu_items.sv"
    `include "cpu_sequences.sv"
    `include "cpu_driver.sv"
    `include "cpu_monitor.sv"
    `include "cpu_agent.sv"
    `include "cpu_coverage.sv"
    `include "cpu_scoreboard.sv"
    `include "cpu_env.sv"
    `include "cpu_tests.sv"

endpackage
