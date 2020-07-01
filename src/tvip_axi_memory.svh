`ifndef TVIP_AXI_MEMORY_SVH
`define TVIP_AXI_MEMORY_SVH
typedef tvip_memory #(
  .ADDRESS_WIDTH  ($bits(tvip_axi_address)  ),
  .DATA_WIDTH     ($bits(tvip_axi_data)     )
) tvip_axi_memory_base;

class tvip_axi_memory extends tue_object_base #(
  .BASE           (tvip_axi_memory_base   ),
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        )
);
  function void set_configuration(tue_configuration configuration);
    super.set_configuration(configuration);
    byte_width  = this.configuration.data_width / 8;
  endfunction

  `tue_object_default_constructor(tvip_axi_memory)
  `uvm_object_utils(tvip_axi_memory)
endclass
`endif
