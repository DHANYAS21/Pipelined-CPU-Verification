`timescale 1ns/1ps
bind cpu_core hazard_checker u_hazard_checker (
    .clk(clk), .reset(reset), .stall(stall), .pc(pc_reg),
    .memread_ex(memread_ex), .regwrite_ex(regwrite_ex), .memwrite_ex(memwrite_ex),
    .rd_ex(rd_ex), .rs1_id(rs1_id), .rs2_id(rs2_id),
    .uses_rs1_id(uses_rs1_id), .uses_rs2_id(uses_rs2_id));

bind cpu_core forwarding_checker u_forwarding_checker (
    .clk(clk), .reset(reset), .fa(FA), .fb(FB),
    .rs1_ex(rs1_ex), .rs2_ex(rs2_ex), .rd_mem(rd_mem), .rd_wb(rd_wb),
    .regwrite_mem(regwrite_mem), .memread_mem(memread_mem), .regwrite_wb(regwrite_wb));

bind cpu_core pipeline_checker u_pipeline_checker (
    .clk(clk), .reset(reset),
    .memwrite_ex(memwrite_ex), .memread_mem(memread_mem), .regwrite_mem(regwrite_mem),
    .regwrite_ex(regwrite_ex), .alusrc_ex(alusrc_ex),
    .rd_mem(rd_mem), .rs1_ex(rs1_ex), .rs2_ex(rs2_ex), .fwd_b(forwarded_b_ex),
    .dmem_write(dmem_write), .dmem_wdata(dmem_wdata), .dmem_rdata(dmem_rdata),
    .wb_en(writeback_enable), .wb_data(writeback_data));
