#######################################################
# Set the clock constraints
#######################################################
# Frequency: 131.072 kHz -> Period: 7629.394531 ns
create_clock [get_ports clk]          -name clk        -domain sysclk -period 7629.394531

#######################################################
# set the generated clocks
#######################################################
#create_generated_clock -name post_divN_ruler0 -domain post_div_N0 -source [get_ports ruler_clk_p_pad[0]] -divide_by 1  [get_pins hpin:buf12_chip/u_digital_core/u_buf12_clock_dist_plane/GEN_CLK_DIV[0].u_clkdiv/clk_out] 

#######################################################
# set false/multicycl paths
#######################################################
#set_false_path -from aux* -to epu_clk*
#set_false_path -from epu_clk* -to aux*

#######################################################
# Set the input/output delay constraints
#######################################################
#set_input_delay  -max 2 -clock clk [all_inputs]
#set_output_delay -max 3 -clock clk [all_outputs]


#######################################################
# Set the critical path
#######################################################
#set_max_delay -from epu_clk -to u_clock_dist_plane/u_div2[0]/clk_in 0.4 -comment "epu clock path" 
