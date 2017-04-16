# Common configuration for all targets
# Mostly for Mercury options.

#GRADE?=asm_fast.par.gc.stseg
GRADE?=hlc.gc

MMC?=mmc
WARNINGS=--warn-non-tail-recursion --warn-suspicious-foreign-procs
MMCFLAGS?=--cflags "-g -I$(ROOTDIR)" --ld-flag -g --no-strip $(WARNINGS) # --mercury-linkage static
# --opt-level 7 #--intermodule-optimization
MMCCALL=$(MMC) $(MMCFLAGS) -L$(ROOTDIR)/lib --mld $(LIBDIR)/mercury --grade=$(GRADE)
MMCIN=$(MMCCALL) -E -j4 --make
