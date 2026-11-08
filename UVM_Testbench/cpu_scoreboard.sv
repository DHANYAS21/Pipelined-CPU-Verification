// reference model + checks
//  - values : runs the program without a pipeline -> expected write-backs, stores, final regs
//  - hazards: expected FA, FB and stall for every instruction
//      stall : previous instr is LW (rd != 0) and this one reads that rd
//      FA/FB : 10 if the instr 1 slot ahead writes the reg (not a load)
//              01 if the instr 2 slots ahead writes it, else 00 (x0 never forwarded)
// Verified instructions are sent to the coverage collector through cov_ap.


`uvm_analysis_imp_decl(_obs)
`uvm_analysis_imp_decl(_prog)

class cpu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(cpu_scoreboard)

    uvm_analysis_imp_obs  #(cpu_obs, cpu_scoreboard)          obs_imp;
    uvm_analysis_imp_prog #(cpu_program_item, cpu_scoreboard) prog_imp;
    uvm_analysis_port     #(cpu_hz_item)                      cov_ap;
    virtual cpu_bfm bfm;

    int n_checked, n_fail, errs;

    // what the monitor saw since the last reset
    cpu_obs    ex[$];
    bit [36:0] wb[$];          // {rd, data}
    bit [31:0] st[$];          // addr, data, addr, data ...

    // reference model results for the current program
    bit [31:0] regs[32];
    bit [31:0] mem[int];
    bit [36:0] exp_wb[$];
    bit [31:0] exp_st[$];
    int        exp_fa[$], exp_fb[$];
    bit        exp_stall[$], exp_prio[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        obs_imp  = new("obs_imp", this);
        prog_imp = new("prog_imp", this);
        cov_ap   = new("cov_ap", this);
        if (!uvm_config_db #(virtual cpu_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("SB", "no cpu_bfm in config_db")
    endfunction

    function void write_obs(cpu_obs o);
        case (o.kind)
            OBS_RESET: begin ex.delete(); wb.delete(); st.delete(); end
            OBS_EX   : ex.push_back(o);
            OBS_WB   : wb.push_back({o.rd, o.data});
            OBS_ST   : begin st.push_back(o.addr); st.push_back(o.data); end
        endcase
    endfunction

    // ---------------- reference model ----------------
    function void predict(cpu_program_item p);
        int slot[$];
        foreach (regs[r]) regs[r] = 0;
        mem.delete(); exp_wb.delete(); exp_st.delete();
        exp_fa.delete(); exp_fb.delete(); exp_stall.delete(); exp_prio.delete();

        foreach (p.instrs[i]) begin
            cpu_instr  c = p.instrs[i];
            bit [31:0] a = regs[c.rs1], b = regs[c.rs2], res;
            bit        st_, pa, pb;

            case (c.op)
                OP_ADD : res = a + b;
                OP_SUB : res = a - b;
                OP_AND : res = a & b;
                OP_OR  : res = a | b;
                OP_ADDI: res = a + c.imm;
                OP_LW  : res = mem.exists(a + c.imm) ? mem[a + c.imm] : 0;
                OP_SW  : begin mem[a + c.imm] = b; exp_st.push_back(a + c.imm); exp_st.push_back(b); end
            endcase
            if (c.writes_rd()) begin regs[c.rd] = res; exp_wb.push_back({c.rd, res}); end

            st_ = 0;
            if (i > 0 && p.instrs[i-1].op == OP_LW && p.instrs[i-1].rd != 0)
                st_ = (c.rs1 == p.instrs[i-1].rd) || (c.uses_rs2() && c.rs2 == p.instrs[i-1].rd);
            slot.push_back(i == 0 ? 0 : slot[i-1] + 1 + st_);
            exp_stall.push_back(st_);
            exp_fa.push_back(fwd(p, slot, i, c.rs1, pa));
            exp_fb.push_back(c.uses_rs2() ? fwd(p, slot, i, c.rs2, pb) : 0);
            exp_prio.push_back(pa || (c.uses_rs2() && pb));
        end
    endfunction

    function int fwd(cpu_program_item p, int slot[$], int i, bit [4:0] r, output bit prio);
        bit exmem = 0, memwb = 0;
        prio = 0;
        if (r == 0) return 0;
        for (int j = i - 1; j >= 0 && slot[i] - slot[j] <= 2; j--)
            if (p.instrs[j].writes_rd() && p.instrs[j].rd == r) begin
                if (slot[i] - slot[j] == 1 && p.instrs[j].op != OP_LW) exmem = 1;
                if (slot[i] - slot[j] == 2) memwb = 1;
            end
        prio = exmem && memwb;
        return exmem ? 2 : memwb ? 1 : 0;
    endfunction

    // ---------------- compare (called by the driver after each program) ----------------
    function void err(cpu_program_item p, string s);
        errs++;
        if (errs <= 8) `uvm_error("SB", {p.id, ": ", s})
    endfunction

    function void write_prog(cpu_program_item p);
        int n = p.instrs.size(), stalls = 0, fwds = 0;
        errs = 0;
        predict(p);

        if (ex.size() < n) err(p, $sformatf("only %0d of %0d instructions reached EX", ex.size(), n));
        for (int i = 0; i < n && i < ex.size(); i++) begin
            string s = p.instrs[i].convert2string();
            if (ex[i].stall != exp_stall[i]) err(p, $sformatf("%s : stall=%0d expected %0d", s, ex[i].stall, exp_stall[i]));
            if (ex[i].fa != exp_fa[i])       err(p, $sformatf("%s : FA=%b expected %b", s, 2'(ex[i].fa), 2'(exp_fa[i])));
            if (ex[i].fb != exp_fb[i])       err(p, $sformatf("%s : FB=%b expected %b", s, 2'(ex[i].fb), 2'(exp_fb[i])));
            stalls += ex[i].stall;
            fwds   += (ex[i].fa != 0) + (ex[i].fb != 0);
        end

        if (wb != exp_wb) err(p, $sformatf("register write-backs differ (%0d vs %0d expected)", wb.size(), exp_wb.size()));
        if (st != exp_st) err(p, $sformatf("stores differ (%0d vs %0d expected)", st.size() / 2, exp_st.size() / 2));
        for (int r = 1; r < 32; r++)
            if (bfm.read_reg(r) !== regs[r])
                err(p, $sformatf("x%0d = %0d expected %0d", r, $signed(bfm.read_reg(r)), $signed(regs[r])));

        n_checked++;
        if (errs == 0) begin
            for (int i = 0; i < n; i++) begin
                cpu_hz_item h = cpu_hz_item::type_id::create("h");
                h.fa = exp_fa[i]; h.fb = exp_fb[i]; h.uses_rs2 = p.instrs[i].uses_rs2();
                h.stall = exp_stall[i]; h.is_sw = (p.instrs[i].op == OP_SW); h.prio = exp_prio[i];
                cov_ap.write(h);
            end
            if (p.id[0] == "T")
                `uvm_info("SB", $sformatf("PASS %s  %-42s stalls=%0d forwards=%0d", p.id, p.descr, stalls, fwds), UVM_NONE)
        end else begin
            n_fail++;
            `uvm_info("SB", {"FAILED program ", p.convert2string()}, UVM_NONE)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("%0d programs checked, %0d failed, %0d assertion failures",
                                  n_checked, n_fail, cpu_pkg::get_assert_fails()), UVM_NONE)
    endfunction
endclass
