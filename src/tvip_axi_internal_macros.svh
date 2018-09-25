`ifndef TVIP_AXI_INTERNAL_MACROS_SVH
`define TVIP_AXI_INTERNAL_MACROS_SVH

`define tvip_axi_declare_delay_size_constraints(DELAY_TYPE) \
constraint c_valid_max_min_``DELAY_TYPE``_delay { \
  max_``DELAY_TYPE``_delay >= -1; \
  min_``DELAY_TYPE``_delay >= -1; \
  max_``DELAY_TYPE``_delay >= min_``DELAY_TYPE``_delay; \
} \
constraint c_default_max_min_``DELAY_TYPE``_delay { \
  soft max_``DELAY_TYPE``_delay == -1; \
  soft min_``DELAY_TYPE``_delay == -1; \
} \
constraint c_valid_mid_``DELAY_TYPE``_delay { \
  solve max_``DELAY_TYPE``_delay before mid_``DELAY_TYPE``_delay; \
  solve min_``DELAY_TYPE``_delay before mid_``DELAY_TYPE``_delay; \
  mid_``DELAY_TYPE``_delay[0] inside {-1, [min_``DELAY_TYPE``_delay:max_``DELAY_TYPE``_delay]}; \
  mid_``DELAY_TYPE``_delay[1] inside {-1, [min_``DELAY_TYPE``_delay:max_``DELAY_TYPE``_delay]}; \
  if (get_delay_delta(max_``DELAY_TYPE``_delay, min_``DELAY_TYPE``_delay) >= 1) { \
    if ((mid_``DELAY_TYPE``_delay[0] >= 0) || (mid_``DELAY_TYPE``_delay[1] >= 0)) { \
      mid_``DELAY_TYPE``_delay[0] < mid_``DELAY_TYPE``_delay[1]; \
    } \
    if (get_min_delay(min_``DELAY_TYPE``_delay) == 0) { \
      mid_``DELAY_TYPE``_delay[0] > 0; \
    } \
  } \
  else { \
    mid_``DELAY_TYPE``_delay[0] == -1; \
    mid_``DELAY_TYPE``_delay[1] == -1; \
  } \
} \
constraint c_default_mid_``DELAY_TYPE``_delay { \
  soft mid_``DELAY_TYPE``_delay[0] == -1; \
  soft mid_``DELAY_TYPE``_delay[1] == -1; \
} \
constraint c_valid_``DELAY_TYPE``_delay_weight { \
  solve max_``DELAY_TYPE``_delay before ``DELAY_TYPE``_delay_weight; \
  solve min_``DELAY_TYPE``_delay before ``DELAY_TYPE``_delay_weight; \
  foreach (``DELAY_TYPE``_delay_weight[i]) { \
    ``DELAY_TYPE``_delay_weight[i] >= -1; \
    if (get_delay_delta(max_``DELAY_TYPE``_delay, min_``DELAY_TYPE``_delay) == 0) { \
      ``DELAY_TYPE``_delay_weight[i] == 0; \
    } \
  } \
  if (min_``DELAY_TYPE``_delay > 0) { \
    ``DELAY_TYPE``_delay_weight[TVIP_AXI_ZERO_DELAY] == 0; \
  } \
  if ((min_``DELAY_TYPE``_delay <= 0) && (max_``DELAY_TYPE``_delay == 1)) { \
    ``DELAY_TYPE``_delay_weight[TVIP_AXI_SHORT_DELAY] == 0; \
  } \
} \
constraint c_default_``DELAY_TYPE``_delay_weight { \
  foreach (``DELAY_TYPE``_delay_weight[i]) { \
    soft ``DELAY_TYPE``_delay_weight[i] == -1; \
  } \
}

`define tvip_axi_declare_delay_consraint(DELAY, MIN, MID_0, MID_1, MAX, WEIGHT_ZERO_DELAY, WEIGHT_SHORT_DELAY, WEIGHT_LONG_DELAY, VALID_CONDITION = 1) \
constraint c_valid_``DELAY { \
  if (VALID_CONDITION) { \
    ((DELAY >= MIN) && (DELAY <= MID_0)) || ((DELAY >= MID_1) && (DELAY >= MAX)); \
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
  foreach (DELAY[i]) { \
    ((DELAY[i] >= MIN) && (DELAY[i] <= MID_0)) || ((DELAY[i] >= MID_1) && (DELAY[i] <= MAX)); \
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
}

`endif
