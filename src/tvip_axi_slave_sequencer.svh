`ifndef TVIP_AXI_SLAVE_SEQUENCER_SVH
`define TVIP_AXI_SLAVE_SEQUENCER_SVH
typedef tue_sequencer #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_slave_item    )
) tvip_axi_slave_sequencer_base;

class tvip_axi_slave_sequencer extends tvip_axi_sequencer_base #(
  .BASE (tvip_axi_slave_sequencer_base  )
);
  uvm_analysis_imp #(
    tvip_axi_item, tvip_axi_slave_sequencer
  ) request_export;

  protected tvip_axi_item_waiter  write_request_waiter;
  protected tvip_axi_item_waiter  read_request_waiter;
  protected tvip_axi_item_waiter  request_waiter[tvip_axi_access_type];

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    request_export  = new("request_export", this);

    write_request_waiter  = new("write_request_waiter", this);
    read_request_waiter   = new("read_request_waiter" , this);

    request_waiter[TVIP_AXI_WRITE_ACCESS] = write_request_waiter;
    request_waiter[TVIP_AXI_READ_ACCESS ] = read_request_waiter;
  endfunction

  virtual function void write(tvip_axi_item request);
    request_waiter[request.access_type].write(request);
  endfunction

  virtual task get_request(
    input tvip_axi_access_type  access_type,
    ref   tvip_axi_slave_item   request
  );
    tvip_axi_item item;
    request_waiter[access_type].get_item(item);
    void'($cast(request, item));
  endtask

  `tue_component_default_constructor(tvip_axi_slave_sequencer)
  `uvm_component_utils(tvip_axi_slave_sequencer)
endclass
`endif
