// 10 hazard bins, sampled only for instructions the scoreboard has verified.
// The covergroup goes to the simulator's coverage database; the counters print
// the same bins in the log (Verilator ignores covergroups).

class cpu_coverage extends uvm_subscriber #(cpu_hz_item);
    `uvm_component_utils(cpu_coverage)

    int fa, fb;
    bit uses_rs2, stall, is_sw, prio;
    int hits[10];
    string names[10] = '{"FA = 00 (reg file)", "FA = 01 (MEM/WB)", "FA = 10 (EX/MEM)",
                         "FB = 00 (reg file)", "FB = 01 (MEM/WB)", "FB = 10 (EX/MEM)",
                         "no stall", "load-use stall", "store data forwarded",
                         "EX/MEM priority"};
`ifndef VERILATOR
    covergroup cg;
        cp_fa   : coverpoint fa { bins rf = {0}; bins memwb = {1}; bins exmem = {2}; }
        cp_fb   : coverpoint fb iff (uses_rs2) { bins rf = {0}; bins memwb = {1}; bins exmem = {2}; }
        cp_stall: coverpoint stall { bins no_stall = {0}; bins stall = {1}; }
        cp_sw   : coverpoint (is_sw && fb != 0) { bins fwd = {1}; }
        cp_prio : coverpoint prio { bins exmem_wins = {1}; }
    endgroup
`endif

    function new(string name, uvm_component parent);
        super.new(name, parent);
`ifndef VERILATOR
        cg = new();
`endif
    endfunction

    function void write(cpu_hz_item t);
        fa = t.fa; fb = t.fb; uses_rs2 = t.uses_rs2;
        stall = t.stall; is_sw = t.is_sw; prio = t.prio;
        hits[fa]++;
        if (uses_rs2) hits[3 + fb]++;
        hits[6 + stall]++;
        if (is_sw && fb != 0) hits[8]++;
        if (prio) hits[9]++;
`ifndef VERILATOR
        cg.sample();
`endif
    endfunction

    function void report_phase(uvm_phase phase);
        int    covered = 0;
        string s = "";
        foreach (hits[i]) begin
            s = {s, $sformatf("\n  %-22s %6d %s", names[i], hits[i], hits[i] ? "" : "<- not hit")};
            if (hits[i]) covered++;
        end
        `uvm_info("COV", $sformatf("%0d/10 bins hit%s", covered, s), UVM_NONE)
    endfunction
endclass
