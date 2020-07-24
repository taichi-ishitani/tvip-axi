`ifndef TVIP_AXI_CONFIGURATION_SVH
`define TVIP_AXI_CONFIGURATION_SVH
class tvip_axi_configuration extends tue_configuration;
        tvip_axi_vif              vif;
  rand  tvip_axi_protocol         protocol;
  rand  int                       id_width;
  rand  int                       address_width;
  rand  int                       max_burst_length;
  rand  int                       data_width;
  rand  int                       strobe_width;
  rand  int                       qos_range[2];
  rand  tvip_axi_ordering_mode    response_ordering;
  rand  int                       outstanding_responses;
  rand  bit                       enable_response_interleaving;
  rand  int                       min_interleave_size;
  rand  int                       max_interleave_size;
  rand  int                       response_weight_okay;
  rand  int                       response_weight_exokay;
  rand  int                       response_weight_slave_error;
  rand  int                       response_weight_decode_error;
  rand  tvip_delay_configuration  request_start_delay;
  rand  tvip_delay_configuration  write_data_delay;
  rand  tvip_delay_configuration  response_start_delay;
  rand  tvip_delay_configuration  response_delay;
  rand  bit                       default_awready;
  rand  tvip_delay_configuration  awready_delay;
  rand  bit                       default_wready;
  rand  tvip_delay_configuration  wready_delay;
  rand  bit                       default_bready;
  rand  tvip_delay_configuration  bready_delay;
  rand  bit                       default_arready;
  rand  tvip_delay_configuration  arready_delay;
  rand  bit                       default_rready;
  rand  tvip_delay_configuration  rready_delay;
  rand  bit                       reset_by_agent;

  constraint c_default_protocol {
    soft protocol == TVIP_AXI4;
  }

  constraint c_valid_id_width {
    id_width inside {[0:`TVIP_AXI_MAX_ID_WIDTH]};
  }

  constraint c_default_id_width {
    solve protocol before id_width;
    if (protocol == TVIP_AXI4LITE) {
      soft id_width == 0;
    }
  }

  constraint c_valid_address_width {
    address_width inside {[1:`TVIP_AXI_MAX_ADDRESS_WIDTH]};
  }

  constraint c_valid_max_burst_length {
    solve protocol before max_burst_length;
    max_burst_length inside {[1:256]};
    if (protocol == TVIP_AXI4LITE) {
      max_burst_length == 1;
    }
  }

  constraint c_valid_data_width {
    solve protocol before data_width;
    data_width inside {
      8, 16, 32, 64, 128, 256, 512, 1024
    };
    if (protocol == TVIP_AXI4LITE) {
      data_width inside {32, 64};
    }
  }

  constraint c_valid_strobe_width {
    solve data_width before strobe_width;
    strobe_width == (data_width / 8);
  }

  constraint c_valid_qos_range {
    solve protocol before qos_range;
    if (protocol == TVIP_AXI4LITE) {
      qos_range[0] == 0;
      qos_range[1] == 0;
    }
    else {
      qos_range[0] <= qos_range[1];
      foreach (qos_range[i]) {
        qos_range[i] inside {-1, [0:15]};
      }
    }
  }

  constraint c_default_qos_range {
    foreach (qos_range[i]) {
      soft qos_range[i] == -1;
    }
  }

  constraint c_valid_response_ordering {
    solve protocol before response_ordering;
    if (protocol == TVIP_AXI4LITE) {
      response_ordering == TVIP_AXI_IN_ORDER;
    }
  }

  constraint c_default_response_ordering {
    soft response_ordering == TVIP_AXI_OUT_OF_ORDER;
  }

  constraint c_valid_outstanding_responses {
    outstanding_responses >= 0;
  }

  constraint c_default_outstanding_responses {
    soft outstanding_responses == 0;
  }

  constraint c_default_enable_response_interleaving {
    soft enable_response_interleaving == 0;
  }

  constraint c_valid_interleave_size {
    min_interleave_size >= 0;
    max_interleave_size >= 0;
    max_interleave_size >= min_interleave_size;
  }

  constraint c_default_interleave_size {
    soft min_interleave_size == 0;
    soft max_interleave_size == 0;
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

  constraint c_default_reset_by_agent {
    soft reset_by_agent == 1;
  }

  function new(string name = "tvip_axi_configuration");
    super.new(name);
    request_start_delay   = tvip_delay_configuration::type_id::create("request_start_delay");
    write_data_delay      = tvip_delay_configuration::type_id::create("write_data_delay");
    response_start_delay  = tvip_delay_configuration::type_id::create("response_start_delay");
    response_delay        = tvip_delay_configuration::type_id::create("response_delay");
    awready_delay         = tvip_delay_configuration::type_id::create("awready_delay");
    wready_delay          = tvip_delay_configuration::type_id::create("wready_delay");
    bready_delay          = tvip_delay_configuration::type_id::create("bready_delay");
    arready_delay         = tvip_delay_configuration::type_id::create("arready_delay");
    rready_delay          = tvip_delay_configuration::type_id::create("rready_delay");
  endfunction

  function void post_randomize();
    super.post_randomize();
    qos_range[0]                  = (qos_range[0]                 >= 0) ? qos_range[0]                 : 0;
    qos_range[1]                  = (qos_range[1]                 >= 0) ? qos_range[1]                 : 0;
    response_weight_okay          = (response_weight_okay         >= 0) ? response_weight_okay         : 1;
    response_weight_exokay        = (response_weight_exokay       >= 0) ? response_weight_exokay       : 0;
    response_weight_slave_error   = (response_weight_slave_error  >= 0) ? response_weight_slave_error  : 0;
    response_weight_decode_error  = (response_weight_decode_error >= 0) ? response_weight_decode_error : 0;
  endfunction

  `uvm_object_utils_begin(tvip_axi_configuration)
    `uvm_field_enum(tvip_axi_protocol, protocol, UVM_DEFAULT)
    `uvm_field_int(id_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(address_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_burst_length, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(data_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(strobe_width, UVM_DEFAULT | UVM_DEC)
    `uvm_field_sarray_int(qos_range, UVM_DEFAULT | UVM_DEC)
    `uvm_field_enum(tvip_axi_ordering_mode, response_ordering, UVM_DEFAULT)
    `uvm_field_int(outstanding_responses, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(enable_response_interleaving, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(min_interleave_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(max_interleave_size, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_okay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_exokay, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_slave_error, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(response_weight_decode_error, UVM_DEFAULT | UVM_DEC)
    `uvm_field_object(request_start_delay, UVM_DEFAULT)
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
    `uvm_field_int(reset_by_agent, UVM_DEFAULT | UVM_BIN)
  `uvm_object_utils_end
endclass
`endif
