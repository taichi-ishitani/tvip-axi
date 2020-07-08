`ifndef TVIP_AXI_MASTER_SEQUENCER_SVH
`define TVIP_AXI_MASTER_SEQUENCER_SVH
typedef tue_sequencer #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_master_item   )
) tvip_axi_master_sequencer_base;

class tvip_axi_master_sequencer extends tvip_axi_sequencer_base #(
  .BASE (tvip_axi_master_sequencer_base )
);
  `tue_component_default_constructor(tvip_axi_master_sequencer)
  `uvm_component_utils(tvip_axi_master_sequencer)
endclass
`endif
