TVIP_AXI_HOME	= $(shell git rev-parse --show-toplevel)
export TVIP_AXI_HOME

TUE_HOME	?= $(TVIP_AXI_HOME)/tue
export TUE_HOME

FILE_LISTS	+= $(TUE_HOME)/compile.f
FILE_LISTS	+= $(TVIP_AXI_HOME)/compile.f

SOURCE_FILES	= $(TVIP_AXI_HOME)/sample/env/top.sv

VCS_ARGS	+= -full64
VCS_ARGS	+= -sverilog
VCS_ARGS	+= -timescale=1ns/1ps
VCS_ARGS	+= -ntb_opts uvm
VCS_ARGS	+= +define+UVM_NO_DEPRECATED+UVM_OBJECT_MUST_HAVE_CONSTRUCTO
VCS_ARGS	+= -top top

compile_simv:
	vcs $(VCS_ARGS) $(addprefix -f , $(FILE_LISTS)) $(SOURCE_FILES)
