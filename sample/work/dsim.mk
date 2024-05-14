DSIM_COMP_ARGS += -genimage image
DSIM_COMP_ARGS += -uvm $(UVM_VERSION)
DSIM_COMP_ARGS += -l dsim_comp.log
DSIM_COMP_ARGS += -timescale 1ns/1ps
DSIM_COMP_ARGS += +define+UVM_NO_DEPRECATED
DSIM_COMP_ARGS += +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTO
DSIM_COMP_ARGS += -top top

DSIM_SIM_ARGS += -work ../dsim_work
DSIM_SIM_ARGS += -image image
DSIM_SIM_ARGS += -uvm $(UVM_VERSION)
DSIM_SIM_ARGS += -l dsim_simulation.log
DSIM_SIM_ARGS += -f test.f

ifneq ($(strip $(RANDOM_SEED)), auto)
  DSIM_SIM_ARGS += -sv_seed $(RANDOM_SEED)
endif

ifeq ($(strip $(DUMP)), vcd)
	DSIM_COMP_ARGS += +acc
	DSIM_SIM_ARGS += -waves dump.vcd
endif

CLEAN_TARGET += dsim.env
CLEAN_TARGET += dsim_work
CLEAN_TARGET += */dsim.env
CLEAN_TARGET += */metrics.db

CLEAN_ALL_TARGET += *.vcd

.PHONY: sim_dsim compile_dsim

sim_dsim:
	[ -f dsim_work/image.so ] || ($(MAKE) compile_dsim)
	cd $(TEST); dsim $(DSIM_SIM_ARGS)

compile_dsim:
	dsim $(DSIM_COMP_ARGS) $(addprefix -f , $(FILE_LISTS)) $(SOURCE_FILES)
