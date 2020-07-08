`ifndef TVIP_AXI_PKG_SV
`define TVIP_AXI_PKG_SV

`include  "tvip_axi_types_pkg.sv"
`include  "tvip_axi_if.sv"

package tvip_axi_pkg;
  import  uvm_pkg::*;
  import  tue_pkg::*;
  import  tvip_common_pkg::*;
  import  tvip_axi_types_pkg::*;

  `include  "uvm_macros.svh"
  `include  "tue_macros.svh"
  `include  "tvip_common_macros.svh"

  typedef virtual tvip_axi_if tvip_axi_vif;

  `include  "tvip_axi_internal_macros.svh"
  `include  "tvip_axi_configuration.svh"
  `include  "tvip_axi_status.svh"
  `include  "tvip_axi_memory.svh"
  `include  "tvip_axi_item.svh"
  `include  "tvip_axi_payload_store.svh"
  `include  "tvip_axi_component_base.svh"
  `include  "tvip_axi_monitor_base.svh"
  `include  "tvip_axi_sequencer_base.svh"
  `include  "tvip_axi_driver_base.svh"
  `include  "tvip_axi_agent_base.svh"
  `include  "tvip_axi_sequence_base.svh"
  `include  "tvip_axi_master_monitor.svh"
  `include  "tvip_axi_master_driver.svh"
  `include  "tvip_axi_master_sequencer.svh"
  `include  "tvip_axi_master_agent.svh"
  `include  "tvip_axi_master_sequence_base.svh"
  `include  "tvip_axi_master_access_sequence.svh"
  `include  "tvip_axi_master_write_sequence.svh"
  `include  "tvip_axi_master_read_sequence.svh"
  `include  "tvip_axi_slave_monitor.svh"
  `include  "tvip_axi_slave_data_monitor.svh"
  `include  "tvip_axi_slave_driver.svh"
  `include  "tvip_axi_slave_sequencer.svh"
  `include  "tvip_axi_slave_agent.svh"
  `include  "tvip_axi_slave_sequence_base.svh"
  `include  "tvip_axi_slave_default_sequence.svh"
  `include  "tvip_axi_ral_adapter.svh"
  `include  "tvip_axi_ral_predictor.svh"
  `include  "tvip_axi_undef_internal_macros.svh"
endpackage
`endif
