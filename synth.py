import subprocess
import csv

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

# Filepaths
cons_path = "cons/timing.sdc"
area_log_path = "logs/area_report.log"
timing_log_path = "logs/timing_report.log"

with open(area_log_path, 'r', encoding='utf-8') as file: 
    area_data = file.readlines()

# Thank you kenn for your service
combi_area = float(area_data[21].split()[-1])
buffinv_area = float(area_data[22].split()[-1])
noncombi_data = float(area_data[23].split()[-1])
total_area = float(area_data[27].split()[-1])
print("Combinational Area:", combi_area, "Buff/Inv Area:", buffinv_area, "Noncombinational Area:", noncombi_data)
print("Total Area:", total_area)

components = [
    ("Controller", "top_controller_inst"),
    ("Input SPAD", "ir_inst/input_sram"), 
    ("Input Router", "ir_inst"), 
    ("Weight SPAD", "wr_inst/weight_sram"),
    ("Weight Router", "wr_inst"),
    ("Output Router", "or_inst"), 
    ("Systolic Array", "systolic_array_inst"),
]

csv_filename = f"{spad_data_width}_{rows}.csv"

spad_area = 0
spad_percentage = 0

# Save data to CSV
with open(csv_filename, mode="w", newline="") as file:
    writer = csv.writer(file)
    writer.writerow(["Component", "Area", "Percentage"])

    for name, identifier in components:
        area_info = next((line.strip() for line in area_data if identifier in line), None)

        if area_info:
            text = area_info.split()
            area = float(text[1])
            percentage = float(text[2])

            # Ensure that the SPAD area is not counted twice
            if name == "Input SPAD" or name == "Weight SPAD":
                spad_area = area
                spad_percentage = percentage
            
            if name == "Input Router" or name == "Weight Router":
                area -= spad_area
                percentage -= spad_percentage

            area = f"{area:.4f}"
            percentage = f"{percentage:.1f}"
            writer.writerow([name, area, percentage])
        else:
            writer.writerow([name, "n/a", "n/a"])

print(f"Area data has been saved to {csv_filename}")