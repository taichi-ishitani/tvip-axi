`ifndef TVIP_AXI_SEQUENCER_BASE_SVH
`define TVIP_AXI_SEQUENCER_BASE_SVH
class tvip_axi_item_waiter extends tue_subscriber #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .T              (tvip_axi_item          )
);
  protected uvm_event waiters[$];
  protected uvm_event id_waiters[tvip_axi_id][$];

  function void write(tvip_axi_item t);
    while (waiters.size() > 0) begin
      uvm_event waiter  = waiters.pop_front();
      waiter.trigger(t);
    end

    if (!id_waiters.exists(t.id)) begin
      return;
    end

    while (id_waiters[t.id].size() > 0) begin
      uvm_event waiter  = id_waiters[t.id].pop_front();
      waiter.trigger(t);
    end
  endfunction

  task get_item(ref tvip_axi_item  item);
    uvm_event waiter  = get_waiter();
    waiter.wait_on();
    $cast(item, waiter.get_trigger_data());
  endtask

  task get_item_by_id(ref tvip_axi_item item, input tvip_axi_id id);
    uvm_event waiter  = get_id_waiter(id);
    waiter.wait_on();
    $cast(item, waiter.get_trigger_data());
  endtask

  protected function uvm_event get_waiter();
    uvm_event waiter  = new();
    waiters.push_back(waiter);
    return waiter;
  endfunction

  protected function uvm_event get_id_waiter(tvip_axi_id id);
    uvm_event waiter  = new();
    id_waiters[id].push_back(waiter);
    return waiter;
  endfunction

  `tue_component_default_constructor(tvip_axi_item_waiter)
endclass

class tvip_axi_dispatcher #(
  type  ITEM  = uvm_sequence_item
) extends tue_sequence #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .REQ            (ITEM                   )
);
  protected uvm_sequencer_base  write_sequencer;
  protected uvm_sequencer_base  read_sequencer;

  function new(
    string              name,
    uvm_sequencer_base  write_sequencer,
    uvm_sequencer_base  read_sequencer
  );
    super.new(name);
    this.write_sequencer  = write_sequencer;
    this.read_sequencer   = read_sequencer;
  endfunction

  virtual task dispatch(
    ITEM              item,
    uvm_sequence_base parent_sequence = null,
    bit               wait_for_end    = 0
  );
    uvm_sequencer_base  sequencer;
    
    sequencer = (item.is_write()) ? write_sequencer : read_sequencer;
    if (parent_sequence == null) begin
      parent_sequence = item.get_parent_sequence();
    end
    if (parent_sequence == null) begin
      parent_sequence = this;
    end

    parent_sequence.start_item(item, -1, sequencer);
    parent_sequence.finish_item(item, -1);

    if (item.wait_for_end || wait_for_end) begin
      item.response_end_event.wait_on();
    end
  endtask
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

            SUB_SEQEUENCER              write_sequencer;
            SUB_SEQEUENCER              read_sequencer;
  protected tvip_axi_dispatcher #(ITEM) dispatcher;
  protected tvip_axi_item_waiter        address_item_waiter;
  protected tvip_axi_item_waiter        request_item_waiter;
  protected tvip_axi_item_waiter        response_item_waiter;
  protected tvip_axi_item_waiter        item_waiter;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    write_sequencer = SUB_SEQEUENCER::type_id::create("write_sequencer", this);
    write_sequencer.set_context(configuration, status);

    read_sequencer  = SUB_SEQEUENCER::type_id::create("read_sequencer", this);
    read_sequencer.set_context(configuration, status);

    dispatcher  = new("dispatcher", write_sequencer, read_sequencer);

    address_item_export = new("address_item_export", this);
    address_item_waiter = new("address_item_waiter", this);
    address_item_waiter.set_context(configuration, status);

    request_item_export = new("request_item_export", this);
    request_item_waiter = new("request_item_waiter", this);
    request_item_waiter.set_context(configuration, status);

    response_item_export  = new("response_item_export", this);
    response_item_waiter  = new("response_item_waiter", this);
    response_item_waiter.set_context(configuration, status);

    item_export = new("item_export", this);
    item_waiter = new("item_waiter", this);
    item_waiter.set_context(configuration, status);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    address_item_export.connect(address_item_waiter.analysis_export);
    request_item_export.connect(request_item_waiter.analysis_export);
    response_item_export.connect(response_item_waiter.analysis_export);
    item_export.connect(item_waiter.analysis_export);
  endfunction

  virtual task dispatch(
    ITEM              item,
    uvm_sequence_base parent_sequence = null,
    bit               wait_for_end    = 0
  );
    dispatcher.dispatch(item, parent_sequence, wait_for_end);
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
