VCS_ARGS	+= -full64
VCS_ARGS	+= -lca
VCS_ARGS	+= -sverilog
VCS_ARGS	+= -l compile.log
VCS_ARGS	+= -timescale=1ns/1ps
VCS_ARGS	+= -ntb_opts uvm
VCS_ARGS	+= +define+UVM_NO_DEPRECATED+UVM_OBJECT_MUST_HAVE_CONSTRUCTO
VCS_ARGS	+= -top top

SIMV_ARGS	+= -l simv.log
SIMV_ARGS	+= -f test.f

ifeq ($(strip $(RANDOM_SEED)), auto)
	SIMV_ARGS	+= +ntb_random_seed_automatic
else
	SIMV_ARGS	+= +ntb_random_seed=$(RANDOM_SEED)
endif

ifeq ($(strip $(DUMP)), vpd)
	VCS_ARGS	+= -debug_access
	VCS_ARGS	+= +vcs+vcdpluson
	SIMV_ARGS	+= -vpd_file dump.vpd
endif

ifeq ($(strip $(DUMP)), fsdb)
	VCS_ARGS	+= -debug_access
	VCS_ARGS	+= -kdb
	VCS_ARGS	+= +vcs+fsdbon
	SIMV_ARGS	+= +fsdbfile+dump.fsdb
endif

ifeq ($(strip $(GUI)), dve)
	VCS_ARGS	+= -debug_access+all
	VCS_ARGS	+= +vcs+vcdpluson
	SIMV_ARGS	+= -gui=dve
endif

ifeq ($(strip $(GUI)), verdi)
	VCS_ARGS	+= -debug_access+all
	VCS_ARGS	+= -kdb
	VCS_ARGS	+= +vcs+fsdbon
	SIMV_ARGS	+= -gui=verdi
endif

CLEAN_TARGET	+= simv*
CLEAN_TARGET	+= csrc
CLEAN_TARGET	+= *.h

CLEAN_ALL_TARGET += *.vpd
CLEAN_ALL_TARGET += *.fsdb
CLEAN_ALL_TARGET += *.key
CLEAN_ALL_TARGET += *.conf
CLEAN_ALL_TARGET += *.rc
CLEAN_ALL_TARGET += DVEfiles
CLEAN_ALL_TARGET += verdiLog
CLEAN_ALL_TARGET += .inter.vpd.uvm

.PHONY: sim_vcs compile_vcs

sim_vcs:
	[ -f simv ] || ($(MAKE) compile_vcs)
	cd $(TEST); ../simv $(SIMV_ARGS)

compile_vcs:
	vcs $(VCS_ARGS) $(addprefix -f , $(FILE_LISTS)) $(SOURCE_FILES)
