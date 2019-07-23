`ifndef TVIP_AXI_SLAVE_DRIVER_SVH
`define TVIP_AXI_SLAVE_DRIVER_SVH
typedef tue_driver #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_slave_item    )
) tvip_axi_slave_driver_base;

virtual class tvip_axi_slave_driver extends tvip_axi_component_base #(
  .BASE (tvip_axi_slave_driver_base )
);
  typedef struct {
    tvip_axi_item item;
    int           start_delay;
  } response_delay_buffer_item;

  typedef struct {
    tvip_axi_item item;
    int           response_index;
  } interleave_buffer_item;

  protected tvip_axi_item               item_buffer[$];
  protected bit                         address_busy;
  protected bit                         default_address_ready;
  protected int                         address_ready_delay;
  protected int                         address_ready_delay_queue[$];
  protected bit                         default_write_data_ready;
  protected int                         write_data_ready_delay;
  protected int                         write_data_ready_delay_queue[$];
  protected response_delay_buffer_item  response_delay_buffer[tvip_axi_id][$];
  protected interleave_buffer_item      interleave_buffer[tvip_axi_id];
  protected bit                         active_ids[tvip_axi_id];
  protected tvip_axi_item               current_response_item;
  protected tvip_axi_id                 current_response_id;
  protected int                         response_size;
  protected int                         response_delay;

  task run_phase(uvm_phase phase);
    forever @(vif.slave_cb, negedge vif.areset_n) begin
      if (!vif.areset_n) begin
        do_reset();
      end
      else begin
        if ((current_response_item != null) && get_response_ack()) begin
          finish_response();
        end

        if ((!address_busy) && get_address_valid()) begin
          uvm_wait_for_nba_region();
          update_ready_delay_queue();
          address_busy  = 1;
        end
        if (address_busy && get_address_ready()) begin
          address_busy  = 0;
        end
        drive_address_channel();
        if (is_write_component()) begin
          drive_write_data_channel();
        end

        manage_response_buffer();
        if ((current_response_item == null) && (interleave_buffer.size() >= 1)) begin
          get_next_response_item();
        end
        if ((current_response_item != null) && (response_delay >= 0)) begin
          consume_response_delay();
        end
        drive_response_channel();
      end
    end
  endtask

  function void begin_response(tvip_axi_item item);
    super.begin_response(item);
    void'(begin_tr(item));
  endfunction

  protected task do_reset();
    foreach (item_buffer[i]) begin
      end_tr(item_buffer[i]);
    end

    foreach (response_delay_buffer[i, j]) begin
      if (!response_delay_buffer[i][j].item.ended()) begin
        end_tr(response_delay_buffer[i][j].item);
      end
    end

    foreach (interleave_buffer[i]) begin
      if (!interleave_buffer[i].item.ended()) begin
        end_tr(interleave_buffer[i].item);
      end
    end

    if (current_response_item != null) begin
      if (!current_response_item.ended()) begin
        end_tr(current_response_item);
      end
    end

    address_busy            = 0;
    address_ready_delay     = -1;
    write_data_ready_delay  = -1;
    response_delay          = -1;
    item_buffer.delete();
    address_ready_delay_queue.delete();
    write_data_ready_delay_queue.delete();
    response_delay_buffer.delete();
    interleave_buffer.delete();
    active_ids.delete();

    if (configuration.reset_by_agent) begin
      reset_if();
    end
  endtask

  protected pure virtual task reset_if();

  protected task update_item_buffer();
    while (seq_item_port.has_do_available()) begin
      tvip_axi_slave_item item;
      seq_item_port.get_next_item(item);
      item_buffer.push_back(item);
      seq_item_port.item_done();
    end
  endtask

  protected task update_ready_delay_queue();
    bit ready_delay_available;

    update_item_buffer();
    ready_delay_available = (
      (item_buffer.size() > 0) && (item_buffer[$].address_begin_time == $time)
    ) ? 1 : 0;

    if (ready_delay_available) begin
      address_ready_delay_queue.push_back(item_buffer[$].address_ready_delay);
    end
    else begin
      address_ready_delay_queue.push_back(0);
    end

    if (is_read_component()) begin
      return;
    end

    if (ready_delay_available) begin
      foreach (item_buffer[$].write_data_ready_delay[i]) begin
        write_data_ready_delay_queue.push_back(item_buffer[$].write_data_ready_delay[i]);
      end
    end
    else begin
      repeat (get_burst_length()) begin
        write_data_ready_delay_queue.push_back(0);
      end
    end
  endtask

  protected task drive_address_channel();
    bit address_ready;

    if ((address_ready_delay < 0) && (address_ready_delay_queue.size() > 0)) begin
      address_ready_delay = address_ready_delay_queue.pop_front();
    end

    address_ready = (
      ((default_address_ready == 1) && (address_ready_delay <= 0)) ||
      ((default_address_ready == 0) && (address_ready_delay == 0))
    ) ? 1 : 0;
    drive_address_ready(address_ready);

    if (address_ready_delay >= 0) begin
      --address_ready_delay;
    end
  endtask

  protected pure virtual task drive_address_ready(bit address_ready);

  protected task drive_write_data_channel();
    bit write_data_ready;

    if ((write_data_ready_delay < 0) && (write_data_ready_delay_queue.size() > 0)) begin
      if (
        ((default_write_data_ready == 1) && get_write_data_valid() &&   get_write_data_ready() ) ||
        ((default_write_data_ready == 0) && get_write_data_valid() && (!get_write_data_ready()))
      ) begin
        write_data_ready_delay  = write_data_ready_delay_queue.pop_front();
      end
    end

    write_data_ready  = (
      ((default_write_data_ready == 1) && (write_data_ready_delay <= 0)) ||
      ((default_write_data_ready == 0) && (write_data_ready_delay == 0))
    ) ? 1 : 0;
    drive_write_data_ready(write_data_ready);

    if (write_data_ready_delay >= 0) begin
      --write_data_ready_delay;
    end
  endtask

  protected pure virtual task drive_write_data_ready(bit write_data_ready);

  protected task manage_response_buffer();
    foreach (response_delay_buffer[i, j]) begin
      if (!response_delay_buffer[i][j].item.request_ended()) begin
        continue;
      end
      if (response_delay_buffer[i][j].start_delay <= 0) begin
        continue;
      end
      --response_delay_buffer[i][j].start_delay;
    end

    if (item_buffer.size() == 0) begin
      update_item_buffer();
    end
    while (item_buffer.size() > 0) begin
      tvip_axi_item               item;
      response_delay_buffer_item  buffer_item;

      item                    = item_buffer.pop_front();
      buffer_item.item        = item;
      buffer_item.start_delay = item.response_start_delay;
      if (configuration.response_ordering == TVIP_AXI_OUT_OF_ORDER) begin
        response_delay_buffer[item.id].push_back(buffer_item);
      end
      else begin
        response_delay_buffer[0].push_back(buffer_item);
      end

      accept_tr(item);
    end

    foreach (response_delay_buffer[i]) begin
      tvip_axi_id             id;
      interleave_buffer_item  buffer_item;

      if (response_delay_buffer[i].size() == 0) begin
        continue;
      end
      if (!response_delay_buffer[i][0].item.request_ended()) begin
        continue;
      end
      if (response_delay_buffer[i][0].start_delay > 0) begin
        continue;
      end
      if (
        (configuration.interleave_depth >= 1                              ) &&
        (interleave_buffer.size()       >= configuration.interleave_depth)
      ) begin
        continue;
      end

      id  = response_delay_buffer[i][0].item.id;
      if (interleave_buffer.exists(id)) begin
        continue;
      end

      buffer_item.item            = response_delay_buffer[i][0].item;
      buffer_item.response_index  = 0;
      interleave_buffer[id]       = buffer_item;
      active_ids[id]              = 1;
      void'(response_delay_buffer[i].pop_front());
    end
  endtask

  protected task get_next_response_item();
    tvip_axi_id   id;
    int           remainings;
    tvip_axi_item item;
    int           size;

    if (!std::randomize(id) with { active_ids[id]; }) begin
      return;
    end

    item        = interleave_buffer[id].item;
    remainings  = (is_read_component()) ? item.get_burst_length() - interleave_buffer[id].response_index : 1;
    if (
      (configuration.max_interleave_size >= 0) &&
      (configuration.min_interleave_size >= 0)
    ) begin
      if (!std::randomize(size) with {
        size inside {[1:remainings]};
        if (remainings >= configuration.min_interleave_size) {
          size >= configuration.min_interleave_size;
        }
        else {
          size == remainings;
        }
        if (configuration.max_interleave_size >= 1) {
          size <= configuration.max_interleave_size;
        }
      }) begin
        return;
      end
    end
    else begin
      size  = remainings;
    end

    current_response_item = item;
    current_response_id   = id;
    response_size         = size;
    response_delay        = 0;
  endtask

  protected task consume_response_delay();
    int index = interleave_buffer[current_response_id].response_index;
    if (response_delay < current_response_item.response_delay[index]) begin
      ++response_delay;
    end
  endtask

  protected task drive_response_channel();
    bit valid;
    int index;

    if (current_response_item != null) begin
      index = interleave_buffer[current_response_id].response_index;
      valid = (response_delay >= current_response_item.response_delay[index]) ? 1 : 0;
    end
    else begin
      valid = 0;
    end

    if (valid && (!current_response_item.response_began())) begin
      begin_response(current_response_item);
    end

    drive_response_valid(valid);
    drive_response_id(get_response_id_value(valid));
    drive_read_data(get_read_data_value(valid, index));
    drive_response(get_response_value(valid, index));
    drive_response_last(get_response_last_value(valid, index));
  endtask

  protected virtual function tvip_axi_id get_response_id_value(bit valid);
    if (valid) begin
      return current_response_item.id;
    end
    else begin
      return '0;  //  TBD
    end
  endfunction

  protected pure virtual function tvip_axi_data get_read_data_value(bit valid, int index);

  protected virtual function tvip_axi_response get_response_value(bit valid, int index);
    if (valid) begin
      return current_response_item.get_response(index);
    end
    else begin
      return TVIP_AXI_OKAY; //  TBD
    end
  endfunction

  protected pure virtual function bit get_response_last_value(bit valid, int index);

  protected pure virtual task drive_response_valid(bit valid);
  protected pure virtual task drive_response_id(tvip_axi_id id);
  protected pure virtual task drive_read_data(tvip_axi_data data);
  protected pure virtual task drive_response(tvip_axi_response response);
  protected pure virtual task drive_response_last(bit response_last);

  protected task finish_response();
    int response_index;

    interleave_buffer[current_response_id].response_index += 1;
    response_size                                         -= 1;

    response_index  = interleave_buffer[current_response_id].response_index;
    if (response_index >= current_response_item.response.size()) begin
      interleave_buffer.delete(current_response_id);
      active_ids.delete(current_response_id);
      end_response(current_response_item);
      current_response_item = null;
      response_size         = 0;
      response_delay        = -1;
    end
    else if (response_size == 0) begin
      current_response_item = null;
      response_delay        = -1;
    end
    else begin
      response_delay  = 0;
    end
  endtask

  `tue_component_default_constructor(tvip_axi_slave_driver)
endclass

class tvip_axi_write_slave_driver extends tvip_axi_slave_driver;
  function new(string name = "tvip_axi_write_slave_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 1;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    default_address_ready     = configuration.default_awready;
    default_write_data_ready  = configuration.default_wready;
  endfunction

  task reset_if();
    vif.awready = default_address_ready;
    vif.wready  = default_write_data_ready;
    vif.bvalid  = 0;
    vif.bid     = get_response_id_value(0);
    vif.bresp   = get_response_value(0, 0);
  endtask

  function tvip_axi_data get_read_data_value(bit valid, int index);
    return '0;
  endfunction

  function bit get_response_last_value(bit valid, int index);
    return 0;
  endfunction

  task drive_address_ready(bit address_ready);
    vif.slave_cb.awready  <= address_ready;
  endtask

  task drive_write_data_ready(bit write_data_ready);
    vif.slave_cb.wready <= write_data_ready;
  endtask

  task drive_response_valid(bit valid);
    vif.slave_cb.bvalid <= valid;
  endtask

  task drive_response_id(tvip_axi_id id);
    vif.slave_cb.bid  <= id;
  endtask

  task drive_read_data(tvip_axi_data data);
  endtask

  task drive_response(tvip_axi_response response);
    vif.slave_cb.bresp  <= response;
  endtask

  task drive_response_last(bit response_last);
  endtask

  `uvm_component_utils(tvip_axi_write_slave_driver)
endclass

class tvip_axi_read_slave_driver extends tvip_axi_slave_driver;
  function new(string name = "tvip_axi_read_slave_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    default_address_ready = configuration.default_arready;
  endfunction

  task reset_if();
    vif.arready = default_address_ready;
    vif.rvalid  = 0;
    vif.rid     = get_response_id_value(0);
    vif.rdata   = get_read_data_value(0, 0);
    vif.rresp   = get_response_value(0, 0);
    vif.rlast   = get_response_last_value(0, 0);
  endtask

  function tvip_axi_data get_read_data_value(bit valid, int index);
    if (valid) begin
      return current_response_item.get_data(index);
    end
    else begin
      return '0;  //  TBD
    end
  endfunction

  function bit get_response_last_value(bit valid, int index);
    if (valid) begin
      return (index == (current_response_item.get_burst_length() - 1)) ? 1 : 0;
    end
    else begin
      return 0; //  TBD
    end
  endfunction

  task drive_address_ready(bit address_ready);
    vif.slave_cb.arready  <= address_ready;
  endtask

  task drive_write_data_ready(bit write_data_ready);
  endtask

  task drive_response_valid(bit valid);
    vif.slave_cb.rvalid <= valid;
  endtask

  task drive_response_id(tvip_axi_id id);
    vif.slave_cb.rid  <= id;
  endtask

  task drive_read_data(tvip_axi_data data);
    vif.slave_cb.rdata  <= data;
  endtask

  task drive_response(tvip_axi_response response);
    vif.slave_cb.rresp  <= response;
  endtask

  task drive_response_last(bit response_last);
    vif.slave_cb.rlast  <= response_last;
  endtask

  `uvm_component_utils(tvip_axi_read_slave_driver)
endclass
`endif
