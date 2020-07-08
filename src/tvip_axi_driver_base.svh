`ifndef TVIP_AXI_DRIVER_BASE_SVH
`define TVIP_AXI_DRIVER_BASE_SVH
class tvip_axi_sub_driver_base #(
  type  ITEM  = uvm_sequence_item
) extends tue_component #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        )
);
  protected tvip_axi_item       item_buffer[$];
  protected uvm_driver #(ITEM)  root_driver;

  function new(string name = "tvip_axi_sub_driver_base", uvm_component parent = null);
    super.new(name, parent);
    void'($cast(root_driver, parent));
  endfunction

  virtual task put_request(tvip_axi_item request);
    item_buffer.push_back(request);
  endtask

  virtual task put_response(tvip_axi_item response);
    ITEM  item;
    void'($cast(item, response));
    root_driver.seq_item_port.put(item);
  endtask
endclass

class tvip_axi_driver_base #(
  type  ITEM          = uvm_sequence_item,
  type  WRITE_DRIVER  = uvm_component,
  type  READ_DRIVER   = uvm_component
) extends tue_driver #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (ITEM                   )
);
  protected WRITE_DRIVER  write_driver;
  protected READ_DRIVER   read_driver;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    write_driver  = WRITE_DRIVER::type_id::create("write_driver", this);
    write_driver.set_context(configuration, status);

    read_driver   = READ_DRIVER::type_id::create("read_driver", this);
    read_driver.set_context(configuration, status);
  endfunction

  task run_phase(uvm_phase phase);
    ITEM  item;
    forever begin
      seq_item_port.get(item);
      if (item.is_write()) begin
        write_driver.put_request(item);
      end
      else begin
        read_driver.put_request(item);
      end
    end
  endtask

  `tue_component_default_constructor(tvip_axi_driver_base)
endclass
`endif
