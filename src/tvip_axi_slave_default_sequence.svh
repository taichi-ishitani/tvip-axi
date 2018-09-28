`ifndef TVIP_AXI_SLAVE_DEFAULT_SEQUENCE_SVH
`define TVIP_AXI_SLAVE_DEFAULT_SEQUENCE_SVH
class tvip_axi_slave_default_sequence extends tvip_axi_slave_sequence_base;
  protected tvip_axi_slave_item current_item;

  task body();
    forever begin
      tvip_axi_slave_item item;
      get_request(item);
      randomize_response(item);
      fork
        execute_response(item);
      join_none
    end
  endtask

  protected virtual function randomize_response(tvip_axi_slave_item item);
    bit               read_access;
    int               response_size;
    int               address_ready_delay;
    int               write_data_ready_delay[int];
    int               response_start_delay;
    int               response_delay[int];
    tvip_axi_response response[int];
    bit               response_existance[int];
    tvip_axi_data     read_data[int];
    bit               read_data_existance[int];

    current_item          = item;
    read_access           = item.is_read();
    response_size         = (read_access) ? item.burst_length : 1;
    address_ready_delay   = get_address_ready_delay();
    response_start_delay  = get_response_start_delay();
    if (item.is_write()) begin
      for (int i = 0;i < item.burst_length;++i) begin
        write_data_ready_delay[i] = get_write_data_ready_delay(i);
      end
    end
    for (int i = 0;i < response_size;++i) begin
      response[i]           = get_response_status(i);
      response_existance[i] = get_response_existence(i);
      response_delay[i]     = get_response_delay(i);
      if (item.is_read()) begin
        read_data[i]            = get_read_data(i);
        read_data_existance[i]  = get_read_data_existence(i);
      end
    end

    if (!item.randomize() with {
      if (local::address_ready_delay >= 0) {
        address_ready_delay == local::address_ready_delay;
      }
      foreach (write_data_ready_delay[i]) {
        if (local::write_data_ready_delay[i] >= 0) {
          write_data_ready_delay[i] == local::write_data_ready_delay[i];
        }
      }
      if (local::response_start_delay >= 0) {
        response_start_delay == local::response_start_delay;
      }
      foreach (response_delay[i]) {
        if (local::response_delay[i] >= 0) {
          response_delay[i] == local::response_delay[i];
        }
      }
      foreach (response[i]) {
        if (local::response_existance[i]) {
          response[i] == local::response[i];
        }
      }
      if (local::read_access) {
        foreach (data[i]) {
          if (local::read_data_existance[i]) {
            data[i] == local::read_data[i];
          }
        }
      }
    }) begin
      //  TODO
    end
  endfunction

  protected virtual task execute_response(tvip_axi_slave_item item);
    `uvm_send(item)
  endtask

  protected virtual function int get_address_ready_delay();
    return -1;
  endfunction

  protected virtual function int get_write_data_ready_delay(int index);
    return -1;
  endfunction

  protected virtual function int get_response_start_delay();
    return -1;
  endfunction

  protected virtual function int get_response_delay(int index);
    return -1;
  endfunction

  protected virtual function tvip_axi_response get_response_status(int index);
    return TVIP_AXI_OKAY;
  endfunction

  protected virtual function bit get_response_existence(int index);
    return 0;
  endfunction

  protected virtual function tvip_axi_data get_read_data(int index);
    return status.memory.get(current_item.burst_size, current_item.address, index);
  endfunction

  protected virtual function bit get_read_data_existence(int index);
    return status.memory.exists(current_item.burst_size, current_item.address, index);
  endfunction

  `tue_object_default_constructor(tvip_axi_slave_default_sequence)
  `uvm_object_utils(tvip_axi_slave_default_sequence)
endclass
`endif
