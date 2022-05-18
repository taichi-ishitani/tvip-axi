CLEAN_TARGET += *.pb
CLEAN_TARGET += *.jou
CLEAN_TARGET += *.wdb
CLEAN_TARGET += vivado_*.str
CLEAN_TARGET += xsim.dir
CLEAN_TARGET += .Xil

XVLOG_ARGS += -sv
XVLOG_ARGS += -log xvlog.log
XVLOG_ARGS += -L uvm
XVLOG_ARGS += -verbose 2
XVLOG_ARGS += $(subst +incdir+, -i , $(shell cat $(FILE_LISTS) | grep +incdir+))
XVLOG_ARGS += $(shell cat $(FILE_LISTS) | grep -v +incdir+)

XELAB_ARGS += -log xelab.log
XELAB_ARGS += -verbose 2
XELAB_ARGS += -timescale 1ns/1ps
XELAB_ARGS += -L uvm
XELAB_ARGS += top

XSIM_ARGS += work.top
XSIM_ARGS += -log $(TEST)/xsim.log
XSIM_ARGS += -f $(TEST)/test.f

ifeq ($(strip $(GUI)), on)
  XELAB_ARGS += -debug all
	XSIM_ARGS  += -gui
else
	XSIM_ARGS += -R
endif

.PHONY: sim_vivado compile_vivado

sim_vivado:
	[ -d xsim.dir ] || ($(MAKE) compile_vivado)
	xsim $(XSIM_ARGS)

compile_vivado:
	xvlog $(XVLOG_ARGS) $(SOURCE_FILES)
	xelab $(XELAB_ARGS)
