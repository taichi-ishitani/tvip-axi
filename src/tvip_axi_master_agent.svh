`ifndef TVIP_AXI_MASTER_AGENT_SVH
`define TVIP_AXI_MASTER_AGENT_SVH
typedef tvip_axi_agent_base #(
  .WRITE_MONITOR  (tvip_axi_write_master_monitor  ),
  .READ_MONITOR   (tvip_axi_read_master_monitor   ),
  .SEQUENCER      (tvip_axi_master_sequencer      ),
  .SUB_SEQUENCER  (tvip_axi_master_sub_sequencer  ),
  .WRITE_DRIVER   (tvip_axi_write_master_driver   ),
  .READ_DRIVER    (tvip_axi_read_master_driver    )
) tvip_axi_master_agent_base;

class tvip_axi_master_agent extends tvip_axi_master_agent_base;
  `tue_component_default_constructor(tvip_axi_master_agent)
  `uvm_component_utils(tvip_axi_master_agent)
endclass
`endif
