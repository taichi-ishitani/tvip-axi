`ifndef TVIP_AXI_SLAVE_SEQUENCER_SVH
`define TVIP_AXI_SLAVE_SEQUENCER_SVH
typedef tue_sequencer #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_slave_item    )
) tvip_axi_slave_sub_sequencer;

typedef tue_reactive_sequencer #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .ITEM           (tvip_axi_slave_item    )
) tvip_axi_slave_sequencer_base;

class tvip_axi_slave_sequencer extends tvip_axi_sequencer_base #(
  .BASE           (tvip_axi_slave_sequencer_base  ),
  .SUB_SEQEUENCER (tvip_axi_slave_sub_sequencer   ),
  .ITEM           (tvip_axi_slave_item            )
);
  protected tvip_axi_item_waiter #(tvip_axi_slave_item) request_waiter;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    request_waiter  = new("request_waiter", this);
    request_waiter.set_context(configuration, status);
  endfunction

  function void write_request(tvip_axi_slave_item request);
    request_waiter.write(request);
  endfunction

  task get_request(ref tvip_axi_slave_item request);
    request_waiter.get_item(request);
  endtask

  `tue_component_default_constructor(tvip_axi_slave_sequencer)
  `uvm_component_utils(tvip_axi_slave_sequencer)
endclass
`endif
