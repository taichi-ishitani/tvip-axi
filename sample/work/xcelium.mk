XRUN_COMMON_ARGS	+= -64bit
XRUN_COMMON_ARGS	+= -timedetail
XRUN_COMMON_ARGS	+= -status

XMVLOG_ARGS	+= -compile
XMVLOG_ARGS	+= -uvmhome CDNS-1.1d
XMVLOG_ARGS	+= -plusperf
XMVLOG_ARGS	+= -l xmvlog.log

XMELAB_ARGS	+= -elaborate
XMELAB_ARGS	+= -uvmhome CDNS-1.1d
XMELAB_ARGS	+= -uvmnoautocompile
XMELAB_ARGS	+= -timescale 1ns/1ps
XMELAB_ARGs	+= -newperf
XMELAB_ARGS	+= -top worklib.top
XMELAB_ARGS	+= -l xmelab.log

XMSIM_ARGS	+= -R
XMSIM_ARGS	+= -uvmhome CDNS-1.1d
XMSIM_ARGS	+= -xmlibdirname ../xcelium.d
XMSIM_ARGS	+= -xceligen on
XMSIM_ARGS	+= -f test.f
XMSIM_ARGS	+= -l xmsim.log

ifeq ($(strip $(RANDOM_SEED)), auto)
	XMSIM_ARGS	+= -svseed random
else
	XMSIM_ARGS	+= -svseed $(RANDOM_SEED)
endif

ifeq ($(GUI), indago)
	XMVLOG_ARGS	+= -classlinedebug
	XMELAB_ARGS	+= -xmdebug
	XMELAB_ARGS	+= -lwdgen
	XMSIM_ARGS	+= -gui -indago
	XMSIM_ARGS	+= -input @"ida_probe -log"
	XMSIM_ARGS	+= -input @"ida_probe -wave -wave_probe_args=\"-all -depth to_cells\""
endif

CLEAN_TARGET	+= xcelium.d
CLEAN_TARGET	+= *.history

CLEAN_ALL_TARGET	+= ida.db
CLEAN_ALL_TARGET	+= .ida*
CLEAN_ALL_TARGET	+= indago_logs

.PHONY: sim_xcelium compile_xcelium

sim_xcelium:
	(xmls -64bit -nolog -snapshot | grep SSS) || $(MAKE) compile_xcelium
	cd $(TEST); xrun $(XRUN_COMMON_ARGS) $(XMSIM_ARGS)

compile_xcelium:
	xrun $(XRUN_COMMON_ARGS) $(XMVLOG_ARGS) $(addprefix -f , $(FILE_LISTS)) $(SOURCE_FILES)
	xrun $(XRUN_COMMON_ARGS) $(XMELAB_ARGS)
