`ifndef TVIP_AXI_MASTER_DRIVER_SVH
`define TVIP_AXI_MASTER_DRIVER_SVH
typedef tue_driver #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_master_item   )
) tvip_axi_master_driver_base;

virtual class tvip_axi_master_driver extends tvip_axi_component_base #(
  .BASE (tvip_axi_master_driver_base  )
);
  protected tvip_axi_item           request_items[$];
  protected tvip_axi_item           current_address;
  protected tvip_axi_item           write_items[$];
  protected tvip_axi_item           current_write_data;
  protected int                     write_data_delay;
  protected int                     write_data_index;
  protected tvip_axi_payload_store  response_items[tvip_axi_id][$];
  protected bit                     default_response_ready;
  protected int                     response_ready_delay;

  task run_phase(uvm_phase phase);
    fork
      queuing_thread();
      main_thread();
    join
  endtask

  protected task queuing_thread();
    forever begin
      tvip_axi_master_item  item;
      seq_item_port.get_next_item(item);
      accept_tr(item);
      request_items.push_back(item);
      seq_item_port.item_done();
    end
  endtask

  protected task main_thread();
    forever @(vif.master_cb, negedge vif.areset_n) begin
      if (!vif.areset_n) begin
        do_reset();
      end
      else begin
        if ((current_address != null) && get_address_ack()) begin
          finish_address();
        end
        if ((current_write_data != null) && get_write_data_ack()) begin
          finish_write_data();
        end
        if (get_response_valid() && (response_ready_delay < 0)) begin
          get_next_response_delay();
        end
        if (get_response_ack()) begin
          sample_response();
        end

        if (current_address == null) begin
          uvm_wait_for_nba_region();
          if (request_items.size() > 0) begin
            get_next_request();
          end
        end
        drive_address_channel();

        if (is_write_component()) begin
          if ((current_write_data == null) && (write_items.size() > 0)) begin
            get_next_write_data();
          end
          if ((current_write_data != null) && (write_data_delay >= 0)) begin
            consume_write_data_delay();
          end
          drive_write_data_channel();
        end

        drive_response_channel();
      end
    end
  endtask

  protected task do_reset();
    if (current_address != null) begin
      end_tr(current_address);
    end

    foreach (write_items[i]) begin
      if (write_items[i].end_event.is_off()) begin
        end_tr(write_items[i]);
      end
    end
    write_items.delete();

    foreach (response_items[i, j]) begin
      if (response_items[i][j].item.end_event.is_off()) begin
        end_tr(response_items[i][j].item);
      end
    end
    response_items.delete();

    current_address       = null;
    current_write_data    = null;
    write_data_delay      = -1;
    write_data_index      = 0;
    response_ready_delay  = -1;

    if (configuration.reset_by_agent) begin
      reset_if();
    end
  endtask

  protected pure virtual task reset_if();

  protected task get_next_request();
    current_address = request_items.pop_front();
    begin_address(current_address);

    if (current_address.is_write()) begin
      write_items.push_back(current_address);
    end

    response_items[current_address.id].push_back(
      tvip_axi_payload_store::create(current_address)
    );
  endtask

  protected task drive_address_channel();
    bit valid = (current_address != null) ? 1 : 0;
    drive_address_valid(valid);
    drive_id(get_id_value(valid));
    drive_address(get_address_value(valid));
    drive_burst_length(get_burst_length_value(valid));
    drive_burst_size(get_burst_size_value(valid));
    drive_burst_type(get_burst_type_value(valid));
  endtask

  protected virtual function tvip_axi_id get_id_value(bit valid);
    if (valid) begin
      return current_address.id;
    end
    else begin
      return '0;  //  TBD
    end
  endfunction

  protected virtual function tvip_axi_address get_address_value(bit valid);
    if (valid) begin
      return current_address.address;
    end
    else begin
      return '0;  //  TBD
    end
  endfunction

  protected virtual function tvip_axi_burst_length get_burst_length_value(bit valid);
    if (valid) begin
      return pack_burst_length(current_address.get_burst_length());
    end
    else begin
      return '0;  //  TBD
    end
  endfunction

  protected virtual function tvip_axi_burst_size get_burst_size_value(bit valid);
    if (valid) begin
      return pack_burst_size(current_address.get_burst_size());
    end
    else begin
      return TVIP_AXI_BURST_SIZE_1_BYTE;  //  TBD
    end
  endfunction

  protected virtual function tvip_axi_burst_type get_burst_type_value(bit valid);
    if (valid) begin
      return current_address.burst_type;
    end
    else begin
      return TVIP_AXI_FIXED_BURST;  //  TBD
    end
  endfunction

  protected pure virtual task drive_address_valid(bit valid);
  protected pure virtual task drive_id(tvip_axi_id id);
  protected pure virtual task drive_address(tvip_axi_address address);
  protected pure virtual task drive_burst_length(tvip_axi_burst_length burst_length);
  protected pure virtual task drive_burst_size(tvip_axi_burst_size burst_size);
  protected pure virtual task drive_burst_type(tvip_axi_burst_type burst_type);

  protected virtual task finish_address();
    end_address(current_address);
    current_address = null;
  endtask

  protected task get_next_write_data();
    current_write_data  = write_items.pop_front();
    write_data_delay    = 0;
    write_data_index    = 0;
  endtask

  protected task consume_write_data_delay();
    if (write_data_delay < current_write_data.write_data_delay[write_data_index]) begin
      ++write_data_delay;
    end
  endtask

  protected task drive_write_data_channel();
    bit valid;

    valid = (
      (current_write_data != null) &&
      (write_data_delay == current_write_data.write_data_delay[write_data_index])
    ) ? '1 : 0;
    if (valid && (!current_write_data.write_data_began())) begin
      begin_write_data(current_write_data);
    end

    drive_write_data_valid(valid);
    drive_write_data(get_write_data_value(valid));
    drive_strobe(get_strobe_value(valid));
    drive_write_data_last(get_write_data_last_value(valid));
  endtask

  protected virtual function tvip_axi_data get_write_data_value(bit valid);
    if (valid) begin
      return current_write_data.get_data(write_data_index);
    end
    else begin
      return '0;  //  TBD
    end
  endfunction

  protected virtual function tvip_axi_strobe get_strobe_value(bit valid);
    if (valid) begin
      return current_write_data.get_strobe(write_data_index);
    end
    else begin
      return '0;  //  TBD
    end
  endfunction

  protected virtual function bit get_write_data_last_value(bit valid);
    if (valid) begin
      return (
        write_data_index == (current_write_data.get_burst_length() - 1)
      ) ? '1 : '0;
    end
    else begin
      return '0;  //  TBD
    end
  endfunction

  protected pure virtual task drive_write_data_valid(bit valid);
  protected pure virtual task drive_write_data(tvip_axi_data data);
  protected pure virtual task drive_strobe(tvip_axi_strobe strobe);
  protected pure virtual task drive_write_data_last(bit last);

  protected virtual task finish_write_data();
    if (write_data_index == (current_write_data.get_burst_length() - 1)) begin
      write_data_delay  = -1;
      end_write_data(current_write_data);
      current_write_data  = null;
    end
    else begin
      write_data_delay  = 0;
      ++write_data_index;
    end
  endtask

  protected task get_next_response_delay();
    tvip_axi_id id;
    int         index;

    if (get_response_ready() != default_response_ready) begin
      return;
    end

    id  = get_response_id();
    if ((!response_items.exists(id)) || (response_items[id].size() == 0)) begin
      return;
    end

    index                 = response_items[id][0].get_stored_response_count();
    response_ready_delay  = response_items[id][0].item.response_ready_delay[index];
  endtask

  protected task drive_response_channel();
    bit response_ready;

    response_ready  = (
      ((default_response_ready == 1) && (response_ready_delay <= 0)) ||
      ((default_response_ready == 0) && (response_ready_delay == 0))
    ) ? 1 : 0;
    drive_response_ready(response_ready);

    if (response_ready_delay >= 0) begin
      --response_ready_delay;
    end
  endtask

  protected pure virtual task drive_response_ready(bit ready);

  protected task sample_response();
    tvip_axi_id id;

    id  = get_response_id();
    if ((!response_items.exists(id)) || (response_items[id].size() == 0)) begin
      return;
    end

    if (!response_items[id][0].item.response_began()) begin
      begin_response(response_items[id][0].item);
    end

    response_items[id][0].store_response(get_response(), get_read_data());
    if (get_response_last()) begin
      response_items[id][0].pack_response();
      end_response(response_items[id][0].item);
      void'(response_items[id].pop_front());
    end
  endtask

  `tue_component_default_constructor(tvip_axi_master_driver)
endclass

class tvip_axi_write_master_driver extends tvip_axi_master_driver;
  function new(string name = "tvip_axi_write_master_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 1;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    default_response_ready  = configuration.default_bready;
  endfunction

  task reset_if();
    vif.awvalid = 0;
    vif.awid    = get_id_value(0);
    vif.awaddr  = get_address_value(0);
    vif.awlen   = get_burst_length_value(0);
    vif.awsize  = get_burst_size_value(0);
    vif.awburst = get_burst_type_value(0);
    vif.wvalid  = 0;
    vif.wdata   = get_write_data_value(0);
    vif.wstrb   = get_strobe_value(0);
    vif.wlast   = get_write_data_last_value(0);
    vif.bready  = default_response_ready;
  endtask

  task drive_address_valid(bit valid);
    vif.master_cb.awvalid <= valid;
  endtask

  task drive_id(tvip_axi_id id);
    vif.master_cb.awid  <= id;
  endtask

  task drive_address(tvip_axi_address address);
    vif.master_cb.awaddr  <= address;
  endtask

  task drive_burst_length(tvip_axi_burst_length burst_length);
    vif.master_cb.awlen <= burst_length;
  endtask

  task drive_burst_size(tvip_axi_burst_size burst_size);
    vif.master_cb.awsize  <= burst_size;
  endtask

  task drive_burst_type(tvip_axi_burst_type burst_type);
    vif.master_cb.awburst <= burst_type;
  endtask

  task drive_write_data_valid(bit valid);
    vif.master_cb.wvalid  <= valid;
  endtask

  task drive_write_data(tvip_axi_data data);
    vif.master_cb.wdata <= data;
  endtask

  task drive_strobe(tvip_axi_strobe strobe);
    vif.master_cb.wstrb <= strobe;
  endtask

  task drive_write_data_last(bit last);
    vif.master_cb.wlast <= last;
  endtask

  task drive_response_ready(bit ready);
    vif.master_cb.bready  <= ready;
  endtask

  `uvm_component_utils(tvip_axi_write_master_driver)
endclass

class tvip_axi_read_master_driver extends tvip_axi_master_driver;
  function new(string name = "tvip_axi_read_master_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    default_response_ready  = configuration.default_rready;
  endfunction

  task reset_if();
    vif.arvalid = 0;
    vif.arid    = get_id_value(0);
    vif.araddr  = get_address_value(0);
    vif.arlen   = get_burst_length_value(0);
    vif.arsize  = get_burst_size_value(0);
    vif.arburst = get_burst_type_value(0);
    vif.rready  = default_response_ready;
  endtask

  task drive_address_valid(bit valid);
    vif.master_cb.arvalid <= valid;
  endtask

  task drive_id(tvip_axi_id id);
    vif.master_cb.arid  <= id;
  endtask

  task drive_address(tvip_axi_address address);
    vif.master_cb.araddr  <= address;
  endtask

  task drive_burst_length(tvip_axi_burst_length burst_length);
    vif.master_cb.arlen <= burst_length;
  endtask

  task drive_burst_size(tvip_axi_burst_size burst_size);
    vif.master_cb.arsize  <= burst_size;
  endtask

  task drive_burst_type(tvip_axi_burst_type burst_type);
    vif.master_cb.arburst <= burst_type;
  endtask

  task drive_write_data_valid(bit valid);
  endtask

  task drive_write_data(tvip_axi_data data);
  endtask

  task drive_strobe(tvip_axi_strobe strobe);
  endtask

  task drive_write_data_last(bit last);
  endtask

  task drive_response_ready(bit ready);
    vif.master_cb.rready  <= ready;
  endtask

  `uvm_component_utils(tvip_axi_read_master_driver)
endclass
`endif
