`ifndef TVIP_AXI_SAMPLE_PKG_SV
`define TVIP_AXI_SAMPLE_PKG_SV
package tvip_axi_sample_pkg;
  import  uvm_pkg::*;
  import  tue_pkg::*;
  import  tvip_axi_types_pkg::*;
  import  tvip_axi_pkg::*;

  `include  "uvm_macros.svh"
  `include  "tue_macros.svh"

  `include  "tvip_axi_sample_configuration.svh"
  `include  "tvip_axi_sample_write_read_sequence.svh"
  `include  "tvip_axi_sample_test.svh"
endpackage
`endif
