// =================================================================
// Self-checking testbench for the parameterized ALU
// -----------------------------------------------------------------
// Run from the repo root:
//   iverilog -o sim src/alu.v testbench/alu_tb.v && vvp sim
//
// Re-run at a different width without touching any code:
//   iverilog -o sim -Palu_tb.WIDTH=16 src/alu.v testbench/alu_tb.v && vvp sim
// =================================================================
`timescale 1ns/1ps

module alu_tb;
    // WIDTH here is the testbench's own copy - override it from the
    // command line (-Palu_tb.WIDTH=N) to regression-test other sizes.
    parameter WIDTH = 8;

    reg  [WIDTH-1:0] a, b;          // driven test operands
    reg  [2:0]       opcode;        // driven test opcode
    wire [WIDTH-1:0] result;        // observed from the DUT
    wire             carry_borrow, zero, equal, greater, less;

    integer errors = 0;             // running count of mismatches
    integer i;                      // loop index for the random pass

    // Device under test - wires our test signals straight to the ALU
    alu #(.WIDTH(WIDTH)) dut (
        .a(a), .b(b), .opcode(opcode),
        .result(result), .carry_borrow(carry_borrow),
        .zero(zero), .equal(equal), .greater(greater), .less(less)
    );

    // Compares the DUT's result against the value we expect, and
    // prints a diagnostic line only when they disagree.
    task check(input [WIDTH-1:0] expected, input [8*12-1:0] label);
        begin
            if (result !== expected) begin
                errors = errors + 1;
                $display("FAIL [%0s] a=%0d b=%0d opcode=%0d -> got=%0d expected=%0d",
                          label, a, b, opcode, result, expected);
            end
        end
    endtask

    initial begin
        // Waveform dump - open alu_tb.vcd in GTKWave to inspect timing
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // ---- Directed edge cases (the ones random testing tends to miss) ----
        a = 0; b = 0; opcode = 3'b000; #10; check(8'd0, "ADD-zero");
        a = {WIDTH{1'b1}}; b = 1; opcode = 3'b000; #10; check(8'd0, "ADD-overflow");
        a = 5; b = 3; opcode = 3'b001; #10; check(8'd2, "SUB-basic");
        a = 3; b = 5; opcode = 3'b001; #10; check(3 - 5, "SUB-borrow");
        a = 8'hAA; b = 8'h0F; opcode = 3'b010; #10; check(8'h0A, "AND-basic");
        a = 8'hAA; b = 8'h0F; opcode = 3'b011; #10; check(8'hAF, "OR-basic");
        a = 7; b = 7; opcode = 3'b100; #10; check(8'd1, "CMP-equal");

        // ---- Randomized regression: 100 pseudo-random operand/opcode pairs ----
        for (i = 0; i < 100; i = i + 1) begin
            a = $random;
            b = $random;
            opcode = $random % 4;      // exercise ADD / SUB / AND / OR
            #10;
            case (opcode)
                3'b000: check(a + b, "ADD-rand");
                3'b001: check(a - b, "SUB-rand");
                3'b010: check(a & b, "AND-rand");
                3'b011: check(a | b, "OR-rand");
            endcase
        end

        // ---- Summary ----
        if (errors == 0)
            $display(">>> ALL TESTS PASSED (WIDTH=%0d)", WIDTH);
        else
            $display(">>> %0d TEST(S) FAILED (WIDTH=%0d)", errors, WIDTH);

        $finish;
    end
endmodule
