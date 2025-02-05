# not working
# iverilog -g2012 -o dsn -s tb_top ./top.sv ./tb_top.sv ./input_router/*.sv ./memory/*.sv
-g2012
+incdir+./input_router
+incdir+./memory
-timescale=1ns/1ps
./top.sv
./tb_top.sv
./input_router/*.sv
./memory/*.sv
-o dsn
-s tb_top