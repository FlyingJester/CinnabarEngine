# Common configuration for all targets
# Mostly for Mercury options.

GRADE?=asm_fast.par.gc.stseg

MMC?=mmc

MMCFLAGS?=--cflags -g  --ld-flag -g --mercury-linkage static --opt-level 7 --intermodule-optimization 
MMCCALL=$(MMC) $(MMCFLAGS) -L./ --mld lib/mercury --grade=$(GRADE)
MMCIN=$(MMCCALL) -E -j4 --make
