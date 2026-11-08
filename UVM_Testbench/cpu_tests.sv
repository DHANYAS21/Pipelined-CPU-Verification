// +UVM_TESTNAME = cpu_directed_test | cpu_random_test | cpu_full_test (default)
//   +TEST=T06       run one directed test        (cpu_directed_test / cpu_full_test)
//   +NUM_RANDOM=n   number of random programs    (cpu_random_test / cpu_full_test)


class cpu_base_test extends uvm_test;
    `uvm_component_utils(cpu_base_test)
    cpu_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        env = cpu_env::type_id::create("env", this);
    endfunction

    task run_directed();
        cpu_directed_seq seq = cpu_directed_seq::type_id::create("dir_seq");
        void'($value$plusargs("TEST=%s", seq.test_id));
        seq.start(env.agent.sqr);
    endtask

    task run_random();
        cpu_random_seq seq = cpu_random_seq::type_id::create("rand_seq");
        void'($value$plusargs("NUM_RANDOM=%d", seq.num_programs));
        seq.start(env.agent.sqr);
    endtask

    function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();

        int errors = svr.get_severity_count(UVM_ERROR)
                   + svr.get_severity_count(UVM_FATAL)
                   + cpu_pkg::get_assert_fails();

        $display("==== RESULT: %s", (errors == 0) ? "PASS" : "FAIL");
    endfunction
endclass

class cpu_directed_test extends cpu_base_test;
    `uvm_component_utils(cpu_directed_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        run_directed();
        phase.drop_objection(this);
    endtask
endclass

class cpu_random_test extends cpu_base_test;
    `uvm_component_utils(cpu_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        run_random();
        phase.drop_objection(this);
    endtask
endclass

class cpu_full_test extends cpu_base_test;
    `uvm_component_utils(cpu_full_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        run_directed();
        run_random();
        phase.drop_objection(this);
    endtask
endclass
