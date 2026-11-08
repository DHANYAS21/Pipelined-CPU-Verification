// samples on the falling edge: FA/FB/stall of every instruction in EX,
// register write-backs and stores

class cpu_monitor extends uvm_monitor;
    `uvm_component_utils(cpu_monitor)

    virtual cpu_if vif;
    uvm_analysis_port #(cpu_obs) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual cpu_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "no cpu_if in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        cpu_obs o;
        bit     was_stalled = 0;
        forever begin
            @(negedge vif.clk);
            if (vif.reset) begin
                o = cpu_obs::type_id::create("o"); o.kind = OBS_RESET; ap.write(o);
                was_stalled = 0;
                continue;
            end
            // a bubble has all EX control bits low
            if (vif.regwrite_ex || vif.memread_ex || vif.memwrite_ex || vif.alusrc_ex) begin
                o = cpu_obs::type_id::create("o");
                o.kind  = OBS_EX;
                o.fa    = vif.fa;
                o.fb    = (!vif.alusrc_ex || vif.memwrite_ex) ? vif.fb : 0;  // FB unused by addi/lw
                o.stall = was_stalled;
                ap.write(o);
                was_stalled = 0;
            end
            if (vif.stall) was_stalled = 1;     // the stalled instruction is still in ID
            if (vif.wb_en && vif.wb_rd != 0) begin
                o = cpu_obs::type_id::create("o");
                o.kind = OBS_WB; o.rd = vif.wb_rd; o.data = vif.wb_data; ap.write(o);
            end
            if (vif.dmem_write) begin
                o = cpu_obs::type_id::create("o");
                o.kind = OBS_ST; o.addr = vif.dmem_addr; o.data = vif.dmem_wdata; ap.write(o);
            end
        end
    endtask
endclass
