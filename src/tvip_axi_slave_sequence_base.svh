`ifndef TVIP_AXI_SLAVE_SEQUENCE_BASE_SVH
`define TVIP_AXI_SLAVE_SEQUENCE_BASE_SVH
typedef tue_reactive_sequence #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .ITEM           (tvip_axi_slave_item    )
) tvip_axi_slave_sequence_base_base;

virtual class tvip_axi_slave_sequence_base extends tvip_axi_sequence_base #(
  .BASE           (tvip_axi_slave_sequence_base_base  ),
  .SEQUENCER      (tvip_axi_slave_sequencer           ),
  .SUB_SEQUENCER  (tvip_axi_slave_sub_sequencer       )
);
  function new(string name = "tvip_axi_master_sequence_base");
    super.new(name);
    set_automatic_phase_objection(0);
  endfunction

  task get_request(ref tvip_axi_slave_item request);
    super.get_request(request);
    if (request.is_write()) begin
      request.set_sequencer(write_sequencer);
    end
    else begin
      request.set_sequencer(read_sequencer);
    end
  endtask
endclass
`endif
