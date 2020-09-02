TVIP_AXI_HOME	= $(shell git rev-parse --show-toplevel)
export TVIP_AXI_HOME

TUE_HOME	?= $(TVIP_AXI_HOME)/tue
export TUE_HOME

TVIP_COMMON_HOME	?= $(TVIP_AXI_HOME)/tvip-common
export TVIP_COMMON_HOME

FILE_LISTS	+= $(TUE_HOME)/compile.f
FILE_LISTS	+= $(TVIP_COMMON_HOME)/compile.f
FILE_LISTS	+= $(TVIP_AXI_HOME)/compile.f
FILE_LISTS	+= $(TVIP_AXI_HOME)/sample/env/compile.f

SOURCE_FILES	+= $(TVIP_AXI_HOME)/sample/env/tvip_axi_sample_delay.sv
SOURCE_FILES	+= $(TVIP_AXI_HOME)/sample/env/top.sv

SIMULATOR	?= vcs
RANDOM_SEED	?= auto
DUMP	?= off
GUI	?= off

TESTS	+= default
TESTS	+= request_delay
TESTS	+= response_delay
TESTS	+= ready_delay
TESTS	+= out_of_order_response
TESTS	+= read_interleave
TESTS	+= wvalid_preceding_awvalid

.PHONY: all $(TESTS) clean clean_all

all: $(TESTS)

$(TESTS):
	make sim_$(SIMULATOR) TEST=$@

CLEAN_TARGET	+= *.log
CLEAN_ALL_TARGET += *.log
CLEAN_ALL_TARGET += *.key

clean:
	rm -rf $(CLEAN_TARGET)

clean_all:
	make clean
	rm -rf $(CLEAN_ALL_TARGET)
	rm -rf $(addprefix */,$(CLEAN_ALL_TARGET))

include vcs.mk
include xcelium.mk
