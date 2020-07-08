`ifndef TVIP_AXI_MASTER_MONITOR_SVH
`define TVIP_AXI_MASTER_MONITOR_SVH
typedef tue_param_monitor #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .ITEM           (tvip_axi_item          )
) tvip_axi_master_monitor_base;

virtual class tvip_axi_master_monitor extends tvip_axi_monitor_base #(
  .BASE (tvip_axi_master_monitor_base ),
  .ITEM (tvip_axi_master_item         )
);
  `tue_component_default_constructor(tvip_axi_master_monitor)
endclass

class tvip_axi_master_write_monitor extends tvip_axi_master_monitor;
  function new(string name = "tvip_axi_master_write_monitor", uvm_component parent = null);
    super.new(name, parent);
    write_component = 1;
  endfunction
  `uvm_component_utils(tvip_axi_master_write_monitor)
endclass

class tvip_axi_master_read_monitor extends tvip_axi_master_monitor;
  function new(string name = "tvip_axi_master_read_monitor", uvm_component parent = null);
    super.new(name, parent);
    write_component = 0;
  endfunction
  `uvm_component_utils(tvip_axi_master_read_monitor)
endclass
`endif
