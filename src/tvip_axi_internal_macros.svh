`ifndef TVIP_AXI_INTERNAL_MACROS_SVH
`define TVIP_AXI_INTERNAL_MACROS_SVH

`define tvip_axi_select_delay_configuration(ACCESS_TYPE, WRITE_CONFIGURATION, READ_CONFIGURATION) \
( \
  (ACCESS_TYPE == TVIP_AXI_WRITE_ACCESS) ? this.configuration.WRITE_CONFIGURATION \
                                         : this.configuration.READ_CONFIGURATION \
)

`define tvip_axi_declare_delay_consraint(DELAY, MIN, MID_0, MID_1, MAX, WEIGHT_ZERO_DELAY, WEIGHT_SHORT_DELAY, WEIGHT_LONG_DELAY, VALID_CONDITION = 1) \
constraint c_valid_``DELAY { \
  if (VALID_CONDITION && (MAX > MIN)) { \
    (DELAY inside {[MIN:MID_0]}) || (DELAY inside {[MID_1:MAX]}); \
    if (MIN == 0) { \
      DELAY dist { \
        0           := WEIGHT_ZERO_DELAY, \
        [1:MID_0]   :/ WEIGHT_SHORT_DELAY, \
        [MID_1:MAX] :/ WEIGHT_LONG_DELAY \
      }; \
    } \
    else { \
      DELAY dist { \
        [MIN:MID_0] :/ WEIGHT_SHORT_DELAY, \
        [MID_1:MAX] :/ WEIGHT_LONG_DELAY \
      }; \
    } \
  } \
  else { \
    DELAY == 0; \
  } \
}

`define tvip_axi_declare_delay_consraint_array(DELAY, MIN, MID_0, MID_1, MAX, WEIGHT_ZERO_DELAY, WEIGHT_SHORT_DELAY, WEIGHT_LONG_DELAY) \
constraint c_valid_``DELAY { \
  if (MAX > MIN) { \
    foreach (DELAY[i]) { \
      (DELAY[i] inside {[MIN:MID_0]}) || (DELAY[i] inside {[MID_1:MAX]}); \
      if (MIN == 0) { \
        DELAY[i] dist { \
          0           := WEIGHT_ZERO_DELAY, \
          [1:MID_0]   :/ WEIGHT_SHORT_DELAY, \
          [MID_1:MAX] :/ WEIGHT_LONG_DELAY \
        }; \
      } \
      else { \
        DELAY[i] dist { \
          [MIN:MID_0] :/ WEIGHT_SHORT_DELAY, \
          [MID_1:MAX] :/ WEIGHT_LONG_DELAY \
        }; \
      } \
    } \
  } \
  else { \
    foreach (DELAY[i]) { \
      DELAY[i] == 0; \
    } \
  } \
}

`endif