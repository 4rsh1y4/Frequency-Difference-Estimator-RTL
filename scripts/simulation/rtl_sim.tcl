# Frequency Difference Estimator vC - RTL Functional Simulation
# Run from WORKSPACE/simulation:
#   source ./script/func_sim.tcl

xrun -gui -ieee1364 -sv -disable_sem2009 -access +rwc \
-timescale 1ns/1ps \
-top tb_freq_diff_estimator \
../rtl/freq_diff_estimator_vC.v \
../tb/tb_freq_diff_estimator.v \
-logfile ./logs/vC_rtl.log
