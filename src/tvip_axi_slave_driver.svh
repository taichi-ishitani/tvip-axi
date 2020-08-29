`ifndef TVIP_AXI_SLAVE_DRIVER_SVH
`define TVIP_AXI_SLAVE_DRIVER_SVH
class tvip_axi_slave_driver_response_item;
  tvip_axi_item item;
  int           start_delay;
  int           delay;
  int           transfer_size;
  int           index;

  function new(tvip_axi_item item);
    this.item         = item;
    this.start_delay  = start_delay;
    this.delay        = -1;
  endfunction

  function tvip_axi_id get_id();
    return item.id;
  endfunction

  function tvip_axi_response get_response();
    return item.response[index];
  endfunction

  function tvip_axi_data get_data();
    return item.data[index];
  endfunction

  function bit get_last();
    return is_last_response(1);
  endfunction

  function void consume_delay();
    if (start_delay > 0) begin
      --start_delay;
    end
    else begin
      if (delay < 0) begin
        delay = item.response_delay[index];
      end
      if (delay > 0) begin
        --delay;
      end
    end
  endfunction

  function void next();
    --delay;
    --transfer_size;
    ++index;
  endfunction

  function bit is_drivable();
    return (start_delay == 0) && (delay == 0);
  endfunction

  function bit is_last_response(bit before_calling_next);
    if (item.access_type == TVIP_AXI_WRITE_ACCESS) begin
      return 1;
    end
    else if (before_calling_next) begin
      return index == (item.burst_length - 1);
    end
    else begin
      return index == item.burst_length;
    end
  endfunction

  function bit is_end_response(bit before_calling_next);
    if (item.access_type == TVIP_AXI_WRITE_ACCESS) begin
      return 1;
    end
    else if (before_calling_next) begin
      return transfer_size == 1;
    end
    else begin
      return transfer_size == 0;
    end
  endfunction
endclass

typedef tvip_axi_sub_driver_base #(
  .ITEM (tvip_axi_slave_item  )
) tvip_axi_slave_sub_driver_base;

class tvip_axi_slave_sub_driver extends tvip_axi_component_base #(
  .BASE (tvip_axi_slave_sub_driver_base )
);
  protected bit                                 address_busy;
  protected bit                                 default_address_ready;
  protected bit                                 default_ready[2];
  protected int                                 ready_delay_queue[2][$];
  protected int                                 ready_delay[2];
  protected int                                 preceding_writes;
  protected tvip_axi_item                       response_queue[tvip_axi_id][$];
  protected tvip_axi_slave_driver_response_item response_items[tvip_axi_id];
  protected tvip_axi_id                         active_ids[tvip_axi_id];
  protected tvip_axi_slave_driver_response_item current_response;
  protected bit                                 response_busy;


  task run_phase(uvm_phase phase);
    forever @(vif.slave_cb, negedge vif.areset_n) begin
      if (!vif.areset_n) begin
        do_reset();
      end
      else begin
        if ((current_response != null) && get_response_ack()) begin
          response_busy = 0;
          finish_response();
        end

        if ((!address_busy) && get_address_valid()) begin
          address_busy  = 1;
          update_ready_delay_queue();
        end
        if (address_busy && get_address_ready()) begin
          address_busy  = 0;
        end
        drive_address_channel();
        if (is_write_component()) begin
          drive_write_data_channel();
        end

        manage_response_buffer();
        if ((current_response == null) && (response_items.size() > 0)) begin
          get_next_response_item();
        end
        drive_response_channel();
      end
    end
  endtask

  task begin_response(tvip_axi_item item);
    super.begin_response(item);
    void'(begin_tr(item));
  endtask

  protected task do_reset();
    foreach (item_buffer[i]) begin
      end_tr(item_buffer[i]);
    end

    foreach (response_queue[i, j]) begin
      if (!response_queue[i][j].ended()) begin
        end_tr(response_queue[i][j]);
      end
    end

    foreach (response_items[i]) begin
      if (!response_items[i].item.ended()) begin
        end_tr(response_items[i].item);
      end
    end

    address_busy      = 0;
    ready_delay       = '{-1, -1};
    current_response  = null;
    response_busy     = 0;
    preceding_writes  = 0;
    item_buffer.delete();
    ready_delay_queue[0].delete();
    ready_delay_queue[1].delete();
    response_queue.delete();
    response_items.delete();
    active_ids.delete();

    if (configuration.reset_by_agent) begin
      reset_if();
    end
  endtask

  protected virtual task reset_if();
  endtask

  protected task update_ready_delay_queue();
    tvip_axi_item item;
    int           length;

    uvm_wait_for_nba_region();
    if (item_buffer.size() > 0) begin
      if (item_buffer[$].address_begin_time == $time) begin
        item  = item_buffer[$];
      end
    end

    if (item != null) begin
      ready_delay_queue[0].push_back(item.address_ready_delay);
    end
    else if (is_write_component()) begin
      ready_delay_queue[0].push_back(
        randomize_delay(configuration.awready_delay)
      );
    end
    else begin
      ready_delay_queue[0].push_back(
        randomize_delay(configuration.arready_delay)
      );
    end

    if (is_read_component()) begin
      return;
    end

    length  = (item != null) ? item.burst_length : get_burst_length();
    for (int i = 0;i < length;++i) begin
      if (preceding_writes > 0) begin
        --preceding_writes;
      end
      else if (item != null) begin
        ready_delay_queue[1].push_back(item.write_data_ready_delay[i]);
      end
      else begin
        ready_delay_queue[1].push_back(randomize_delay(configuration.wready_delay));
      end
    end
  endtask

  protected task drive_address_channel();
    bit address_ready;

    if (ready_delay[0] < 0) begin
      ready_delay[0]  = ready_delay_queue[0].pop_front();
    end

    address_ready =
      ((default_ready[0] == 1) && (ready_delay[0] <= 0)) ||
      ((default_ready[0] == 0) && (ready_delay[0] == 0));
    drive_address_ready(address_ready);

    if (ready_delay[0] >= 0) begin
      --ready_delay[0];
    end
  endtask

  protected virtual task drive_address_ready(bit address_ready);
  endtask

  protected task drive_write_data_channel();
    bit pop_ready_delay;
    bit write_data_ready;

    pop_ready_delay =
      (ready_delay[1] < 0) && get_write_data_valid() && (get_write_data_ready() == default_ready[1]);
    if (pop_ready_delay) begin
      if (ready_delay_queue[1].size() > 0) begin
        ready_delay[1]  = ready_delay_queue[1].pop_front();
      end
      else begin
        ready_delay[1]  = randomize_delay(configuration.wready_delay);
        ++preceding_writes;
      end
    end

    write_data_ready  =
      ((default_ready[1] == 1) && (ready_delay[1] <= 0)) ||
      ((default_ready[1] == 0) && (ready_delay[1] == 0));
    drive_write_data_ready(write_data_ready);

    if (ready_delay[1] >= 0) begin
      --ready_delay[1];
    end
  endtask

  protected virtual task drive_write_data_ready(bit write_data_ready);
  endtask

  protected task manage_response_buffer();
    while (item_buffer.size() > 0) begin
      tvip_axi_item item;
      item  = item_buffer.pop_front();
      accept_tr(item);
      case (configuration.response_ordering)
        TVIP_AXI_OUT_OF_ORDER:
          response_queue[item.id].push_back(item);
        TVIP_AXI_IN_ORDER:
          response_queue[0].push_back(item);
      endcase
    end

    foreach (response_queue[i]) begin
      if (response_queue[i].size() == 0) begin
        continue;
      end
      else if (!response_queue[i][0].request_ended()) begin
        continue;
      end
      else if (response_items.exists(i)) begin
        continue;
      end
      else if (is_response_items_full()) begin
        continue;
      end

      response_items[i] = new(response_queue[i].pop_front());
      active_ids[i]     = i;
    end
  endtask

  protected function bit is_response_items_full();
    if (configuration.outstanding_responses == 0) begin
      return 0;
    end
    else begin
      return response_items.size() == configuration.outstanding_responses;
    end
  endfunction

  protected task get_next_response_item();
    tvip_axi_id                         key;
    tvip_axi_slave_driver_response_item item;

    if (configuration.response_ordering == TVIP_AXI_IN_ORDER) begin
      key = 0;
    end
    else if (!std::randomize(key) with { key inside {active_ids}; }) begin
      `uvm_fatal("RNDFLD", "Randomization failed")
    end

    item                = response_items[key];
    item.transfer_size  = get_transfer_size(item);
    current_response    = item;
  endtask

  protected function int get_transfer_size(tvip_axi_slave_driver_response_item item);
    if (is_write_component()) begin
      return 1;
    end
    else if (configuration.protocol == TVIP_AXI4LITE) begin
      return 1;
    end
    else if (!configuration.enable_response_interleaving) begin
      return item.item.burst_length;
    end
    else begin
      return randomize_transfer_size(item);
    end
  endfunction

  protected function int randomize_transfer_size(tvip_axi_slave_driver_response_item item);
    int transfer_size;
    int min;
    int max;
    int remaining;

    remaining = item.item.burst_length - item.index;
    min       = configuration.min_interleave_size;
    max       = configuration.max_interleave_size;
    if (std::randomize(transfer_size) with {
      transfer_size inside {[1:remaining]};
      if ((min > 0) && (remaining >= min)) {
        transfer_size >= min;
      }
      if (max > 0) {
        transfer_size <= max;
      }
    }) begin
      return transfer_size;
    end
    else begin
      `uvm_fatal("RNDFLD", "Randomization failed")
    end
  endfunction

  protected task drive_response_channel();
    bit valid;
    int index;

    valid = 0;
    if (current_response != null) begin
      current_response.consume_delay();
      valid = current_response.is_drivable();
    end

    if (valid && (!response_busy)) begin
      response_busy = 1;
      begin_response(current_response.item);
      drive_active_response();
    end
    else if (!valid) begin
      drive_idle_response();
    end
  endtask

  protected virtual task drive_active_response();
  endtask

  protected virtual task drive_idle_response();
  endtask

  protected task finish_response();
    current_response.next();
    if (current_response.is_end_response(0)) begin
      if (current_response.is_last_response(0)) begin
        remove_response_item();
      end
      current_response  = null;
    end
  endtask

  protected task remove_response_item();
    tvip_axi_id id;

    case (configuration.response_ordering)
      TVIP_AXI_OUT_OF_ORDER:
        id  = current_response.item.id;
      TVIP_AXI_IN_ORDER:
        id  = 0;
    endcase

    response_items.delete(id);
    active_ids.delete(id);
    end_response(current_response.item);
  endtask

  protected function int randomize_delay(tvip_delay_configuration delay_configuration);
    int delay;
    if (std::randomize(delay) with {
      `tvip_delay_constraint(delay, delay_configuration)
    }) begin
      return delay;
    end
    else begin
      `uvm_fatal("RNDFLD", "Randomization failed")
    end
  endfunction

  `tue_component_default_constructor(tvip_axi_slave_sub_driver)
endclass

class tvip_axi_slave_write_driver extends tvip_axi_slave_sub_driver;
  function new(string name = "tvip_axi_slave_write_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 1;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    default_ready[0]  = configuration.default_awready;
    default_ready[1]  = configuration.default_wready;
  endfunction

  protected task reset_if();
    vif.awready = default_ready[0];
    vif.wready  = default_ready[1];
    vif.bvalid  = 0;
    vif.bid     = 0;
    vif.bresp   = TVIP_AXI_OKAY;
  endtask

  protected task drive_address_ready(bit address_ready);
    vif.slave_cb.awready  <= address_ready;
  endtask

  protected task drive_write_data_ready(bit write_data_ready);
    vif.slave_cb.wready <= write_data_ready;
  endtask

  protected task drive_active_response();
    vif.slave_cb.bvalid <= 1;
    vif.slave_cb.bid    <= current_response.get_id();
    vif.slave_cb.bresp  <= current_response.get_response();
  endtask

  protected task drive_idle_response();
    vif.slave_cb.bvalid <= 0;
    vif.slave_cb.bid    <= 0;
    vif.slave_cb.bresp  <= TVIP_AXI_OKAY;
  endtask

  `uvm_component_utils(tvip_axi_slave_write_driver)
endclass

class tvip_axi_slave_read_driver extends tvip_axi_slave_sub_driver;
  function new(string name = "tvip_axi_slave_read_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    default_ready[0]  = configuration.default_arready;
  endfunction

  protected task reset_if();
    vif.arready = default_address_ready;
    vif.rvalid  = 0;
    vif.rid     = 0;
    vif.rdata   = 0;
    vif.rresp   = TVIP_AXI_OKAY;
    vif.rlast   = 0;
  endtask

  protected task drive_address_ready(bit address_ready);
    vif.slave_cb.arready  <= address_ready;
  endtask

  protected task drive_write_data_ready(bit write_data_ready);
  endtask

  protected task drive_active_response();
    vif.slave_cb.rvalid <= 1;
    vif.slave_cb.rid    <= current_response.get_id();
    vif.slave_cb.rdata  <= current_response.get_data();
    vif.slave_cb.rresp  <= current_response.get_response();
    vif.slave_cb.rlast  <= current_response.get_last();
  endtask

  protected task drive_idle_response();
    vif.slave_cb.rvalid <= 0;
    vif.slave_cb.rid    <= 0;
    vif.slave_cb.rdata  <= 0;
    vif.slave_cb.rresp  <= TVIP_AXI_OKAY;
    vif.slave_cb.rlast  <= 0;
  endtask

  `uvm_component_utils(tvip_axi_slave_read_driver)
endclass

class tvip_axi_slave_driver extends tvip_axi_driver_base #(
  .ITEM         (tvip_axi_slave_item          ),
  .WRITE_DRIVER (tvip_axi_slave_write_driver  ),
  .READ_DRIVER  (tvip_axi_slave_read_driver   )
);
  `tue_component_default_constructor(tvip_axi_slave_driver)
  `uvm_component_utils(tvip_axi_slave_driver)
endclass
`endif
