# Common configuration for all targets
# Mostly for Mercury options.

GRADE?=asm_fast.par.gc.stseg

MMC?=mmc

MMCFLAGS?=--cflags "-g -I$(ROOTDIR)" --ld-flag -g --mercury-linkage static # --opt-level 7 #--intermodule-optimization
MMCCALL=$(MMC) $(MMCFLAGS) -L$(ROOTDIR)/lib --mld $(LIBDIR)/mercury --grade=$(GRADE)
MMCIN=$(MMCCALL) -E -j4 --make
