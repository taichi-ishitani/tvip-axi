`ifndef TVIP_AXI_SLAVE_MONITOR_SVH
`define TVIP_AXI_SLAVE_MONITOR_SVH
typedef tue_reactive_monitor #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .ITEM           (tvip_axi_slave_item    )
) tvip_axi_slave_monitor_base;

virtual class tvip_axi_slave_monitor extends tvip_axi_monitor_base #(
  .BASE (tvip_axi_slave_monitor_base  ),
  .ITEM (tvip_axi_slave_item          )
);
  virtual protected function void begin_address(tvip_axi_item item);
    tvip_axi_slave_item temp;
    super.begin_address(item);
    $cast(temp, item);
    write_request(temp);
  endfunction

  `tue_component_default_constructor(tvip_axi_master_monitor)
endclass

class tvip_axi_write_slave_monitor extends tvip_axi_slave_monitor;
  function new(string name = "tvip_axi_write_slave_monitor", uvm_component parent = null);
    super.new(name, parent);
    write_component = 1;
  endfunction
  `uvm_component_utils(tvip_axi_write_slave_monitor)
endclass

class tvip_axi_read_slave_monitor extends tvip_axi_slave_monitor;
  function new(string name = "tvip_axi_read_slave_monitor", uvm_component parent = null);
    super.new(name, parent);
    write_component = 0;
  endfunction
  `uvm_component_utils(tvip_axi_read_slave_monitor)
endclass
`endif
