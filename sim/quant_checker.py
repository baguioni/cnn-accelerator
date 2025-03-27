import argparse
import random
import numpy as np
import subprocess
import sys

def convert_scale_to_shift_and_m0(scale,precision=16):
    " Convert scale(s) to shift and zero point "

    shift = int(np.ceil(np.log2(scale)))
    # shift = np.abs(shift)
    m0 = scale / 2**shift
    fp_string = convert_to_fixed_point(m0,precision)
    m0_clipped = fixed_point_to_float(fp_string,precision)
    return m0_clipped, shift

def convert_to_fixed_point(number,precision):
    " Convert a float [0,1] to fixed point binary string"
    out = ''
    for i in range(precision):
        number *= 2
        integer = int(number)
        number -= integer
        out += str(integer)
    return out

def convert_to_fixed_point_int(number,precision):
    " Convert a float [0,1] to fixed point binary "
    return int(convert_to_fixed_point(number,precision),base=2)

def fixed_point_to_float(number,precision):
    " Convert a fixed point binary to float [0,1] "
    out = 0
    for i in range(precision):
        out += int(number[i]) * 2**-(i+1)
    return out

def mult_and_quant(fp_int,shift,precision,num):
    return (num*fp_int)>>(precision-shift)

def main():
    parser = argparse.ArgumentParser(description="Process input parameter.")
    parser.add_argument("testcases"     , type=int  , help="Number of testcases to generate")
    parser.add_argument("precision"     , type=int  , help="Precision of quantization", )
    parser.add_argument("-scale", "--S" , type=float, help="Scale to use for quantization")
    args = parser.parse_args()
    
    testcases = args.testcases
    scale     = args.S
    precision = args.precision
    
    if (precision != 16):
        print("For precisions other than 16 bits, changing the DATA_WIDTH parameter in the tb_quant.sv is required")
        print(f"DATA_WIDTH must be set to {precision//2}")
        sys.exit(1)
    
    print("**************** Input parameters ****************")
    print(f"Scale: {scale} | Precision: {precision} bits")
    
    with open("input.txt","w") as ifile, open("golden_output.txt","w") as ofile:
        if not args.S:
            scale = random.uniform(0,1)
        
        m0, shift = convert_scale_to_shift_and_m0(scale, precision)
        fp_int = convert_to_fixed_point_int(m0, precision)
        print("**************** M0 and Shift amt ****************")
        print(f"fp_int: {fp_int}, Shift: {shift}")
        print("**************************************************")
        
        num_saturate_testcase = 0
        for _ in range(testcases):
            
            act = random.randint(0,(1<<precision)-1)
            res = mult_and_quant(fp_int, shift, precision, act)
            if (res >> (precision//2)) > 0:
                if num_saturate_testcase < 2:
                    res = int(f"{'1'*(precision//2)}",2)
                    num_saturate_testcase += 1
                else:
                    # generate testcase that doesn't saturate
                    while (res >> (precision//2)) > 0:
                        act = random.randint(0,(1<<precision)-1)
                        res = mult_and_quant(fp_int, shift, precision, act)

            ifile.write(f"{fp_int}, {-shift}, {act}\n")
            ofile.write(f"{res:0{precision//8}x}\n")
    
    # iverilog
    res = subprocess.run("iverilog -g2012 -o dsn -f quant_filelist.txt")
    res = subprocess.run("vvp dsn")
    
    with open("output.txt","r") as o_file, open("golden_output.txt","r") as g_file:
        print("\nVerifying output against golden output...")
        
        for output_line, golden_line in zip(o_file, g_file):
            output = output_line.strip() if output_line.strip() else None
            golden = golden_line.strip() if golden_line.strip() else None

            if output == golden:
                print(f"OUTPUT MATCH    {output} (output) == {golden} (golden)")
            else:
                print(f"OUTPUT MISMATCH {output} (output) != {golden} (golden)")

        # Check if one file is longer than the other
        extra_output = o_file.readline().strip()
        extra_golden = g_file.readline().strip()

        if extra_output:
            print("Warning: output.txt has extra lines not found in golden_output.txt.")
        if extra_golden:
            print("Warning: golden_output.txt has extra lines not found in output.txt.")

if __name__ == '__main__':
    main()