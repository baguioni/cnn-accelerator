# Get input size, stride, precision, and how data is generated (random or sequential)
# Determine the output size
# Generate input array either randomly or sequentially (based on user input)
# Generate kernel array either randomly or sequentially (based on user input)
# Generate output array based on input array and stride
# Output the input, kernel, and output arrays to a file
# Run VCS or Icarus Verilog simulation
# Output the results to a file


import argparse
import subprocess
import random

def generate_sequential_array(input_size, precision):
    max_value = 1 << precision
    total_elements = input_size * input_size
    array_1d = [i % max_value for i in range(total_elements)]
    
    array_2d = []
    for row_index in range(input_size):
        start = row_index * input_size
        end = start + input_size
        array_2d.append(array_1d[start:end])
    
    return array_2d

def generate_random_2d_array(input_size, precision):
    max_value = (1 << precision) - 1
    array_2d = []

    for _ in range(input_size):
        row = [random.randint(0, max_value) for _ in range(input_size)]
        array_2d.append(row)
    
    return array_2d

def generate_random_3d_array(input_size, channels, precision):
    max_value = (1 << precision) - 1
    array_3d = []

    for _ in range(channels):
        channel = []
        for _ in range(input_size):
            row = [random.randint(0, max_value) for _ in range(input_size)]
            channel.append(row)
        array_3d.append(channel)
    
    return array_3d

def convolve_2d(input_matrix, kernel, stride=1):
    input_rows = len(input_matrix)
    input_cols = len(input_matrix[0])
    kernel_size = len(kernel)
    
    output_rows = (input_rows - kernel_size) // stride + 1
    output_cols = (input_cols - kernel_size) // stride + 1

    output = [[0 for _ in range(output_cols)] for _ in range(output_rows)]
    
    for i in range(0, output_rows * stride, stride):
        for j in range(0, output_cols * stride, stride):
            sum_value = 0
            for ki in range(kernel_size):
                for kj in range(kernel_size):
                    sum_value += input_matrix[i + ki][j + kj] * kernel[ki][kj]
            output[i // stride][j // stride] = sum_value
    

    hex_output = [[format(val, 'x') for val in row] for row in output]
    
    return (hex_output, output_rows)

# Helper Functions
def flatten_2d_array(a):
    return [i for r in a for i in r]

def flatten_3d_array(arr):
    return [item for row in arr for col in row for item in col]

# n is how many bytes the theoretical SPAD can hold
def array_to_file(array, n, filename):
    if n <= 0:
        print("Group size must be greater than 0.")
        return
    
    try:
        with open(filename, 'w') as file:
            for i in range(0, len(array), n):
                group = array[i:i + n]
                hex_string = ''.join(f"{x:02x}" for x in reversed(group))
                file.write(hex_string + '\n')
        
        print(f"Data successfully written to {filename}")
    except IOError as e:
        print(f"An error occurred while writing to the file: {e}")

def output_to_file(array, n, filename):
    if n <= 0:
        print("Group size must be greater than 0.")
        return
    
    try:
        with open(filename, 'w') as file:
            for i in range(0, len(array), n):
                group = array[i:i + n]
                file.write(group[0] + '\n')
        
        print(f"Data successfully written to {filename}")
    except IOError as e:
        print(f"An error occurred while writing to the file: {e}")

def to_precision(number, bits):
    n = f"{(number & ((1<<bits)-1)):0{bits}b}"
    n = n[0]*(32-bits)+n
    num = int(n, 2)
    if num >= 2**(bits-1):
        num -= 2**32
    return num

def format_output(array):
    flattened_array = []
    
    for i in range(0, len(array), 2):
        first_part = array[i][-2:]
        
        if i + 1 < len(array):
            second_part = array[i+1][-2:]
        else:
            second_part = "00"
        
        combined_value = first_part + second_part
        flattened_array.append(combined_value)
    
    return flattened_array

def convert_nchw_to_nhwc(nchw_array):
    channels = len(nchw_array)
    height = len(nchw_array[0])
    width = len(nchw_array[0][0])

    # Initialize NHWC array with shape (height, width, channels)
    nhwc_array = [[[nchw_array[c][h][w] for c in range(channels)] 
                   for w in range(width)] 
                   for h in range(height)]
    
    return nhwc_array

def main():
    parser = argparse.ArgumentParser(description="Process input parameters.")
    parser.add_argument("input_size", type=int, help="Size of input")
    parser.add_argument("channels", type=int, help="Number of channels")
    parser.add_argument("stride", type=int, help="Stride value")
    parser.add_argument("precision", type=int, help="Precision value")

    args = parser.parse_args()

    input_size = args.input_size
    channels = args.channels
    stride = args.stride
    precision = args.precision

    input_array = generate_random_3d_array(input_size, channels, precision)

    kernel = generate_random_2d_array(3, precision)

    output, output_size = convolve_2d(input_array[0], kernel, stride)

    nhwc_array = convert_nchw_to_nhwc(input_array)

    print(f'Input Size: {input_size}\nNumber of Channels: {channels}\nOutput Size: {output_size}\nStride: {stride}\nPrecision: {precision}')
    if (input_size <= 10):
        print("---------------------------------------------------------------")
        print("Input:")
        print(input_array)
        print("Channel 0:")
        print(input_array[0])
        print("Kernel:")
        print(kernel)
        print("Output:")
        print(output)

    # # Write input, kernel, and output arrays to files
    array_to_file(flatten_3d_array(nhwc_array), 8, "ifmap.txt")
    array_to_file(flatten_2d_array(kernel), 8, "kernel.txt")
    output_to_file(format_output(flatten_2d_array(output)), 1, "golden_output.txt")

    sim_command = "xargs -a filelist.txt iverilog -g2012 -o dsn"
    result = subprocess.run(sim_command, shell=True, capture_output=True, text=True)
    sim_error = result.stderr

    # defaults to 8-bit precision
    p_mode = 0
    if precision == 4:
        p_mode = 1
    elif precision == 2:
        p_mode = 2

    # To add specific which channel to convolve
    if not sim_error:
        print(f"input_size: {input_size}, channels: {channels}, output_size: {output_size}, stride: {stride}, precision: {precision}")
        sim_command = f'vvp dsn +i_i_size={input_size} +i_c_size={channels} +i_c={0} +i_o_size={output_size} +i_stride={stride} +i_p_mode={p_mode}'
        result = subprocess.run(sim_command, shell=True, capture_output=True, text=True)
        print(result.stdout)
    else:
        print(sim_error)

    # Check if the difference of output and golden_output
    sim_command = "diff output.txt golden_output.txt"
    result = subprocess.run(sim_command, shell=True, capture_output=True, text=True)
    print('\nOutput vs Golden Comparison:')
    if result.stdout:
        print("Differences found :(")
        #print(result.stdout)
    else:
        print("No differences found :)")

if __name__ == "__main__":
    main()
