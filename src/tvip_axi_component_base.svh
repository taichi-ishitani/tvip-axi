`ifndef TVIP_AXI_COMPONENT_BASE_SVH
`define TVIP_AXI_COMPONENT_BASE_SVH
virtual class tvip_axi_component_base #(
  type  BASE  = uvm_component
) extends BASE;
  protected bit           write_component;
  protected tvip_axi_vif  vif;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    vif = configuration.vif;
  endfunction

  protected function bit is_write_component();
    return write_component;
  endfunction

  protected function bit is_read_component();
    return !write_component;
  endfunction

  virtual task begin_address(tvip_axi_item item);
    if (!item.write_data_began()) begin
      void'(begin_tr(item));
    end
    item.begin_address();
  endtask

  virtual task end_address(tvip_axi_item item);
    item.end_address();
  endtask

  virtual task begin_write_data(tvip_axi_item item);
    if (item.is_write()) begin
      if (!item.address_began()) begin
        void'(begin_tr(item));
      end
      item.begin_write_data();
    end
  endtask

  virtual task end_write_data(tvip_axi_item item);
    if (item.is_write()) begin
      item.end_write_data();
    end
  endtask

  virtual task begin_response(tvip_axi_item item);
    item.begin_response();
  endtask

  virtual task end_response(tvip_axi_item item);
    item.end_response();
    end_tr(item);
  endtask

  `tue_component_default_constructor(tvip_axi_component_base)
endclass
`endif
