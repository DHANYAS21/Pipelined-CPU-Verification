// for each program: reset, backdoor-load IMEM, clear DMEM, run until the
// pipeline drains, then send the program to the scoreboard (prog_ap)

class cpu_driver extends uvm_driver #(cpu_program_item);
    `uvm_component_utils(cpu_driver)

    virtual cpu_if  vif;
    virtual cpu_bfm bfm;
    uvm_analysis_port #(cpu_program_item) prog_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        prog_ap = new("prog_ap", this);
        if (!uvm_config_db #(virtual cpu_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "no cpu_if in config_db")
        if (!uvm_config_db #(virtual cpu_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("DRV", "no cpu_bfm in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        logic [31:0] words[$];
        forever begin
            seq_item_port.get_next_item(req);
            words.delete();
            foreach (req.instrs[i]) words.push_back(req.instrs[i].encode());
            @(posedge vif.clk) vif.reset <= 1;
            repeat (2) @(posedge vif.clk);
            bfm.load_program(words);
            bfm.clear_dmem();
            @(posedge vif.clk) vif.reset <= 0;
            repeat (2 * req.instrs.size() + 10) @(posedge vif.clk);
            prog_ap.write(req);                // scoreboard checks it now
            seq_item_port.item_done();
        end
    endtask
endclass
