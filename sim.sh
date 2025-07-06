#!/bin/bash

# Enhanced simulation script with configurable instruction file
# Usage: ./run_sim [directory] [sim_number]
# Examples: 
#   ./run_sim forwarding 1       (runs instr/forwarding/sim1.dat)
#   ./run_sim non_forwarding 6   (runs instr/non_forwarding/sim6.dat)  
#   ./run_sim 6                  (runs instr/non_forwarding/sim6.dat - default dir)
#   ./run_sim                    (runs instr/non_forwarding/sim5.dat - default)

# Default values
DEFAULT_DIR="non_forwarding"
DEFAULT_SIM="sim5"

# Parse command line arguments
if [ $# -eq 0 ]; then
    DIR=$DEFAULT_DIR
    SIM=$DEFAULT_SIM
    echo "No arguments specified. Using default: instr/${DIR}/${SIM}.dat"
elif [ $# -eq 1 ]; then
    # Check if argument is a number (sim file) or directory name
    case $1 in
        ''|*[!0-9]*) 
            DIR=$1
            SIM=$DEFAULT_SIM
            echo "Using instruction file: instr/${DIR}/${SIM}.dat"
            ;;
        *) 
            DIR=$DEFAULT_DIR
            SIM=$1
            echo "Using instruction file: instr/${DIR}/${SIM}.dat"
            ;;
    esac
elif [ $# -eq 2 ]; then
    DIR=$1
    SIM=$2
    echo "Using instruction file: instr/${DIR}/${SIM}.dat"
else
    echo "Usage: $0 [directory] [sim_number]"
    echo "Available directories:"
    ls -1 instr/ | grep -v '\.'
    echo "Available sim files:"
    find instr/ -name "sim*.dat" | sort
    exit 1
fi

# Set the instruction file path
INSTR_FILE="\"./instr/${DIR}/${SIM}.dat\""

# Check if the instruction file exists
if [ ! -f "./instr/${DIR}/${SIM}.dat" ]; then
    echo "Error: Instruction file instr/${DIR}/${SIM}.dat not found!"
    echo ""
    echo "Available directories:"
    ls -1 instr/ | grep -v '\.'
    echo ""
    echo "Available sim files:"
    find instr/ -name "sim*.dat" | sort
    exit 1
fi

echo "Compiling with instruction file: ${INSTR_FILE}"

# Compile with the specified instruction file including interrupt support
iverilog -I cpu -D INSTR_FILE=${INSTR_FILE} -o cpu_sim.out \
    cpu/def.v cpu/alu.v cpu/ctrl.v cpu/ext.v cpu/rf.v \
    cpu/hazard.v cpu/forward.v cpu/branch.v cpu/interrupt.v cpu/csr.v \
    cpu/cpu.v cpu/comp.v cpu/comp_tb.v cpu/trap.v cpu/timer.v cpu/external_int_gen.v \
    cpu/mem.v

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

echo "Running simulation..."
vvp cpu_sim.out

echo "Simulation complete!"
echo "VCD file: cpu.vcd"