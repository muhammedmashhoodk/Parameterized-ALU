# Parameterized ALU

Digital Electronics project — **Logic Circuit Design (PBECT304)**,
S3 ECE 2, Government Engineering College Wayanad.

A fully parameterized, simulation-verified Arithmetic Logic Unit (ALU)
written in Verilog. Operand width is set via a single `WIDTH`
parameter — the same code works unchanged for 4-bit, 8-bit, 16-bit,
or any other width.

## Team

| Name | Register No | Roll No |
|---|---|---|
| Muhammed Mashhood K | WYD25EC085 | 36 |
| Muhammed Sinan E | WYD25EC088 | 37 |
| Nasbil K | WYD25EC092 | 38 |
| Neha Biju | WYD25EC094 | 39 |
| Nevil KJ | WYD25EC095 | 40 |

## Files

```
alu.v       - the parameterized ALU module
alu_tb.v    - self-checking testbench
```

## Interface

| Port | Direction | Width | Description |
|---|---|---|---|
| `a` | input | `WIDTH` | Operand A |
| `b` | input | `WIDTH` | Operand B |
| `opcode` | input | 3 | Operation select |
| `result` | output | `WIDTH` | Result of the selected operation |
| `carry_borrow` | output | 1 | Carry-out (ADD) / Borrow (SUB) |
| `zero` | output | 1 | 1 when `result == 0` |
| `equal` | output | 1 | 1 when `a == b` |
| `greater` | output | 1 | 1 when `a > b` |
| `less` | output | 1 | 1 when `a < b` |

## Supported operations

| opcode | Operation |
|---|---|
| `000` | ADD |
| `001` | SUB |
| `010` | AND |
| `011` | OR |
| `100` | CMP (equality) |

## How it works

- Both operands are zero-extended by one bit before add/subtract; the
  extra bit catches the carry-out (ADD) or borrow (SUB) that a
  `WIDTH`-bit-only result would silently drop.
- The `case (opcode)` block synthesizes to a 4:1 multiplexer — all
  operations are computed in parallel, and the opcode just selects
  which result passes through.
- `zero`, `equal`, `greater`, and `less` are plain combinational
  outputs, valid on every cycle regardless of which opcode is active.

## Requirements

- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`)
- [GTKWave](http://gtkwave.sourceforge.net/) (optional, for viewing waveforms)

On Ubuntu/Debian: `sudo apt install iverilog gtkwave`

## Running the simulation

```bash
iverilog -o sim alu.v alu_tb.v
vvp sim
```

Expected output:

```
>>> ALL TESTS PASSED (WIDTH=8)
```

To confirm the parameterization itself works, re-run at a different
width with no code changes:

```bash
iverilog -o sim -Palu_tb.WIDTH=16 alu.v alu_tb.v
vvp sim
```

Inspect signal timing:

```bash
gtkwave alu_tb.vcd
```

## Verification

Passing at `WIDTH = 4`, `8`, and `16` — directed edge cases (zero,
overflow, borrow) plus 100 randomized operand/opcode pairs per run,
self-checked against a reference calculation in the testbench.

## License

Academic project — Government Engineering College Wayanad.
