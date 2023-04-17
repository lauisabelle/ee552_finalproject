onerror {resume}
quietly WaveActivateNextPane {} 0


add wave -noupdate {/testbench/tb/dn}
add wave -noupdate {/testbench/tb/st} 
add wave -noupdate {/testbench/tb/s_r} 
add wave -noupdate {/testbench/tb/ts} 
add wave -noupdate {/testbench/tb/i1_addr} 
add wave -noupdate {/testbench/tb/i2_addr} 
add wave -noupdate {/testbench/tb/f_addr} 
add wave -noupdate {/testbench/tb/out_addr} 
add wave -noupdate {/testbench/tb/out_data} 

add wave -noupdate {/testbench/intf[11]/data} 
add wave -noupdate {/testbench/intf[4]/data} 
add wave -noupdate {/testbench/intf[3]/data} 
add wave -noupdate {/testbench/intf[5]/data} 

add wave -noupdate {/testbench/dut/ch_wmem[0]/data} 
add wave -noupdate {/testbench/dut/ch_wmem[1]/data} 
add wave -radix unsigned -noupdate {/testbench/dut/wmem_mod/filter_mem} 
add wave -noupdate {/testbench/dut/imem_mod/partial_sum} 
add wave -noupdate {/testbench/dut/imem_mod/t1_mem} 
add wave -noupdate {/testbench/dut/imem_mod/t2_mem} 

add wave -noupdate {/testbench/intf[11]/data} 
add wave -noupdate {/testbench/intf[1]/data} 
add wave -noupdate {/testbench/intf[0]/data} 
add wave -noupdate {/testbench/intf[2]/data} 
add wave -noupdate {/testbench/intf[5]/data} 

add wave -noupdate {/testbench/dut/ch_imem[0]/data} 
add wave -noupdate {/testbench/dut/ch_imem[1]/data} 
add wave -noupdate {/testbench/dut/omem_mod/t1_spike_mem} 
add wave -noupdate {/testbench/dut/omem_mod/t2_spike_mem} 
add wave -noupdate {/testbench/dut/omem_mod/t1_residue_mem} 
add wave -noupdate {/testbench/dut/omem_mod/t2_residue_mem} 
add wave -noupdate {/testbench/dut/omem_mod/new_potential} 
add wave -noupdate {/testbench/dut/omem_mod/spike} 

add wave -noupdate {/testbench/intf[12]/data} 
add wave -noupdate {/testbench/intf[10]/data} 
add wave -noupdate {/testbench/intf[9]/data} 
add wave -noupdate {/testbench/intf[6]/data} 
add wave -noupdate {/testbench/intf[7]/data} 
add wave -noupdate {/testbench/intf[8]/data} 

add wave -noupdate {/testbench/dut/ch_omem[0]/data} 
add wave -noupdate {/testbench/dut/ch_omem[1]/data} 

add wave -noupdate {/testbench/dut/ch_spe[0]/data}
add wave -noupdate {/testbench/dut/ch_spe[1]/data} 
add wave -noupdate {/testbench/dut/ch_spe[2]/data} 
add wave -noupdate {/testbench/dut/ch_spe[3]/data} 
add wave -noupdate {/testbench/dut/ch_spe[4]/data} 
add wave -noupdate {/testbench/dut/ch_spe[5]/data} 
add wave -noupdate {/testbench/dut/ch_spe[6]/data} 
add wave -noupdate {/testbench/dut/ch_spe[7]/data} 
add wave -noupdate {/testbench/dut/ch_spe[8]/data} 
add wave -noupdate {/testbench/dut/ch_spe[9]/data} 

add wave -noupdate {/testbench/dut/ch_ppe[0]/data}
add wave -noupdate {/testbench/dut/ch_ppe[1]/data} 
add wave -noupdate {/testbench/dut/ch_ppe[2]/data} 
add wave -noupdate {/testbench/dut/ch_ppe[3]/data} 
add wave -noupdate {/testbench/dut/ch_ppe[4]/data} 
add wave -noupdate {/testbench/dut/ch_ppe[5]/data} 
add wave -noupdate {/testbench/dut/ch_ppe[6]/data} 
add wave -noupdate {/testbench/dut/ch_ppe[7]/data} 
add wave -noupdate {/testbench/dut/ch_ppe[8]/data} 
add wave -noupdate {/testbench/dut/ch_ppe[9]/data} 


add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod5/wrf/weights_mem }
add wave -radix binary -noupdate {/testbench/dut/ppe_mod5/irf/inputs_mem }
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod6/wrf/weights_mem }
add wave -radix binary -noupdate {/testbench/dut/ppe_mod6/irf/inputs_mem }
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod7/wrf/weights_mem }
add wave -radix binary -noupdate {/testbench/dut/ppe_mod7/irf/inputs_mem }
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod8/wrf/weights_mem }
add wave -radix binary -noupdate {/testbench/dut/ppe_mod8/irf/inputs_mem }
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod9/wrf/weights_mem }
add wave -radix binary -noupdate {/testbench/dut/ppe_mod9/irf/inputs_mem }

add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod5/ppe_fb/partial_sum }
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod5/ppe_fb/isum_ptr}
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod5/ppe_fb/input_data} 
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod5/ppe_fb/weight }

add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod6/ppe_fb/partial_sum }
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod6/ppe_fb/isum_ptr}
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod6/ppe_fb/input_data} 
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod6/ppe_fb/weight }

add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod7/ppe_fb/partial_sum }
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod7/ppe_fb/isum_ptr}
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod7/ppe_fb/input_data} 
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod7/ppe_fb/weight }

add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod8/ppe_fb/partial_sum }
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod8/ppe_fb/isum_ptr}
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod8/ppe_fb/input_data} 
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod8/ppe_fb/weight }

add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod9/ppe_fb/partial_sum }
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod9/ppe_fb/isum_ptr}
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod9/ppe_fb/input_data} 
add wave -radix unsigned -noupdate {/testbench/dut/ppe_mod9/ppe_fb/weight }



add wave -radix unsigned -noupdate {/testbench/dut/spe_mod0/ppe_fb/f5 }
add wave -radix unsigned -noupdate {/testbench/dut/spe_mod0/ppe_fb/f6 }
add wave -radix unsigned -noupdate {/testbench/dut/spe_mod0/ppe_fb/f7 }
add wave -radix unsigned -noupdate {/testbench/dut/spe_mod0/ppe_fb/f8 }
add wave -radix unsigned -noupdate {/testbench/dut/spe_mod0/ppe_fb/f9 }


TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
configure wave -namecolwidth 246
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
// update
// WaveRestoreZoom {0 fs} {836 fs}







// /testbench/dut/ppe_mod5/wrf/weights_mem 
// /testbench/dut/ppe_mod5/irf/inputs_mem 
// /testbench/dut/ppe_mod6/wrf/weights_mem 
// /testbench/dut/ppe_mod6/irf/inputs_mem 
// /testbench/dut/ppe_mod7/wrf/weights_mem 
// /testbench/dut/ppe_mod7/irf/inputs_mem 
// /testbench/dut/ppe_mod8/wrf/weights_mem 
// /testbench/dut/ppe_mod8/irf/inputs_mem 
// /testbench/dut/ppe_mod9/wrf/weights_mem 
// /testbench/dut/ppe_mod9/irf/inputs_mem 


