`ifndef TVIP_AXI_PKG_SV
`define TVIP_AXI_PKG_SV
package tvip_axi_pkg;
  import  uvm_pkg::*;
  import  tue_pkg::*;
  import  tvip_axi_types_pkg::*;

  `include  "uvm_macros.svh"
  `include  "tue_macros.svh"

  typedef virtual tvip_axi_if tvip_axi_vif;

  `include  "tvip_axi_configuration.svh"
  `include  "tvip_axi_status.svh"
  `include  "tvip_axi_item.svh"
  `include  "tvip_axi_payload_store.svh"
  `include  "tvip_axi_component_base.svh"
  `include  "tvip_axi_monitor_base.svh"
  `include  "tvip_axi_sequencer_base.svh"
  `include  "tvip_axi_agent_base.svh"
  `include  "tvip_axi_master_monitor.svh"
  `include  "tvip_axi_master_driver.svh"
  `include  "tvip_axi_master_sequencer.svh"
  `include  "tvip_axi_master_agent.svh"
  `include  "tvip_axi_slave_monitor.svh"
  `include  "tvip_axi_slave_driver.svh"
  `include  "tvip_axi_slave_sequencer.svh"
  `include  "tvip_axi_slave_agent.svh"
endpackage
`endif
