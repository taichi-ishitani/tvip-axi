`ifndef TVIP_AXI_COMPONENT_BASE_SVH
`define TVIP_AXI_COMPONENT_BASE_SVH
virtual class tvip_axi_component_base #(
  type  BASE  = uvm_component
) extends BASE;
  protected bit           write_component;
  protected tvip_axi_vif  vif;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    vif = configuration.vif;
  endfunction

  protected function bit is_write_component();
    return write_component;
  endfunction

  protected function bit is_read_component();
    return !write_component;
  endfunction

  virtual function void begin_address(tvip_axi_item item);
    void'(begin_tr(item));
    item.begin_address();
  endfunction

  virtual function void end_address(tvip_axi_item item);
    item.end_address();
  endfunction

  virtual function void begin_write_data(tvip_axi_item item);
    if (item.is_write()) begin
      item.begin_write_data();
    end
  endfunction

  virtual function void end_write_data(tvip_axi_item item);
    if (item.is_write()) begin
      item.end_write_data();
    end
  endfunction

  virtual function void begin_response(tvip_axi_item item);
    item.begin_response();
  endfunction

  virtual function void end_response(tvip_axi_item item);
    item.end_response();
    end_tr(item);
  endfunction

  protected function bit get_address_valid();
    return (write_component) ? vif.monitor_cb.awvalid : vif.monitor_cb.arvalid;
  endfunction

  protected function bit get_address_ready();
    return (write_component) ? vif.monitor_cb.awready : vif.monitor_cb.arready;
  endfunction

  protected function bit get_address_ack();
    return (write_component) ? vif.monitor_cb.awack : vif.monitor_cb.arack;
  endfunction

  protected function bit get_write_data_valid();
    return (write_component) ? vif.monitor_cb.wvalid : '0;
  endfunction

  protected function bit get_write_data_ready();
    return (write_component) ? vif.monitor_cb.wready : '0;
  endfunction

  protected function bit get_write_data_ack();
    return (write_component) ? vif.monitor_cb.wack : '0;
  endfunction

  protected function bit get_response_valid();
    return (write_component) ? vif.monitor_cb.bvalid : vif.monitor_cb.rvalid;
  endfunction

  protected function bit get_response_ready();
    return (write_component) ? vif.monitor_cb.bready : vif.monitor_cb.rready;
  endfunction

  protected function bit get_response_ack();
    return (write_component) ? vif.monitor_cb.back : vif.monitor_cb.rack;
  endfunction

  protected function tvip_axi_id get_address_id();
    return (write_component) ? vif.monitor_cb.awid : vif.monitor_cb.arid;
  endfunction

  protected function tvip_axi_address get_address();
    return (write_component) ? vif.monitor_cb.awaddr : vif.monitor_cb.araddr;
  endfunction

  protected function int get_burst_length();
    tvip_axi_burst_length burst_length;
    burst_length  = (write_component) ? vif.monitor_cb.awlen : vif.monitor_cb.arlen;
    return unpack_burst_length(burst_length);
  endfunction

  protected function int get_burst_size();
    tvip_axi_burst_size burst_size;
    burst_size  = (write_component) ? vif.monitor_cb.awsize : vif.monitor_cb.arsize;
    return unpack_burst_size(burst_size);
  endfunction

  protected function tvip_axi_burst_type get_burst_type();
    return (write_component) ? vif.monitor_cb.awburst : vif.monitor_cb.arburst;
  endfunction

  protected function tvip_axi_data get_write_data();
    return (write_component) ? vif.monitor_cb.wdata : '0;
  endfunction

  protected function tvip_axi_strobe get_strobe();
    return (write_component) ? vif.monitor_cb.wstrb : '0;
  endfunction

  protected function bit get_write_data_last();
    return (write_component) ? vif.monitor_cb.wlast : '0;
  endfunction

  protected function tvip_axi_id get_response_id();
    return (write_component) ? vif.monitor_cb.bid : vif.monitor_cb.rid;
  endfunction

  protected function tvip_axi_response get_response();
    return (write_component) ? vif.monitor_cb.bresp : vif.monitor_cb.rresp;
  endfunction

  protected function tvip_axi_data get_read_data();
    return (write_component) ? '0 : vif.monitor_cb.rdata;
  endfunction

  protected function bit get_response_last();
    return (write_component) ? '1 : vif.monitor_cb.rlast;
  endfunction

  `tue_component_default_constructor(tvip_axi_component_base)
endclass
`endif
