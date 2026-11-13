// cpu_instr        : one instruction (constrained random)
// cpu_program_item : sequence item = one complete test program
// cpu_obs          : what the monitor saw
// cpu_hz_item      : one verified instruction, sent to coverage

typedef enum {OP_ADD, OP_SUB, OP_AND, OP_OR, OP_ADDI, OP_LW, OP_SW} op_t;
typedef enum {OBS_RESET, OBS_EX, OBS_WB, OBS_ST} obs_t;

class cpu_instr extends uvm_object;
    `uvm_object_utils(cpu_instr)

    rand op_t      op;
    rand bit [4:0] rd, rs1, rs2;
    rand int       imm;

    // only x0-x4, so most random instructions depend on a recent one
    constraint c_op   { op dist {OP_ADD:=2, OP_SUB:=1, OP_AND:=1, OP_OR:=1,
                                 OP_ADDI:=2, OP_LW:=2, OP_SW:=2}; }
    constraint c_regs { rd inside {[0:4]}; rs1 inside {[0:4]}; rs2 inside {[0:4]}; }
    constraint c_imm  { if (op inside {OP_LW, OP_SW}) { rs1 == 0; imm inside {1000, 1004, 1008, 1012}; }
                        else if (op == OP_ADDI)        { imm inside {[-20:20]}; }
                        else                           { imm == 0; } }
    constraint c_unused { (op == OP_SW) -> rd == 0;
                          (op inside {OP_ADDI, OP_LW}) -> rs2 == 0; }

    function new(string name = "cpu_instr");
        super.new(name);
    endfunction

    function bit writes_rd(); return (op != OP_SW) && (rd != 0); endfunction
    function bit uses_rs2();  return !(op inside {OP_ADDI, OP_LW}); endfunction

    function bit [31:0] encode();
        bit [11:0] i = imm[11:0];
        case (op)
            OP_ADD : return {7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011};
            OP_SUB : return {7'b0100000, rs2, rs1, 3'b000, rd, 7'b0110011};
            OP_AND : return {7'b0000000, rs2, rs1, 3'b111, rd, 7'b0110011};
            OP_OR  : return {7'b0000000, rs2, rs1, 3'b110, rd, 7'b0110011};
            OP_ADDI: return {i, rs1, 3'b000, rd, 7'b0010011};
            OP_LW  : return {i, rs1, 3'b010, rd, 7'b0000011};
            default: return {i[11:5], rs2, rs1, 3'b010, i[4:0], 7'b0100011};  // SW
        endcase
    endfunction

    function string convert2string();
        case (op)
            OP_ADDI: return $sformatf("addi x%0d, x%0d, %0d", rd, rs1, imm);
            OP_LW  : return $sformatf("lw   x%0d, %0d(x%0d)", rd, imm, rs1);
            OP_SW  : return $sformatf("sw   x%0d, %0d(x%0d)", rs2, imm, rs1);
            OP_ADD : return $sformatf("add  x%0d, x%0d, x%0d", rd, rs1, rs2);
            OP_SUB : return $sformatf("sub  x%0d, x%0d, x%0d", rd, rs1, rs2);
            OP_AND : return $sformatf("and  x%0d, x%0d, x%0d", rd, rs1, rs2);
            default: return $sformatf("or   x%0d, x%0d, x%0d", rd, rs1, rs2);
        endcase
    endfunction
endclass

class cpu_program_item extends uvm_sequence_item;
    `uvm_object_utils(cpu_program_item)

    string    id, descr;
    cpu_instr instrs[$];

    function new(string name = "cpu_program_item");
        super.new(name);
    endfunction

    function void add(op_t op, int rd, int rs1, int rs2, int imm = 0);
        cpu_instr c = cpu_instr::type_id::create("c");
        c.op = op; c.rd = rd; c.rs1 = rs1; c.rs2 = rs2; c.imm = imm;
        instrs.push_back(c);
    endfunction

    function string convert2string();
        string s = $sformatf("%s (%s)", id, descr);
        foreach (instrs[i]) s = {s, $sformatf("\n      %2d: %08h  %s", i, instrs[i].encode(), instrs[i].convert2string())};
        return s;
    endfunction
endclass

class cpu_obs extends uvm_sequence_item;
    `uvm_object_utils(cpu_obs)
    obs_t      kind;
    int        fa, fb;
    bit        stall;
    bit [4:0]  rd;
    bit [31:0] addr, data;
    function new(string name = "cpu_obs");
        super.new(name);
    endfunction
endclass

class cpu_hz_item extends uvm_sequence_item;
    `uvm_object_utils(cpu_hz_item)
    int fa, fb;
   bit uses_rs2, stall, is_sw, prio;
bit hazard_rs1, hazard_rs2;
    function new(string name = "cpu_hz_item");
        super.new(name);
    endfunction
endclass
