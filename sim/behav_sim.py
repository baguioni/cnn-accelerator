# Get input size, stride, precision, and how data is generated (random or sequential)
# Determine the output size
# Generate input array either randomly or sequentially (based on user input)
# Generate kernel array either randomly or sequentially (based on user input)
# Generate output array based on input array and stride
# Output the input, kernel, and output arrays to a file
# Run VCS or Icarus Verilog simulation
# Output the results to a file


import argparse
import numpy as np
import subprocess

def generate_sequential_array(input_size, precision):
    max_value = (1 << precision)
    array = np.arange(input_size * input_size) % max_value
    return array.reshape(input_size, input_size)

def generate_random_array(input_size, precision):
    max_value = (1 << precision) - 1
    return np.random.randint(0, max_value + 1, size=(input_size, input_size), dtype=np.int32)

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

def main():
    parser = argparse.ArgumentParser(description="Process input parameters.")
    parser.add_argument("input_size", type=int, help="Size of input")
    parser.add_argument("stride", type=int, help="Stride value")
    parser.add_argument("precision", type=int, help="Precision value")
    parser.add_argument("data_type", choices=["r", "s"], help="Type of r (random) or s (sequential) data generation")

    args = parser.parse_args()

    input_size = args.input_size
    stride = args.stride
    precision = args.precision
    data_type = args.data_type

    input_array = None
    if data_type == "s":
        input_array = generate_sequential_array(input_size, precision)
    else:
        input_array = generate_random_array(input_size, precision)

    kernel = None
    if data_type == "s":
        kernel = generate_sequential_array(3, precision)
    else:
        kernel = generate_random_array(3, precision)

    output, output_size = convolve_2d(input_array, kernel, stride)

    print(f'Input Size: {input_size}\nOutput Size: {output_size}\nStride: {stride}\nPrecision: {precision}')
    if (input_size <= 10):
        print("---------------------------------------------------------------")
        print("Input:")
        print(np.matrix(input_array))
        print("Kernel:")
        print(np.matrix(kernel))
        print("Output:")
        print(np.matrix(output))


    # # Write input, kernel, and output arrays to files
    array_to_file(flatten_2d_array(input_array), 8, "ifmap.txt")
    array_to_file(flatten_2d_array(kernel), 8, "kernel.txt")
    output_to_file(format_output(flatten_2d_array(output)), 1, "golden_output.txt")

    sim_command = "xargs -a filelist.txt iverilog -g2012 -o dsn"
    result = subprocess.run(sim_command, shell=True, capture_output=True, text=True)
    sim_error = result.stderr

    if not sim_error:
        sim_command = f'vvp dsn +i_i_size={input_size} +i_o_size={output_size} +i_stride={stride} +i_p_mode={precision}'
        result = subprocess.run(sim_command, shell=True, capture_output=True, text=True)

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
