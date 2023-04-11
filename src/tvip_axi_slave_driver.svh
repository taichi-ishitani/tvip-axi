`ifndef TVIP_AXI_SLAVE_DRIVER_SVH
`define TVIP_AXI_SLAVE_DRIVER_SVH
typedef tue_fifo #(tvip_axi_item) tvip_axi_slave_driver_item_queue;

typedef struct {
  tvip_axi_item                     item;
  tvip_axi_slave_driver_item_queue  queue;
} tvip_axi_start_delay_item;

class tvip_axi_slave_driver_start_delay_consumer;
  protected uvm_component                         parent;
  protected tvip_axi_vif                          vif;
  protected tue_fifo #(tvip_axi_start_delay_item) delay_queue[tvip_axi_id];
  protected event                                 reset;
  protected event                                 notifier;

  function new(uvm_component parent, tvip_axi_vif vif);
    this.parent = parent;
    this.vif    = vif;
  endfunction

  task consume_start_delay(
    tvip_axi_item                     item,
    tvip_axi_id                       queue_id,
    tvip_axi_slave_driver_item_queue  queue
  );
    tvip_axi_start_delay_item delay_item;

    delay_item.item   = item;
    delay_item.queue  = queue;
    if (!delay_queue.exists(queue_id)) begin
      start_delay_thread(queue_id);
    end
    delay_queue[queue_id].put(delay_item);
  endtask

  task wait_for_active_response();
    @(notifier);
  endtask

  function void do_reset();
    ->reset;
  endfunction

  protected task start_delay_thread(tvip_axi_id id);
    delay_queue[id] = new("delay_queue", 0);
    fork
      automatic tvip_axi_id __id  = id;
      delay_thread(__id);
    join_none
  endtask

  protected task delay_thread(tvip_axi_id id);
    tvip_axi_start_delay_item item;

    forever begin
      fork
        forever begin
          delay_queue[id].get(item);
          delay_thread_body(item);
        end
        @(reset);
      join_any
      disable fork;

      if ((item.item != null) && (!item.item.finished())) begin
        parent.end_tr(item.item);
      end

      while (delay_queue[id].try_get(item)) begin
        if (!item.item.finished()) begin
          parent.end_tr(item.item);
        end
      end
    end
  endtask

  protected task delay_thread_body(ref tvip_axi_start_delay_item item);
    item.item.wait_for_request_done();
    repeat (item.item.start_delay) begin
      @(vif.slave_cb);
    end
    item.queue.put(item.item);
    ->notifier;
  endtask
endclass

class tvip_axi_slave_driver_response_item;
  tvip_axi_item item;
  int           size;
  int           index;

  function new(tvip_axi_item item);
    this.item = item;
  endfunction

  function tvip_axi_id get_id();
    return item.id;
  endfunction

  function tvip_axi_response get_response_status();
    return item.response[index];
  endfunction

  function tvip_axi_data get_data();
    if (item.is_read()) begin
      return item.data[index];
    end
    else begin
      return '0;
    end
  endfunction

  function bit get_last();
    if (item.is_read()) begin
      return (index + 1) == item.get_burst_length();
    end
    else begin
      return 1;
    end
  endfunction

  function int get_delay();
    return item.response_delay[index];
  endfunction

  function bit is_last_response_done();
    return item.is_write() || (index == item.get_burst_length());
  endfunction

  function void next();
    size  -= 1;
    index += 1;
  endfunction
endclass

typedef tvip_axi_sub_driver_base #(
  .ITEM (tvip_axi_slave_item  )
) tvip_axi_slave_sub_driver_base;

class tvip_axi_slave_sub_driver extends tvip_axi_component_base #(
  .BASE (tvip_axi_slave_sub_driver_base )
);
  protected int                                         ready_delay_queue[2][$];
  protected int                                         preceded_ready_count[2];
  protected tvip_axi_slave_driver_start_delay_consumer  start_delay_consumer;
  protected tvip_axi_slave_driver_item_queue            response_queue[tvip_axi_id];
  protected tvip_axi_slave_driver_response_item         active_responses[$];
  protected tvip_axi_id                                 active_ids[$];
  protected int                                         current_response_index;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    start_delay_consumer  = new(this, vif);
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

  task put_request(tvip_axi_item request);
    tvip_axi_id queue_id;

    ready_delay_queue[0].push_back(request.address_ready_delay);
    if (is_write_component()) begin
      foreach (request.write_data_ready_delay[i]) begin
        ready_delay_queue[1].push_back(request.write_data_ready_delay[i]);
      end
    end

    case (configuration.response_ordering)
      TVIP_AXI_OUT_OF_ORDER:  queue_id  = request.id;
      TVIP_AXI_IN_ORDER:      queue_id  = 0;
    endcase

    if (!response_queue.exists(queue_id)) begin
      response_queue[queue_id]  = new("response_queue", 0);
    end

    accept_tr(request);
    start_delay_consumer.consume_start_delay(request, queue_id, response_queue[queue_id]);
  endtask

  task begin_response(tvip_axi_item item);
    super.begin_response(item);
    void'(begin_tr(item));
  endtask

  protected task do_reset();
    start_delay_consumer.do_reset();

    ready_delay_queue[0].delete();
    ready_delay_queue[1].delete();
    preceded_ready_count[0] = 0;
    preceded_ready_count[1] = 0;

    foreach (response_queue[i]) begin
      tvip_axi_item item;
      while (response_queue[i].try_get(item)) begin
        if (!item.finished()) begin
          end_tr(item);
        end
      end
    end
    response_queue.delete();

    foreach (active_responses[i]) begin
      if (active_responses[i].item.finished()) begin
        end_tr(active_responses[i].item);
      end
    end
    active_responses.delete();
    active_ids.delete();

    reset_if();
    @(posedge vif.areset_n);
  endtask

  protected virtual task reset_if();
  endtask

  protected task main();
    fork
      drive_ready_thread(0);
      drive_ready_thread(1);
      response_thread();
    join
  endtask

  protected task drive_ready_thread(bit write_data_thread);
    bit                       default_ready;
    tvip_delay_configuration  delay_configuration;
    int                       delay;

    if (write_data_thread && is_read_component()) begin
      return;
    end

    if (is_read_component()) begin
      default_ready       = configuration.default_arready;
      delay_configuration = configuration.arready_delay;
    end
    else if (write_data_thread) begin
      default_ready       = configuration.default_wready;
      delay_configuration = configuration.wready_delay;
    end
    else begin
      default_ready       = configuration.default_awready;
      delay_configuration = configuration.awready_delay;
    end

    forever begin
      wait_for_request_valid(write_data_thread);
      get_ready_delay(write_data_thread, delay_configuration, delay);

      if (default_ready && (delay > 0)) begin
        drive_ready(write_data_thread, 0);
        consume_delay(delay);
        drive_ready(write_data_thread, 1);
      end
      else if (!default_ready) begin
        consume_delay(delay);
        drive_ready(write_data_thread, 1);
        consume_delay(1);
        drive_ready(write_data_thread, 0);
      end
    end
  endtask

  protected task wait_for_request_valid(bit write_data_thread);
    do begin
      @(vif.slave_cb);
    end while (!get_request_valid(write_data_thread));
  endtask

  protected virtual function bit get_request_valid(bit write_data_thread);
  endfunction

  protected task get_ready_delay(
    input bit                       write_data_thread,
    input tvip_delay_configuration  delay_configuration,
    ref   int                       delay
  );
    int queque_index  = int'(write_data_thread);

    if (ready_delay_queue[queque_index].size() == 0) begin
      uvm_wait_for_nba_region();
    end

    if (ready_delay_queue[queque_index].size() > 0) begin
      while (preceded_ready_count[queque_index] > 0) begin
        preceded_ready_count[queque_index]  -= 1;
        void'(ready_delay_queue[queque_index].pop_front());
      end
      delay = ready_delay_queue[queque_index].pop_front();
    end
    else begin
      preceded_ready_count[queque_index]  += 1;
      delay = randomize_ready_delay(delay_configuration);
    end
  endtask

  protected function int randomize_ready_delay(tvip_delay_configuration delay_configuration);
    int delay;

    if (!std::randomize(delay) with {
      `tvip_delay_constraint(delay, delay_configuration)
    }) begin
      `uvm_fatal("RNDFLD", "Randomization failed")
    end

    return delay;
  endfunction

  protected virtual task drive_ready(bit write_data_thread, bit ready);
  endtask

  protected task response_thread();
    tvip_axi_slave_driver_response_item item;
    int                                 size;

    forever begin
      get_next_response_item(item);
      if (item == null) begin
        continue;
      end

      if (!item.item.response_began()) begin
        begin_response(item.item);
      end

      size  = get_response_size(item);
      repeat (size) begin
        execute_response_item(item);
      end

      if (item.is_last_response_done()) begin
        active_responses.delete(current_response_index);
        active_ids.delete(current_response_index);
      end
    end
  endtask

  protected task get_next_response_item(ref tvip_axi_slave_driver_response_item item);
    tvip_axi_item                       axi_item;
    tvip_axi_slave_driver_response_item new_item;

    if (no_response()) begin
      start_delay_consumer.wait_for_active_response();
      if (!vif.at_slave_cb_edge.triggered) begin
        @(vif.at_slave_cb_edge);
      end
    end

    foreach (response_queue[id]) begin
      if (response_queue[id].used() == 0) begin
        continue;
      end
      if (!is_acceptable_response(id)) begin
        continue;
      end

      response_queue[id].get(axi_item);
      new_item  = new(axi_item);
      active_responses.push_back(new_item);
      active_ids.push_back(id);
    end

    if (active_responses.size() == 0) begin
      item  = null;
      return;
    end

    current_response_index  = select_response();
    item                    = active_responses[current_response_index];
  endtask

  protected function bit no_response();
    if (active_responses.size() > 0) begin
      return 0;
    end
    foreach (response_queue[i]) begin
      if (response_queue[i].used() > 0) begin
        return 0;
      end
    end
    return 1;
  endfunction

  protected function bit is_acceptable_response(tvip_axi_id id);
    if (id inside {active_ids}) begin
      return 0;
    end
    else if (configuration.outstanding_responses > 0) begin
      return active_responses.size() < configuration.outstanding_responses;
    end
    else begin
      return 1;
    end
  endfunction

  protected virtual function int select_response();
    if (configuration.response_ordering == TVIP_AXI_OUT_OF_ORDER) begin
      foreach (active_responses[i]) begin
        randcase
          1:  return i;
          1:  continue;
        endcase
      end
    end

    return 0;
  endfunction

  protected virtual function int get_response_size(tvip_axi_slave_driver_response_item item);
    if (is_write_component()) begin
      return 1;
    end
    else if (!configuration.enable_response_interleaving) begin
      return item.item.get_burst_length();
    end
    else begin
      return randomize_response_size(item);
    end
  endfunction

  protected virtual function int randomize_response_size(tvip_axi_slave_driver_response_item item);
    int size;
    int min;
    int max;
    int remaining;

    remaining = item.item.get_burst_length() - item.index;
    min       = configuration.min_interleave_size;
    max       = configuration.max_interleave_size;
    if (std::randomize(size) with {
      size inside {[1:remaining]};
      if ((min > 0) && (remaining >= min)) {
        size >= min;
      }
      if ((max > 0)) {
        size <= max;
      }
    }) begin
      return size;
    end
    else begin
      `uvm_fatal("RNDFLD", "Randomization failed")
    end
  endfunction

  protected task execute_response_item(tvip_axi_slave_driver_response_item item);
    consume_delay(item.get_delay());
    drive_response(1, item);
    wait_for_response_ready();
    drive_response(0, null);

    item.next();
    if (item.is_last_response_done()) begin
      end_response(item.item);
    end
  endtask

  protected virtual task drive_response(bit valid, tvip_axi_slave_driver_response_item item);
  endtask

  protected task wait_for_response_ready();
    do begin
      @(vif.slave_cb);
    end while (!get_response_ready());
  endtask

  protected virtual function bit get_response_ready();
  endfunction

  protected task consume_delay(int delay);
    repeat (delay) begin
      @(vif.slave_cb);
    end
  endtask

  `tue_component_default_constructor(tvip_axi_slave_sub_driver)
endclass

class tvip_axi_slave_write_driver extends tvip_axi_slave_sub_driver;
  function new(string name = "tvip_axi_slave_write_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 1;
  endfunction

  protected task reset_if();
    vif.slave_cb.awready  <= configuration.default_awready;
    vif.slave_cb.wready   <= configuration.default_wready;
    vif.slave_cb.bvalid   <= '0;
    vif.slave_cb.bid      <= '0;
    vif.slave_cb.bresp    <= tvip_axi_response'(0);
  endtask

  protected function bit get_request_valid(bit write_data_thread);
    if (write_data_thread) begin
      return vif.slave_cb.wvalid;
    end
    else begin
      return vif.slave_cb.awvalid;
    end
  endfunction

  protected task drive_ready(bit write_data_thread, bit ready);
    if (write_data_thread) begin
      vif.slave_cb.wready <= ready;
    end
    else begin
      vif.slave_cb.awready  <= ready;
    end
  endtask

  protected task drive_response(bit valid, tvip_axi_slave_driver_response_item item);
    vif.slave_cb.bvalid <= valid;
    if (valid) begin
      vif.slave_cb.bid    <= item.get_id();
      vif.slave_cb.bresp  <= item.get_response_status();
    end
  endtask

  protected function bit get_response_ready();
    return vif.slave_cb.bready;
  endfunction

  `uvm_component_utils(tvip_axi_slave_write_driver)
endclass

class tvip_axi_slave_read_driver extends tvip_axi_slave_sub_driver;
  function new(string name = "tvip_axi_slave_read_driver", uvm_component parent = null);
    super.new(name, parent);
    write_component = 0;
  endfunction

  protected task reset_if();
    vif.slave_cb.arready  <= configuration.default_arready;
    vif.slave_cb.rvalid   <= '0;
    vif.slave_cb.rid      <= '0;
    vif.slave_cb.rresp    <= tvip_axi_response'(0);
    vif.slave_cb.rdata    <= '0;
    vif.slave_cb.rlast    <= '0;
  endtask

  protected function bit get_request_valid(bit write_data_thread);
    return vif.slave_cb.arvalid;
  endfunction

  protected task drive_ready(bit write_data_thread, bit ready);
    vif.slave_cb.arready  <= ready;
  endtask

  protected task drive_response(bit valid, tvip_axi_slave_driver_response_item item);
    vif.slave_cb.rvalid <= valid;
    if (valid) begin
      vif.slave_cb.rid    <= item.get_id();
      vif.slave_cb.rresp  <= item.get_response_status();
      vif.slave_cb.rdata  <= item.get_data();
      vif.slave_cb.rlast  <= item.get_last();
    end
  endtask

  protected function bit get_response_ready();
    return vif.slave_cb.rready;
  endfunction

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
