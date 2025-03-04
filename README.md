## Common Commands
For running VCS:
```vcs -sverilog -f filelist.txt -full64 -debug_pp```


For running Design Compiler:
```dc_shell -f compile.tcl -output_log_file logs/compile.log```

For running post logic synthesis verification:
```vcs tb_top.sv ../mapped/top_mapped.v /cad/tools/libraries/dwc_logic_in_gf22fdx_sc7p5t_116cpp_base_csc20l/GF22FDX_SC7P5T_116CPP_BASE_CSC20L_FDK_RELV02R80/model/verilog/GF22FDX_SC7P5T_116CPP_BASE_CSC20L.v /cad/tools/libraries/dwc_logic_in_gf22fdx_sc7p5t_116cpp_base_csc20l/GF22FDX_SC7P5T_116CPP_BASE_CSC20L_FDK_RELV02R80/model/verilog/prim.v -sverilog -full64 -debug_pp +neg_tchk -R -l vcs.log```