`ifndef TVIP_AXI_MASTER_DRIVER_SVH
`define TVIP_AXI_MASTER_DRIVER_SVH
typedef tvip_axi_sub_driver_base #(
  .ITEM (tvip_axi_master_item )
) tvip_axi_master_sub_driver_base;

class tvip_axi_master_sub_driver extends tvip_axi_component_base #(
  .BASE (tvip_axi_master_sub_driver_base  )
);
  protected int                     start_delay;
  protected tvip_axi_item           current_address;
  protected tvip_axi_item           write_items[$];
  protected tvip_axi_item           current_write_data;
  protected int                     write_data_delay;
  protected int                     write_data_index;
  protected tvip_axi_payload_store  response_items[tvip_axi_id][$];
  protected bit                     default_response_ready;
  protected int                     response_ready_delay;

  task run_phase(uvm_phase phase);
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
          get_next_request();
        end
        drive_address_channel();

        if (is_write_component()) begin
          if ((current_write_data == null) && (write_items.size() > 0)) begin
            get_next_write_data();
          end
          drive_write_data_channel();
        end

        drive_response_channel();
      end
    end
  endtask

  task end_response(tvip_axi_item item);
    super.end_response(item);
    if (item.need_response) begin
      put_response(item);
    end
  endtask

  protected task do_reset();
    if (current_address != null) begin
      end_tr(current_address);
    end

    foreach (write_items[i]) begin
      if (!write_items[i].ended()) begin
        end_tr(write_items[i]);
      end
    end
    write_items.delete();

    foreach (response_items[i, j]) begin
      if (!response_items[i][j].item.ended()) begin
        end_tr(response_items[i][j].item);
      end
    end
    response_items.delete();

    current_address       = null;
    current_write_data    = null;
    start_delay           = 0;
    write_data_delay      = 0;
    write_data_index      = 0;
    response_ready_delay  = -1;

    if (configuration.reset_by_agent) begin
      reset_if();
    end
  endtask

  protected virtual task reset_if();
  endtask

  protected task get_next_request();
    uvm_wait_for_nba_region();
    if (item_buffer.size() == 0) begin
      return;
    end

    current_address = item_buffer.pop_front();
    start_delay     = current_address.start_delay;

    if (current_address.is_write()) begin
      write_items.push_back(current_address);
    end

    response_items[current_address.id].push_back(
      tvip_axi_payload_store::create(current_address)
    );
  endtask

  protected task drive_address_channel();
    bit valid;

    if (start_delay > 0) begin
      --start_delay;
    end

    valid = ((current_address != null) && (start_delay == 0));
    if (valid && (!current_address.address_began())) begin
      begin_address(current_address);
    end

    drive_address_valid(valid);
    drive_id(get_id_value(valid));
    drive_address(get_address_value(valid));
    drive_burst_length(get_burst_length_value(valid));
    drive_burst_size(get_burst_size_value(valid));
    drive_burst_type(get_burst_type_value(valid));
    drive_qos(get_qos_value(valid));
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

  protected virtual function tvip_axi_qos get_qos_value(bit valid);
    if (valid) begin
      return current_address.qos;
    end
    else begin
      return '0;  //  TBD
    end
  endfunction

  protected virtual task drive_address_valid(bit valid);
  endtask

  protected virtual task drive_id(tvip_axi_id id);
  endtask

  protected virtual task drive_address(tvip_axi_address address);
  endtask

  protected virtual task drive_burst_length(tvip_axi_burst_length burst_length);
  endtask

  protected virtual task drive_burst_size(tvip_axi_burst_size burst_size);
  endtask

  protected virtual task drive_burst_type(tvip_axi_burst_type burst_type);
  endtask

  protected virtual task drive_qos(tvip_axi_qos qos);
  endtask

  protected virtual task finish_address();
    end_address(current_address);
    current_address = null;
  endtask

  protected task get_next_write_data();
    current_write_data  = write_items.pop_front();
    write_data_delay    = current_write_data.write_data_delay[0];
    write_data_index    = 0;
  endtask

  protected task drive_write_data_channel();
    bit valid;

    if ((current_write_data != null) && current_write_data.address_began()) begin
      if (write_data_delay > 0) begin
        --write_data_delay;
      end
      valid = (write_data_delay == 0);
    end
    else begin
      valid = 0;
    end

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

  protected virtual task drive_write_data_valid(bit valid);
  endtask

  protected virtual task drive_write_data(tvip_axi_data data);
  endtask

  protected virtual task drive_strobe(tvip_axi_strobe strobe);
  endtask

  protected virtual task drive_write_data_last(bit last);
  endtask

  protected virtual task finish_write_data();
    if (write_data_index == (current_write_data.get_burst_length() - 1)) begin
      end_write_data(current_write_data);
      current_write_data  = null;
    end
    else begin
      ++write_data_index;
      write_data_delay  = current_write_data.write_data_delay[write_data_index];
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

  protected virtual task drive_response_ready(bit ready);
  endtask

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

  protected task drive_address_valid(bit valid);
    vif.master_cb.awvalid <= valid;
  endtask

  protected task drive_id(tvip_axi_id id);
    vif.master_cb.awid  <= id;
  endtask

  protected task drive_address(tvip_axi_address address);
    vif.master_cb.awaddr  <= address;
  endtask

  protected task drive_burst_length(tvip_axi_burst_length burst_length);
    vif.master_cb.awlen <= burst_length;
  endtask

  protected task drive_burst_size(tvip_axi_burst_size burst_size);
    vif.master_cb.awsize  <= burst_size;
  endtask

  protected task drive_burst_type(tvip_axi_burst_type burst_type);
    vif.master_cb.awburst <= burst_type;
  endtask

  protected task drive_qos(tvip_axi_qos qos);
    vif.master_cb.awqos <= qos;
  endtask

  protected task drive_write_data_valid(bit valid);
    vif.master_cb.wvalid  <= valid;
  endtask

  protected task drive_write_data(tvip_axi_data data);
    vif.master_cb.wdata <= data;
  endtask

  protected task drive_strobe(tvip_axi_strobe strobe);
    vif.master_cb.wstrb <= strobe;
  endtask

  protected task drive_write_data_last(bit last);
    vif.master_cb.wlast <= last;
  endtask

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
    vif.arvalid = 0;
    vif.arid    = get_id_value(0);
    vif.araddr  = get_address_value(0);
    vif.arlen   = get_burst_length_value(0);
    vif.arsize  = get_burst_size_value(0);
    vif.arburst = get_burst_type_value(0);
    vif.rready  = default_response_ready;
  endtask

  protected task drive_address_valid(bit valid);
    vif.master_cb.arvalid <= valid;
  endtask

  protected task drive_id(tvip_axi_id id);
    vif.master_cb.arid  <= id;
  endtask

  protected task drive_address(tvip_axi_address address);
    vif.master_cb.araddr  <= address;
  endtask

  protected task drive_burst_length(tvip_axi_burst_length burst_length);
    vif.master_cb.arlen <= burst_length;
  endtask

  protected task drive_burst_size(tvip_axi_burst_size burst_size);
    vif.master_cb.arsize  <= burst_size;
  endtask

  protected task drive_burst_type(tvip_axi_burst_type burst_type);
    vif.master_cb.arburst <= burst_type;
  endtask

  protected task drive_qos(tvip_axi_qos qos);
    vif.master_cb.arqos <= qos;
  endtask

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
