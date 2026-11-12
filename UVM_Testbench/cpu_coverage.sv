// 10 hazard bins, sampled only for instructions the scoreboard has verified.
// The covergroup goes to the simulator's coverage database; the counters print
// the same bins in the log (Verilator ignores covergroups).

// 14 functional coverage bins:
// Original 10 hazard bins + 4 load-use dependency categories.
// Coverage is sampled only for instructions verified by the scoreboard.

class cpu_coverage extends uvm_subscriber #(cpu_hz_item);
    `uvm_component_utils(cpu_coverage)

    int fa, fb;
    bit uses_rs2, stall, is_sw, prio;
    bit hazard_rs1, hazard_rs2;

    int hits[14];

    string names[14] = '{
        "FA = 00 (reg file)",
        "FA = 01 (MEM/WB)",
        "FA = 10 (EX/MEM)",
        "FB = 00 (reg file)",
        "FB = 01 (MEM/WB)",
        "FB = 10 (EX/MEM)",
        "no stall",
        "load-use stall",
        "store data forwarded",
        "EX/MEM priority",
        "no load dependency",
        "rs1 dependency only",
        "rs2 dependency only",
        "rs1 and rs2 dependency"
    };

`ifndef VERILATOR
    covergroup cg;
        cp_fa : coverpoint fa {
            bins rf    = {0};
            bins memwb = {1};
            bins exmem = {2};
        }

        cp_fb : coverpoint fb iff (uses_rs2) {
            bins rf    = {0};
            bins memwb = {1};
            bins exmem = {2};
        }

        cp_stall : coverpoint stall {
            bins no_stall = {0};
            bins stall    = {1};
        }

        cp_sw : coverpoint (is_sw && fb != 0) {
            bins fwd = {1};
        }

        cp_prio : coverpoint prio {
            bins exmem_wins = {1};
        }

        cp_load_use : coverpoint {hazard_rs1, hazard_rs2} {
            bins no_hazard = {2'b00};
            bins rs1_only  = {2'b10};
            bins rs2_only  = {2'b01};
            bins both      = {2'b11};
        }
    endgroup
`endif

    function new(string name, uvm_component parent);
        super.new(name, parent);
`ifndef VERILATOR
        cg = new();
`endif
    endfunction

    function void write(cpu_hz_item t);
        fa          = t.fa;
        fb          = t.fb;
        uses_rs2    = t.uses_rs2;
        stall       = t.stall;
        is_sw       = t.is_sw;
        prio        = t.prio;
        hazard_rs1  = t.hazard_rs1;
        hazard_rs2  = t.hazard_rs2;

        // Original 10 coverage counters
        hits[fa]++;

        if (uses_rs2)
            hits[3 + fb]++;

        hits[6 + stall]++;

        if (is_sw && fb != 0)
            hits[8]++;

        if (prio)
            hits[9]++;

        // Four additional load-use dependency categories
        case ({hazard_rs1, hazard_rs2})
            2'b00: hits[10]++;
            2'b10: hits[11]++;
            2'b01: hits[12]++;
            2'b11: hits[13]++;
        endcase

`ifndef VERILATOR
        cg.sample();
`endif
    endfunction

    function void report_phase(uvm_phase phase);
        int covered = 0;
        string s = "";

        foreach (hits[i]) begin
            s = {s, $sformatf("\n  %-28s %6d %s",
                names[i], hits[i], hits[i] ? "" : "<- not hit")};

            if (hits[i])
                covered++;
        end

        `uvm_info("COV",
            $sformatf("%0d/14 bins hit%s", covered, s), UVM_NONE)
    endfunction

endclass

