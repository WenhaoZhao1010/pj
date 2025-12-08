# Part 3

This part extends the given systolic CNN accelerator with an **output-stationary (OS)** dataflow on top of the original **weight-stationary (WS)** design.

- **WS (original)**: weights stay in PEs, activations stream through.
- **OS (this work)**: partial sums stay in PEs (`c_q`), weights & activations stream through.

---

## 1. Output-Stationary Design

### 1.1 Mode select (`os_en`)

- `os_en` is used as **OS enable**:
  - `0` – weight-stationary mode (original behavior)
  - `1` – output-stationary mode

The same **RTL** is reused; only control / dataflow change when OS is enabled.

---

### 1.2 IFIFO and diagonal weight loading

In OS mode, kernel weights are loaded via an **input FIFO (IFIFO)** instead of L0:

Inside the array:

- Weights are loaded in a **diagonal** pattern across columns.
- Activations still come from L0.
- Each MAC keeps its local partial sum in `c_q`.

---

### 1.3 Partial sums in `c_q`

For OS:

- MAC behavior:
  - `product  = a * b`
  - `c_q_next = c_q + product`
  - `out      = c_q_next`
- For one output position:
  - With `ic = 8`, `kernel = 3×3`, each MAC sees **72 multiply–accumulate operations** (`8 * 3 * 3`).
  - All contributions are accumulated locally in `c_q`.
- Final results are stored in c_q, accessed by the testbench.

ReLU is not applied.

---

### 1.4 nij_out = 8
Since MAC array is 8×8, we can only verify `len_onij = 8`:

The MAC/OS hardware works more generally; the limitation is in **testbench + reference model file alignment**, not the core arithmetic.

---

### 1.5 Fifo depth extended to 128 (fifo_depth128.v and ififo.v)
Since the input data for input channel = 8, kernel size = 3*3, total 72 activation need to write in fifo. Original design of 64 was not enough for os mode.

## 2. Testbench Overview (core_tb.v)

Testbench will run weight-stationary (WS) first, then let `os_en` = 1, run output-stationary (OS), usinginput file: activation_os.txt, weight_os.txt, output_os.txt.

## 3.Random Testdata Generate

You can use test_data_generate.py to verify the hardware correctness, this code will generate activation_os_veri.txt, weight_os_veri.txt, output_os_veri.txt (In order to avoid original file overwrite). Then change the input file name in the testbench.



