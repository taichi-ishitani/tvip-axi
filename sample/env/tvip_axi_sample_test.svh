`ifndef TVIP_AXI_SAMPLE_TEST_SVH
`define TVIP_AXI_SAMPLE_TEST_SVH
class tvip_axi_sample_test extends tue_test #(
  .CONFIGURATION  (tvip_axi_sample_configuration)
);
  tvip_axi_master_agent     master_agent;
  tvip_axi_master_sequencer master_sequencer;
  tvip_axi_slave_agent      slave_agent;
  tvip_axi_slave_sequencer  slave_sequencer;

  function new(string name = "tvip_axi_sample_test", uvm_component parent = null);
    super.new(name, parent);
    `uvm_info("SRANDOM", $sformatf("Initial random seed: %0d", $get_initial_random_seed), UVM_NONE)
  endfunction

  function void create_configuration();
    super.create_configuration();
    void'(uvm_config_db #(tvip_axi_vif)::get(null, "", "vif[0]", configuration.axi_cfg[0].vif));
    void'(uvm_config_db #(tvip_axi_vif)::get(null, "", "vif[1]", configuration.axi_cfg[1].vif));
    if (configuration.randomize()) begin
      `uvm_info(get_name(), $sformatf("configuration...\n%s", configuration.sprint()), UVM_NONE)
    end
    else begin
      `uvm_fatal(get_name(), "randomization failed !!")
    end
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    master_agent  = tvip_axi_master_agent::type_id::create("master_agent", this);
    master_agent.set_configuration(configuration.axi_cfg[0]);

    slave_agent = tvip_axi_slave_agent::type_id::create("slave_agent", this);
    slave_agent.set_configuration(configuration.axi_cfg[1]);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    master_sequencer  = master_agent.sequencer;
    slave_sequencer   = slave_agent.sequencer;
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_config_db #(uvm_object_wrapper)::set(
      master_sequencer, "main_phase", "default_sequence", tvip_axi_sample_write_read_sequence::type_id::get()
    );
    uvm_config_db #(uvm_object_wrapper)::set(
      slave_sequencer, "run_phase", "default_sequence", tvip_axi_slave_default_sequence::type_id::get()
    );
  endfunction

  `uvm_component_utils(tvip_axi_sample_test)
endclass
`endif
