`ifndef TVIP_AXI_SLAVE_DATA_MONITOR_SVH
`define TVIP_AXI_SLAVE_DATA_MONITOR_SVH
class tvip_axi_slave_data_monitor extends tue_subscriber #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .T              (tvip_axi_item          )
);
  protected tvip_axi_memory   memory;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (status.memory == null) begin
      status.memory = tvip_axi_memory::type_id::create("memory");
      status.memory.set_context(configuration, status);
    end
    memory  = status.memory;
  endfunction

  function void write(tvip_axi_item t);
    foreach (t.data[i]) begin
      memory.put(t.data[i], t.strobe[i], t.burst_size, t.address, i);
    end
  endfunction

  `tue_component_default_constructor(tvip_axi_slave_data_monitor)
  `uvm_component_utils(tvip_axi_slave_data_monitor)
endclass
`endif
