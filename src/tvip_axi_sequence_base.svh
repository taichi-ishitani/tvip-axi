`ifndef TVIP_AXI_SEQUENCE_BASE_SVH
`define TVIP_AXI_SEQUENCE_BASE_SVH
class tvip_axi_sequence_base #(
  type  BASE          = uvm_sequence,
  type  SEQUENCER     = uvm_sequencer
) extends BASE;
  `tue_object_default_constructor(tvip_axi_sequence_base)
  `uvm_declare_p_sequencer(SEQUENCER)
endclass
`endif
