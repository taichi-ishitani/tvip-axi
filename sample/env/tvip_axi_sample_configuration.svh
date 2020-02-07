`ifndef TVIP_AXI_SAMPLE_CONFIGURATION_SVH
`define TVIP_AXI_SAMPLE_CONFIGURATION_SVH
class tvip_axi_sample_configuration extends tue_configuration;
        bit                     enable_request_start_delay;
        bit                     enable_write_data_delay;
        bit                     enable_response_start_delay;
        bit                     enable_response_delay;
        bit                     enable_ready_delay;
        bit                     enable_out_of_order_response;
        bit                     enable_read_interleave;
  rand  tvip_axi_configuration  axi_cfg;

  constraint c_axi_basic {
    axi_cfg.id_width         == 8;
    axi_cfg.address_width    == 64;
    axi_cfg.max_burst_length == 256;
    axi_cfg.data_width       == 64;
    axi_cfg.qos_range[0]     != -1;
    axi_cfg.qos_range[1]     != -1;
  }

  constraint c_request_start_delay {
    if (enable_request_start_delay) {
      axi_cfg.request_start_delay.min_delay          == 0;
      axi_cfg.request_start_delay.max_delay          == 10;
      axi_cfg.request_start_delay.weight_zero_delay  == 6;
      axi_cfg.request_start_delay.weight_short_delay == 3;
      axi_cfg.request_start_delay.weight_long_delay  == 1;
    }
  }

  constraint c_write_data_delay {
    if (enable_write_data_delay) {
      axi_cfg.write_data_delay.min_delay          == 0;
      axi_cfg.write_data_delay.max_delay          == 10;
      axi_cfg.write_data_delay.weight_zero_delay  == 6;
      axi_cfg.write_data_delay.weight_short_delay == 3;
      axi_cfg.write_data_delay.weight_long_delay  == 1;
    }
  }

  constraint c_response_weight {
    axi_cfg.response_weight_okay         == 6;
    axi_cfg.response_weight_exokay       == 2;
    axi_cfg.response_weight_slave_error  == 1;
    axi_cfg.response_weight_decode_error == 1;
  }

  constraint c_response_start_delay {
    if (enable_response_start_delay || enable_out_of_order_response) {
      axi_cfg.response_start_delay.min_delay          == 0;
      axi_cfg.response_start_delay.max_delay          == 10;
      axi_cfg.response_start_delay.weight_zero_delay  == 6;
      axi_cfg.response_start_delay.weight_short_delay == 3;
      axi_cfg.response_start_delay.weight_long_delay  == 1;
    }
  }

  constraint c_response_delay {
    if (enable_response_delay) {
      axi_cfg.response_delay.min_delay          == 0;
      axi_cfg.response_delay.max_delay          == 10;
      axi_cfg.response_delay.weight_zero_delay  == 6;
      axi_cfg.response_delay.weight_short_delay == 3;
      axi_cfg.response_delay.weight_long_delay  == 1;
    }
  }

  constraint c_ready_delay {
    if (enable_ready_delay) {
      axi_cfg.awready_delay.min_delay          == 0;
      axi_cfg.awready_delay.max_delay          == 10;
      axi_cfg.awready_delay.weight_zero_delay  == 6;
      axi_cfg.awready_delay.weight_short_delay == 3;
      axi_cfg.awready_delay.weight_long_delay  == 1;

      axi_cfg.wready_delay.min_delay          == 0;
      axi_cfg.wready_delay.max_delay          == 10;
      axi_cfg.wready_delay.weight_zero_delay  == 6;
      axi_cfg.wready_delay.weight_short_delay == 3;
      axi_cfg.wready_delay.weight_long_delay  == 1;

      axi_cfg.bready_delay.min_delay          == 0;
      axi_cfg.bready_delay.max_delay          == 10;
      axi_cfg.bready_delay.weight_zero_delay  == 6;
      axi_cfg.bready_delay.weight_short_delay == 3;
      axi_cfg.bready_delay.weight_long_delay  == 1;

      axi_cfg.arready_delay.min_delay          == 0;
      axi_cfg.arready_delay.max_delay          == 10;
      axi_cfg.arready_delay.weight_zero_delay  == 6;
      axi_cfg.arready_delay.weight_short_delay == 3;
      axi_cfg.arready_delay.weight_long_delay  == 1;

      axi_cfg.rready_delay.min_delay          == 0;
      axi_cfg.rready_delay.max_delay          == 10;
      axi_cfg.rready_delay.weight_zero_delay  == 6;
      axi_cfg.rready_delay.weight_short_delay == 3;
      axi_cfg.rready_delay.weight_long_delay  == 1;
    }
  }

  constraint c_response_ordering {
    if (enable_out_of_order_response || enable_read_interleave) {
      axi_cfg.response_ordering == TVIP_AXI_OUT_OF_ORDER;
    }
    else {
      axi_cfg.response_ordering == TVIP_AXI_IN_ORDER;
    }
  }

  constraint c_read_interleave {
    if (enable_read_interleave) {
      axi_cfg.interleave_depth inside {[1:4]};
    }
  }

  function new(string name = "tvip_axi_sample_configuration");
    super.new(name);
    axi_cfg = tvip_axi_configuration::type_id::create("axi_cfg");
  endfunction

  function void pre_randomize();
    uvm_cmdline_processor clp;
    string                values[$];
    clp = uvm_cmdline_processor::get_inst();
    if (clp.get_arg_matches("+ENABLE_REQUEST_START_DELAY", values)) begin
      enable_request_start_delay  = 1;
    end
    if (clp.get_arg_matches("+ENABLE_WRITE_DATA_DELAY", values)) begin
      enable_write_data_delay = 1;
    end
    if (clp.get_arg_matches("+ENABLE_RESPONSE_START_DELAY", values)) begin
      enable_response_start_delay = 1;
    end
    if (clp.get_arg_matches("+ENABLE_RESPONSE_DELAY", values)) begin
      enable_response_delay = 1;
    end
    if (clp.get_arg_matches("+ENABLE_READY_DELAY", values)) begin
      enable_ready_delay  = 1;
    end
    if (clp.get_arg_matches("+ENABLE_OUT_OF_ORDER_RESPONSE", values)) begin
      enable_out_of_order_response  = 1;
    end
    if (clp.get_arg_matches("+ENABLE_READ_INTERLEAVE", values)) begin
      enable_read_interleave  = 1;
    end
  endfunction

  `uvm_object_utils_begin(tvip_axi_sample_configuration)
    `uvm_field_int(enable_write_data_delay, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(enable_response_start_delay, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(enable_response_delay, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(enable_ready_delay, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(enable_out_of_order_response, UVM_DEFAULT | UVM_BIN)
    `uvm_field_int(enable_read_interleave, UVM_DEFAULT | UVM_BIN)
    `uvm_field_object(axi_cfg, UVM_DEFAULT)
  `uvm_object_utils_end
endclass
`endif
