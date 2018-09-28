`ifndef TVIP_AXI_CONFIGURATION_SVH
`define TVIP_AXI_CONFIGURATION_SVH
typedef enum {
  TVIP_AXI_ZERO_DELAY,
  TVIP_AXI_SHORT_DELAY,
  TVIP_AXI_LONG_DELAY
} tvip_axi_delay_type;

class tvip_axi_configuration extends tue_configuration;
        tvip_axi_vif  vif;
  rand  int           id_width;
  rand  int           address_width;
  rand  int           max_burst_length;
  rand  int           data_width;
  rand  int           strobe_width;
  rand  int           response_weight[tvip_axi_response];
  rand  int           max_write_data_delay;
  rand  int           mid_write_data_delay[2];
  rand  int           min_write_data_delay;
  rand  int           write_data_delay_weight[tvip_axi_delay_type];
  rand  int           max_response_start_delay;
  rand  int           mid_response_start_delay[2];
  rand  int           min_response_start_delay;
  rand  int           response_start_delay_weight[tvip_axi_delay_type];
  rand  int           max_response_delay;
  rand  int           mid_response_delay[2];
  rand  int           min_response_delay;
  rand  int           response_delay_weight[tvip_axi_delay_type];
  rand  bit           default_awready;
  rand  int           max_awready_delay;
  rand  int           mid_awready_delay[2];
  rand  int           min_awready_delay;
  rand  int           awready_delay_weight[tvip_axi_delay_type];
  rand  bit           default_wready;
  rand  int           max_wready_delay;
  rand  int           mid_wready_delay[2];
  rand  int           min_wready_delay;
  rand  int           wready_delay_weight[tvip_axi_delay_type];
  rand  bit           default_bready;
  rand  int           max_bready_delay;
  rand  int           mid_bready_delay[2];
  rand  int           min_bready_delay;
  rand  int           bready_delay_weight[tvip_axi_delay_type];
  rand  bit           default_arready;
  rand  int           max_arready_delay;
  rand  int           mid_arready_delay[2];
  rand  int           min_arready_delay;
  rand  int           arready_delay_weight[tvip_axi_delay_type];
  rand  bit           default_rready;
  rand  int           max_rready_delay;
  rand  int           mid_rready_delay[2];
  rand  int           min_rready_delay;
  rand  int           rready_delay_weight[tvip_axi_delay_type];
  rand  int           interleave_depth;
  rand  int           max_interleave_size;
  rand  int           min_interleave_size;
  rand  bit           reset_by_agent;

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
    foreach (response_weight[i]) {
      response_weight[i] >= -1;
    }
  }

  constraint c_default_response_weight {
    foreach (response_weight[i]) {
      soft response_weight[i] == -1;
    }
  }

  `tvip_axi_declare_delay_size_constraints(write_data    )
  `tvip_axi_declare_delay_size_constraints(response_start)
  `tvip_axi_declare_delay_size_constraints(response      )
  `tvip_axi_declare_delay_size_constraints(awready       )
  `tvip_axi_declare_delay_size_constraints(wready        )
  `tvip_axi_declare_delay_size_constraints(bready        )
  `tvip_axi_declare_delay_size_constraints(arready       )
  `tvip_axi_declare_delay_size_constraints(rready        )

  constraint c_valid_interleave_depth {
    interleave_depth >= -1;
  }

  constraint c_default_interleave_depth {
    soft interleave_depth == -1;
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
    response_weight[TVIP_AXI_OKAY]          = -1;
    response_weight[TVIP_AXI_EXOKAY]        = -1;
    response_weight[TVIP_AXI_SLAVE_ERROR]   = -1;
    response_weight[TVIP_AXI_DECODE_ERROR]  = -1;
    setup_initial_delay_weight();
  endfunction

  function void post_randomize();
    super.post_randomize();
    foreach (response_weight[i]) begin
      if (response_weight[i] <= -1) begin
        response_weight[i]  = (i == TVIP_AXI_OKAY) ? 1 : 0;
      end
    end
    setup_delay_configuration(
      max_write_data_delay, mid_write_data_delay, min_write_data_delay, write_data_delay_weight
    );
    setup_delay_configuration(
      max_response_start_delay, mid_response_start_delay, min_response_start_delay, response_start_delay_weight
    );
    setup_delay_configuration(
      max_response_delay, mid_response_delay, min_response_delay, response_delay_weight
    );
    setup_delay_configuration(
      max_awready_delay, mid_awready_delay, min_awready_delay, awready_delay_weight
    );
    setup_delay_configuration(
      max_wready_delay, mid_wready_delay, min_wready_delay, wready_delay_weight
    );
    setup_delay_configuration(
      max_bready_delay, mid_bready_delay, min_bready_delay, bready_delay_weight
    );
    setup_delay_configuration(
      max_arready_delay, mid_arready_delay, min_arready_delay, arready_delay_weight
    );
    setup_delay_configuration(
      max_rready_delay, mid_rready_delay, min_rready_delay, rready_delay_weight
    );
    if (interleave_depth == -1) begin
      interleave_depth  = 1;
    end
  endfunction

  local function void setup_initial_delay_weight();
    tvip_axi_delay_type delay_type;
    delay_type  = TVIP_AXI_ZERO_DELAY;
    while (1) begin
      write_data_delay_weight[delay_type]     = -1;
      response_start_delay_weight[delay_type] = -1;
      response_delay_weight[delay_type]       = -1;
      awready_delay_weight[delay_type]        = -1;
      wready_delay_weight[delay_type]         = -1;
      bready_delay_weight[delay_type]         = -1;
      arready_delay_weight[delay_type]        = -1;
      rready_delay_weight[delay_type]         = -1;
      if (delay_type != delay_type.last()) begin
        delay_type  = delay_type.next();
      end
      else begin
        break;
      end
    end
  endfunction

  local function void setup_delay_configuration(
    ref int max_delay,
    ref int mid_delay[2],
    ref int min_delay,
    ref int delay_weight[tvip_axi_delay_type]
  );
    int delay_delta;

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

    foreach (delay_weight[i]) begin
      if (delay_weight[i] == -1) begin
        delay_weight[i] = 1;
      end
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

  `uvm_object_utils_begin(tvip_axi_configuration)
    `uvm_field_int(id_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(address_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_burst_length, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(data_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(strobe_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_enumkey(tvip_axi_response, response_weight, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_write_data_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_sarray_int(mid_write_data_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_write_data_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_enumkey(tvip_axi_delay_type, write_data_delay_weight, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_response_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_sarray_int(mid_response_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_response_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_enumkey(tvip_axi_delay_type, response_delay_weight, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(default_awready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(max_awready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_sarray_int(mid_awready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_awready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_enumkey(tvip_axi_delay_type, awready_delay_weight, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(default_wready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(max_wready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_sarray_int(mid_wready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_wready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_enumkey(tvip_axi_delay_type, wready_delay_weight, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(default_bready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(max_bready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_sarray_int(mid_bready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_bready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_enumkey(tvip_axi_delay_type, bready_delay_weight, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(default_arready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(max_arready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_sarray_int(mid_arready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_arready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_enumkey(tvip_axi_delay_type, arready_delay_weight, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(default_rready, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(max_rready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_sarray_int(mid_rready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_rready_delay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_aa_int_enumkey(tvip_axi_delay_type, rready_delay_weight, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(interleave_depth, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_interleave_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(min_interleave_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(reset_by_agent, UVM_DEFAULT | UVM_BIN)
  `uvm_object_utils_end
endclass
`endif
