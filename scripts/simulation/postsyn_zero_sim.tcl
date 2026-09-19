# Frequency Difference Estimator vC - Zero-Delay Gate-Level Simulation
# Run from WORKSPACE/simulation:
#   source ./script/postsyn_zero_sim.tcl

xrun -gui -ieee1364 -sv -disable_sem2009 -access +rwc \
-timescale 1ns/1ps \
+define+POSTSYN_SIM \
-top tb_freq_diff_estimator \
../synthesis/netlist/freq_diff_estimator_vC_postsyn.v \
../tb/tb_freq_diff_estimator.v \
-logfile ./logs/vC_postsyn_zero_delay.log

