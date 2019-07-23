`ifndef TVIP_AXI_MASTER_SEQUENCER_SVH
`define TVIP_AXI_MASTER_SEQUENCER_SVH
class tvip_axi_master_sub_sequencer extends tue_sequencer #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_master_item   )
);
  `tue_component_default_constructor(tvip_axi_master_sub_sequencer)
  `uvm_component_utils(tvip_axi_master_sub_sequencer)
endclass

typedef tue_sequencer #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_master_item   )
) tvip_axi_master_sequencer_base;

class tvip_axi_master_sequencer extends tvip_axi_sequencer_base #(
  .BASE           (tvip_axi_master_sequencer_base ),
  .SUB_SEQEUENCER (tvip_axi_master_sub_sequencer  ),
  .ITEM           (tvip_axi_master_item           )
);
  task run_phase(uvm_phase phase);
    tvip_axi_master_item  item;
    forever begin
      get_next_item(item);
      dispatch_item(item);
      item_done();
    end
  endtask

  local task dispatch_item(tvip_axi_master_item item);
    int sequence_id;
    sequence_id = item.get_sequence_id();
    dispatch(item);
    item.set_sequence_id(sequence_id);
  endtask

  `tue_component_default_constructor(tvip_axi_master_sequencer)
  `uvm_component_utils(tvip_axi_master_sequencer)
endclass
`endif
