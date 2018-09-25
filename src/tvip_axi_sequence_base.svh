`ifndef TVIP_AXI_SEQUENCE_BASE_SVH
`define TVIP_AXI_SEQUENCE_BASE_SVH
virtual class tvip_axi_sequence_base #(
  type  BASE          = uvm_sequence,
  type  SEQUENCER     = uvm_sequencer,
  type  SUB_SEQUENCER = uvm_sequencer
) extends BASE;
  SUB_SEQUENCER write_sequencer;
  SUB_SEQUENCER read_sequencer;

  function void set_sequencer(uvm_sequencer_base sequencer);
    super.set_sequencer(sequencer);
    write_sequencer = p_sequencer.write_sequencer;
    read_sequencer  = p_sequencer.read_sequencer;
  endfunction

  `tue_object_default_constructor(tvip_axi_sequence_base)
  `uvm_declare_p_sequencer(SEQUENCER)
endclass
`endif
