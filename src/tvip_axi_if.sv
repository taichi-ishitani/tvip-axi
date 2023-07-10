`ifndef TVIP_AXI_IF_SV
`define TVIP_AXI_IF_SV
interface tvip_axi_if (
  input var aclk,
  input var areset_n
);
  import  tvip_axi_types_pkg::*;

  //  Write Address Channel
  logic                 awvalid;
  logic                 awready;
  tvip_axi_id           awid;
  tvip_axi_address      awaddr;
  tvip_axi_burst_length awlen;
  tvip_axi_burst_size   awsize;
  tvip_axi_burst_type   awburst;
  tvip_axi_write_cache  awcache;
  tvip_axi_protection   awprot;
  tvip_axi_qos          awqos;
  //  Write Data Channel
  logic                 wvalid;
  logic                 wready;
  tvip_axi_data         wdata;
  tvip_axi_strobe       wstrb;
  logic                 wlast;
  //  Write Response Channel
  logic                 bvalid;
  logic                 bready;
  tvip_axi_id           bid;
  tvip_axi_response     bresp;
  //  Read Address Channel
  logic                 arvalid;
  logic                 arready;
  tvip_axi_id           arid;
  tvip_axi_address      araddr;
  tvip_axi_burst_length arlen;
  tvip_axi_burst_size   arsize;
  tvip_axi_burst_type   arburst;
  tvip_axi_read_cache   arcache;
  tvip_axi_protection   arprot;
  tvip_axi_qos          arqos;
  //  Read Data Channel
  logic                 rvalid;
  logic                 rready;
  tvip_axi_id           rid;
  tvip_axi_data         rdata;
  tvip_axi_response     rresp;
  logic                 rlast;

  clocking master_cb @(posedge aclk, negedge areset_n);
    output  awvalid;
    input   awready;
    output  awid;
    output  awaddr;
    output  awlen;
    output  awsize;
    output  awburst;
    output  awprot;
    output  awcache;
    output  awqos;
    output  wvalid;
    input   wready;
    output  wdata;
    output  wstrb;
    output  wlast;
    input   bvalid;
    output  bready;
    input   bid;
    input   bresp;
    output  arvalid;
    input   arready;
    output  arid;
    output  araddr;
    output  arlen;
    output  arsize;
    output  arburst;
    output  arcache;
    output  arprot;
    output  arqos;
    input   rvalid;
    output  rready;
    input   rid;
    input   rdata;
    input   rresp;
    input   rlast;
  endclocking

  clocking slave_cb @(posedge aclk, negedge areset_n);
    input   awvalid;
    output  awready;
    input   awid;
    input   awaddr;
    input   awlen;
    input   awsize;
    input   awburst;
    input   awcache;
    input   awprot;
    input   awqos;
    input   wvalid;
    output  wready;
    input   wdata;
    input   wstrb;
    input   wlast;
    output  bvalid;
    input   bready;
    output  bid;
    output  bresp;
    input   arvalid;
    output  arready;
    input   arid;
    input   araddr;
    input   arlen;
    input   arsize;
    input   arburst;
    input   arcache;
    input   arprot;
    input   arqos;
    output  rvalid;
    input   rready;
    output  rid;
    output  rdata;
    output  rresp;
    output  rlast;
  endclocking

  clocking monitor_cb @(posedge aclk);
    input areset_n;
    input awvalid;
    input awready;
    input awid;
    input awaddr;
    input awlen;
    input awsize;
    input awburst;
    input awcache;
    input awprot;
    input awqos;
    input wvalid;
    input wready;
    input wdata;
    input wstrb;
    input wlast;
    input bvalid;
    input bready;
    input bid;
    input bresp;
    input arvalid;
    input arready;
    input arid;
    input araddr;
    input arlen;
    input arsize;
    input arburst;
    input arcache;
    input arprot;
    input arqos;
    input rvalid;
    input rready;
    input rid;
    input rdata;
    input rresp;
    input rlast;
  endclocking

  event at_master_cb_edge;
  event at_slave_cb_edge;
  event at_monitor_cb_edge;

  always @(master_cb) begin
    ->at_master_cb_edge;
  end

  always @(slave_cb) begin
    ->at_slave_cb_edge;
  end

  always @(monitor_cb) begin
    ->at_monitor_cb_edge;
  end
endinterface
`endif
