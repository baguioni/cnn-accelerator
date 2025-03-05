.PHONY: vcs dc vcs_post

setup:
	source ~/set_synopsys.sh

dc_init:
	echo 'set_app_var search_path "$$search_path mapped lib cons rtl"' > .synopsys_dc.setup
	echo 'set_app_var target_library /cad/tools/libraries/dwc_logic_in_gf22fdx_sc7p5t_116cpp_base_csc20l/GF22FDX_SC7P5T_116CPP_BASE_CSC20L_FDK_RELV02R80/model/timing/db/GF22FDX_SC7P5T_116CPP_BASE_CSC20L_TT_0P80V_0P00V_0P00V_0P00V_25C.db' >> .synopsys_dc.setup
	echo 'set_app_var link_library "* $$target_library"' >> .synopsys_dc.setup

init:
	mkdir -p mapped logs  # Create directories if they don't exist

bv:
	vcs -sverilog -f filelist.txt -full64 -debug_pp

dc:
	dc_shell -f compile.tcl -output_log_file logs/compile.log

fv:
	vcs tb_top.sv ../mapped/top_mapped.v /cad/tools/libraries/dwc_logic_in_gf22fdx_sc7p5t_116cpp_base_csc20l/GF22FDX_SC7P5T_116CPP_BASE_CSC20L_FDK_RELV02R80/model/verilog/GF22FDX_SC7P5T_116CPP_BASE_CSC20L.v /cad/tools/libraries/dwc_logic_in_gf22fdx_sc7p5t_116cpp_base_csc20l/GF22FDX_SC7P5T_116CPP_BASE_CSC20L_FDK_RELV02R80/model/verilog/prim.v -sverilog -full64 -debug_pp +neg_tchk -R -l vcs.log
