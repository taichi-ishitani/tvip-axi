TVIP_AXI_HOME	= $(shell git rev-parse --show-toplevel)
export TVIP_AXI_HOME

TUE_HOME	?= $(TVIP_AXI_HOME)/tue
export TUE_HOME

FILE_LISTS	+= $(TUE_HOME)/compile.f
FILE_LISTS	+= $(TVIP_AXI_HOME)/compile.f
FILE_LISTS	+= $(TVIP_AXI_HOME)/sample/env/compile.f

SOURCE_FILES	= $(TVIP_AXI_HOME)/sample/env/top.sv

SIMULATOR	?= vcs
RANDOM_SEED	?= auto
GUI	?= off

TESTS	+= default
TESTS	+= write_data_delay
TESTS	+= response_start_delay
TESTS	+= response_delay
TESTS	+= ready_delay
TESTS	+= out_of_order_response
TESTS	+= read_interleave

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
	rm -rf $(addprefix */,$(CLEAN_ALL_TARGET))

include vcs.mk
include xcelium.mk
