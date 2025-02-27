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

def generate_sequential_array(input_size, precision):
    max_value = (1 << precision)
    array = np.arange(input_size * input_size) % max_value
    return array.reshape(input_size, input_size)

def generate_random_array(input_size, precision):
    max_value = (1 << precision) - 1
    return np.random.randint(0, max_value + 1, size=(input_size, input_size), dtype=np.int32)

def convolve_2d(input_array, kernel, stride):
    input_size = input_array.shape[0]
    kernel_size = kernel.shape[0]
    output_size = (input_size - kernel_size) // stride + 1
    output = np.zeros((output_size, output_size), dtype=np.float32)

    for i in range(0, output_size):
        for j in range(0, output_size):
            x, y = i * stride, j * stride
            output[i, j] = np.sum(input_array[x:x+kernel_size, y:y+kernel_size] * kernel)

    return output.astype(np.int32)

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

    output = convolve_2d(input_array, kernel, stride)
    print(output)

if __name__ == "__main__":
    main()
