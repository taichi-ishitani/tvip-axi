`ifndef TVIP_AXI_SEQUENCER_BASE_SVH
`define TVIP_AXI_SEQUENCER_BASE_SVH
class tvip_axi_item_waiter #(
  type  ITEM  = uvm_sequence_item
) extends tue_subscriber #(
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        ),
  .T              (ITEM                   )
);
  protected uvm_event waiters[$];
  protected uvm_event id_waiters[tvip_axi_id][$];

  function void write(ITEM t);
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

  task get_item(ref ITEM  item);
    uvm_event waiter  = get_waiter();
    waiter.wait_on();
    $cast(item, waiter.get_trigger_data());
  endtask

  task get_item_by_id(ref ITEM item, input tvip_axi_id id);
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

virtual class tvip_axi_sequencer_base #(
  type  BASE            = uvm_sequencer,
  type  SUB_SEQEUENCER  = uvm_sequencer,
  type  ITEM            = uvm_sequence_item
) extends BASE;
  uvm_analysis_export #(ITEM) address_item_export;
  uvm_analysis_export #(ITEM) request_item_export;
  uvm_analysis_export #(ITEM) response_item_export;
  uvm_analysis_export #(ITEM) item_export;

  protected tvip_axi_item_waiter #(ITEM)  address_item_waiter;
  protected tvip_axi_item_waiter #(ITEM)  request_item_waiter;
  protected tvip_axi_item_waiter #(ITEM)  response_item_waiter;
  protected tvip_axi_item_waiter #(ITEM)  item_waiter;

  SUB_SEQEUENCER  write_sequencer;
  SUB_SEQEUENCER  read_sequencer;
  SUB_SEQEUENCER  sub_sequencer[tvip_axi_access_type];

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

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

  `define tvip_axi_define_item_getter_tasks(ITEM_TYPE) \
  virtual task get_``ITEM_TYPE``(ref ITEM item); \
    ``ITEM_TYPE``_waiter.get_item(item); \
  endtask \
  virtual task get_``ITEM_TYPE``_by_id(ref ITEM item, input tvip_axi_id id); \
    ``ITEM_TYPE``_waiter.get_item_by_id(item, id); \
  endtask

  `tvip_axi_define_item_getter_tasks(address_item )
  `tvip_axi_define_item_getter_tasks(request_item )
  `tvip_axi_define_item_getter_tasks(response_item)
  `tvip_axi_define_item_getter_tasks(item         )

  `undef  tvip_axi_define_item_getter_tasks

  function void set_sub_sequencer(SUB_SEQEUENCER sequencer, tvip_axi_access_type access_type);
    sub_sequencer[access_type]  = sequencer;
    case (access_type)
      TVIP_AXI_WRITE_ACCESS:  write_sequencer = sequencer;
      TVIP_AXI_READ_ACCESS:   read_sequencer  = sequencer;
    endcase
  endfunction

  `tue_component_default_constructor(pzvip_ocp_sequencer_base)
endclass
`endif
