// cpu_directed_seq : hazard tests T01-T10 (test_id = "ALL" runs all ten)
// cpu_random_seq   : num_programs constrained-random programs

class cpu_directed_seq extends uvm_sequence #(cpu_program_item);
    `uvm_object_utils(cpu_directed_seq)
    string test_id = "ALL";

    function new(string name = "cpu_directed_seq");
        super.new(name);
    endfunction

    task body();
        if (test_id == "ALL")
            for (int i = 1; i <= 10; i++) send($sformatf("T%02d", i));
        else
            send(test_id);
    endtask

    // add(op, rd, rs1, rs2, imm)     for sw: rs1 = base, rs2 = data
    task send(string id);
        cpu_program_item p = cpu_program_item::type_id::create(id);
        start_item(p);
        p.id = id;
        case (id)
        "T01": begin p.descr = "EX/MEM forwarding to rs1";
            p.add(OP_ADDI,1,0,0,5); p.add(OP_ADD,2,1,0); end
        "T02": begin p.descr = "EX/MEM forwarding to rs2";
            p.add(OP_ADDI,1,0,0,5); p.add(OP_SUB,2,0,1); end
        "T03": begin p.descr = "MEM/WB forwarding to rs1";
            p.add(OP_ADDI,1,0,0,7); p.add(OP_ADDI,0,0,0,0); p.add(OP_ADD,2,1,0); end
        "T04": begin p.descr = "MEM/WB forwarding to rs2";
            p.add(OP_ADDI,1,0,0,7); p.add(OP_ADDI,0,0,0,0); p.add(OP_SUB,2,0,1); end
        "T05": begin p.descr = "EX/MEM has priority over MEM/WB";
            p.add(OP_ADDI,1,0,0,10); p.add(OP_ADDI,1,0,0,20); p.add(OP_ADD,2,1,1); end
        "T06": begin p.descr = "Load-use on rs1 -> 1 stall";
            p.add(OP_ADDI,1,0,0,9); p.add(OP_SW,0,0,1,1000);
            p.add(OP_LW,2,0,0,1000); p.add(OP_ADD,3,2,0); end
        "T07": begin p.descr = "Load-use on rs1 and rs2 -> 1 stall";
            p.add(OP_ADDI,1,0,0,9); p.add(OP_SW,0,0,1,1000);
            p.add(OP_LW,2,0,0,1000); p.add(OP_ADD,3,2,2); end
        "T08": begin p.descr = "Load with no dependent -> no stall";
            p.add(OP_ADDI,1,0,0,9); p.add(OP_SW,0,0,1,1000);
            p.add(OP_LW,2,0,0,1000); p.add(OP_ADD,3,1,1); end
        "T09": begin p.descr = "Store data forwarded from ALU";
            p.add(OP_ADDI,1,0,0,42); p.add(OP_SW,0,0,1,1004); p.add(OP_LW,2,0,0,1004); end
        "T10": begin p.descr = "Load then store of loaded value -> 1 stall";
            p.add(OP_ADDI,1,0,0,13); p.add(OP_SW,0,0,1,1000); p.add(OP_LW,2,0,0,1000);
            p.add(OP_SW,0,0,2,1008); p.add(OP_LW,3,0,0,1008); end
        default: `uvm_fatal("SEQ", {"unknown test ", id})
        endcase
        finish_item(p);
    endtask
endclass

class cpu_random_seq extends uvm_sequence #(cpu_program_item);
    `uvm_object_utils(cpu_random_seq)
    int num_programs = 50;

    function new(string name = "cpu_random_seq");
        super.new(name);
    endfunction

    task body();
        for (int n = 0; n < num_programs; n++) begin
            cpu_program_item p = cpu_program_item::type_id::create($sformatf("R%02d", n));
            start_item(p);
            p.id    = $sformatf("R%02d", n);
            p.descr = "random";
            repeat ($urandom_range(30, 20)) begin
                cpu_instr c = cpu_instr::type_id::create("c");
                op_t      pick;
                // choose the opcode here (same mix on every simulator), the solver does the fields
                randcase
                    2: pick = OP_ADD;   1: pick = OP_SUB;   1: pick = OP_AND;   1: pick = OP_OR;
                    2: pick = OP_ADDI;  2: pick = OP_LW;    2: pick = OP_SW;
                endcase
                if (!c.randomize() with { op == pick; }) `uvm_fatal("SEQ", "randomize failed")
                p.instrs.push_back(c);
            end
            finish_item(p);
        end
    endtask
endclass
