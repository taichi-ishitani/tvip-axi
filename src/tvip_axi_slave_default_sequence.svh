`ifndef TVIP_AXI_SLAVE_DEFAULT_SEQUENCE_SVH
`define TVIP_AXI_SLAVE_DEFAULT_SEQUENCE_SVH
class tvip_axi_slave_default_sequence extends tvip_axi_slave_sequence_base;
  task body();
    fork
      process_response_request(TVIP_AXI_WRITE_ACCESS);
      process_response_request(TVIP_AXI_READ_ACCESS);
    join
  endtask

  protected task process_response_request(tvip_axi_access_type access_type);
    forever begin
      tvip_axi_slave_item item;
      get_request(access_type, item);
      randomize_response(access_type, item);
      execute_response(item);
    end
  endtask

  protected virtual function void randomize_response(
    tvip_axi_access_type  access_type,
    tvip_axi_slave_item   item
  );
    int response_size;

    if (!item.randomize()) begin
      `uvm_fatal("RNDFLD", "Randomization failed")
    end

    overwrite_delay(item.address_ready_delay, get_address_ready_delay(item));
    overwrite_delay(item.start_delay, get_response_start_delay(item));

    response_size = (item.is_read()) ? item.burst_length : 1;
    for (int i = 0;i < response_size;++i) begin
      overwrite_delay(item.response_delay[i], get_response_delay(item, i));
      if (item.is_write()) begin
        overwrite_delay(item.write_data_ready_delay[i], get_write_data_ready_delay(item, i));
      end

      if (get_response_existence(item, i)) begin
        item.response[i]  = get_response_status(item, i);
      end
      if (item.is_read() && get_read_data_existence(item, i)) begin
        item.data[i]  = get_read_data(item, i);
      end
    end
  endfunction

  protected virtual task execute_response(tvip_axi_slave_item item);
    fork
      automatic tvip_axi_slave_item __item  = item;
      `uvm_send(__item);
    join_none
  endtask

  protected virtual function int get_address_ready_delay(tvip_axi_slave_item item);
    return -1;
  endfunction

  protected virtual function int get_write_data_ready_delay(tvip_axi_slave_item item, int index);
    return -1;
  endfunction

  protected virtual function int get_response_start_delay(tvip_axi_slave_item item);
    return -1;
  endfunction

  protected virtual function int get_response_delay(tvip_axi_slave_item item, int index);
    return -1;
  endfunction

  protected virtual function tvip_axi_response get_response_status(tvip_axi_slave_item item, int index);
    return TVIP_AXI_OKAY;
  endfunction

  protected virtual function bit get_response_existence(tvip_axi_slave_item item, int index);
    return 0;
  endfunction

  protected virtual function tvip_axi_data get_read_data(tvip_axi_slave_item item, int index);
    return status.memory.get(item.burst_size, item.address, index);
  endfunction

  protected virtual function bit get_read_data_existence(tvip_axi_slave_item item, int index);
    return status.memory.exists(item.burst_size, item.address, index);
  endfunction

  protected function void overwrite_delay(
    ref   int delay,
    input int new_delay
  );
    if (new_delay >= 0) begin
      delay = new_delay;
    end
  endfunction

  `tue_object_default_constructor(tvip_axi_slave_default_sequence)
  `uvm_object_utils(tvip_axi_slave_default_sequence)
endclass
`endif
