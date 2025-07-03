# Vivado RISC-V Project Creation Script
# Usage: vivado -mode tcl -source create_project.tcl

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
]

set constraint_file "board/Nexys4DDR_CPU.xdc"
set coe_file "instr/fpga/riscv-studentnosorting.coe"

# ========================================
# UTILITY FUNCTIONS
# ========================================

proc check_file_exists {filepath} {
    if {![file exists $filepath]} {
        puts "ERROR: File not found: $filepath"
        return 0
    }
    return 1
}

proc add_files_with_check {filelist filetype} {
    set valid_files []
    foreach file $filelist {
        if {[check_file_exists $file]} {
            lappend valid_files $file
            puts "Adding $filetype: $file"
        } else {
            puts "WARNING: Skipping missing file: $file"
        }
    }
    
    if {[llength $valid_files] > 0} {
        if {$filetype eq "sources"} {
            add_files -norecurse $valid_files
        } elseif {$filetype eq "constraints"} {
            add_files -fileset constrs_1 -norecurse $valid_files
        } elseif {$filetype eq "sim"} {
            add_files -fileset sim_1 -norecurse $valid_files
        }
    }
    return [llength $valid_files]
}

# ========================================
# CREATE PROJECT
# ========================================

puts "========================================="
puts "Creating RISC-V CPU Project"
puts "========================================="

# Remove existing project if it exists
if {[file exists $project_dir]} {
    puts "Removing existing project directory..."
    file delete -force $project_dir
}

# Create new project
puts "Creating project: $project_name"
create_project $project_name $project_dir -part $fpga_part -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

# ========================================
# ADD SOURCE FILES
# ========================================

puts "\n========================================="
puts "Adding Source Files"
puts "========================================="

# Add CPU source files
puts "\nAdding CPU modules:"
set cpu_count [add_files_with_check $cpu_files "sources"]

# Add board files
puts "\nAdding board modules:"
set board_count [add_files_with_check $board_files "sources"]

# Add testbench if it exists
if {[check_file_exists "cpu/comp_tb.v"]} {
    puts "\nAdding testbench:"
    add_files -fileset sim_1 -norecurse "cpu/comp_tb.v"
    set_property top comp_tb [get_filesets sim_1]
}

puts "\nTotal source files added: [expr $cpu_count + $board_count]"

# ========================================
# ADD CONSTRAINTS
# ========================================

puts "\n========================================="
puts "Adding Constraints"
puts "========================================="

if {[check_file_exists $constraint_file]} {
    add_files_with_check [list $constraint_file] "constraints"
    puts "Constraints file added successfully"
} else {
    puts "WARNING: No constraints file found"
}

# ========================================
# CREATE ROM IP CORE
# ========================================

puts "\n========================================="
puts "Creating ROM IP Core"
puts "========================================="

if {[check_file_exists $coe_file]} {
    # Create instruction memory ROM IP
    puts "Creating instruction memory ROM IP..."
    
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
    set optimal_jobs [expr {min(8, [exec nproc])}]
    launch_runs imem_synth_1 -jobs $optimal_jobs
    
    puts "ROM IP core created successfully"
} else {
    puts "WARNING: COE file not found, skipping ROM IP creation"
}

# ========================================
# SET TOP MODULE
# ========================================

puts "\n========================================="
puts "Configuring Project Settings"
puts "========================================="

# Set top-level module
set_property top $top_module [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# Set synthesis strategy (optional)
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]

# Set implementation strategy (optional)
set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]

# ========================================
# PROJECT SUMMARY
# ========================================

puts "\n========================================="
puts "Project Creation Summary"
puts "========================================="
puts "Project name: $project_name"
puts "Project directory: [file normalize $project_dir]"
puts "FPGA part: $fpga_part"
puts "Top module: $top_module"
puts "Source files: [llength [get_files -filter {FILE_TYPE == Verilog}]]"
puts "Constraint files: [llength [get_files -of_objects [get_filesets constrs_1]]]"
puts "IP cores: [llength [get_ips]]"

# Check if all critical files are present
set critical_modules [list "cpu.v" "xgriscv_fpga_top.v"]
foreach module $critical_modules {
    set found 0
    foreach file [get_files] {
        if {[string match "*$module" $file]} {
            set found 1
            break
        }
    }
    if {!$found} {
        puts "WARNING: Critical module $module not found!"
    }
}

puts "\n========================================="
puts "Project created successfully!"
puts "You can now:"
puts "1. Run synthesis: launch_runs synth_1"
puts "2. Run implementation: launch_runs impl_1"
puts "3. Generate bitstream: launch_runs impl_1 -to_step write_bitstream"
puts "========================================="

# Optional: Auto-open GUI
# start_gui

# Save project
save_project_as -force $project_name $project_dir