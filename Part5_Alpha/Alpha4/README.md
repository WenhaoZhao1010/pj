
# About Part 2 SIMD

## Test Procedure
1. Run `project_2b4b.ipynb` and `project_4b4b.ipynb` to generate test data (you may choose whether to retrain; trained models are saved in `./result/VGG16_quant2b4b` and `./result/VGG16_quant4b4b`).
2. Verify that the following six files have been generated:  
   `activation2b4b.txt`, `weight2b4b.txt`, `output2b4b.txt`,  
   `activation4b4b.txt`, `weight4b4b.txt`, `output4b4b.txt`.
3. Run `address_gen.ipynb` to generate `address2b4b.txt` and `address4b4b.txt` (you need to manually modify the output filenames and the output tile size).
4. Execute `source ./cmd.sh` in the terminal to run tests for both 2b4b and 4b4b with output tiling enabled. Please ignore any warnings printed in the terminal.

## Test Results
![alt text](<tiling without huffman.png>)

The tests pass successfully. Detailed waveforms can be found in `core_tb.vcd`.

## 2b4b Introduction

### Model Training
The 2b4b quantized model was trained in `project_2b4b.ipynb`, achieving an accuracy of **89.51%**.

### mac_tile
Compared to the vanilla implementation, the 2b4b version expands the original 4-bit `x` and `w` ports into eight ports with different bit widths (`a_bw=2`, `w_bw=4`). The port definitions are as follows:

```verilog
input  [a_bw-1:0] in_x_0;
input  [a_bw-1:0] in_x_1;
input  [w_bw-1:0] in_w_0;
input  [w_bw-1:0] in_w_1;
output [a_bw-1:0] out_x_0;
output [a_bw-1:0] out_x_1;
output [w_bw-1:0] out_w_0;
output [w_bw-1:0] out_w_1;
```

Both activation (`x`) and weight (`w`) data flow from west to east. Note that `out_w_0` and `out_w_1` are passed through two separate registers unrelated to `b_q_0` and `b_q_1`:

```verilog
reg [w_bw-1:0] out_w_0_q; // to pass weight to next mac_tile
reg [w_bw-1:0] out_w_1_q;
```

The `out_s` logic is defined as:

```verilog
assign mac_out_comb = (mac_out_1 << 2) + mac_out_0; // Shift high bits left by 2 positions
assign out_s = ctrl ? (mac_out_comb + c_q) : (mac_out_0 + mac_out_1 + c_q); // Final output based on mode
```

The `ctrl` signal is provided directly by the testbench (`tb`) and propagated to each `mac_tile`. When `ctrl = 1`, `out_s = mac_out_comb + c_q`; when `ctrl = 0`, `out_s = mac_out_0 + mac_out_1 + c_q`.

### mac_array and mac_row
The implementation of `mac_array` and `mac_row` remains consistent with the vanilla version, except that inputs/outputs of `mac_tile` are encapsulated.  
Importantly, I preserved the dual-port design to allow two distinct signals (`x` or `w`) to be loaded within the same clock cycle:

```verilog
input  [row*a_bw-1:0] in_x_0; // Input activations low bits
input  [row*a_bw-1:0] in_x_1; // Input activations high bits
input  [row*w_bw-1:0] in_w_0; // Weight inputs
input  [row*w_bw-1:0] in_w_1; // Weight inputs
```

### core_let
In `core_let`, logic is implemented to split and route continuous data streams of varying bit widths from L0 to four distinct ports:

```verilog
// Wires for reorganized weight inputs
wire [row*w_bw-1:0] reorg_w_0;
wire [row*w_bw-1:0] reorg_w_1;
wire [row*x_bw-1:0] reorg_x_0;
wire [row*x_bw-1:0] reorg_x_1;

genvar i;
for (i = 0; i < row; i = i + 1) begin : weight_reorg
    assign reorg_w_1[w_bw*(i+1)-1 : w_bw*i] = ctrl==0 ? data_out_l0[l0_bw*(i+1)-1 : l0_bw*i + 4] : data_out_l0[l0_bw*i + 3 : l0_bw*i]; // Upper 4 bits
    assign reorg_w_0[w_bw*(i+1)-1 : w_bw*i] = ctrl==0 ? data_out_l0[l0_bw*i + 3 : l0_bw*i] : data_out_l0[l0_bw*i + 3 : l0_bw*i];       // Lower 4 bits
    assign reorg_x_1[x_bw*(i+1)-1 : x_bw*i] = ctrl==0 ? data_out_l0[l0_bw*i+ 5 : l0_bw*i + 4] : data_out_l0[l0_bw*i+ 3 : l0_bw*i + 2];    // [5:4]
    assign reorg_x_0[x_bw*(i+1)-1 : x_bw*i] = ctrl==0 ? data_out_l0[l0_bw*i+ 1 : l0_bw*i] : data_out_l0[l0_bw*i+ 1 : l0_bw*i];        // [1:0]
end
```

### core
To deliver two different 4-bit weights to `mac_tile` in the same cycle, the bit width (`bw`) of L0 and `xmem` was changed to 8 bits. In `core_let`, a `genvar` loop splits the 8-bit input into 4-bit segments.  
For activations formed by concatenating two 2-bit values into 4 bits, zero-padding is used to align them to the 4-bit input format.

In `project_2b4b.ipynb` (which generates `activation2b4b.txt`, `weight2b4b.txt`, etc.):

```python
for i in range(X.size(1)):
    line_bin = ""

    for j in range(X.size(0)):
        val = int(round(X[15-j, i].item()))
        val_2s = val & 0xF
        line_bin += f'{val_2s:04b}'

    f.write(line_bin + '\n')
```

### core_tb
For the 2b4b test, since the output channel count (`och`) is 16—but our SIMD-enabled 8×8 systolic array only supports 16×8 convolutions—we introduced `och_tile` for temporal tiling.  

- **Weight storage order** (`weight2b4b.txt`): `K_ij → output_tile → Output_Ch (Col) → Input_Ch (Row)`  
- **Output storage order** (`output2b4b.txt`): `output_tile → nij_o → Output_Ch`  
- The address generation logic in `address2b4b.txt` follows this layout.

---

## 4b4b Introduction

### Model Training
The 4b4b quantized model was trained in `project_4b4b.ipynb`, achieving an accuracy of **91.36%**.

### mac_tile
For the 4b4b case where weights are identical, both `b_q_0` and `b_q_1` registers are driven from `x_in_0` to ensure they remain the same.

### core_let
Although `b_q_0` and `b_q_1` originate from the same port, both `reorg_w_0` and `reorg_w_1` are connected only to the upper 4 bits of L0’s output: `data_out_l0[l0_bw*i + 3 : l0_bw*i]`.

### core_tb
In `project_4b4b.ipynb` (which generates `activation4b4b.txt`, `weight4b4b.txt`, etc.), all data bit widths are aligned to 8 bits to match the width of `xmem` and L0.

---

# About Huffman Coding

## Test Procedure
1. Complete the Part 2 SIMD test procedure.
2. In `core_tb.v`, comment out lines 477–485 and uncomment lines 487–498.
3. Run `Huffman.ipynb` to generate `activation4b4b_huffman.txt` (skip if already present).
4. Execute `source ./cmd.sh` to run tests for 2b4b with output tiling and 4b4b with Huffman decoding enabled. Ignore terminal warnings.

## Test Results
![alt text](huffman_decoder.png)

The test passes successfully. Waveforms are available in `core_tb.vcd`.

## Huffman Encoder
Our Huffman encoder uses a simple variable-length coding scheme optimized for activation data:

- **Zero-value encoding**: Input `0` → encoded as single bit `'0'`
- **Non-zero encoding**: Non-zero input → encoded as `'1'` + 8-bit raw value (total 9 bits)

Implementation details are in `Huffman.ipynb`. You can inspect `activation4b4b_huffman.txt` to observe encoded results.

**Compression metrics**:
- Original size: 2304 bits  
- Compressed size: 560 bits  
- Compression ratio: **4.11×**

## Huffman Decoder
The decoder consists of two main modules:

1. **Huffman Decoder (`huffman_decoder.v`)**  
   - Receives serial bitstream input  
   - Uses a 9-state finite state machine (FSM)  
   - Decodes compressed data back to original 8-bit values

2. **Huffman Wrapper (`huffman_wrapper.v`)**  
   - Buffers 8 consecutive decoded outputs  
   - Concatenates them into a 64-bit wide word  
   - Generates address signals for memory writes  
   - Managed by an 8-state FSM

## Integration into Core Module

### 1. Interface Enhancement
Two new input ports were added to the core module:
- `huffman_data_in`: Serial bitstream input for compressed Huffman data
- `inst[5]`: Control signal to switch between data source modes

### 2. Huffman Decoder Instantiation
```verilog
huffman_wrapper #(
    .col(col),
    .bw(bw)
) huffman_wrapper_inst (
    .clk(clk),
    .reset(reset),
    .data_in(huffman_data_in),
    .data_valid(inst[5]),
    .data_out(huffman_data_out),
    .data_out_valid(huffman_data_out_valid),
    .address(huffman_address)
);
```

The wrapper receives:
- Clock and reset
- Serial input (`huffman_data_in`)
- Data valid signal (`inst[5]`)
- Outputs 64-bit decoded data, validity flag, and write address

### 3. Intelligent Data Path Switching
A ternary operator selects the data source dynamically:

```verilog
assign xmem_input_data = (inst[5]) ? huffman_data_out : d_xmem;
assign xmem_address = (inst[5]) ? huffman_address : inst[17:7];
assign CEN_xmem = (inst[5]) ? (~huffman_data_out_valid) : inst[19];
assign WEN_xmem = (inst[5]) ? (~huffman_data_out_valid) : inst[18];
```

- **When `inst[5] = 0` (Legacy Mode)**:  
  - Data from `d_xmem`  
  - Address from instruction (`inst[17:7]`)  
  - Control signals from instruction (`CEN`, `WEN`)

- **When `inst[5] = 1` (Huffman Mode)**:  
  - Data from Huffman decoder output  
  - Address auto-generated by wrapper  
  - Control signals inverted from decoder’s `valid` signal

### 4. Memory Control Logic
In Huffman mode, memory enable signals are tied to the decoder’s validity:
- When `huffman_data_out_valid = 1` → memory enabled (active low)
- When `huffman_data_out_valid = 0` → memory disabled

This ensures writes occur only after a full 64-bit block is decoded.

### 5. Automatic Address Management
The wrapper maintains an internal address counter that auto-increments after each 64-bit output, eliminating the need for software-managed addresses.

### 6. Seamless Integration Benefits
- **Backward compatible**: Toggle between modes via `inst[5]`
- **Hardware-transparent**: Core computation units see identical interfaces regardless of data source
- **Automated control**: Addressing and memory enables are fully managed in hardware

This integration adds Huffman decoding support without compromising existing functionality.

## Performance Advantages
- Significant compression for activation data with many zeros
- Pipelined decoding enables continuous processing
- Seamless integration with existing memory architecture—no major hardware redesign needed