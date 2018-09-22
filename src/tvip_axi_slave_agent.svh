`ifndef TVIP_AXI_SLAVE_AGENT_SVH
`define TVIP_AXI_SLAVE_AGENT_SVH
typedef tvip_axi_agent_base #(
  .ITEM           (tvip_axi_slave_item          ),
  .WRITE_MONITOR  (tvip_axi_write_slave_monitor ),
  .READ_MONITOR   (tvip_axi_read_slave_monitor  ),
  .SEQUENCER      (tvip_axi_slave_sequencer     ),
  .SUB_SEQUENCER  (tvip_axi_slave_sub_sequencer ),
  .WRITE_DRIVER   (tvip_axi_write_slave_driver  ),
  .READ_DRIVER    (tvip_axi_read_slave_driver   )
) tvip_axi_slave_agent_base;

class tvip_axi_slave_agent extends tvip_axi_slave_agent_base;
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (is_active_agent()) begin
      write_monitor.request_port.connect(sequencer.request_export);
      read_monitor.request_port.connect(sequencer.request_export);
    end
  endfunction

  `tue_component_default_constructor(tvip_axi_slave_agent)
  `uvm_component_utils(tvip_axi_slave_agent)
endclass
`endif
