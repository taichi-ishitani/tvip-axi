`ifndef TVIP_AXI_RAL_ADAPTER_SVH
`define TVIP_AXI_RAL_ADAPTER_SVH
class tvip_axi_ral_adapter extends uvm_reg_adapter;
  function new(string name = "tvip_axi_ral_adapter");
    super.new(name);
    supports_byte_enable  = 1;
    provides_responses    = 1;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    tvip_axi_master_item  axi_item;

    axi_item                = tvip_axi_master_item::type_id::create("axi_item");
    axi_item.id             = get_axi_id();
    axi_item.address        = rw.addr;
    axi_item.need_response  = 1;
    if (rw.kind == UVM_WRITE) begin
      axi_item.access_type  = TVIP_AXI_WRITE_ACCESS;
      axi_item.data         = new[1];
      axi_item.data[0]      = rw.data;
      axi_item.strobe       = new[1];
      axi_item.strobe[0]    = rw.byte_en;
    end
    else begin
      axi_item.access_type  = TVIP_AXI_READ_ACCESS;
    end

    return axi_item;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    tvip_axi_item axi_item;
    $cast(axi_item, bus_item);
    rw.addr     = axi_item.address;
    rw.kind     = (axi_item.is_write()) ? UVM_WRITE : UVM_READ;
    rw.data     = axi_item.data[0];
    rw.byte_en  = (axi_item.is_write()) ? axi_item.strobe[0] : rw.byte_en;
    rw.status   = get_status(axi_item);
  endfunction

  protected virtual function tvip_axi_id get_axi_id();
    return 0;
  endfunction

  protected function uvm_status_e get_status(tvip_axi_item axi_item);
    case (axi_item.response[0])
      TVIP_AXI_OKAY:          return UVM_IS_OK;
      TVIP_AXI_EXOKAY:        return UVM_IS_OK;
      TVIP_AXI_SLAVE_ERROR:   return UVM_NOT_OK;
      TVIP_AXI_DECODE_ERROR:  return UVM_NOT_OK;
    endcase
  endfunction

  `uvm_object_utils(tvip_axi_ral_adapter)
endclass
`endif
