`ifndef TVIP_AXI_ITEM_SVH
`define TVIP_AXI_ITEM_SVH
virtual class tvip_axi_item extends tue_sequence_item #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        )
);
  rand      tvip_axi_access_type  access_type;
  rand      tvip_axi_id           id;
  rand      tvip_axi_address      address;
  rand      int                   burst_length;
  rand      int                   burst_size;
  rand      tvip_axi_burst_type   burst_type;
  rand      tvip_axi_data         data[];
  rand      tvip_axi_strobe       strobe[];
  rand      tvip_axi_response     response[];
  rand      int                   write_data_delay[];
  rand      int                   response_start_delay;
  rand      int                   response_delay[];
  rand      int                   address_ready_delay;
  rand      int                   write_data_ready_delay[];
  rand      int                   response_ready_delay[];
            uvm_event             address_begin_event;
            time                  address_begin_time;
            uvm_event             address_end_event;
            time                  address_end_time;
            uvm_event             write_data_begin_event;
            time                  write_data_begin_time;
            uvm_event             write_data_end_event;
            time                  write_data_end_time;
            uvm_event             response_begin_event;
            time                  response_begin_time;
            uvm_event             response_end_event;
            time                  response_end_time;

  function new(string name = "tvip_axi_item");
    super.new(name);
    address_begin_event     = events.get("address_begin");
    address_end_event       = events.get("address_end");
    write_data_begin_event  = events.get("write_data_begin");
    write_data_end_event    = events.get("write_data_end");
    response_begin_event    = events.get("response_begin");
    response_end_event      = events.get("response_end");
  endfunction

  function bit is_write();
    return (access_type == TVIP_AXI_WRITE_ACCESS) ? '1 : '0;
  endfunction

  function bit is_read();
    return (access_type == TVIP_AXI_READ_ACCESS) ? '1 : '0;
  endfunction

  function tvip_axi_burst_length get_packed_burst_length();
    return pack_burst_length(burst_length);
  endfunction

  function void set_packed_burst_length(tvip_axi_burst_length packed_burst_length);
    burst_length  = unpack_burst_length(packed_burst_length);
  endfunction

  function tvip_axi_burst_size get_packed_burst_size();
    return pack_burst_size(burst_size);
  endfunction

  function void set_packed_burst_size(tvip_axi_burst_size packed_burst_size);
    burst_size  = unpack_burst_size(packed_burst_size);
  endfunction

  function void put_data(const ref tvip_axi_data data[$]);
    this.data = new[data.size()];
    foreach (data[i]) begin
      this.data[i]  = data[i];
    end
  endfunction

  function tvip_axi_data get_data(int index);
    if (index < data.size()) begin
      return data[index];
    end
    else begin
      return '0;
    end
  endfunction

  function void put_strobe(const ref tvip_axi_strobe strobe[$]);
    this.strobe = new[strobe.size()];
    foreach (strobe[i]) begin
      this.strobe[i]  = strobe[i];
    end
  endfunction

  function tvip_axi_strobe get_strobe(int index);
    if (index < strobe.size()) begin
      return strobe[index];
    end
    else begin
      return '0;
    end
  endfunction

  function void put_response(const ref tvip_axi_response response[$]);
    this.response = new[response.size()];
    foreach (response[i]) begin
      this.response[i]  = response[i];
    end
  endfunction

  function tvip_axi_response get_response(int index);
    if (index < response.size()) begin
      return response[index];
    end
    else begin
      return TVIP_AXI_OKAY;
    end
  endfunction

  `define tvip_axi_define_begin_end_event_api(EVENT_TYPE) \
  function void begin_``EVENT_TYPE``(time begin_time = 0); \
    if (``EVENT_TYPE``_begin_event.is_off()) begin \
      ``EVENT_TYPE``_begin_time = (begin_time <= 0) ? $time : begin_time; \
      ``EVENT_TYPE``_begin_event.trigger(); \
    end \
  endfunction \
  function void end_``EVENT_TYPE``(time end_time = 0); \
    if (``EVENT_TYPE``_end_event.is_off()) begin \
      ``EVENT_TYPE``_end_time = (end_time <= 0) ? $time : end_time; \
      ``EVENT_TYPE``_end_event.trigger(); \
    end \
  endfunction

  `tvip_axi_define_begin_end_event_api(address   )
  `tvip_axi_define_begin_end_event_api(write_data)
  `tvip_axi_define_begin_end_event_api(response  )

  `undef  tvip_axi_define_begin_end_event_api

  task wait_for_done();
    fork
      begin
        address_end_event.wait_on();
        if (is_write()) begin
          write_data_end_event.wait_on();
        end
        response_end_event.wait_on();
      end
      begin
        end_event.wait_on();
      end
    join_any
    disable fork;
  endtask

  `uvm_field_utils_begin(tvip_axi_item)
    `uvm_field_enum(tvip_axi_access_type, access_type, UVM_DEFAULT)
    `uvm_field_int(id, UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(address, UVM_DEFAULT | UVM_HEX)
    `uvm_field_int(burst_length, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(burst_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_enum(tvip_axi_burst_type, burst_type, UVM_DEFAULT)
    `uvm_field_array_int(data, UVM_DEFAULT | UVM_HEX)
    `uvm_field_array_int(strobe, UVM_DEFAULT | UVM_HEX)
    `uvm_field_array_enum(tvip_axi_response, response, UVM_DEFAULT)
    `uvm_field_array_int(write_data_delay, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_int(response_start_delay, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_array_int(response_delay, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_int(address_ready_delay, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_array_int(write_data_ready_delay, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_array_int(response_ready_delay, UVM_DEFAULT | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_int(address_begin_time, UVM_DEFAULT | UVM_TIME | UVM_NOCOMPARE)
    `uvm_field_int(address_end_time, UVM_DEFAULT | UVM_TIME | UVM_NOCOMPARE)
    `uvm_field_int(write_data_begin_time, UVM_DEFAULT | UVM_TIME | UVM_NOCOMPARE)
    `uvm_field_int(write_data_end_time, UVM_DEFAULT | UVM_TIME | UVM_NOCOMPARE)
    `uvm_field_int(response_begin_time, UVM_DEFAULT | UVM_TIME | UVM_NOCOMPARE)
    `uvm_field_int(response_end_time, UVM_DEFAULT | UVM_TIME | UVM_NOCOMPARE)
  `uvm_field_utils_end
endclass

`define tvip_axi_define_delay_consraint(DELAY, MIN, MID_0, MID_1, MAX, WEIGHT_ZERO_DELAY, WEIGHT_SHORT_DELAY, WEIGHT_LONG_DELAY, VALID_CONDITION = 1) \
constraint c_valid_``DELAY { \
  if (VALID_CONDITION) { \
    ((DELAY >= MIN) && (DELAY <= MID_0)) || ((DELAY >= MID_1) && (DELAY >= MAX)); \
    if (MIN == 0) { \
      DELAY dist { \
        0           := WEIGHT_ZERO_DELAY, \
        [1:MID_0]   :/ WEIGHT_SHORT_DELAY, \
        [MID_1:MAX] :/ WEIGHT_LONG_DELAY \
      }; \
    } \
    else { \
      DELAY dist { \
        [MIN:MID_0] :/ WEIGHT_SHORT_DELAY, \
        [MID_1:MAX] :/ WEIGHT_LONG_DELAY \
      }; \
    } \
  } \
  else { \
    DELAY == 0; \
  } \
}

`define tvip_axi_define_delay_consraint_array(DELAY, MIN, MID_0, MID_1, MAX, WEIGHT_ZERO_DELAY, WEIGHT_SHORT_DELAY, WEIGHT_LONG_DELAY) \
constraint c_valid_``DELAY { \
  foreach (DELAY[i]) { \
    ((DELAY[i] >= MIN) && (DELAY[i] <= MID_0)) || ((DELAY[i] >= MID_1) && (DELAY[i] <= MAX)); \
    if (MIN == 0) { \
      DELAY[i] dist { \
        0           := WEIGHT_ZERO_DELAY, \
        [1:MID_0]   :/ WEIGHT_SHORT_DELAY, \
        [MID_1:MAX] :/ WEIGHT_LONG_DELAY \
      }; \
    } \
    else { \
      DELAY[i] dist { \
        [MIN:MID_0] :/ WEIGHT_SHORT_DELAY, \
        [MID_1:MAX] :/ WEIGHT_LONG_DELAY \
      }; \
    } \
  } \
}

class tvip_axi_master_item extends tvip_axi_item;
  constraint c_valid_id {
    (id >> this.configuration.id_width) == 0;
  }

  constraint c_valid_address {
    (address >> this.configuration.address_width) == 0;
  }

  constraint c_valid_burst_length {
    burst_length inside {[1:this.configuration.max_burst_length]};
  }

  constraint c_valid_burst_size {
    burst_size inside {1, 2, 4, 8, 16, 32, 64, 128};
    (8 * burst_size) <= this.configuration.data_width;
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

  constraint c_write_data_delay_order_and_valid_size {
    solve access_type  before write_data_delay;
    solve burst_length before write_data_delay;
    (access_type == TVIP_AXI_WRITE_ACCESS) -> write_data_delay.size() == burst_length;
    (access_type == TVIP_AXI_READ_ACCESS ) -> write_data_delay.size() == 0;
  }

  `tvip_axi_define_delay_consraint_array(
    write_data_delay,
    this.configuration.min_write_data_delay,
    this.configuration.mid_write_data_delay[0],
    this.configuration.mid_write_data_delay[1],
    this.configuration.max_write_data_delay,
    this.configuration.write_data_delay_weight[TVIP_AXI_ZERO_DELAY],
    this.configuration.write_data_delay_weight[TVIP_AXI_SHORT_DELAY],
    this.configuration.write_data_delay_weight[TVIP_AXI_LONG_DELAY]
  )

  constraint c_response_ready_delay_order_and_valid_size {
    solve access_type  before response_ready_delay;
    solve burst_length before response_ready_delay;
    (access_type == TVIP_AXI_WRITE_ACCESS) -> response_ready_delay.size() == 1;
    (access_type == TVIP_AXI_READ_ACCESS ) -> response_ready_delay.size() == burst_length;
  }

  `tvip_axi_define_delay_consraint_array(
    response_ready_delay,
    get_min_response_ready_delay(access_type),
    get_mid_response_ready_delay(access_type, 0),
    get_mid_response_ready_delay(access_type, 1),
    get_max_response_ready_delay(access_type),
    get_response_delay_weight(access_type, TVIP_AXI_ZERO_DELAY ),
    get_response_delay_weight(access_type, TVIP_AXI_SHORT_DELAY),
    get_response_delay_weight(access_type, TVIP_AXI_LONG_DELAY )
  )

  local function int get_min_response_ready_delay(tvip_axi_access_type access_type);
    if (access_type == TVIP_AXI_WRITE_ACCESS) begin
      return configuration.min_bready_delay;
    end
    else begin
      return configuration.min_rready_delay;
    end
  endfunction

  local function int get_mid_response_ready_delay(tvip_axi_access_type access_type, int index);
    if (access_type == TVIP_AXI_WRITE_ACCESS) begin
      return configuration.mid_bready_delay[index];
    end
    else begin
      return configuration.mid_rready_delay[index];
    end
  endfunction

  local function int get_max_response_ready_delay(tvip_axi_access_type access_type);
    if (access_type == TVIP_AXI_WRITE_ACCESS) begin
      return configuration.max_bready_delay;
    end
    else begin
      return configuration.max_rready_delay;
    end
  endfunction

  local function int get_response_delay_weight(tvip_axi_access_type access_type, tvip_axi_delay_type delay_type);
    if (access_type == TVIP_AXI_WRITE_ACCESS) begin
      return configuration.bready_delay_weight[delay_type];
    end
    else begin
      return configuration.rready_delay_weight[delay_type];
    end
  endfunction

  function void pre_randomize();
    super.pre_randomize();
    response.rand_mode(0);
    response_start_delay.rand_mode(0);
    response_delay.rand_mode(0);
    address_ready_delay.rand_mode(0);
    write_data_ready_delay.rand_mode(0);
  endfunction

  `tue_object_default_constructor(tvip_axi_master_item)
  `uvm_object_utils(tvip_axi_master_item)
endclass

class tvip_axi_slave_item extends tvip_axi_item;
  constraint c_valid_data {
    if (access_type == TVIP_AXI_READ_ACCESS) {
      data.size() == burst_length;
      foreach (data[i]) {
        (data[i] >> this.configuration.data_width) == 0;
      }
    }
  }

  constraint c_valid_response {
    (access_type == TVIP_AXI_WRITE_ACCESS) -> response.size() == 1;
    (access_type == TVIP_AXI_READ_ACCESS ) -> response.size() == burst_length;
  }

  `tvip_axi_define_delay_consraint(
    address_ready_delay,
    get_min_address_ready_delay(access_type),
    get_mid_address_ready_delay(access_type, 0),
    get_mid_address_ready_delay(access_type, 1),
    get_max_address_ready_delay(access_type),
    get_address_ready_delay_weight(access_type, TVIP_AXI_ZERO_DELAY ),
    get_address_ready_delay_weight(access_type, TVIP_AXI_SHORT_DELAY),
    get_address_ready_delay_weight(access_type, TVIP_AXI_LONG_DELAY )
  )

  local function int get_min_address_ready_delay(tvip_axi_access_type access_type);
    if (access_type == TVIP_AXI_WRITE_ACCESS) begin
      return configuration.min_awready_delay;
    end
    else begin
      return configuration.min_arready_delay;
    end
  endfunction

  local function int get_mid_address_ready_delay(tvip_axi_access_type access_type, int index);
    if (access_type == TVIP_AXI_WRITE_ACCESS) begin
      return configuration.mid_awready_delay[index];
    end
    else begin
      return configuration.mid_arready_delay[index];
    end
  endfunction

  local function int get_max_address_ready_delay(tvip_axi_access_type access_type);
    if (access_type == TVIP_AXI_WRITE_ACCESS) begin
      return configuration.max_awready_delay;
    end
    else begin
      return configuration.max_arready_delay;
    end
  endfunction

  local function int get_address_ready_delay_weight(tvip_axi_access_type access_type, tvip_axi_delay_type delay_type);
    if (access_type == TVIP_AXI_WRITE_ACCESS) begin
      return configuration.awready_delay_weight[delay_type];
    end
    else begin
      return configuration.arready_delay_weight[delay_type];
    end
  endfunction

  constraint c_write_data_ready_delay_valid_size {
    (access_type == TVIP_AXI_WRITE_ACCESS) -> write_data_ready_delay.size() == burst_length;
    (access_type == TVIP_AXI_READ_ACCESS ) -> write_data_ready_delay.size() == 0;
  }

  `tvip_axi_define_delay_consraint_array(
    write_data_ready_delay,
    this.configuration.min_wready_delay,
    this.configuration.mid_wready_delay[0],
    this.configuration.mid_wready_delay[1],
    this.configuration.max_wready_delay,
    this.configuration.wready_delay_weight[TVIP_AXI_ZERO_DELAY],
    this.configuration.wready_delay_weight[TVIP_AXI_SHORT_DELAY],
    this.configuration.wready_delay_weight[TVIP_AXI_LONG_DELAY]
  )

  function void pre_randomize();
    super.pre_randomize();
    access_type.rand_mode(0);
    id.rand_mode(0);
    burst_length.rand_mode(0);
    burst_size.rand_mode(0);
    burst_type.rand_mode(0);
    if (access_type == TVIP_AXI_WRITE_ACCESS) begin
      data.rand_mode(0);
    end
    strobe.rand_mode(0);
    write_data_delay.rand_mode(0);
    response_ready_delay.rand_mode(0);
  endfunction

  `tue_object_default_constructor(tvip_axi_slave_item)
  `uvm_object_utils(tvip_axi_slave_item)
endclass

`undef  tvip_axi_define_delay_consraint
`undef  tvip_axi_define_delay_consraint_array

`endif
