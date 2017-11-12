# Common configuration for all targets
# Mostly for Mercury options.

#GRADE?=asm_fast.par.gc.stseg
GRADE?=hlc.gc

MMC?=mmc
WARNINGS=--warn-non-tail-recursion --warn-suspicious-foreign-procs
#MMCFLAGS?=--cflag -g -I $(ROOTDIR) -I /usr/local/include --ld-flag -g -L /usr/local/lib --no-strip $(WARNINGS) # --mercury-linkage static
MMCFLAGS?=--cflags "-g -I$(ROOTDIR) -I/usr/local/include" --ld-flags "-g -L/usr/local/lib" --no-strip $(WARNINGS) # --mercury-linkage static
# --opt-level 7 #--intermodule-optimization
MMCCALL=$(MMC) $(MMCFLAGS) -L$(ROOTDIR)/lib --grade=$(GRADE)
# --mld $(LIBDIR)/mercury
MMCIN=$(MMCCALL) -E -j4 --make
