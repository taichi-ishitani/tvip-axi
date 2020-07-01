`ifndef TVIP_AXI_SEQUENCER_BASE_SVH
`define TVIP_AXI_SEQUENCER_BASE_SVH
class tvip_axi_item_waiter extends tvip_item_waiter #(
  .ITEM (tvip_axi_item  ),
  .ID   (tvip_axi_id    )
);
  protected function tvip_axi_id get_id_from_item(tvip_axi_item item);
    return item.id;
  endfunction
  `tue_component_default_constructor(tvip_axi_item_waiter)
endclass

class tvip_axi_dispatcher extends tue_sequence_item_dispatcher #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .ITEM           (tvip_axi_item          )
);
  protected uvm_sequencer_base  write_sequencer;
  protected uvm_sequencer_base  read_sequencer;

  function void set_sequencers(
    uvm_sequencer_base  write_sequencer,
    uvm_sequencer_base  read_sequencer
  );
    this.write_sequencer  = write_sequencer;
    this.read_sequencer   = read_sequencer;
  endfunction

  protected function uvm_sequencer_base select_sequencer(tvip_axi_item item);
    if (item.is_write()) begin
      return write_sequencer;
    end
    else begin
      return read_sequencer;
    end
  endfunction

  protected task post_dispatch(tvip_axi_item item);
    if (item.wait_for_end) begin
      item.response_end_event.wait_on();
    end
  endtask

  `tue_object_default_constructor(tvip_axi_dispatcher)
endclass

virtual class tvip_axi_sequencer_base #(
  type  BASE            = uvm_sequencer,
  type  SUB_SEQEUENCER  = uvm_sequencer,
  type  ITEM            = uvm_sequence_item
) extends BASE;
  uvm_analysis_export #(tvip_axi_item)  address_item_export;
  uvm_analysis_export #(tvip_axi_item)  request_item_export;
  uvm_analysis_export #(tvip_axi_item)  response_item_export;
  uvm_analysis_export #(tvip_axi_item)  item_export;

            SUB_SEQEUENCER        write_sequencer;
            SUB_SEQEUENCER        read_sequencer;
  protected tvip_axi_dispatcher   dispatcher;
  protected tvip_axi_item_waiter  address_item_waiter;
  protected tvip_axi_item_waiter  request_item_waiter;
  protected tvip_axi_item_waiter  response_item_waiter;
  protected tvip_axi_item_waiter  item_waiter;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    write_sequencer = SUB_SEQEUENCER::type_id::create("write_sequencer", this);
    write_sequencer.set_context(configuration, status);

    read_sequencer  = SUB_SEQEUENCER::type_id::create("read_sequencer", this);
    read_sequencer.set_context(configuration, status);

    dispatcher  = new("dispatcher");
    dispatcher.set_sequencers(write_sequencer, read_sequencer);

    address_item_export = new("address_item_export", this);
    address_item_waiter = new("address_item_waiter", this);

    request_item_export = new("request_item_export", this);
    request_item_waiter = new("request_item_waiter", this);

    response_item_export  = new("response_item_export", this);
    response_item_waiter  = new("response_item_waiter", this);

    item_export = new("item_export", this);
    item_waiter = new("item_waiter", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    address_item_export.connect(address_item_waiter.analysis_export);
    request_item_export.connect(request_item_waiter.analysis_export);
    response_item_export.connect(response_item_waiter.analysis_export);
    item_export.connect(item_waiter.analysis_export);
  endfunction

  virtual task dispatch(
    tvip_axi_item     item,
    uvm_sequence_base parent_sequence = null
  );
    dispatcher.dispatch(item, parent_sequence);
  endtask

  `define tvip_axi_define_item_getter_tasks(ITEM_TYPE) \
  virtual task get_``ITEM_TYPE``(ref tvip_axi_item item); \
    ``ITEM_TYPE``_waiter.get_item(item); \
  endtask \
  virtual task get_``ITEM_TYPE``_by_id(ref tvip_axi_item item, input tvip_axi_id id); \
    ``ITEM_TYPE``_waiter.get_item_by_id(item, id); \
  endtask

  `tvip_axi_define_item_getter_tasks(address_item )
  `tvip_axi_define_item_getter_tasks(request_item )
  `tvip_axi_define_item_getter_tasks(response_item)
  `tvip_axi_define_item_getter_tasks(item         )

  `undef  tvip_axi_define_item_getter_tasks

  `tue_component_default_constructor(pzvip_ocp_sequencer_base)
endclass
`endif
