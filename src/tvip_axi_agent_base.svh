`ifndef TVIP_AXI_AGENT_BASE_SVH
`define TVIP_AXI_AGENT_BASE_SVH
virtual class tvip_axi_agent_base #(
  type  WRITE_MONITOR = uvm_monitor,
  type  READ_MONITOR  = uvm_monitor,
  type  SEQUENCER     = uvm_sequencer,
  type  SUB_SEQUENCER = uvm_sequencer,
  type  WRITE_DRIVER  = uvm_driver,
  type  READ_DRIVER   = uvm_driver
) extends tue_agent #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        )
);
  uvm_analysis_port #(tvip_axi_item)  item_port;
  SEQUENCER                           sequencer;

  protected WRITE_MONITOR write_monitor;
  protected WRITE_DRIVER  write_driver;
  protected SUB_SEQUENCER write_sequencer;

  protected READ_MONITOR  read_monitor;
  protected READ_DRIVER   read_driver;
  protected SUB_SEQUENCER read_sequencer;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    item_port = new("item_port", this);
    if (is_active_agent()) begin
      sequencer = SEQUENCER::type_id::create("sequencer", this);
      sequencer.set_context(configuration, status);
    end

    write_monitor = WRITE_MONITOR::type_id::create("write_monitor", this);
    write_monitor.set_context(configuration, status);
    if (is_active_agent()) begin
      write_driver    = WRITE_DRIVER::type_id::create("write_driver", this);
      write_driver.set_context(configuration, status);
    end

    read_monitor = READ_MONITOR::type_id::create("read_monitor", this);
    read_monitor.set_context(configuration, status);
    if (is_active_agent()) begin
      read_driver     = READ_DRIVER::type_id::create("read_driver", this);
      read_driver.set_context(configuration, status);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    write_monitor.item_port.connect(item_port);
    if (is_active_agent()) begin
      write_monitor.address_item_port.connect(sequencer.address_item_export);
      write_monitor.request_item_port.connect(sequencer.request_item_export);
      write_monitor.response_item_port.connect(sequencer.response_item_export);
      write_monitor.item_port.connect(sequencer.item_export);
      write_driver.seq_item_port.connect(sequencer.write_sequencer.seq_item_export);
    end

    read_monitor.item_port.connect(item_port);
    if (is_active_agent()) begin
      read_monitor.address_item_port.connect(sequencer.address_item_export);
      read_monitor.request_item_port.connect(sequencer.request_item_export);
      read_monitor.response_item_port.connect(sequencer.response_item_export);
      read_monitor.item_port.connect(sequencer.item_export);
      read_driver.seq_item_port.connect(sequencer.read_sequencer.seq_item_export);
    end
  endfunction

  `tue_component_default_constructor(tvip_axi_agent_base)
endclass
`endif
