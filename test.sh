#!/bin/sh
export LD_LIBRARY_PATH=$(dirname $0)/lib
$(dirname $0)/test
