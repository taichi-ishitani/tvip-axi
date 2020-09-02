module top();
  timeunit 1ns;
  timeprecision 1ps;

  import  uvm_pkg::*;
  import  tue_pkg::*;
  import  tvip_axi_types_pkg::*;
  import  tvip_axi_pkg::*;
  import  tvip_axi_sample_pkg::*;

  bit aclk  = 0;
  initial begin
    forever begin
      #(0.5ns);
      aclk  ^= 1'b1;
    end
  end

  bit areset_n  = 0;
  initial begin
    repeat (20) @(posedge aclk);
    areset_n  = 1;
  end

  tvip_axi_if axi_if[2](aclk, areset_n);

  tvip_axi_sample_delay #(
    .WRITE_ADDRESS_DELAY  (8  ),
    .WRITE_DATA_DELAY     (8  ),
    .WRITE_RESPONSE_DELAY (8  ),
    .READ_ADDRESS_DELAY   (8  ),
    .READ_RESPONSE_DELAY  (8  )
  ) u_delay (
    aclk, areset_n, axi_if[0], axi_if[1]
  );

  initial begin
    uvm_config_db #(tvip_axi_vif)::set(null, "", "vif[0]", axi_if[0]);
    uvm_config_db #(tvip_axi_vif)::set(null, "", "vif[1]", axi_if[1]);
    run_test("tvip_axi_sample_test");
  end
endmodule
