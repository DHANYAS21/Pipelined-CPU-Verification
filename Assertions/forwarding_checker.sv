

`timescale 1ns/1ps

// Checks forwarding priority: EX/MEM first, then MEM/WB.
// Never forward from x0 or from a load in MEM.

module forwarding_checker (
    input logic       clk, reset,
    input logic [1:0] fa, fb,
    input logic [4:0] rs1_ex, rs2_ex, rd_mem, rd_wb,
    input logic       regwrite_mem, memread_mem, regwrite_wb
);

    function automatic logic [1:0] expected(
        input logic [4:0] rs,
        input logic [4:0] rd_m,
        input logic [4:0] rd_w,
        input logic       rw_m,
        input logic       mr_m,
        input logic       rw_w
    );
        if (rw_m && !mr_m && (rd_m != 5'd0) && (rd_m == rs))
            return 2'b10;
        else if (rw_w && (rd_w != 5'd0) && (rd_w == rs))
            return 2'b01;
        else
            return 2'b00;
    endfunction

    a_fa: assert property (
        @(posedge clk) disable iff (reset)
        fa == expected(rs1_ex, rd_mem, rd_wb,
                       regwrite_mem, memread_mem, regwrite_wb)
    )
    else begin
        cpu_pkg::fwd_fa_fails++;
        $error("FA=%b EXP=%b RS1=%d RD_MEM=%d RD_WB=%d MEM_REGWRITE=%b MEM_READ=%b WB_REGWRITE=%b",
            $sampled(fa),
            $sampled(expected(rs1_ex, rd_mem, rd_wb,
                              regwrite_mem, memread_mem, regwrite_wb)),
            $sampled(rs1_ex),
            $sampled(rd_mem),
            $sampled(rd_wb),
            $sampled(regwrite_mem),
            $sampled(memread_mem),
            $sampled(regwrite_wb));
    end

    a_fb: assert property (
        @(posedge clk) disable iff (reset)
        fb == expected(rs2_ex, rd_mem, rd_wb,
                       regwrite_mem, memread_mem, regwrite_wb)
    )
    else begin
        cpu_pkg::fwd_fb_fails++;
        $error("FB=%b EXP=%b RS2=%d RD_MEM=%d RD_WB=%d MEM_REGWRITE=%b MEM_READ=%b WB_REGWRITE=%b",
            $sampled(fb),
            $sampled(expected(rs2_ex, rd_mem, rd_wb,
                              regwrite_mem, memread_mem, regwrite_wb)),
            $sampled(rs2_ex),
            $sampled(rd_mem),
            $sampled(rd_wb),
            $sampled(regwrite_mem),
            $sampled(memread_mem),
            $sampled(regwrite_wb));
    end

    c_fa_exmem: cover property (@(posedge clk) disable iff (reset) fa == 2'b10);
    c_fa_memwb: cover property (@(posedge clk) disable iff (reset) fa == 2'b01);
    c_fb_exmem: cover property (@(posedge clk) disable iff (reset) fb == 2'b10);
    c_fb_memwb: cover property (@(posedge clk) disable iff (reset) fb == 2'b01);

    // Register x0 must never receive forwarded data
    a_no_forward_rs1_x0: assert property (
        @(posedge clk) disable iff (reset)
        (rs1_ex == 5'd0) |-> (fa == 2'b00)
    )
    else begin
        cpu_pkg::fwd_rs1_x0_fails++;
        $error("Forwarding incorrectly selected for RS1=x0");
    end

    a_no_forward_rs2_x0: assert property (
        @(posedge clk) disable iff (reset)
        (rs2_ex == 5'd0) |-> (fb == 2'b00)
    )
    else begin
        cpu_pkg::fwd_rs2_x0_fails++;
        $error("Forwarding incorrectly selected for RS2=x0");
    end

endmodule
