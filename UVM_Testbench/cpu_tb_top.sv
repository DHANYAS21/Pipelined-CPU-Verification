`timescale 1ns/1ps
`include "uvm_macros.svh"
module cpu_tb_top;
    import uvm_pkg::*;
    import cpu_pkg::*;

    logic clk = 0;
    always #5 clk = ~clk;

    cpu_if  intf (clk);
    cpu_bfm bfm  (clk);

    // memories (cpu_core has external memory ports)
    logic [31:0] imem [0:255];
    logic [31:0] dmem [0:255];

    wire [31:0] pc, instr, dmem_addr, dmem_wdata, dmem_rdata, wb_data;
    wire        dmem_read, dmem_write, wb_en;
    wire [4:0]  wb_rd;

    initial intf.reset = 1;

    assign instr = imem[pc[9:2]];

    wire [31:0] dmem_off = dmem_addr - 1000;           // address 1000 = word 0, like datamem.v
    assign dmem_rdata = dmem_read ? dmem[dmem_off[9:2]] : 0;
    always @(posedge clk)
        if (!intf.reset && dmem_write) dmem[dmem_off[9:2]] <= dmem_wdata;

    cpu_core DUT (
        .clk(clk), .reset(intf.reset),
        .current_pc(pc), .instruction(instr),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_rdata(dmem_rdata),
        .dmem_read(dmem_read), .dmem_write(dmem_write),
        .writeback_enable(wb_en), .writeback_rd(wb_rd), .writeback_data(wb_data));

    assign intf.wb_en       = wb_en;
    assign intf.wb_rd       = wb_rd;
    assign intf.wb_data     = wb_data;
    assign intf.dmem_write  = dmem_write;
    assign intf.dmem_addr   = dmem_addr;
    assign intf.dmem_wdata  = dmem_wdata;
    assign intf.stall       = DUT.stall;
    assign intf.fa          = DUT.FA;
    assign intf.fb          = DUT.FB;
    assign intf.regwrite_ex = DUT.regwrite_ex;
    assign intf.memread_ex  = DUT.memread_ex;
    assign intf.memwrite_ex = DUT.memwrite_ex;
    assign intf.alusrc_ex   = DUT.alusrc_ex;

    // bug injection, used by run_bugs.sh (the RTL files are not edited)
    initial begin
        if ($test$plusargs("BUG_NO_FWD_A"))   force DUT.FA = 2'b00;
        if ($test$plusargs("BUG_NO_FWD_B"))   force DUT.FB = 2'b00;
        if ($test$plusargs("BUG_NO_STALL"))   force DUT.HAZARD_UNIT.ID_EX_MemRead = 1'b0;
        if ($test$plusargs("BUG_STORE_DATA")) force DUT.EX_MEM.write_data_in = DUT.read_d2_ex;
    end

    // UVM: hand the interfaces to the testbench, then start the test
    initial begin
        uvm_config_db #(virtual cpu_if)::set(null, "*", "vif", intf);
        uvm_config_db #(virtual cpu_bfm)::set(null, "*", "bfm", bfm);
        run_test("cpu_full_test");     // overridden by +UVM_TESTNAME
    end

    initial begin
        #2ms $display("==== RESULT: FAIL (timeout)");
        $finish;
    end

    initial if ($test$plusargs("VCD")) begin
        $dumpfile("RESULTS/waveforms/waves.vcd");
        $dumpvars(0, cpu_tb_top);
    end
endmodule
