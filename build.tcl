# Vivado RISC-V Project Creation Script
# Usage: vivado -mode batch -source create_project.tcl

# ========================================
# PROJECT CONFIGURATION
# ========================================

# Project settings
set project_name "riscv_cpu"
set project_dir "./vivado_project"
set top_module "xgriscv_fpga_top"

# FPGA part (Nexys4 DDR uses XC7A100T)
set fpga_part "xc7a100tcsg324-1"

# Source file paths
set board_files [list \
    "board/CLK_DIV.v" \
    "board/dmem.v" \
    "board/MIO_BUS.v" \
    "board/MULTI_CH32.v" \
    "board/SEG7x16.v" \
    "board/xgriscv_fpga_top.v" \
]

set cpu_files [list \
    "cpu/alu.v" \
    "cpu/branch.v" \
    "cpu/cpu.v" \
    "cpu/ctrl.v" \
    "cpu/def.v" \
    "cpu/ext.v" \
    "cpu/forward.v" \
    "cpu/hazard.v" \
    "cpu/rf.v" \
    "cpu/interrupt.v" \
    "cpu/csr.v" \
    "cpu/timer.v" \
]

set constraint_file "board/Nexys4DDR_CPU.xdc"
set coe_file "instr/fpga/riscv-studentnosorting.coe"

# ========================================
# CREATE PROJECT
# ========================================

# Remove existing project if it exists
if {[file exists $project_dir]} {
    file delete -force $project_dir
}

create_project $project_name $project_dir -part $fpga_part -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

# ========================================
# ADD SOURCE FILES
# ========================================

# Add CPU source files
add_files -norecurse $cpu_files

# Add board files
add_files -norecurse $board_files

# ========================================
# ADD CONSTRAINTS
# ========================================

add_files -fileset constrs_1 -norecurse $constraint_file

# ========================================
# CREATE ROM IP CORE
# ========================================

# Create instruction memory ROM IP
create_ip -name dist_mem_gen -vendor xilinx.com -library ip -module_name imem

set_property -dict [list \
    CONFIG.memory_type {ROM} \
    CONFIG.data_width {32} \
    CONFIG.depth {128} \
    CONFIG.coefficient_file [file normalize $coe_file] \
    CONFIG.input_options {non_registered} \
    CONFIG.output_options {non_registered} \
] [get_ips imem]

# Generate IP
generate_target all [get_files imem.xci]

# Optional: Synthesize IP
create_ip_run [get_files imem.xci]
launch_runs imem_synth_1 -jobs 12
wait_on_run imem_synth_1
    
# ========================================
# SET TOP MODULE
# ========================================

# Set top-level module
set_property top $top_module [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# Set synthesis strategy (optional)
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]

# Set implementation strategy (optional)
set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]

reset_run synth_1
launch_runs synth_1 -jobs 12
wait_on_run synth_1

# =============================================================================
# IMPLEMENTATION
# =============================================================================

launch_runs impl_1 -jobs 12
wait_on_run impl_1

# =============================================================================
# BITSTREAM GENERATION
# =============================================================================

launch_runs impl_1 -to_step write_bitstream -jobs 12
wait_on_run impl_1

# =============================================================================
# COMPLETION
# =============================================================================

puts "Build Complete!"