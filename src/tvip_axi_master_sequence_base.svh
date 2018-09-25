`ifndef TVIP_AXI_MASTER_SEQUENCE_BASE_SVH
`define TVIP_AXI_MASTER_SEQUENCE_BASE_SVH
typedef tue_sequence #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_master_item   )
) tvip_axi_master_sequence_base_base;

virtual class tvip_axi_master_sequence_base extends tvip_axi_sequence_base #(
  .BASE           (tvip_axi_master_sequence_base_base ),
  .SEQUENCER      (tvip_axi_master_sequencer          ),
  .SUB_SEQUENCER  (tvip_axi_master_sub_sequencer      )
);
  function new(string name = "tvip_axi_master_sequence_base");
    super.new(name);
    set_automatic_phase_objection(0);
  endfunction

  function tvip_axi_master_item create_axi_item(tvip_axi_access_type access_type);
    tvip_axi_master_item  item;
    case (access_type)
      TVIP_AXI_WRITE_ACCESS: begin
        `uvm_create_on(item, write_sequencer)
        item.access_type  = access_type;
      end
      TVIP_AXI_READ_ACCESS: begin
        `uvm_create_on(item, read_sequencer)
        item.access_type  = access_type;
      end
    endcase
    return item;
  endfunction
endclass
`endif
