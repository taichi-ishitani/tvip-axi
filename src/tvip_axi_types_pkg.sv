`ifndef TVIP_AXI_TYPES_PKG_SV
`define TVIP_AXI_TYPES_PKG_SV
package tvip_axi_types_pkg;
  `include  "tvip_axi_defines.svh"

  typedef bit [`TVIP_AXI_MAX_ID_WIDTH-1:0]  tvip_axi_id;

  typedef bit [`TVIP_AXI_MAX_ADDRESS_WIDTH-1:0] tvip_axi_address;

  typedef bit [7:0] tvip_axi_burst_length;

  function automatic tvip_axi_burst_length pack_burst_length(int burst_length);
    if (burst_length inside {[1:256]}) begin
      return tvip_axi_burst_length'(burst_length - 1);
    end
    else begin
      ; //  TBD
    end
  endfunction

  function automatic int unpack_burst_length(tvip_axi_burst_length burst_length);
    return int'(burst_length) + 1;
  endfunction

  typedef bit [3:0] tvip_axi_qos;

  typedef enum bit [2:0] {
    TVIP_AXI_BURST_SIZE_1_BYTE    = 'b000,
    TVIP_AXI_BURST_SIZE_2_BYTES   = 'b001,
    TVIP_AXI_BURST_SIZE_4_BYTES   = 'b010,
    TVIP_AXI_BURST_SIZE_8_BYTES   = 'b011,
    TVIP_AXI_BURST_SIZE_16_BYTES  = 'b100,
    TVIP_AXI_BURST_SIZE_32_BYTES  = 'b101,
    TVIP_AXI_BURST_SIZE_64_BYTES  = 'b110,
    TVIP_AXI_BURST_SIZE_128_BYTES = 'b111
  } tvip_axi_burst_size;

  function automatic tvip_axi_burst_size pack_burst_size(int burst_size);
    case (burst_size)
      1:        return  TVIP_AXI_BURST_SIZE_1_BYTE;
      2:        return  TVIP_AXI_BURST_SIZE_2_BYTES;
      4:        return  TVIP_AXI_BURST_SIZE_4_BYTES;
      8:        return  TVIP_AXI_BURST_SIZE_8_BYTES;
      16:       return  TVIP_AXI_BURST_SIZE_16_BYTES;
      32:       return  TVIP_AXI_BURST_SIZE_32_BYTES;
      64:       return  TVIP_AXI_BURST_SIZE_64_BYTES;
      128:      return  TVIP_AXI_BURST_SIZE_128_BYTES;
      default:  ; //  TBD
    endcase
  endfunction

  function automatic int unpack_burst_size(tvip_axi_burst_size burst_size);
    case (burst_size)
      TVIP_AXI_BURST_SIZE_1_BYTE:     return  1;
      TVIP_AXI_BURST_SIZE_2_BYTES:    return  2;
      TVIP_AXI_BURST_SIZE_4_BYTES:    return  4;
      TVIP_AXI_BURST_SIZE_8_BYTES:    return  8;
      TVIP_AXI_BURST_SIZE_16_BYTES:   return  16;
      TVIP_AXI_BURST_SIZE_32_BYTES:   return  32;
      TVIP_AXI_BURST_SIZE_64_BYTES:   return  64;
      TVIP_AXI_BURST_SIZE_128_BYTES:  return  128;
    endcase
  endfunction

  typedef enum bit [1:0] {
    TVIP_AXI_FIXED_BURST        = 'b00,
    TVIP_AXI_INCREMENTING_BURST = 'b01,
    TVIP_AXI_WRAPPING_BURST     = 'b10
  } tvip_axi_burst_type;

  typedef bit [`TVIP_AXI_MAX_DATA_WIDTH-1:0]  tvip_axi_data;

  typedef bit [`TVIP_AXI_MAX_DATA_WIDTH/8-1:0]  tvip_axi_strobe;

  typedef enum bit [1:0] {
    TVIP_AXI_OKAY         = 'b00,
    TVIP_AXI_EXOKAY       = 'b01,
    TVIP_AXI_SLAVE_ERROR  = 'b10,
    TVIP_AXI_DECODE_ERROR = 'b11
  } tvip_axi_response;

  typedef enum {
    TVIP_AXI4,
    TVIP_AXI4LITE
  } tvip_axi_protocol;

  typedef enum {
    TVIP_AXI_IN_ORDER,
    TVIP_AXI_OUT_OF_ORDER
  } tvip_axi_ordering_mode;

  typedef enum {
    TVIP_AXI_WRITE_ACCESS,
    TVIP_AXI_READ_ACCESS
  } tvip_axi_access_type;
endpackage
`endif
