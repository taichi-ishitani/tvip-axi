`ifndef TVIP_AXI_IF_SV
`define TVIP_AXI_IF_SV
interface tvip_axi_if (
  input bit aclk,
  input bit areset_n
);
  import  tvip_axi_types_pkg::*;

  //  Write Address Channel
  bit                   awvalid;
  bit                   awready;
  bit                   awack;
  tvip_axi_id           awid;
  tvip_axi_address      awaddr;
  tvip_axi_burst_length awlen;
  tvip_axi_burst_size   awsize;
  tvip_axi_burst_type   awburst;
  tvip_axi_qos          awqos;
  //  Write Data Channel
  bit                   wvalid;
  bit                   wready;
  bit                   wack;
  tvip_axi_data         wdata;
  tvip_axi_strobe       wstrb;
  bit                   wlast;
  //  Write Response Channel
  bit                   bvalid;
  bit                   bready;
  bit                   back;
  tvip_axi_id           bid;
  tvip_axi_response     bresp;
  //  Read Address Channel
  bit                   arvalid;
  bit                   arready;
  bit                   arack;
  tvip_axi_id           arid;
  tvip_axi_address      araddr;
  tvip_axi_burst_length arlen;
  tvip_axi_burst_size   arsize;
  tvip_axi_burst_type   arburst;
  tvip_axi_qos          arqos;
  //  Read Data Channel
  bit                   rvalid;
  bit                   rready;
  bit                   rack;
  tvip_axi_id           rid;
  tvip_axi_data         rdata;
  tvip_axi_response     rresp;
  bit                   rlast;

  assign  awack = (awvalid && awready) ? '1 : '0;
  assign  wack  = (wvalid  && wready ) ? '1 : '0;
  assign  back  = (bvalid  && bready ) ? '1 : '0;
  assign  arack = (arvalid && arready) ? '1 : '0;
  assign  rack  = (rvalid  && rready ) ? '1 : '0;

  clocking master_cb @(posedge aclk);
    output  awvalid;
    input   awready;
    input   awack;
    output  awid;
    output  awaddr;
    output  awlen;
    output  awsize;
    output  awburst;
    output  awqos;
    output  wvalid;
    input   wready;
    input   wack;
    output  wdata;
    output  wstrb;
    output  wlast;
    input   bvalid;
    output  bready;
    input   back;
    input   bid;
    input   bresp;
    output  arvalid;
    input   arready;
    input   arack;
    output  arid;
    output  araddr;
    output  arlen;
    output  arsize;
    output  arburst;
    output  arqos;
    input   rvalid;
    output  rready;
    input   rack;
    input   rid;
    input   rdata;
    input   rresp;
    input   rlast;
  endclocking

  clocking slave_cb @(posedge aclk);
    input   awvalid;
    output  awready;
    input   awack;
    input   awid;
    input   awaddr;
    input   awlen;
    input   awsize;
    input   awburst;
    input   awqos;
    input   wvalid;
    output  wready;
    input   wack;
    input   wdata;
    input   wstrb;
    input   wlast;
    output  bvalid;
    input   bready;
    input   back;
    output  bid;
    output  bresp;
    input   arvalid;
    output  arready;
    input   arack;
    input   arid;
    input   araddr;
    input   arlen;
    input   arsize;
    input   arburst;
    input   arqos;
    output  rvalid;
    input   rready;
    input   rack;
    output  rid;
    output  rdata;
    output  rresp;
    output  rlast;
  endclocking

  clocking monitor_cb @(posedge aclk);
    input awvalid;
    input awready;
    input awack;
    input awid;
    input awaddr;
    input awlen;
    input awsize;
    input awburst;
    input awqos;
    input wvalid;
    input wready;
    input wack;
    input wdata;
    input wstrb;
    input wlast;
    input bvalid;
    input bready;
    input back;
    input bid;
    input bresp;
    input arvalid;
    input arready;
    input arack;
    input arid;
    input araddr;
    input arlen;
    input arsize;
    input arburst;
    input arqos;
    input rvalid;
    input rready;
    input rack;
    input rid;
    input rdata;
    input rresp;
    input rlast;
  endclocking
endinterface
`endif
