`ifndef TVIP_AXI_MASTER_DRIVER_SVH
`define TVIP_AXI_MASTER_DRIVER_SVH
typedef tue_fifo #(tvip_axi_item) tvip_axi_request_item_queue;

typedef tvip_axi_sub_driver_base #(
  .ITEM (tvip_axi_master_item )
) tvip_axi_master_sub_driver_base;

class tvip_axi_master_sub_driver extends tvip_axi_component_base #(
  .BASE (tvip_axi_master_sub_driver_base  )
);
  protected tvip_axi_request_item_queue address_queue;
  protected tvip_axi_request_item_queue write_data_queue;
  protected tvip_axi_payload_store      response_stores[tvip_axi_id][$];
  protected bit                         default_response_ready;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    address_queue = new("address_queue", 0);
    if (is_write_component()) begin
      write_data_queue  = new("write_data_queue", 0);
    end
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

  task end_response(tvip_axi_item item);
    super.end_response(item);
    if (item.need_response) begin
      put_response(item);
    end
  endtask

  task put_request(tvip_axi_item request);
    accept_tr(request);

    address_queue.put(request);
    if (write_data_queue != null) begin
      write_data_queue.put(request);
    end

    response_stores[request.id]
      .push_back(tvip_axi_payload_store::create(request));
  endtask

  protected virtual task do_reset();
    tvip_axi_item item;

    while (!address_queue.is_empty()) begin
      void'(address_queue.try_get(item));
      if (!item.finished()) begin
        end_tr(item);
      end
    end

    if (write_data_queue != null) begin
      while (!write_data_queue.is_empty()) begin
        void'(write_data_queue.try_get(item));
        if (!item.finished()) begin
          end_tr(item);
        end
      end
    end

    foreach (response_stores[i, j]) begin
      if (!response_stores[i][j].item.finished()) begin
        end_tr(response_stores[i][j].item);
      end
    end
    response_stores.delete();

    reset_if();
    @(posedge vif.areset_n);
  endtask

  protected virtual task reset_if();
  endtask

  protected task main();
    fork
      address_thread();
      write_data_thread();
      response_thread();
    join
  endtask

  protected task address_thread();
    tvip_axi_item item;

    forever begin
      get_item_from_queue(address_queue, item);
      consume_delay(item.start_delay);
      begin_address(item);
      drive_address(1, item);
      wait_for_address_ready();
      drive_address(0, null);
      end_address(item);
    end
  endtask

  protected virtual task drive_address(
    bit           valid,
    tvip_axi_item item
  );
  endtask

  protected task wait_for_address_ready();
    do begin
      @(vif.master_cb);
    end while (!get_address_ready());
  endtask

  protected virtual function bit get_address_ready();
  endfunction

  protected task write_data_thread();
    tvip_axi_item item;

    if (is_read_component()) begin
      return;
    end

    forever begin
      get_item_from_queue(write_data_queue, item);

      for (int i = 0;i < item.get_burst_length();++i) begin
        consume_delay(item.write_data_delay[i]);
        if (i == 0) begin
          begin_write_data(item);
        end
        drive_write_data(1, item, i);
        wait_for_write_data_ready();
        drive_write_data(0, null, 0);
      end

      end_write_data(item);
    end
  endtask

  protected virtual task drive_write_data(
    bit           valid,
    tvip_axi_item item,
    int           index
  );
    vif.master_cb.wvalid  <= valid;
    if (valid) begin
      vif.master_cb.wdata <= item.data[index];
      vif.master_cb.wstrb <= item.strobe[index];
      if (configuration.protocol == TVIP_AXI4) begin
        vif.master_cb.wlast <= index == (item.get_burst_length() - 1);
      end
    end
  endtask

  protected task wait_for_write_data_ready();
    do begin
      @(vif.master_cb);
    end while (!vif.master_cb.wready);
  endtask

  protected task response_thread();
    bit         busy;
    tvip_axi_id id;
    tvip_axi_id current_id;
    int         delay;

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

      delay = get_response_ready_delay(current_id);
      if (default_response_ready) begin
        sample_response(current_id, busy);
        if (delay > 0) begin
          drive_response_ready(0);
          consume_delay(delay);
          drive_response_ready(1);
        end
      end
      else begin
        consume_delay(delay);
        drive_response_ready(1);
        consume_delay(1);
        sample_response(current_id, busy);
        drive_response_ready(0);
      end
    end
  endtask

  protected task wait_for_response_valid();
    do begin
      @(vif.master_cb);
    end while (!get_response_valid());
  endtask

  protected virtual function bit get_response_valid();
  endfunction

  protected virtual function tvip_axi_id get_response_id();
  endfunction

  protected virtual function tvip_axi_data get_response_data();
  endfunction

  protected virtual function tvip_axi_response get_response_status();
  endfunction

  protected virtual function logic get_response_last();
  endfunction

  protected function bit is_valid_response(tvip_axi_id id);
    return response_stores.exists(id) && response_stores[id].size() > 0;
  endfunction

  protected function int get_response_ready_delay(tvip_axi_id id);
    tvip_axi_payload_store  store;
    int                     index;
    store = response_stores[id][0];
    index = store.get_stored_response_count();
    return store.item.response_ready_delay[index];
  endfunction

  protected virtual task drive_response_ready(bit ready);
  endtask

  protected task sample_response(
    input tvip_axi_id id,
    ref   bit         busy
  );
    tvip_axi_payload_store  store;

    store = response_stores[id][0];
    store.store_response(get_response_status(), get_response_data());
    if (get_response_last()) begin
      store.pack_response();
      end_response(store.item);
      void'(response_stores[id].pop_front());
      busy  = 0;
    end
  endtask

  protected task get_item_from_queue(
    input tvip_axi_request_item_queue queue,
    ref   tvip_axi_item               item
  );
    queue.get(item);
    if (!vif.at_master_cb_edge.triggered) begin
      @(vif.at_master_cb_edge);
    end
  endtask

  protected task consume_delay(int delay);
    repeat (delay) begin
      @(vif.master_cb);
    end
  endtask

  `tue_component_default_constructor(tvip_axi_master_sub_driver)
endclass

class tvip_axi_master_write_driver extends tvip_axi_master_sub_driver;
  function new(string name = "tvip_axi_master_write_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 1;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    default_response_ready  = configuration.default_bready;
  endfunction

  protected task reset_if();
    vif.master_cb.awvalid <= '0;
    vif.master_cb.awid    <= '0;
    vif.master_cb.awaddr  <= '0;
    vif.master_cb.awlen   <= '0;
    vif.master_cb.awsize  <= tvip_axi_burst_size'(0);
    vif.master_cb.awburst <= tvip_axi_burst_type'(0);
    vif.master_cb.awcache <= tvip_axi_write_cache'(0);
    vif.master_cb.awprot  <= '0;
    vif.master_cb.awqos   <= '0;
    vif.master_cb.wvalid  <= '0;
    vif.master_cb.wdata   <= '0;
    vif.master_cb.wstrb   <= '0;
    vif.master_cb.wlast   <= '0;
    vif.master_cb.bready  <= configuration.default_bready;
  endtask

  protected task drive_address(
    bit           valid,
    tvip_axi_item item
  );
    vif.master_cb.awvalid <= valid;
    if (valid) begin
      vif.master_cb.awaddr  <= item.address;
      vif.master_cb.awid    <= item.id;
      vif.master_cb.awlen   <= item.get_packed_burst_length();
      vif.master_cb.awsize  <= item.get_packed_burst_size();
      vif.master_cb.awburst <= item.burst_type;
      vif.master_cb.awcache <= item.get_cache();
      vif.master_cb.awprot  <= item.protection;
      vif.master_cb.awqos   <= item.qos;
    end
  endtask

  protected function bit get_address_ready();
    return vif.master_cb.awready;
  endfunction

  protected function bit get_response_valid();
    return vif.master_cb.bvalid;
  endfunction

  protected function tvip_axi_id get_response_id();
    return vif.master_cb.bid;
  endfunction

  protected function tvip_axi_data get_response_data();
    return '0;
  endfunction

  protected function tvip_axi_response get_response_status();
    return vif.master_cb.bresp;
  endfunction

  protected function logic get_response_last();
    return '1;
  endfunction

  protected task drive_response_ready(bit ready);
    vif.master_cb.bready  <= ready;
  endtask

  `uvm_component_utils(tvip_axi_master_write_driver)
endclass

class tvip_axi_master_read_driver extends tvip_axi_master_sub_driver;
  function new(string name = "tvip_axi_master_read_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    default_response_ready  = configuration.default_rready;
  endfunction

  protected task reset_if();
    vif.master_cb.arvalid <= '0;
    vif.master_cb.arid    <= '0;
    vif.master_cb.araddr  <= '0;
    vif.master_cb.arlen   <= '0;
    vif.master_cb.arsize  <= tvip_axi_burst_size'(0);
    vif.master_cb.arburst <= tvip_axi_burst_type'(0);
    vif.master_cb.arcache <= tvip_axi_read_cache'(0);
    vif.master_cb.arprot  <= '0;
    vif.master_cb.arqos   <= '0;
    vif.master_cb.rready  <= configuration.default_rready;
  endtask

  protected task drive_address(
    bit           valid,
    tvip_axi_item item
  );
    vif.master_cb.arvalid <= valid;
    if (valid) begin
      vif.master_cb.araddr  <= item.address;
      vif.master_cb.arid    <= item.id;
      vif.master_cb.arlen   <= item.get_packed_burst_length();
      vif.master_cb.arsize  <= item.get_packed_burst_size();
      vif.master_cb.arburst <= item.burst_type;
      vif.master_cb.arcache <= item.get_cache();
      vif.master_cb.arprot  <= item.protection;
      vif.master_cb.arqos   <= item.qos;
    end
  endtask

  protected function bit get_address_ready();
    return vif.master_cb.arready;
  endfunction

  protected function bit get_response_valid();
    return vif.master_cb.rvalid;
  endfunction

  protected function tvip_axi_id get_response_id();
    return vif.master_cb.rid;
  endfunction

  protected function tvip_axi_data get_response_data();
    return vif.master_cb.rdata;
  endfunction

  protected function tvip_axi_response get_response_status();
    return vif.master_cb.rresp;
  endfunction

  protected function logic get_response_last();
    return (configuration.protocol == TVIP_AXI4LITE) || vif.master_cb.rlast;
  endfunction

  protected task drive_response_ready(bit ready);
    vif.master_cb.rready  <= ready;
  endtask

  `uvm_component_utils(tvip_axi_master_read_driver)
endclass

class tvip_axi_master_driver extends tvip_axi_driver_base #(
  .ITEM         (tvip_axi_master_item         ),
  .WRITE_DRIVER (tvip_axi_master_write_driver ),
  .READ_DRIVER  (tvip_axi_master_read_driver  )
);
  `tue_component_default_constructor(tvip_axi_master_driver)
  `uvm_component_utils(tvip_axi_master_driver)
endclass
`endif
