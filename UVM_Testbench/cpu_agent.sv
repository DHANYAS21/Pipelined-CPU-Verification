class cpu_agent extends uvm_agent;
    `uvm_component_utils(cpu_agent)

    uvm_sequencer #(cpu_program_item) sqr;
    cpu_driver  drv;
    cpu_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        sqr = uvm_sequencer #(cpu_program_item)::type_id::create("sqr", this);
        drv = cpu_driver ::type_id::create("drv", this);
        mon = cpu_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass
