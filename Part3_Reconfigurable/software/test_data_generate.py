# test_data_generate.py
bw       = 4      # activation / weight bitwidth
psum_bw  = 16     # psum bitwidth
row      = 8
col      = 8

# You can modify these values for different test cases
x_val = 3   # [0,15] unsigned
w_val = -2  # [-8,7] signed

len_act_nonzero = 72   
len_act_total   = 120 
len_wgt_total   = 120  
# -----------------------------------


def int_to_twos(v, width):
    if not (-(1 << (width - 1)) <= v < (1 << (width - 1))):
        raise ValueError(f"value {v} out of range for {width}-bit signed")
    if v < 0:
        v = (1 << width) + v
    return format(v, f"0{width}b")


def twos_to_int(bits):
    width = len(bits)
    v = int(bits, 2)
    if v >= (1 << (width - 1)):
        v -= (1 << width)
    return v


act_bits = int_to_twos(x_val, bw)   
wgt_bits = int_to_twos(w_val, bw)   

print(f"Activation value x = {x_val}, bits = {act_bits}")
print(f"Weight     value w = {w_val}, bits = {wgt_bits}")

with open("activation_os_veri.txt", "w") as f_act:
    line_nz = act_bits * col          # 4bit * 8 = 32bit
    for _ in range(len_act_nonzero):
        f_act.write(line_nz + "\n")
    line_zero = "0" * (bw * col)
    for _ in range(len_act_total - len_act_nonzero):
        f_act.write(line_zero + "\n")


with open("weight_os_veri.txt", "w") as f_wgt:
    line_w = wgt_bits * col
    for _ in range(len_wgt_total):
        f_wgt.write(line_w + "\n")


num_mac = len_act_nonzero          
psum_val = x_val * w_val * num_mac 

psum_bits = int_to_twos(psum_val, psum_bw)
print(f" psum = x * w * {num_mac} = {psum_val}, bits = {psum_bits}")

with open("output_os_veri.txt", "w") as f_out:
    row_bits = psum_bits * col    
    for _ in range(row):
        f_out.write(row_bits + "\n")

