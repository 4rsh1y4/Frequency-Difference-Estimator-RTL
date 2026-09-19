#########################################
# Content: Frequency Difference Estimator vC synthesis script
# Tool: Cadence Genus(TM) Synthesis Solution 21.10-p002_1
# Library: TSMC 180nm Digital, Typical case
#
# Course: Digital Design Course
# University: Sharif University of Technology
# Instructor: Dr. F. Baharvand
#########################################

set DESIGN freq_diff_estimator
set RUN_TAG vC
set RTL_FILE ../rtl/freq_diff_estimator_vC.v

set OUT_DIR ./synout_${RUN_TAG}
set RPT_DIR ./reports_${RUN_TAG}

file mkdir $OUT_DIR
file mkdir $RPT_DIR

echo "-------------------------------------------------"
echo " Reading library"
echo "-------------------------------------------------"

source ./script/lib_scr.tcl

echo "-------------------------------------------------"
echo " Reading design RTL"
echo "-------------------------------------------------"

set file_list [list $RTL_FILE]

set_db auto_ungroup none
set_db write_vlog_top_module_first true
set_db information_level 2
set_db remove_assigns true
set_db hdl_error_on_latch true

read_hdl -language sv $file_list

echo "-------------------------------------------------"
echo " Elaborating design"
echo "-------------------------------------------------"

elaborate

echo "-------------------------------------------------"
echo " Setting top module"
echo "-------------------------------------------------"

set_top_module $DESIGN

echo "-------------------------------------------------"
echo " Checking design"
echo "-------------------------------------------------"

check_design -unresolved > ${RPT_DIR}/${RUN_TAG}_check_design.rpt

echo "-------------------------------------------------"
echo " Applying clock constraints"
echo "-------------------------------------------------"

source ./script/fde_clock_const.tcl

echo "-------------------------------------------------"
echo " Initializing design"
echo "-------------------------------------------------"

init_design
time_info init_design

echo "-------------------------------------------------"
echo " Checking clock definition"
echo "-------------------------------------------------"

report_clocks > ${RPT_DIR}/${RUN_TAG}_clocks_pre_synthesis.rpt

echo "-------------------------------------------------"
echo " Running generic synthesis"
echo "-------------------------------------------------"

syn_generic

echo "-------------------------------------------------"
echo " Running technology mapping"
echo "-------------------------------------------------"

syn_map

echo "-------------------------------------------------"
echo " Running incremental optimization"
echo "-------------------------------------------------"

syn_opt

echo "-------------------------------------------------"
echo " Generating post-synthesis reports"
echo "-------------------------------------------------"

report_clocks > ${RPT_DIR}/${RUN_TAG}_clocks.rpt
report_timing -max_paths 20 > ${RPT_DIR}/${RUN_TAG}_timing.rpt
report_area > ${RPT_DIR}/${RUN_TAG}_area.rpt
report_power > ${RPT_DIR}/${RUN_TAG}_power.rpt
report_gates > ${RPT_DIR}/${RUN_TAG}_gates.rpt

echo "-------------------------------------------------"
echo " Writing netlist and output files"
echo "-------------------------------------------------"

write_hdl > ${OUT_DIR}/${DESIGN}_${RUN_TAG}_postsyn.v

write_sdf -version 3.0 -timescale ps -nonegcheck \
    -setuphold split -recrem split \
    > ${OUT_DIR}/${DESIGN}_${RUN_TAG}_postsyn.sdf

write_script > ${OUT_DIR}/${DESIGN}_${RUN_TAG}_constraints.g

echo "-------------------------------------------------"
echo " Writing Innovus handoff files"
echo "-------------------------------------------------"

set_db design_process_node 180

write_design \
    -basename ${OUT_DIR}/${DESIGN}_${RUN_TAG} \
    -innovus \
    -hierarchical $DESIGN

echo "-------------------------------------------------"
echo " Synthesis completed"
echo " Run tag: $RUN_TAG"
echo " Reports: $RPT_DIR"
echo " Outputs: $OUT_DIR"
echo "-------------------------------------------------"

exit