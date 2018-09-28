`ifndef TVIP_AXI_SAMPLE_WRITE_READ_SEQUENCE_SVH
`define TVIP_AXI_SAMPLE_WRITE_READ_SEQUENCE_SVH
class tvip_axi_sample_write_read_sequence extends tvip_axi_master_sequence_base;
  function new(string name = "tvip_axi_sample_write_read_sequence");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction

  task body();
    repeat (20) begin
      fork begin
        tvip_axi_master_access_sequence write_sequence;
        tvip_axi_master_access_sequence read_sequence;
        `uvm_do_with(write_sequence, {
          access_type == TVIP_AXI_WRITE_ACCESS;
        })
        `uvm_do_with(read_sequence, {
          access_type  == TVIP_AXI_READ_ACCESS;
          address      == write_sequence.address;
          burst_size   == write_sequence.burst_size;
          burst_length >= write_sequence.burst_length;
        })
      end join_none
    end
    wait fork;
  endtask

  `uvm_object_utils(tvip_axi_sample_write_read_sequence)
endclass
`endif
