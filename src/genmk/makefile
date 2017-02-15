all: genmk 

.include "../common.mk"

genmk: genmk.m readdir.m makefile_parser.m readdir_c.c readdir_h.h
	$(MMCIN) genmk

clean:
	$(MMCIN) genmk.clean

.IGNORE: clean
.PHONY: clean
.SILENT: clean
