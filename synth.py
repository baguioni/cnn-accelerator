import subprocess

# Filepaths
cons_path = "cons/timing.sdc"
area_log_path = "logs/area_report.log"
timing_log_path = "logs/timing_report.log"

spad_data_width = 64
rows = 8

header = f"""`define DATA_WIDTH 8
`define SPAD_DATA_WIDTH {spad_data_width}
`define SPAD_N (`SPAD_DATA_WIDTH / `DATA_WIDTH)
`define ADDR_WIDTH 8
`define ROWS {rows}
`define COLUMNS 1
`define MISO_DEPTH 32
`define MPP_DEPTH 16"""

with open("rtl/global.svh", "w") as file:
    file.write(header)
    
print("global.svh file has been generated.")

subprocess.run("dc_shell -f compile.tcl -output_log_file logs/compile.log", shell=True)
