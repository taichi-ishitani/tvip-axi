`ifndef TVIP_AXI_CONFIGURATION_SVH
`define TVIP_AXI_CONFIGURATION_SVH
class tvip_axi_delay_configuration extends tue_configuration;
  rand  int max_delay;
  rand  int mid_delay[2];
  rand  int min_delay;
  rand  int weight_zero_delay;
  rand  int weight_short_delay;
  rand  int weight_long_delay;

  constraint c_valid_max_min_delay {
    max_delay >= -1;
    min_delay >= -1;
    max_delay >= min_delay;
  }

  constraint c_default_max_min_delay {
    soft max_delay == -1;
    soft min_delay == -1;
  }

  constraint c_valid_mid_delay {
    solve max_delay before mid_delay;
    solve min_delay before mid_delay;
    mid_delay[0] inside {-1, [min_delay:max_delay]};
    mid_delay[1] inside {-1, [min_delay:max_delay]};
    if (get_delay_delta(max_delay, min_delay) >= 1) {
      if ((mid_delay[0] >= 0) || (mid_delay[1] >= 0)) {
        mid_delay[0] < mid_delay[1];
      }
      if (get_min_delay(min_delay) == 0) {
        mid_delay[0] > 0;
      }
    }
    else {
      mid_delay[0] == -1;
      mid_delay[1] == -1;
    }
  }

  constraint c_default_mid_delay {
    soft mid_delay[0] == -1;
    soft mid_delay[1] == -1;
  }

  constraint c_valid_weight_delay {
    solve max_delay before weight_zero_delay, weight_short_delay, weight_long_delay;
    solve min_delay before weight_zero_delay, weight_short_delay, weight_long_delay;
    if (get_delay_delta(max_delay, min_delay) >= 1) {
      weight_zero_delay  >= -1;
      weight_short_delay >= -1;
      weight_long_delay  >= -1;
    }
    else {
      weight_zero_delay  == 0;
      weight_short_delay == 0;
      weight_long_delay  == 0;
    }
    if (min_delay > 0) {
      weight_zero_delay == 0;
    }
    if ((min_delay <= 0) && (max_delay == 1)) {
      weight_short_delay == 0;
    }
  }

  constraint c_default_weight_delay {
    soft weight_zero_delay  == -1;
    soft weight_short_delay == -1;
    soft weight_long_delay  == -1;
  }

  function void post_randomize();
    int delay_delta;
    weight_zero_delay   = (weight_zero_delay  == -1) ? 1 : weight_zero_delay;
    weight_short_delay  = (weight_short_delay == -1) ? 1 : weight_short_delay;
    weight_long_delay   = (weight_long_delay  == -1) ? 1 : weight_long_delay;
    min_delay   = get_min_delay(min_delay);
    max_delay   = get_max_delay(max_delay, min_delay);
    delay_delta = get_delay_delta(max_delay, min_delay);
    foreach (mid_delay[i]) begin
      if (mid_delay[i] >= 0) begin
        continue;
      end
      case (delay_delta)
        0, 1: begin
          mid_delay[i]  = (i == 0) ? min_delay : max_delay;
        end
        2: begin
          mid_delay[i]  = (i == 0) ? min_delay + 1 : max_delay;
        end
        default: begin
          mid_delay[i]  = min_delay + (delay_delta / 2) + i;
        end
      endcase
    end
  endfunction

  local function int get_min_delay(int min_delay);
    return (min_delay >= 0) ? min_delay : 0;
  endfunction

  local function int get_max_delay(int max_delay, int min_delay);
    return (max_delay >= 0) ? max_delay : get_min_delay(min_delay);
  endfunction

  local function int get_delay_delta(int max_delay, int min_delay);
    return get_max_delay(max_delay, min_delay) - get_min_delay(min_delay);
  endfunction

  `tue_object_default_constructor(tvip_axi_delay_configuration)
  `uvm_object_utils_begin(tvip_axi_delay_configuration)
    `uvm_field_int(max_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_sarray_int(mid_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(weight_zero_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(weight_short_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(weight_long_delay, UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end
endclass

class tvip_axi_configuration extends tue_configuration;
        tvip_axi_vif                  vif;
  rand  int                           id_width;
  rand  int                           address_width;
  rand  int                           max_burst_length;
  rand  int                           data_width;
  rand  int                           strobe_width;
  rand  int                           response_weight_okay;
  rand  int                           response_weight_exokay;
  rand  int                           response_weight_slave_error;
  rand  int                           response_weight_decode_error;
  rand  tvip_axi_delay_configuration  write_data_delay;
  rand  tvip_axi_delay_configuration  response_start_delay;
  rand  tvip_axi_delay_configuration  response_delay;
  rand  bit                           default_awready;
  rand  tvip_axi_delay_configuration  awready_delay;
  rand  bit                           default_wready;
  rand  tvip_axi_delay_configuration  wready_delay;
  rand  bit                           default_bready;
  rand  tvip_axi_delay_configuration  bready_delay;
  rand  bit                           default_arready;
  rand  tvip_axi_delay_configuration  arready_delay;
  rand  bit                           default_rready;
  rand  tvip_axi_delay_configuration  rready_delay;
  rand  tvip_axi_ordering_mode        response_ordering;
  rand  int                           interleave_depth;
  rand  int                           max_interleave_size;
  rand  int                           min_interleave_size;
  rand  bit                           reset_by_agent;

  constraint c_valid_id_width {
    id_width inside {[0:`TVIP_AXI_MAX_ID_WIDTH]};
  }

  constraint c_valid_address_width {
    address_width inside {[1:`TVIP_AXI_MAX_ADDRESS_WIDTH]};
  }

  constraint c_valid_max_burst_length {
    max_burst_length inside {[1:256]};
  }

  constraint c_valid_data_width {
    data_width inside {[8:1024]};
    $countones(data_width) == 1;
  }

  constraint c_valid_strobe_width {
    solve data_width before strobe_width;
    strobe_width == (data_width / 8);
  }

  constraint c_valid_response_weight {
    response_weight_okay         >= -1;
    response_weight_exokay       >= -1;
    response_weight_slave_error  >= -1;
    response_weight_decode_error >= -1;
  }

  constraint c_default_response_weight {
    soft response_weight_okay         == -1;
    soft response_weight_exokay       == -1;
    soft response_weight_slave_error  == -1;
    soft response_weight_decode_error == -1;
  }

  constraint c_valid_interleave_depth {
    solve response_ordering before interleave_depth;
    if (response_ordering == TVIP_AXI_OUT_OF_ORDER) {
      interleave_depth >= -1;
    }
    else {
      interleave_depth == 1;
    }
  }

  constraint c_default_interleave_depth {
    if (response_ordering == TVIP_AXI_OUT_OF_ORDER) {
      soft interleave_depth == -1;
    }
  }

  constraint c_valid_interleave_size {
    solve interleave_depth before max_interleave_size;
    solve interleave_depth before min_interleave_size;
    if ((interleave_depth >= 2) || (interleave_depth == 0)) {
      max_interleave_size >= 0;
      min_interleave_size >= 0;
      max_interleave_size >= min_interleave_size;
    }
    else {
      max_interleave_size == -1;
      min_interleave_size == -1;
    }
  }

  constraint c_default_interleave_size {
    if ((interleave_depth >= 2) || (interleave_depth == 0)) {
      soft max_interleave_size == 0;
      soft min_interleave_size == 0;
    }
  }

  constraint c_default_reset_by_agent {
    soft reset_by_agent == 1;
  }

  function new(string name = "tvip_axi_configuration");
    super.new(name);
    write_data_delay      = tvip_axi_delay_configuration::type_id::create("write_data_delay"    );
    response_start_delay  = tvip_axi_delay_configuration::type_id::create("response_start_delay");
    response_delay        = tvip_axi_delay_configuration::type_id::create("response_delay"      );
    awready_delay         = tvip_axi_delay_configuration::type_id::create("awready_delay"       );
    wready_delay          = tvip_axi_delay_configuration::type_id::create("wready_delay"        );
    bready_delay          = tvip_axi_delay_configuration::type_id::create("bready_delay"        );
    arready_delay         = tvip_axi_delay_configuration::type_id::create("arready_delay"       );
    rready_delay          = tvip_axi_delay_configuration::type_id::create("rready_delay"        );
  endfunction

  function void post_randomize();
    super.post_randomize();
    response_weight_okay          = (response_weight_okay         >= 0) ? response_weight_okay         : 1;
    response_weight_exokay        = (response_weight_exokay       >= 0) ? response_weight_exokay       : 0;
    response_weight_slave_error   = (response_weight_slave_error  >= 0) ? response_weight_slave_error  : 0;
    response_weight_decode_error  = (response_weight_decode_error >= 0) ? response_weight_decode_error : 0;
    interleave_depth              = (interleave_depth             >= 0) ? interleave_depth             : 1;
  endfunction

  `uvm_object_utils_begin(tvip_axi_configuration)
    `uvm_field_int(id_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(address_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_burst_length, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(data_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(strobe_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_okay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_exokay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_slave_error, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_decode_error, UVM_DEFAULT | UVM_DEC)
    `uvm_field_object(write_data_delay, UVM_DEFAULT)
    `uvm_field_object(response_start_delay, UVM_DEFAULT)
    `uvm_field_object(response_delay, UVM_DEFAULT)
    `uvm_field_int(default_awready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(awready_delay, UVM_DEFAULT)
    `uvm_field_int(default_wready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(wready_delay, UVM_DEFAULT)
    `uvm_field_int(default_bready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(bready_delay, UVM_DEFAULT)
    `uvm_field_int(default_arready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(arready_delay, UVM_DEFAULT)
    `uvm_field_int(default_rready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(rready_delay, UVM_DEFAULT)
    `uvm_field_enum(tvip_axi_ordering_mode, response_ordering, UVM_DEFAULT)
    `uvm_field_int(interleave_depth, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_interleave_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_interleave_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(reset_by_agent, UVM_DEFAULT | UVM_BIN)
  `uvm_object_utils_end
endclass
`endif
