iverilog -o pipeline_cpu_sim.out ctrl_encode_def.v alu.v ctrl.v dm.v EXT.v im.v RF.v hazard_detection_unit.v forwarding_unit.v pipeline_cpu.v pipeline_sccomp.v pipeline_sccomp_tb.v && \
vvp pipeline_cpu_sim.out && \
gtkwave pipeline_cpu.vcd