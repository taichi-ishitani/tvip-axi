`ifndef TVIP_AXI_SLAVE_AGENT_SVH
`define TVIP_AXI_SLAVE_AGENT_SVH
typedef tvip_axi_agent_base #(
  .WRITE_MONITOR  (tvip_axi_slave_write_monitor ),
  .READ_MONITOR   (tvip_axi_slave_read_monitor  ),
  .SEQUENCER      (tvip_axi_slave_sequencer     ),
  .DRIVER         (tvip_axi_slave_driver        )
) tvip_axi_slave_agent_base;

class tvip_axi_slave_agent extends tvip_axi_slave_agent_base;
  tvip_axi_slave_data_monitor data_monitor;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    data_monitor  = tvip_axi_slave_data_monitor::type_id::create("data_monitor", this);
    data_monitor.set_context(configuration, status);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    write_monitor.request_item_port.connect(data_monitor.analysis_export);
    if (is_active_agent()) begin
      write_monitor.request_port.connect(sequencer.request_export);
      read_monitor.request_port.connect(sequencer.request_export);
    end
  endfunction

  `tue_component_default_constructor(tvip_axi_slave_agent)
  `uvm_component_utils(tvip_axi_slave_agent)
endclass
`endif
