set common_ui true

# #################################
# Library notes
# Specifying Multiple Libraries
# If your design requires multiple libraries, you must load them simultaneously. Genus uses the
# operating and nominal conditions, thresholds, and units from the first library specified. If you
# specify libraries sequentially, Genus uses only the last one loaded.
# #################################


# #################################
# Load the digital library
# #################################
set_db init_lib_search_path {/home/cad/TECH.D/TSMC180/lib}


set library {typical.lib}
             

set_db library $library

# #################################
# set_db cell_name(s) .avoid {true | false}
# set_db libcell_name .preserve false
# set_db libcell_name .avoid false

# get_liberty_attribute "function" [get_db lib_cells my_libset/scc011ums_hd_rvt_ff_v1p32_0c_ccs/INHDV1]
# get_liberty_attribute "wireload" [get_db libraries default_emulate_libset_max/scc011ums_hd_rvt_ff_v1p32_0c_ecsm]

# #################################
set_db script_search_path { . ./scripts }




