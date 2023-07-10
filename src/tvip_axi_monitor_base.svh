`ifndef TVIP_AXI_MONITOR_BASE_SVH
`define TVIP_AXI_MONITOR_BASE_SVH
virtual class tvip_axi_monitor_base #(
  type  BASE  = uvm_monitor,
  type  ITEM  = uvm_sequence_item
) extends tvip_axi_component_base #(BASE);
  uvm_analysis_port #(tvip_axi_item)  address_item_port;
  uvm_analysis_port #(tvip_axi_item)  request_item_port;
  uvm_analysis_port #(tvip_axi_item)  response_item_port;

  protected tvip_axi_payload_store  write_data_stores[2][$];
  protected tvip_axi_payload_store  response_stores[tvip_axi_id][$];

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    address_item_port   = new("address_item_port" , this);
    request_item_port   = new("request_item_port" , this);
    response_item_port  = new("response_item_port", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      do_reset();
      fork
        main();
        @(negedge vif.areset_n);
      join_any
      disable fork;
    end
  endtask

  task end_address(tvip_axi_item item);
    super.end_address(item);
    address_item_port.write(item);
    if (item.request_ended()) begin
      request_item_port.write(item);
    end
  endtask

  task end_write_data(tvip_axi_item item);
    super.end_write_data(item);
    if (item.request_ended()) begin
      request_item_port.write(item);
    end
  endtask

  task end_response(tvip_axi_item item);
    super.end_response(item);
    write_item(item);
    response_item_port.write(item);
  endtask

  protected virtual task do_reset();
    foreach (write_data_stores[i, j]) begin
      if (!write_data_stores[i][j].item.finished()) begin
        end_tr(write_data_stores[i][j].item);
      end
    end
    write_data_stores[0].delete();
    write_data_stores[1].delete();

    foreach (response_stores[i, j]) begin
      if (!response_stores[i][j].item.finished()) begin
        end_tr(response_stores[i][j].item);
      end
    end
    response_stores.delete();

    @(posedge vif.monitor_cb.areset_n);
  endtask

  protected task main();
    fork
      address_monitor_thread();
      write_data_monitor_thread();
      response_mointor_thread();
    join
  endtask

  protected task address_monitor_thread();
    tvip_axi_item item;

    forever begin
      wait_for_address_valid();
      sample_address(item);

      wait_for_address_ready();
      finish_address(item);
    end
  endtask

  protected task wait_for_address_valid();
    if (is_write_component()) begin
      do begin
        @(vif.monitor_cb);
      end while (!vif.monitor_cb.awvalid);
    end
    else begin
      do begin
        @(vif.monitor_cb);
      end while (!vif.monitor_cb.arvalid);
    end
  endtask

  protected virtual task sample_address(ref tvip_axi_item item);
    tvip_axi_payload_store  store;

    if (is_write_component() && (write_data_stores[1].size() > 0)) begin
      store = write_data_stores[1].pop_front();
      item  = store.item;
    end
    if (item == null) begin
      item  = create_monitor_item();
      store = tvip_axi_payload_store::create(item);
      if (is_write_component()) begin
        write_data_stores[0].push_back(store);
      end
    end

    item.access_type  = (is_write_component()) ? TVIP_AXI_WRITE_ACCESS : TVIP_AXI_READ_ACCESS;
    item.id           = get_address_id();
    item.address      = get_address();
    item.burst_length = get_burst_length();
    item.burst_size   = get_burst_size();
    item.burst_type   = get_burst_type();
    item.memory_type  = get_memory_type();
    item.protection   = get_protection();
    item.qos          = get_qos();

    begin_address(item);
    response_stores[item.id].push_back(store);
  endtask

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

  protected function tvip_axi_memory_type get_memory_type();
    if (configuration.protocol == TVIP_AXI4LITE) begin
      return TVIP_AXI_DEVICE_NON_BUFFERABLE;
    end
    else if (write_component) begin
      return decode_memory_type(vif.monitor_cb.awcache, 0);
    end
    else begin
      return decode_memory_type(vif.monitor_cb.arcache, 1);
    end
  endfunction

  protected function tvip_axi_protection get_protection();
    return (write_component) ? vif.monitor_cb.awprot : vif.monitor_cb.arprot;
  endfunction

  protected function tvip_axi_qos get_qos();
    return (write_component) ? vif.monitor_cb.awqos : vif.monitor_cb.arqos;
  endfunction

  protected task wait_for_address_ready();
    if (is_write_component()) begin
      while (!vif.monitor_cb.awready) begin
        @(vif.monitor_cb);
      end
    end
    else begin
      while (!vif.monitor_cb.arready) begin
        @(vif.monitor_cb);
      end
    end
  endtask

  protected virtual task finish_address(ref tvip_axi_item item);
    end_address(item);
    item  = null;
  endtask

  protected task write_data_monitor_thread();
    tvip_axi_payload_store  store;

    if (is_read_component()) begin
      return;
    end

    forever begin
      wait_for_write_data_valid();
      if (store == null) begin
        store = get_write_data_store();
        begin_write_data(store.item);
      end

      wait_for_write_data_ready();
      sample_write_data(store);
    end
  endtask

  protected task wait_for_write_data_valid();
    do begin
      @(vif.monitor_cb);
    end while (!vif.monitor_cb.wvalid);
  endtask

  protected function tvip_axi_payload_store get_write_data_store();
    if (write_data_stores[0].size() > 0) begin
      return write_data_stores[0].pop_front();
    end
    else begin
      tvip_axi_item           item;
      tvip_axi_payload_store  store;
      item  = create_monitor_item();
      store = tvip_axi_payload_store::create(item);
      write_data_stores[1].push_back(store);
      return store;
    end
  endfunction

  protected task wait_for_write_data_ready();
    while (!vif.monitor_cb.wready) begin
      @(vif.monitor_cb);
    end
  endtask

  protected virtual task sample_write_data(ref tvip_axi_payload_store store);
    store.store_write_data(get_write_data(), get_strobe());
    if (get_write_data_last()) begin
      store.pack_write_data();
      end_write_data(store.item);
      store = null;
    end
  endtask

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

  protected task response_mointor_thread();
    bit         busy;
    tvip_axi_id id;
    tvip_axi_id current_id;

    forever begin
      wait_for_response_valid();

      id  = get_response_id();
      if ((!busy) || (id != current_id)) begin
        if (is_valid_response(id)) begin
          busy        = 1;
          current_id  = id;
          if (!response_stores[current_id][0].item.response_began()) begin
            begin_response(response_stores[current_id][0].item);
          end
        end
        else begin
          busy  = 0;
          `uvm_warning("UNEXPECTED_RESPONSE", $sformatf("unexpected response: id %h", id))
          continue;
        end
      end

      wait_for_response_ready();
      sample_response(current_id, busy);
    end
  endtask

  protected task wait_for_response_valid();
    if (is_write_component()) begin
      do begin
        @(vif.monitor_cb);
      end while (!vif.monitor_cb.bvalid);
    end
    else begin
      do begin
        @(vif.monitor_cb);
      end while (!vif.monitor_cb.rvalid);
    end
  endtask

  protected function bit is_valid_response(tvip_axi_id id);
    return
      response_stores.exists(id) &&
      response_stores[id].size() > 0;
  endfunction

  protected task wait_for_response_ready();
    if (is_write_component()) begin
      while (!vif.monitor_cb.bready) begin
        @(vif.monitor_cb);
      end
    end
    else begin
      while (!vif.monitor_cb.rready) begin
        @(vif.monitor_cb);
      end
    end
  endtask

  protected virtual task sample_response(
    input tvip_axi_id id,
    ref   bit         busy
  );
    tvip_axi_payload_store  store;

    store = response_stores[id][0];
    store.store_response(get_response(), get_read_data());
    if (get_response_last()) begin
      store.pack_response();
      end_response(store.item);
      void'(response_stores[id].pop_front());
      busy  = 0;
    end
  endtask

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

  protected function tvip_axi_item create_monitor_item();
    ITEM  item;
    item  = ITEM::type_id::create("axi_item");
    item.set_context(this.configuration, this.status);
    return item;
  endfunction

  `tue_component_default_constructor(tvip_axi_monitor_base)
endclass
`endif
