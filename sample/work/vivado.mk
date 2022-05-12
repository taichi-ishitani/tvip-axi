CLEAN_TARGET += *.pb
CLEAN_TARGET += xsim.dir

XVLOG_ARGS += -sv
XVLOG_ARGS += -log xvlog.log
XVLOG_ARGS += -L uvm
XVLOG_ARGS += -d VIVADO
XVLOG_ARGS += -verbose 2
XVLOG_ARGS += $(subst +incdir+, -i , $(shell cat $(FILE_LISTS) | grep +incdir+))

XELAB_ARGS += -log xelab.log
XELAB_ARGS += -timescale 1ns/1ps
XELAB_ARGS += -L uvm
XELAB_ARGS += -verbose 2
#XELAB_ARGS += -mt off
XELAB_ARGS += -s top
XELAB_ARGS += work.top

compile_vivado:
	xvlog $(XVLOG_ARGS) $(shell cat $(FILE_LISTS) | grep -v +incdir+) $(SOURCE_FILES)
	xelab $(XELAB_ARGS)
