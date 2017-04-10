#!/bin/sh
export LD_LIBRARY_PATH=$(dirname $0)/lib
gdb $(dirname $0)/src/cinnabar
