`ifndef TVIP_AXI_MASTER_AGENT_SVH
`define TVIP_AXI_MASTER_AGENT_SVH
typedef tvip_axi_agent_base #(
  .WRITE_MONITOR  (tvip_axi_master_write_monitor  ),
  .READ_MONITOR   (tvip_axi_master_read_monitor   ),
  .SEQUENCER      (tvip_axi_master_sequencer      ),
  .DRIVER         (tvip_axi_master_driver         )
) tvip_axi_master_agent_base;

class tvip_axi_master_agent extends tvip_axi_master_agent_base;
  `tue_component_default_constructor(tvip_axi_master_agent)
  `uvm_component_utils(tvip_axi_master_agent)
endclass
`endif
