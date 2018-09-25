`ifndef TVIP_AXI_STATUS_SVH
`define TVIP_AXI_STATUS_SVH
typedef class tvip_axi_memory;

class tvip_axi_status extends tue_status;
  tvip_axi_memory memory;
  `tue_object_default_constructor(tvip_axi_status)
  `uvm_object_utils(tvip_axi_status)
endclass
`endif
