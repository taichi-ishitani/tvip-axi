module tvip_axi_sample_delay_unit #(
  parameter int   DELAY = 0,
  parameter type  DATA  = logic
)(
  input   var       i_clk,
  input   var       i_rst_n,
  input   var       i_enable,
  input   var       i_valid,
  output  var       o_ready,
  input   var DATA  i_d,
  output  var       o_valid,
  input   var       i_ready,
  output  var DATA  o_d
);
  logic valid[DELAY+1];
  logic ready[DELAY+1];
  DATA  data[DELAY+1];

  always_comb begin
    valid[0]  = (i_enable) ? i_valid  : '0;
    o_ready   = (i_enable) ? ready[0] : i_ready;
    data[0]   = (i_enable) ? i_d      : '0;
  end

  always_comb begin
    o_valid       = (i_enable) ? valid[DELAY] : i_valid;
    ready[DELAY]  = (i_enable) ? i_ready      : '0;
    o_d           = (i_enable) ? data[DELAY]  : i_d;
  end

  for (genvar i = 0;i < DELAY;++i) begin : g
    always_ff @(posedge i_clk, negedge i_rst_n) begin
      if (!i_rst_n) begin
        valid[i+1]  <= '0;
        data[i+1]   <= '0;
      end
      else if (ready[i]) begin
        valid[i+1]  <= valid[i];
        data[i+1]   <= data[i];
      end
    end

    always_comb begin
      ready[i]  = ready[i+1] || (!valid[i+1]);
    end
  end
endmodule

module tvip_axi_sample_delay #(
  parameter int WRITE_ADDRESS_DELAY   = 0,
  parameter int WRITE_DATA_DELAY      = 0,
  parameter int WRITE_RESPONSE_DELAY  = 0,
  parameter int READ_ADDRESS_DELAY    = 0,
  parameter int READ_RESPONSE_DELAY   = 0
)(
  input var   i_clk,
  input var   i_rst_n,
  tvip_axi_if slave_if,
  tvip_axi_if master_if
);
  import  tvip_axi_types_pkg::*;

  typedef struct packed {
    tvip_axi_id           awid;
    tvip_axi_address      awaddr;
    tvip_axi_burst_length awlen;
    tvip_axi_burst_size   awsize;
    tvip_axi_burst_type   awburst;
    tvip_axi_cache        awcache;
    tvip_axi_protection   awprot;
    tvip_axi_qos          awqos;
  } tvip_axi_write_address;

  typedef struct packed {
    tvip_axi_data   wdata;
    tvip_axi_strobe wstrb;
    bit             wlast;
  } tvip_axi_write_data;

  typedef struct packed {
    tvip_axi_id       bid;
    tvip_axi_response bresp;
  } tvip_axi_write_response;

  typedef struct packed {
    tvip_axi_id           arid;
    tvip_axi_address      araddr;
    tvip_axi_burst_length arlen;
    tvip_axi_burst_size   arsize;
    tvip_axi_burst_type   arburst;
    tvip_axi_cache        arcache;
    tvip_axi_protection   arprot;
    tvip_axi_qos          arqos;
  } tvip_axi_read_address;

  typedef struct packed {
    tvip_axi_id       rid;
    tvip_axi_data     rdata;
    tvip_axi_response rresp;
    bit               rlast;
  } tvip_axi_read_response;

  bit [4:0] enable_delay;
  initial begin
    enable_delay[0] = $test$plusargs("write_address_delay");
    enable_delay[1] = $test$plusargs("write_data_delay");
    enable_delay[2] = $test$plusargs("write_response_delay");
    enable_delay[3] = $test$plusargs("read_address_delay");
    enable_delay[4] = $test$plusargs("read_response_delay");
  end

  logic                   awvalid[2];
  logic                   awready[2];
  tvip_axi_write_address  write_address[2];

  always @* begin
    slave_if.awready          = awready[0];
    awvalid[0]                = slave_if.awvalid;
    write_address[0].awaddr   = slave_if.awaddr;
    write_address[0].awid     = slave_if.awid;
    write_address[0].awlen    = slave_if.awlen;
    write_address[0].awsize   = slave_if.awsize;
    write_address[0].awburst  = slave_if.awburst;
    write_address[0].awcache  = slave_if.awcache;
    write_address[0].awprot   = slave_if.awprot;
    write_address[0].awqos    = slave_if.awqos;
  end

  always @* begin
    awready[1]        = master_if.awready;
    master_if.awvalid = awvalid[1];
    master_if.awaddr  = write_address[1].awaddr;
    master_if.awid    = write_address[1].awid;
    master_if.awlen   = write_address[1].awlen;
    master_if.awsize  = write_address[1].awsize;
    master_if.awburst = write_address[1].awburst;
    master_if.awcache = write_address[1].awcache;
    master_if.awprot  = write_address[1].awprot;
    master_if.awqos   = write_address[1].awqos;
  end

  tvip_axi_sample_delay_unit #(
    .DELAY  (WRITE_ADDRESS_DELAY    ),
    .DATA   (tvip_axi_write_address )
  ) u_write_address_delay (
    .i_clk    (i_clk            ),
    .i_rst_n  (i_rst_n          ),
    .i_enable (enable_delay[0]  ),
    .i_valid  (awvalid[0]       ),
    .o_ready  (awready[0]       ),
    .i_d      (write_address[0] ),
    .o_valid  (awvalid[1]       ),
    .i_ready  (awready[1]       ),
    .o_d      (write_address[1] )
  );

  logic               wvalid[2];
  logic               wready[2];
  tvip_axi_write_data write_data[2];

  always @* begin
    slave_if.wready     = wready[0];
    wvalid[0]           = slave_if.wvalid;
    write_data[0].wdata = slave_if.wdata;
    write_data[0].wstrb = slave_if.wstrb;
    write_data[0].wlast = slave_if.wlast;
  end

  always @* begin
    wready[1]         = master_if.wready;
    master_if.wvalid  = wvalid[1];
    master_if.wdata   = write_data[1].wdata;
    master_if.wstrb   = write_data[1].wstrb;
    master_if.wlast   = write_data[1].wlast;
  end

  tvip_axi_sample_delay_unit #(
    .DELAY  (WRITE_DATA_DELAY     ),
    .DATA   (tvip_axi_write_data  )
  ) u_write_data_delay (
    .i_clk    (i_clk            ),
    .i_rst_n  (i_rst_n          ),
    .i_enable (enable_delay[1]  ),
    .i_valid  (wvalid[0]        ),
    .o_ready  (wready[0]        ),
    .i_d      (write_data[0]    ),
    .o_valid  (wvalid[1]        ),
    .i_ready  (wready[1]        ),
    .o_d      (write_data[1]    )
  );

  logic                   bvalid[2];
  logic                   bready[2];
  tvip_axi_write_response write_response[2];

  always @* begin
    master_if.bready        = bready[0];
    bvalid[0]               = master_if.bvalid;
    write_response[0].bid   = master_if.bid;
    write_response[0].bresp = master_if.bresp;
  end

  always @* begin
    bready[1]       = slave_if.bready;
    slave_if.bvalid = bvalid[1];
    slave_if.bid    = write_response[1].bid;
    slave_if.bresp  = write_response[1].bresp;
  end

  tvip_axi_sample_delay_unit #(
    .DELAY  (WRITE_RESPONSE_DELAY     ),
    .DATA   (tvip_axi_write_response  )
  ) u_write_response_delay (
    .i_clk    (i_clk              ),
    .i_rst_n  (i_rst_n            ),
    .i_enable (enable_delay[2]    ),
    .i_valid  (bvalid[0]          ),
    .o_ready  (bready[0]          ),
    .i_d      (write_response[0]  ),
    .o_valid  (bvalid[1]          ),
    .i_ready  (bready[1]          ),
    .o_d      (write_response[1]  )
  );

  logic                 arvalid[2];
  logic                 arready[2];
  tvip_axi_read_address read_address[2];

  always @* begin
    slave_if.arready        = arready[0];
    arvalid[0]              = slave_if.arvalid;
    read_address[0].araddr  = slave_if.araddr;
    read_address[0].arid    = slave_if.arid;
    read_address[0].arlen   = slave_if.arlen;
    read_address[0].arsize  = slave_if.arsize;
    read_address[0].arburst = slave_if.arburst;
    read_address[0].arcache = slave_if.arcache;
    read_address[0].arprot  = slave_if.arprot;
    read_address[0].arqos   = slave_if.arqos;
  end

  always @* begin
    arready[1]        = master_if.arready;
    master_if.arvalid = arvalid[1];
    master_if.araddr  = read_address[1].araddr;
    master_if.arid    = read_address[1].arid;
    master_if.arlen   = read_address[1].arlen;
    master_if.arsize  = read_address[1].arsize;
    master_if.arburst = read_address[1].arburst;
    master_if.arcache = read_address[1].arcache;
    master_if.arprot  = read_address[1].arprot;
    master_if.arqos   = read_address[1].arqos;
  end

  tvip_axi_sample_delay_unit #(
    .DELAY  (READ_ADDRESS_DELAY     ),
    .DATA   (tvip_axi_read_address  )
  ) u_read_address_delay (
    .i_clk    (i_clk            ),
    .i_rst_n  (i_rst_n          ),
    .i_enable (enable_delay[3]  ),
    .i_valid  (arvalid[0]       ),
    .o_ready  (arready[0]       ),
    .i_d      (read_address[0]  ),
    .o_valid  (arvalid[1]       ),
    .i_ready  (arready[1]       ),
    .o_d      (read_address[1]  )
  );

  logic                   rvalid[2];
  logic                   rready[2];
  tvip_axi_read_response  read_response[2];

  always @* begin
    master_if.rready        = rready[0];
    rvalid[0]               = master_if.rvalid;
    read_response[0].rid    = master_if.rid;
    read_response[0].rdata  = master_if.rdata;
    read_response[0].rresp  = master_if.rresp;
    read_response[0].rlast  = master_if.rlast;
  end

  always @* begin
    rready[1]       = slave_if.rready;
    slave_if.rvalid = rvalid[1];
    slave_if.rid    = read_response[1].rid;
    slave_if.rdata  = read_response[1].rdata;
    slave_if.rresp  = read_response[1].rresp;
    slave_if.rlast  = read_response[1].rlast;
  end

  tvip_axi_sample_delay_unit #(
    .DELAY  (READ_RESPONSE_DELAY    ),
    .DATA   (tvip_axi_read_response )
  ) u_read_response_delay (
    .i_clk    (i_clk            ),
    .i_rst_n  (i_rst_n          ),
    .i_enable (enable_delay[4]  ),
    .i_valid  (rvalid[0]        ),
    .o_ready  (rready[0]        ),
    .i_d      (read_response[0] ),
    .o_valid  (rvalid[1]        ),
    .i_ready  (rready[1]        ),
    .o_d      (read_response[1] )
  );
endmodule
