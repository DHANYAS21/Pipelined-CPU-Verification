// agent.monitor -> scoreboard.obs_imp
// agent.driver  -> scoreboard.prog_imp   (program finished, check it)
// scoreboard    -> coverage              (verified instructions)

class cpu_env extends uvm_env;
    `uvm_component_utils(cpu_env)

    cpu_agent      agent;
    cpu_scoreboard sb;
    cpu_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        agent = cpu_agent     ::type_id::create("agent", this);
        sb    = cpu_scoreboard::type_id::create("sb", this);
        cov   = cpu_coverage  ::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.mon.ap.connect(sb.obs_imp);
        agent.drv.prog_ap.connect(sb.prog_imp);
        sb.cov_ap.connect(cov.analysis_export);
    endfunction
endclass
