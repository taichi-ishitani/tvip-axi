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

  virtual task begin_address(tvip_axi_item item);
    if (!item.write_data_began()) begin
      void'(begin_tr(item));
    end
    item.begin_address();
  endtask

  virtual task end_address(tvip_axi_item item);
    item.end_address();
  endtask

  virtual task begin_write_data(tvip_axi_item item);
    if (item.is_write()) begin
      if (!item.address_began()) begin
        void'(begin_tr(item));
      end
      item.begin_write_data();
    end
  endtask

  virtual task end_write_data(tvip_axi_item item);
    if (item.is_write()) begin
      item.end_write_data();
    end
  endtask

  virtual task begin_response(tvip_axi_item item);
    item.begin_response();
  endtask

  virtual task end_response(tvip_axi_item item);
    item.end_response();
    end_tr(item);
  endtask

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
    if (configuration.id_width > 0) begin
      return (write_component) ? vif.monitor_cb.awid : vif.monitor_cb.arid;
    end
    else begin
      return 0;
    end
  endfunction

  protected function tvip_axi_address get_address();
    return (write_component) ? vif.monitor_cb.awaddr : vif.monitor_cb.araddr;
  endfunction

  protected function int get_burst_length();
    if (configuration.protocol == TVIP_AXI4) begin
      tvip_axi_burst_length burst_length;
      burst_length  = (write_component) ? vif.monitor_cb.awlen : vif.monitor_cb.arlen;
      return unpack_burst_length(burst_length);
    end
    else begin
      return 1;
    end
  endfunction

  protected function int get_burst_size();
    if (configuration.protocol == TVIP_AXI4) begin
      tvip_axi_burst_size burst_size;
      burst_size  = (write_component) ? vif.monitor_cb.awsize : vif.monitor_cb.arsize;
      return unpack_burst_size(burst_size);
    end
    else begin
      return configuration.data_width / 8;
    end
  endfunction

  protected function tvip_axi_burst_type get_burst_type();
    if (configuration.protocol == TVIP_AXI4) begin
      return (write_component) ? vif.monitor_cb.awburst : vif.monitor_cb.arburst;
    end
    else begin
      return TVIP_AXI_FIXED_BURST;
    end
  endfunction

  protected function tvip_axi_qos get_qos();
    return (write_component) ? vif.monitor_cb.awqos : vif.monitor_cb.arqos;
  endfunction

  protected function tvip_axi_data get_write_data();
    return (write_component) ? vif.monitor_cb.wdata : '0;
  endfunction

  protected function tvip_axi_strobe get_strobe();
    return (write_component) ? vif.monitor_cb.wstrb : '0;
  endfunction

  protected function bit get_write_data_last();
    if (configuration.protocol == TVIP_AXI4) begin
      return (write_component) ? vif.monitor_cb.wlast : '0;
    end
    else begin
      return (write_component) ? 1 : '0;
    end
  endfunction

  protected function tvip_axi_id get_response_id();
    if (configuration.id_width > 0) begin
      return (write_component) ? vif.monitor_cb.bid : vif.monitor_cb.rid;
    end
    else begin
      return 0;
    end
  endfunction

  protected function tvip_axi_response get_response();
    return (write_component) ? vif.monitor_cb.bresp : vif.monitor_cb.rresp;
  endfunction

  protected function tvip_axi_data get_read_data();
    return (write_component) ? '0 : vif.monitor_cb.rdata;
  endfunction

  protected function bit get_response_last();
    if (configuration.protocol == TVIP_AXI4) begin
      return (write_component) ? '1 : vif.monitor_cb.rlast;
    end
    else begin
      return '1;
    end
  endfunction

  `tue_component_default_constructor(tvip_axi_component_base)
endclass
`endif
