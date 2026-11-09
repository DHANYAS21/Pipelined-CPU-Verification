`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 12:09:48
// Design Name: 
// Module Name: piplined_cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cpu_core (
    input  wire        clk,
    input  wire        reset,

    // Instruction memory interface
    output wire [31:0] current_pc,
    input  wire [31:0] instruction,

    // Data memory interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata,
    output wire        dmem_read,
    output wire        dmem_write,

    // Debug / verification outputs
    output wire        writeback_enable,
    output wire [4:0]  writeback_rd,
    output wire [31:0] writeback_data
);

    // =====================================================
    // 1. INSTRUCTION FETCH (IF)
    // =====================================================

    wire  [31:0] pc_reg;
    wire [31:0] pc_next;

    wire pc_write;
    wire ifid_write;
    wire stall;

    assign current_pc = pc_reg;
    assign pc_next = pc_reg + 32'd4;

    // The PC holds during a load-use stall.
    pipelined_pc PC_PIPE (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .next_pc(pc_next),
    .curr_pc(pc_reg)
);


    // =====================================================
    // 2. IF/ID PIPELINE REGISTER
    // =====================================================

    wire [31:0] ifid_inst;
    wire [31:0] ifid_pc;

    // IF/ID holds its contents when ifid_write is low.
    if_id IF_ID (
    .clk(clk),
    .reset(reset),
    .ifid_write(ifid_write),
    .inst(instruction),
    .pc1(current_pc),
    .ifid_inst(ifid_inst),
    .ifid_pc(ifid_pc)
);


    // =====================================================
    // 3. INSTRUCTION DECODE (ID)
    // =====================================================

    wire [6:0] opcode_id;
    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    wire [4:0] rd_id;

    wire [2:0] func3_id;
    wire [6:0] func7_id;

    assign opcode_id = ifid_inst[6:0];
    assign rd_id     = ifid_inst[11:7];
    assign func3_id  = ifid_inst[14:12];
    assign rs1_id    = ifid_inst[19:15];
    assign rs2_id    = ifid_inst[24:20];
    assign func7_id  = ifid_inst[31:25];


    // Main control signals generated in ID.
    wire [1:0] alu_op_id;

    wire regwrite_id;
    wire memread_id;
    wire memwrite_id;
    wire memtoreg_id;
    wire alusrc_id;

    wire [31:0] immediate_id;

    control_unit CU (
        .op_code(opcode_id),
        .Alu_Op(alu_op_id),
        .MemRead(memread_id),
        .MemWrite(memwrite_id),
        .MemtoReg(memtoreg_id),
        .RegWrite(regwrite_id),
        .AluSrc(alusrc_id)
    );

    // Retains the existing immediate-generator module/interface.
    processor IMM_GEN (
        .instruction(ifid_inst),
        .immediate(immediate_id)
    );


    // =====================================================
    // 4. REGISTER FILE
    // =====================================================

    wire [31:0] read_d1_id;
    wire [31:0] read_d2_id;

    wire regwrite_wb;
    wire memtoreg_wb;

    wire [4:0]  rd_wb;
    wire [31:0] alu_result_wb;
    wire [31:0] read_data_mem_wb;
    wire [31:0] wb_data;

    // The WB stage writes results into the Register File.
    regfile REG_FILE (
        .rs1(rs1_id),
        .rs2(rs2_id),
        .rd(rd_wb),
        .write_data(wb_data),
        .regWrite(regwrite_wb),
        .clk(clk),
        .reset(reset),
        .read_d1(read_d1_id),
        .read_d2(read_d2_id)
    );


    // =====================================================
    // 5. SOURCE-REGISTER USAGE FOR HAZARD DETECTION
    // =====================================================

    reg uses_rs1_id;
    reg uses_rs2_id;

    // Supported subset:
    // R-type: ADD, SUB
    // I-type: ADDI, LW
    // S-type: SW
    //
    // These flags prevent immediate bits from being
    // incorrectly treated as an rs2 dependency.

    always @(*) begin
        uses_rs1_id = 1'b0;
        uses_rs2_id = 1'b0;

        case (opcode_id)

            7'b0110011: begin  // R-type: ADD, SUB
                uses_rs1_id = 1'b1;
                uses_rs2_id = 1'b1;
            end

            7'b0010011: begin  // I-type ALU: ADDI
                uses_rs1_id = 1'b1;
                uses_rs2_id = 1'b0;
            end

            7'b0000011: begin  // Load: LW
                uses_rs1_id = 1'b1;
                uses_rs2_id = 1'b0;
            end

            7'b0100011: begin  // Store: SW
                uses_rs1_id = 1'b1;
                uses_rs2_id = 1'b1;
            end

            default: begin
                uses_rs1_id = 1'b0;
                uses_rs2_id = 1'b0;
            end

        endcase
    end


    wire regwrite_ex;
    wire memtoreg_ex;
    wire memread_ex;
    wire memwrite_ex;
    wire alusrc_ex;
    wire [1:0] alu_op_ex;

    wire [31:0] read_d1_ex;
    wire [31:0] read_d2_ex;
    wire [31:0] immediate_ex;

    wire [2:0] func3_ex;
    wire [6:0] func7_ex;

    wire [4:0] rs1_ex;
    wire [4:0] rs2_ex;
    wire [4:0] rd_ex;

    // =====================================================
    // 6. HAZARD DETECTION UNIT
    // =====================================================

    // The hazard unit checks a load in ID/EX against the
    // source registers used by the instruction in IF/ID.
    hazard_detection HAZARD_UNIT (
        .ID_EX_MemRead(memread_ex),
        .ID_EX_RD(rd_ex),

        .IF_ID_RS1(rs1_id),
        .IF_ID_RS2(rs2_id),
        .IF_ID_UsesRs1(uses_rs1_id),
        .IF_ID_UsesRs2(uses_rs2_id),

        .PCWrite(pc_write),
        .IFIDWrite(ifid_write),
        .ST(stall)
    );



    // =====================================================
    // 7. ID/EX PIPELINE REGISTER
    // =====================================================

    // ID/EX receives a bubble during a load-use stall.
    id_ex ID_EX (
        .clk(clk),
        .reset(reset),
        .bubble(stall),

        .RegWrite_in(regwrite_id),
        .MemtoReg_in(memtoreg_id),
        .MemRead_in(memread_id),
        .MemWrite_in(memwrite_id),
        .AluSrc_in(alusrc_id),
        .Alu_Op_in(alu_op_id),

        .read_d1_in(read_d1_id),
        .read_d2_in(read_d2_id),
        .immediate_in(immediate_id),
        .func3_in(func3_id),
        .func7_in(func7_id),
        .rs1_in(rs1_id),
        .rs2_in(rs2_id),
        .rd_in(rd_id),

        .RegWrite_out(regwrite_ex),
        .MemtoReg_out(memtoreg_ex),
        .MemRead_out(memread_ex),
        .MemWrite_out(memwrite_ex),
        .AluSrc_out(alusrc_ex),
        .Alu_Op_out(alu_op_ex),

        .read_d1_out(read_d1_ex),
        .read_d2_out(read_d2_ex),
        .immediate_out(immediate_ex),
        .func3_out(func3_ex),
        .func7_out(func7_ex),
        .rs1_out(rs1_ex),
        .rs2_out(rs2_ex),
        .rd_out(rd_ex)
    );

    // 8. FORWARDING UNIT
  

    wire [1:0] FA;
    wire [1:0] FB;

    wire regwrite_mem;
    wire memtoreg_mem;
    wire memread_mem;
    wire memwrite_mem;

    wire [31:0] alu_result_mem;
    wire [31:0] store_data_mem;
    wire [4:0] rd_mem;

    fowarding_unit forwarding_unit (
        .ID_EX_RS1(rs1_ex),
        .ID_EX_RS2(rs2_ex),

        .EX_MEM_RD(rd_mem),
        .MEM_WB_RD(rd_wb),

        .EX_MEM_RegWrite(regwrite_mem),
        .MEM_WB_RegWrite(regwrite_wb),
        .EX_MEM_MemRead(memread_mem),

        .FA(FA),
        .FB(FB)
    );


    // =====================================================
    // 9. FORWARDING MULTIPLEXERS
    // =====================================================

    reg [31:0] forwarded_a_ex;
    reg [31:0] forwarded_b_ex;

    // Encoding must match forwarding_unit.v:
    // 00 = Register File
    // 01 = MEM/WB write-back data
    // 10 = EX/MEM ALU result

    always @(*) begin

        case (FA)
            2'b10: forwarded_a_ex = alu_result_mem;
            2'b01: forwarded_a_ex = wb_data;
            default: forwarded_a_ex = read_d1_ex;
        endcase

        case (FB)
            2'b10: forwarded_b_ex = alu_result_mem;
            2'b01: forwarded_b_ex = wb_data;
            default: forwarded_b_ex = read_d2_ex;
        endcase

    end


    // =====================================================
    // 10. EXECUTE (EX)
    // =====================================================

    wire [3:0] alu_control_ex;
    wire [31:0] alu_b_ex;
    wire [31:0] alu_result_ex;

    Alu_control ALU_CONTROL (
        .func3(func3_ex),
        .func7(func7_ex),
        .AluOp(alu_op_ex),
        .AluControl(alu_control_ex)
    );

    // Existing 2-to-1 MUX:
    // register operand or immediate.
    Mux ALU_MUX (
        .a(forwarded_b_ex),
        .b(immediate_ex),
        .sel(alusrc_ex),
        .c(alu_b_ex)
    );

    Alu ALU (
        .a(forwarded_a_ex),
        .b(alu_b_ex),
        .out(alu_result_ex),
        .sel(alu_control_ex)
    );


    // =====================================================
    // 11. EX/MEM PIPELINE REGISTER
    // =====================================================

    ex_mem EX_MEM (
        .clk(clk),
        .reset(reset),

        .RegWrite_in(regwrite_ex),
        .MemtoReg_in(memtoreg_ex),
        .MemRead_in(memread_ex),
        .MemWrite_in(memwrite_ex),

        .alu_out_in(alu_result_ex),
        .write_data_in(forwarded_b_ex),
        .rd_in(rd_ex),

        .RegWrite_out(regwrite_mem),
        .MemtoReg_out(memtoreg_mem),
        .MemRead_out(memread_mem),
        .MemWrite_out(memwrite_mem),

        .alu_out_out(alu_result_mem),
        .write_data_out(store_data_mem),
        .rd_out(rd_mem)
    );


  // =====================================================
// DATA MEMORY INTERFACE
// =====================================================

wire [31:0] read_data_mem;

// Address generated by the ALU
assign dmem_addr = alu_result_mem;

// Data to be written into data memory
assign dmem_wdata = store_data_mem;

// Memory read/write control signals
assign dmem_read  = memread_mem;
assign dmem_write = memwrite_mem;

// Data received from external data memory
assign read_data_mem = dmem_rdata;

    // =====================================================
    // 13. MEM/WB PIPELINE REGISTER
    // =====================================================

    mem_wb MEM_WB (
        .clk(clk),
        .reset(reset),

        .RegWrite_in(regwrite_mem),
        .MemtoReg_in(memtoreg_mem),

        .read_data_mem_in(read_data_mem),
        .alu_out_in(alu_result_mem),
        .rd_in(rd_mem),

        .RegWrite_out(regwrite_wb),
        .MemtoReg_out(memtoreg_wb),

        .read_data_mem_out(read_data_mem_wb),
        .alu_out_out(alu_result_wb),
        .rd_out(rd_wb)
    );


    // =====================================================
    // 14. WRITE BACK (WB)E
    // =====================================================

    Mux WB_MUX (
        .a(alu_result_wb),
        .b(read_data_mem_wb),
        .sel(memtoreg_wb),
        .c(wb_data)
    );

    assign writeback_enable = regwrite_wb;
    assign writeback_rd = rd_wb;
    assign writeback_data = wb_data;

endmodule
