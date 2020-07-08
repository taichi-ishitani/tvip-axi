`ifndef TVIP_AXI_SLAVE_SEQUENCE_BASE_SVH
`define TVIP_AXI_SLAVE_SEQUENCE_BASE_SVH
typedef tue_sequence #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (tvip_axi_slave_item    )
) tvip_axi_slave_sequence_base_base;

virtual class tvip_axi_slave_sequence_base extends tvip_axi_sequence_base #(
  .BASE       (tvip_axi_slave_sequence_base_base  ),
  .SEQUENCER  (tvip_axi_slave_sequencer           )
);
  function new(string name = "tvip_axi_master_sequence_base");
    super.new(name);
    set_automatic_phase_objection(0);
  endfunction

  virtual task get_request(
    input tvip_axi_access_type  access_type,
    ref   tvip_axi_slave_item   request
  );
    p_sequencer.get_request(access_type, request);
  endtask

  virtual task get_write_request(ref tvip_axi_slave_item request);
    get_request(TVIP_AXI_WRITE_ACCESS, request);
  endtask

  virtual task get_read_request(ref tvip_axi_slave_item request);
    get_request(TVIP_AXI_READ_ACCESS, request);
  endtask
endclass
`endif
