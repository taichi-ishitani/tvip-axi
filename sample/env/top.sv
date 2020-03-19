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
    #(100ns);
    areset_n  = 1;
  end

  tvip_axi_if axi_if(aclk, areset_n);
  initial begin
    uvm_config_db #(tvip_axi_vif)::set(null, "", "vif", axi_if);
    run_test("tvip_axi_sample_test");
  end
endmodule
