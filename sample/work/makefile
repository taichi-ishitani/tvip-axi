TVIP_AXI_HOME	= $(shell git rev-parse --show-toplevel)
export TVIP_AXI_HOME

TUE_HOME	?= $(TVIP_AXI_HOME)/tue
export TUE_HOME

FILE_LISTS	+= $(TUE_HOME)/compile.f
FILE_LISTS	+= $(TVIP_AXI_HOME)/compile.f
FILE_LISTS	+= $(TVIP_AXI_HOME)/sample/env/compile.f

SOURCE_FILES	= $(TVIP_AXI_HOME)/sample/env/top.sv

VCS_ARGS	+= -full64
VCS_ARGS	+= -sverilog
VCS_ARGS	+= -l compile.log
VCS_ARGS	+= -timescale=1ns/1ps
VCS_ARGS	+= -ntb_opts uvm
VCS_ARGS	+= +define+UVM_NO_DEPRECATED+UVM_OBJECT_MUST_HAVE_CONSTRUCTO
VCS_ARGS	+= -top top

SIMV_ARGS	+= -l sim.log
SIMV_ARGS	+= -f test.f

RANDOM_SEED	?= auto
ifeq ($(strip $(RANDOM_SEED)), auto)
	SIMV_ARGS	+= +ntb_random_seed_automatic
else
	SIMV_ARGS	+= +ntb_random_seed=$(RANDOM_SEED)
endif

GUI	=? off
ifeq ($(strip $(GUI)), dve)
	VCS_ARGS	+= -debug_access+all
	VCS_ARGS	+= +vcs+vcdpluson
	SIMV_ARGS	+= -gui=dve
endif

TESTS	+= default
TESTS += write_data_delay
TESTS += response_start_delay
TESTS	+= response_delay
TESTS += ready_delay
TESTS += read_interleave

TEST_TARGETS	= $(addprefix sim_, $(TESTS))

all: $(TEST_TARGETS)

$(TEST_TARGETS):
	make run_simv TEST=$(subst sim_,,$@)

run_simv:
	if [ ! -f simv ] ; then \
		make compile_simv; \
	fi
	cd $(TEST); ../simv $(SIMV_ARGS)

compile_simv:
	vcs $(VCS_ARGS) $(addprefix -f , $(FILE_LISTS)) $(SOURCE_FILES)

clean:
	rm -rf simv* csrc *.h *.log

clean_all:
	make clean
	rm -rf */*.log */*.vpd */*.key */DVEfiles */.inter.vpd.uvm
