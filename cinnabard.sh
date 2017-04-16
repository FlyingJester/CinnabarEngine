#!/bin/sh
export LD_LIBRARY_PATH=$(dirname $0)/lib
valgrind $(dirname $0)/src/cinnabar
