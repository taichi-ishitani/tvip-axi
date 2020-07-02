`ifndef TVIP_AXI_MASTER_SEQUENCER_SVH
`define TVIP_AXI_MASTER_SEQUENCER_SVH
typedef tue_sequencer #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_master_item   )
) tvip_axi_master_sequencer_base;

typedef tvip_axi_sub_sequencer_base #(
  .ITEM           (tvip_axi_master_item           ),
  .ROOT_SEQUENCER (tvip_axi_master_sequencer_base )
) tvip_axi_master_sub_sequencer;

class tvip_axi_master_sequencer extends tvip_axi_sequencer_base #(
  .BASE           (tvip_axi_master_sequencer_base ),
  .SUB_SEQEUENCER (tvip_axi_master_sub_sequencer  )
);
  task run_phase(uvm_phase phase);
    tvip_axi_master_item  item;
    forever begin
      seq_item_export.get(item);
      dispatch(item);
    end
  endtask

  `tue_component_default_constructor(tvip_axi_master_sequencer)
  `uvm_component_utils(tvip_axi_master_sequencer)
endclass
`endif
