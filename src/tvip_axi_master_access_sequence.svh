`ifndef TVIP_AXI_MASTER_ACCESS_SEQUENCE_SVH
`define TVIP_AXI_MASTER_ACCESS_SEQUENCE_SVH
class tvip_axi_master_access_sequence extends tvip_axi_master_sequence_base;
  rand      tvip_axi_access_type  access_type;
  rand      tvip_axi_id           id;
  rand      tvip_axi_address      address;
  rand      int                   burst_length;
  rand      int                   burst_size;
  rand      tvip_axi_burst_type   burst_type;
  rand      tvip_axi_qos          qos;
  rand      tvip_axi_data         data[];
  rand      tvip_axi_strobe       strobe[];
            tvip_axi_response     response[];
  rand      int                   start_delay;
  rand      int                   write_data_delay[];
  rand      int                   response_ready_delay[];
            uvm_event             address_done_event;
            uvm_event             write_data_done_event;
            uvm_event             response_done_event;
  protected tvip_axi_master_item  request_item;
  protected tvip_axi_master_item  response_item;

  constraint c_valid_id {
    (id >> this.configuration.id_width) == 0;
  }

  constraint c_valid_address {
    (address >> this.configuration.address_width) == 0;
  }

  constraint c_valid_burst_length {
    if (this.configuration.protocol == TVIP_AXI4) {
      burst_length inside {[1:this.configuration.max_burst_length]};
    }
    else {
      burst_length == 1;
    }
  }

  constraint c_valid_burst_size {
    if (this.configuration.protocol == TVIP_AXI4) {
      burst_size inside {1, 2, 4, 8, 16, 32, 64, 128};
      (8 * burst_size) <= this.configuration.data_width;
    }
    else {
      (8 * burst_size) == this.configuration.data_width;
    }
  }

  constraint c_4kb_boundary {
    (
      (address & `tvip_axi_4kb_boundary_mask(burst_size)) +
      (burst_length * burst_size)
    ) <= 4096;
  }

  constraint c_default_burst_type {
    burst_type == TVIP_AXI_INCREMENTING_BURST;
  }

  constraint c_valid_qos {
    qos inside {[
      this.configuration.qos_range[0]:
      this.configuration.qos_range[1]
    ]};
  }

  constraint c_valid_data {
    solve access_type  before data;
    solve burst_length before data;
    (access_type == TVIP_AXI_WRITE_ACCESS) -> data.size() == burst_length;
    (access_type == TVIP_AXI_READ_ACCESS ) -> data.size() == 0;
    foreach (data[i]) {
      (data[i] >> this.configuration.data_width) == 0;
    }
  }

  constraint c_valid_strobe {
    solve access_type  before strobe;
    solve burst_length before strobe;
    (access_type == TVIP_AXI_WRITE_ACCESS) -> strobe.size() == burst_length;
    (access_type == TVIP_AXI_READ_ACCESS ) -> strobe.size() == 0;
    foreach (strobe[i]) {
      (strobe[i] >> this.configuration.strobe_width) == 0;
    }
  }

  constraint c_start_delay {
    `tvip_delay_constraint(start_delay, this.configuration.request_start_delay)
  }

  constraint c_write_data_delay {
    solve access_type, burst_length before write_data_delay;

    if (access_type == TVIP_AXI_WRITE_ACCESS) {
      write_data_delay.size() == burst_length;
    }
    else {
      write_data_delay.size() == 0;
    }

    foreach (write_data_delay[i]) {
      `tvip_delay_constraint(write_data_delay[i], this.configuration.write_data_delay)
    }
  }

  constraint c_response_ready {
    solve access_type, burst_length before response_ready_delay;

    if (access_type == TVIP_AXI_WRITE_ACCESS) {
      response_ready_delay.size() == 1;
    }
    else {
      response_ready_delay.size() == burst_length;
    }

    foreach (response_ready_delay[i]) {
      if (access_type == TVIP_AXI_WRITE_ACCESS) {
        `tvip_delay_constraint(response_ready_delay[i], this.configuration.bready_delay)
      }
      else {
        `tvip_delay_constraint(response_ready_delay[i], this.configuration.rready_delay)
      }
    }
  }

  function new(string name = "tvip_axi_master_access_sequence");
    super.new(name);
    request_item          = tvip_axi_master_item::type_id::create("request_item");
    address_done_event    = request_item.get_event("address_end");
    write_data_done_event = request_item.get_event("write_data_end");
    response_done_event   = request_item.get_event("response_end");
  endfunction

  task body();
    transmit_request();
    wait_for_response();
  endtask

  local task transmit_request();
    copy_request_info();
    `uvm_send(request_item)
  endtask

  local function void copy_request_info();
    request_item.access_type          = access_type;
    request_item.id                   = id;
    request_item.address              = address;
    request_item.burst_length         = burst_length;
    request_item.burst_size           = burst_size;
    request_item.burst_type           = burst_type;
    request_item.qos                  = qos;
    request_item.start_delay          = start_delay;
    request_item.response_ready_delay = new[response_ready_delay.size()](response_ready_delay);
    request_item.need_response        = 1;
    if (request_item.is_write()) begin
      request_item.data             = new[data.size()](data);
      request_item.strobe           = new[strobe.size()](strobe);
      request_item.write_data_delay = new[write_data_delay.size()](write_data_delay);
    end
  endfunction

  local task wait_for_response();
    int id  = request_item.get_transaction_id();
    get_response(response_item, id);
    copy_response_info();
  endtask

  local function void copy_response_info();
    response  = new[response_item.response.size()](response_item.response);
    if (response_item.is_read()) begin
      data  = new[response_item.data.size()](response_item.data);
    end
  endfunction

  `uvm_object_utils_begin(tvip_axi_master_access_sequence)
    `uvm_field_enum(tvip_axi_access_type, access_type, UVM_DEFAULT)
    `uvm_field_int(id, UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(address, UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(burst_length, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(burst_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_enum(tvip_axi_burst_type, burst_type, UVM_DEFAULT)
    `uvm_field_int(qos, UVM_DEFAULT | UVM_DEC)
    `uvm_field_array_int(data, UVM_DEFAULT | UVM_HEX)
    `uvm_field_array_int(strobe, UVM_DEFAULT | UVM_HEX)
    `uvm_field_array_enum(tvip_axi_response, response, UVM_DEFAULT)
    `uvm_field_int(start_delay, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_array_int(write_data_delay, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_array_int(response_ready_delay, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
  `uvm_object_utils_end
endclass
`endif
