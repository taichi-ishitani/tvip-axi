`ifndef TVIP_AXI_INTERNAL_MACROS_SVH
`define TVIP_AXI_INTERNAL_MACROS_SVH

`define tvip_axi_4kb_boundary_mask(BURST_SIZE) \
(tvip_axi_address'('h1000 - BURST_SIZE))

`endif
