
## constraint_mode
create_constraint_mode -name constraint_mode_typ \
    -sdc_files { ./buf12_chip.functional_mode.sdc }

#create_constraint_mode -name constraint_mode_typ \
    -sdc_files { ./buf12_chip.constraint_mode_typ.sdc }

# create_constraint_mode -name constraint_mode_typ \
#     -sdc_files { ./buf12_chip.constraint_mode_typ.sdc }
# 
# create_constraint_mode -name constraint_mode_min \
#     -sdc_files { ./buf12_chip.constraint_mode_min.sdc }


## library_sets
create_library_set -name mmmc_lib_set_typ  -timing [list  \
  scc011ums_hd_rvt_tt_v1p2_25c_ecsm.lib ]

create_library_set -name mmmc_lib_set_min  -timing [list  \
  scc011ums_hd_rvt_ff_v1p32_0c_ecsm.lib    \
  scc011ums_hd_rvt_ff_v1p32_85c_ecsm.lib   ]

create_library_set -name mmmc_lib_set_max  -timing [list  \
  scc011ums_hd_rvt_ss_v1p08_125c_ecsm.lib  ]
  
#  scc011ums_hd_rvt_ff_v1p32_-40c_ecsm.lib  \ 


## operating conditions
create_opcond -name oc_max \
    -process     1.0    \
    -voltage     1.08   \
    -temperature 125.0

create_opcond -name oc_typ \
    -process     1.0    \
    -voltage     1.20   \
    -temperature 25.0

create_opcond -name oc_min1 \
    -process     1.0    \
    -voltage     1.32   \
    -temperature 0.0

create_opcond -name oc_min2 \
    -process     1.0    \
    -voltage     1.32   \
    -temperature -40.0

create_opcond -name oc_min3 \
    -process     1.0    \
    -voltage     1.32   \
    -temperature 85.0


## timing_condition
create_timing_condition -name timing_cond_max \
    -opcond oc_max \
    -library_sets { mmmc_lib_set_max }

create_timing_condition -name timing_cond_typ \
    -opcond oc_typ \
    -library_sets { mmmc_lib_set_typ }

create_timing_condition -name timing_cond_min1 \
    -opcond oc_min1 \
    -library_sets { mmmc_lib_set_min }

# create_timing_condition -name timing_cond_min2 \
#     -opcond oc_min2 \
#     -library_sets { mmmc_lib_set_min }

create_timing_condition -name timing_cond_min3 \
    -opcond oc_min3 \
    -library_sets { mmmc_lib_set_min }



## rc_corner
create_rc_corner -name default_rc_corner \
    -temperature 0.0 \
    -pre_route_res 1.0 \
    -pre_route_cap 1.0 \
    -pre_route_clock_res 0.0 \
    -pre_route_clock_cap 0.0 \
    -post_route_res {1.0 1.0 1.0} \
    -post_route_cap {1.0 1.0 1.0} \
    -post_route_cross_cap {1.0 1.0 1.0} \
    -post_route_clock_res {1.0 1.0 1.0} \
    -post_route_clock_cap {1.0 1.0 1.0}

## delay_corner
create_delay_corner -name delay_corner_max \
    -early_timing_condition { timing_cond_max } \
    -late_timing_condition { timing_cond_max } \
    -early_rc_corner default_rc_corner \
    -late_rc_corner default_rc_corner 

create_delay_corner -name delay_corner_typ \
    -early_timing_condition { timing_cond_typ } \
    -late_timing_condition { timing_cond_typ } \
    -early_rc_corner default_rc_corner \
    -late_rc_corner default_rc_corner 

create_delay_corner -name delay_corner_min \
    -early_timing_condition { timing_cond_min1 } \
    -late_timing_condition { timing_cond_min1 } \
    -early_rc_corner default_rc_corner \
    -late_rc_corner default_rc_corner 



## analysis_view
create_analysis_view -name view_max \
    -constraint_mode constraint_mode_typ \
    -delay_corner delay_corner_max

create_analysis_view -name view_min \
    -constraint_mode constraint_mode_typ \
    -delay_corner delay_corner_min

create_analysis_view -name view_typ \
    -constraint_mode constraint_mode_typ \
    -delay_corner delay_corner_typ


## set_analysis_view
set_analysis_view -setup { view_max} \
                  -hold {view_min}

#set_analysis_view -setup { default_emulate_view_max } \
#                  -hold { default_emulate_view_max }


