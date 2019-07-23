`ifndef TVIP_AXI_MEMORY_SVH
`define TVIP_AXI_MEMORY_SVH
class tvip_axi_memory extends tue_object_base #(
  .BASE           (uvm_object             ),
  .CONFIGURATION  (tvip_axi_configuration ),
  .STATUS         (tvip_axi_status        )
);
  protected int               byte_width;
  protected byte              memory[tvip_axi_address];
  protected tvip_axi_address  address_mask[int];

  function void set_configuration(tue_configuration configuration);
    super.set_configuration(configuration);
    byte_width  = this.configuration.data_width / 8;
  endfunction

  function void put(
    tvip_axi_data     data,
    tvip_axi_strobe   strobe,
    int               size,
    tvip_axi_address  base,
    int               offset
  );
    tvip_axi_address  address = base & get_address_mask(size);
    for (int i = 0;i < size;++i) begin
      tvip_axi_address  memory_index  = (address + size * offset + i);
      int               byte_index    = memory_index % byte_width;
      if (strobe[byte_index]) begin
        memory[memory_index]  = data[8*byte_index+:8];
      end
    end
  endfunction

  function tvip_axi_data get(
    int               size,
    tvip_axi_address  base,
    int               offset
  );
    tvip_axi_data     data;
    tvip_axi_address  address = base & get_address_mask(size);
    for (int i = 0;i < size;++i) begin
      tvip_axi_address  memory_index  = address + size * offset + i;
      int               byte_index    = memory_index % byte_width;
      if (memory.exists(memory_index)) begin
        data[8*byte_index+:8] = memory[memory_index];
      end
    end
    return data;
  endfunction

  function bit exists(int size, tvip_axi_address base, int offset);
    tvip_axi_address  address       = base & get_address_mask(size);
    for (int i = 0;i < size;++i) begin
      tvip_axi_address  memory_index  = address + size * offset + i;
      if (memory.exists(memory_index)) begin
        return 1;
      end
    end
    return 0;
  endfunction

  protected function tvip_axi_address get_address_mask(int burst_size);
    if (!address_mask.exists(burst_size)) begin
      tvip_axi_address  mask;
      mask                      = burst_size - 1;
      address_mask[burst_size]  = ~mask;
    end
    return address_mask[burst_size];
  endfunction

  `tue_object_default_constructor(tvip_axi_memory)
  `uvm_object_utils(tvip_axi_memory)
endclass
`endif
