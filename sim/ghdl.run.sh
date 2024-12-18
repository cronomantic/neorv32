#!/usr/bin/env bash

set -e

cd $(dirname "$0")

NEORV32_RTL=${NEORV32_RTL:-../rtl}
FILE_LIST=`cat $NEORV32_RTL/file_list_soc.f`
CORE_SRCS="${FILE_LIST//NEORV32_RTL_PATH_PLACEHOLDER/"$NEORV32_RTL"}"
GHDL="${GHDL:-ghdl}"

# Prepare UART SIM_MODE output files
touch neorv32.uart0_sim_mode.out neorv32.uart1_sim_mode.out
chmod 777 neorv32.uart0_sim_mode.out neorv32.uart1_sim_mode.out

# Prepare testbench UART log files
touch neorv32_tb.uart0_rx.out neorv32_tb.uart1_rx.out
chmod 777 neorv32_tb.uart0_rx.out neorv32_tb.uart1_rx.out

# GHDL build directory
mkdir -p build

# GHDL import
$GHDL -i --work=neorv32 --workdir=build \
  $CORE_SRCS \
  "$NEORV32_RTL"/processor_templates/*.vhd \
  "$NEORV32_RTL"/system_integration/*.vhd \
  "$NEORV32_RTL"/test_setups/*.vhd \
  neorv32_tb.vhd \
  sim_uart_rx.vhd \
  xbus_gateway.vhd \
  xbus_memory.vhd

# GHDL analyze
$GHDL -m --work=neorv32 --workdir=build neorv32_tb

# GHDL run parameters
if [ -z "$1" ]
  then
    GHDL_RUN_ARGS="${@:---stop-time=10ms}"
  else
    # Let's pass down all the parameters to GHDL
    GHDL_RUN_ARGS=$@
fi
echo "GHDL simulation run parameters: $GHDL_RUN_ARGS";

# GHDL run
runcmd="$GHDL -r --work=neorv32 --workdir=build neorv32_tb \
  --max-stack-alloc=0 \
  --ieee-asserts=disable \
  --assert-level=error $GHDL_RUN_ARGS"

if [ -n "$GHDL_DEVNULL" ]; then
  $runcmd >> /dev/null
else
  $runcmd
fi
