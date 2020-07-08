`ifndef TVIP_AXI_MASTER_SEQUENCE_BASE_SVH
`define TVIP_AXI_MASTER_SEQUENCE_BASE_SVH
typedef tue_sequence #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_master_item   )
) tvip_axi_master_sequence_base_base;

class tvip_axi_master_sequence_base extends tvip_axi_sequence_base #(
  .BASE       (tvip_axi_master_sequence_base_base ),
  .SEQUENCER  (tvip_axi_master_sequencer          )
);
  function new(string name = "tvip_axi_master_sequence_base");
    super.new(name);
    set_automatic_phase_objection(0);
  endfunction
endclass
`endif
