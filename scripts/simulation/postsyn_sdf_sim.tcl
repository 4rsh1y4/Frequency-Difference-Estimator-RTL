# Frequency Difference Estimator vC - SDF-Annotated Gate-Level Simulation
# Run from WORKSPACE/simulation:
#   source ./script/postsyn_sdf_sim.tcl
#
# The testbench back-annotates:
#   ../synthesis/synout_vC/freq_diff_estimator_vC_postsyn.sdf
# using MAXIMUM delays.

xrun -gui -ieee1364 -sv -disable_sem2009 -access +rwc \
-timescale 1ns/1ps \
+define+POSTSYN_SIM +define+SDF_SIM \
-top tb_freq_diff_estimator \
../synthesis/netlist/freq_diff_estimator_vC_postsyn.v \
../tb/tb_freq_diff_estimator.v \
-logfile ./logs/vC_postsyn_sdf.log
