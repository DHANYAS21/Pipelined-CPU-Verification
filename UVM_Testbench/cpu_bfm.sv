`timescale 1ns/1ps
// backdoor access to the TB memories and the register file
interface cpu_bfm (input logic clk);
    task automatic load_program(logic [31:0] words[$]);
        for (int i = 0; i < 256; i++) cpu_tb_top.imem[i] = 32'h00000013;   // nop
        foreach (words[i]) cpu_tb_top.imem[i] = words[i];
    endtask

    task automatic clear_dmem();
        for (int i = 0; i < 256; i++) cpu_tb_top.dmem[i] = 0;
    endtask

    function automatic logic [31:0] read_reg(int r);
        return cpu_tb_top.DUT.REG_FILE.register[r];
    endfunction
endinterface
