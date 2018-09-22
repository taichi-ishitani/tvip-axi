`ifndef TVIP_AXI_PAYLOAD_STORE_SVH
`define TVIP_AXI_PAYLOAD_STORE_SVH
class tvip_axi_payload_store;
        tvip_axi_item     item;
  local tvip_axi_data     data[$];
  local tvip_axi_strobe   strobe[$];
  local tvip_axi_response response[$];

  static function tvip_axi_payload_store create(tvip_axi_item item);
    tvip_axi_payload_store  payload_store = new;
    payload_store.item  = item;
    return payload_store;
  endfunction

  function void store_write_data(
    tvip_axi_data   data,
    tvip_axi_strobe strobe
  );
    if (item.is_write()) begin
      this.data.push_back(data);
      this.strobe.push_back(strobe);
    end
  endfunction

  function void store_response(
    tvip_axi_response response,
    tvip_axi_data     data
  );
    this.response.push_back(response);
    if (item.is_read()) begin
      this.data.push_back(data);
    end
  endfunction

  function void pack_item();
    item.put_data(data);
    if (item.is_write()) begin
      item.put_strobe(strobe);
    end
    item.put_response(response);
  endfunction

  function int get_stored_write_data_count();
    if (item.is_write()) begin
      return data.size();
    end
    else begin
      return 0;
    end
  endfunction

  function int get_stored_response_count();
    return response.size();
  endfunction
endclass
`endif
