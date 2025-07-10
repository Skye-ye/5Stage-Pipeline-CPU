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
    "board/uart.v" \
    "board/xgriscv_fpga_top.v" \
    "board/timer.v" \
    "board/external_int.v" \
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
    "cpu/trap.v" \
]

set constraint_file "board/Nexys4DDR_CPU.xdc"
set coe_file "instr/interrupt/program.coe"

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
# CREATE INSTRUCTION MEMORY (ROM) IP CORE
# ========================================

puts "Creating Distributed Memory Generator IP for instruction memory (ROM)..."

# Check if COE file exists
if {![file exists $coe_file]} {
    puts "ERROR: COE file not found: $coe_file"
    puts "Please generate the COE file first using the build process in instr/interrupt/"
    exit 1
}

# Create Distributed Memory Generator IP for instruction memory (ROM)
create_ip -name dist_mem_gen -vendor xilinx.com -library ip -module_name imem

# Configure the Distributed Memory Generator for ROM
set_property -dict [list \
    CONFIG.memory_type {ROM} \
    CONFIG.data_width {32} \
    CONFIG.depth {1024} \
    CONFIG.coefficient_file [file normalize $coe_file] \
    CONFIG.input_options {non_registered} \
    CONFIG.output_options {non_registered} \
] [get_ips imem]

puts "Generating Instruction Memory IP..."

# Generate IP
generate_target all [get_files imem.xci]

# Synthesize IP
puts "Synthesizing Instruction Memory IP..."
create_ip_run [get_files imem.xci]
launch_runs imem_synth_1 -jobs 12
wait_on_run imem_synth_1

if {[get_property PROGRESS [get_runs imem_synth_1]] != "100%"} {
    puts "ERROR: Instruction Memory IP synthesis failed!"
    exit 1
} else {
    puts "Instruction Memory Generator IP created and synthesized successfully!"
}

# ========================================
# CREATE DATA MEMORY (RAM) IP CORE
# ========================================

puts "Creating Block Memory Generator IP for data memory (RAM)..."

# Create Block Memory Generator IP for data memory (RAM)
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_dmem

# Configure the Block Memory Generator for RAM
set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.Use_Byte_Write_Enable {true} \
    CONFIG.Byte_Size {8} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Write_Depth_A {1024} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File [file normalize $coe_file] \
    CONFIG.Fill_Remaining_Memory_Locations {true} \
    CONFIG.Remaining_Memory_Locations {00000000} \
] [get_ips blk_mem_gen_dmem]

puts "Generating Data Memory IP..."

# Generate IP
generate_target all [get_files blk_mem_gen_dmem.xci]

# Synthesize IP
puts "Synthesizing Data Memory IP..."
create_ip_run [get_files blk_mem_gen_dmem.xci]
launch_runs blk_mem_gen_dmem_synth_1 -jobs 12
wait_on_run blk_mem_gen_dmem_synth_1

if {[get_property PROGRESS [get_runs blk_mem_gen_dmem_synth_1]] != "100%"} {
    puts "ERROR: Data Memory IP synthesis failed!"
    exit 1
} else {
    puts "Data Memory Generator IP created and synthesized successfully!"
}
    
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