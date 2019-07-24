`ifndef TVIP_AXI_MASTER_RAL_ADAPTER_SVH
`define TVIP_AXI_MASTER_RAL_ADAPTER_SVH
class tvip_axi_master_ral_adapter extends uvm_reg_adapter;
  protected tvip_axi_master_sequencer axi_sequencer;
  protected tvip_axi_configuration    axi_configuration;

  function new(string name = "tvip_axi_master_ral_adapter");
    super.new(name);
    supports_byte_enable  = 1;
    provides_responses    = 0;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    tvip_axi_master_item  axi_item;

    if (axi_sequencer == null) begin
      lookup_sequencer();
    end

    axi_item  = tvip_axi_master_item::type_id::create("axi_item");
    axi_item.set_configuration(axi_configuration);
    if (!axi_item.randomize() with {
      address      == rw.addr;
      wait_for_end == 1;
      if (rw.kind == UVM_WRITE) {
        access_type == TVIP_AXI_WRITE_ACCESS;
        data[0]     == rw.data;
        strobe[0]   == (rw.byte_en & ((1 << axi_configuration.strobe_width) - 1));
      }
      else {
        access_type == TVIP_AXI_READ_ACCESS;
      }
    }) begin
      //  TODO: print fatal message
    end

    return axi_item;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    tvip_axi_master_item  axi_item;
    $cast(axi_item, bus_item);
    rw.addr   = axi_item.address;
    rw.kind   = (axi_item.is_write()) ? UVM_WRITE : UVM_READ;
    rw.data   = axi_item.data[0];
    rw.status = get_status(axi_item);
  endfunction

  protected function uvm_status_e get_status(tvip_axi_master_item axi_item);
    case (axi_item.response[0])
      TVIP_AXI_OKAY:          return UVM_IS_OK;
      TVIP_AXI_EXOKAY:        return UVM_IS_OK;
      TVIP_AXI_SLAVE_ERROR:   return UVM_NOT_OK;
      TVIP_AXI_DECODE_ERROR:  return UVM_NOT_OK;
    endcase
  endfunction

  local function void lookup_sequencer();
    uvm_reg_item        reg_item  = get_item();
    uvm_sequencer_base  sequencer;

    sequencer = reg_item.local_map.get_sequencer(UVM_NO_HIER);
    if (sequencer != null) begin
      $cast(axi_sequencer, sequencer);
      axi_configuration = axi_sequencer.get_configuration();
      return;
    end

    sequencer = reg_item.local_map.get_sequencer(UVM_HIER);
    if (sequencer != null) begin
      $cast(axi_sequencer, sequencer);
      axi_configuration = axi_sequencer.get_configuration();
    end
  endfunction

  `uvm_object_utils(tvip_axi_master_ral_adapter)
endclass
`endif
