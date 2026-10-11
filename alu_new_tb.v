// =================================================================
// Self-checking testbench for the extended parameterized ALU
// Run : iverilog -o sim alu_full.v alu_full_tb.v && vvp sim
// Other width: iverilog -o sim -Palu_full_tb.WIDTH=16 alu_full.v alu_full_tb.v && vvp sim
// The expected values come from a separate reference model
// (plain integers and shift loops), not from the same operators
// used in the design, so a design bug cannot hide itself.
// =================================================================
`timescale 1ns/1ps

module alu_full_tb;
    parameter WIDTH = 8;

    reg  [WIDTH-1:0] a, b;
    reg  [3:0]       opcode;
    wire [WIDTH-1:0] result;
    wire             carry_borrow, overflow, zero, equal, greater, less;

    integer errors = 0;
    integer tests  = 0;
    integer i, op;

    alu #(.WIDTH(WIDTH)) dut (
        .a(a), .b(b), .opcode(opcode),
        .result(result), .carry_borrow(carry_borrow), .overflow(overflow),
        .zero(zero), .equal(equal), .greater(greater), .less(less)
    );

    // ---- reference shifts: move one bit at a time, at most WIDTH times ----
    function [WIDTH-1:0] ref_shl(input [WIDTH-1:0] x, input integer n);
        integer k;
        begin
            ref_shl = x;
            for (k = 0; k < n && k < WIDTH; k = k + 1)
                ref_shl = {ref_shl[WIDTH-2:0], 1'b0};
        end
    endfunction

    function [WIDTH-1:0] ref_shr(input [WIDTH-1:0] x, input integer n);
        integer k;
        begin
            ref_shr = x;
            for (k = 0; k < n && k < WIDTH; k = k + 1)
                ref_shr = {1'b0, ref_shr[WIDTH-1:1]};
        end
    endfunction

    function [WIDTH-1:0] ref_sra(input [WIDTH-1:0] x, input integer n);
        integer k;
        reg s;
        begin
            ref_sra = x;
            s = x[WIDTH-1];
            for (k = 0; k < n && k < WIDTH; k = k + 1)
                ref_sra = {s, ref_sra[WIDTH-1:1]};
        end
    endfunction

    // ---- apply one test and compare result + all flags ----
    task run_test(input [3:0] op_in, input [WIDTH-1:0] av, input [WIDTH-1:0] bv,
                  input [8*12-1:0] label);
        reg [WIDTH-1:0] exp_res;
        reg exp_c, exp_v;
        integer ai, bi, as, bs, ss, maxs, mins;
        begin
            a = av; b = bv; opcode = op_in; #10;
            tests = tests + 1;

            ai = av; bi = bv;
            as = av[WIDTH-1] ? ai - (1 << WIDTH) : ai;   // signed value of a
            bs = bv[WIDTH-1] ? bi - (1 << WIDTH) : bi;   // signed value of b
            maxs =  (1 << (WIDTH-1)) - 1;
            mins = -(1 << (WIDTH-1));
            exp_c = 0; exp_v = 0;

            case (op_in)
                4'b0000: begin exp_res = ai + bi; exp_c = ((ai + bi) >= (1 << WIDTH));
                               ss = as + bs;      exp_v = (ss > maxs) || (ss < mins); end
                4'b0001: begin exp_res = ai - bi; exp_c = (ai < bi);
                               ss = as - bs;      exp_v = (ss > maxs) || (ss < mins); end
                4'b0010: exp_res = av & bv;
                4'b0011: exp_res = av | bv;
                4'b0100: exp_res = av ^ bv;
                4'b0101: exp_res = ref_shl(av, bi);
                4'b0110: exp_res = ref_shr(av, bi);
                4'b0111: exp_res = ref_sra(av, bi);
                4'b1000: exp_res = (ai == bi);
                4'b1001: exp_res = (ai >  bi);
                4'b1010: exp_res = (ai <  bi);
                default: exp_res = 0;
            endcase

            if (result !== exp_res || carry_borrow !== exp_c || overflow !== exp_v ||
                zero !== (exp_res == 0) || equal !== (ai == bi) ||
                greater !== (ai > bi) || less !== (ai < bi)) begin
                errors = errors + 1;
                $display("FAIL [%0s] op=%b a=%0d b=%0d | res=%0d(exp %0d) c=%b(exp %b) v=%b(exp %b)",
                         label, op_in, av, bv, result, exp_res, carry_borrow, exp_c, overflow, exp_v);
            end
        end
    endtask

    reg [WIDTH-1:0] MAXPOS, MINNEG, ALLONES;

    initial begin
        $dumpfile("alu_full_tb.vcd");
        $dumpvars(0, alu_full_tb);

        MAXPOS  = {1'b0, {(WIDTH-1){1'b1}}};   // largest positive signed number
        MINNEG  = {1'b1, {(WIDTH-1){1'b0}}};   // most negative signed number
        ALLONES = {WIDTH{1'b1}};

        // ---- hand-checked sanity cases (not from the model) ----
        a = 5; b = 3; opcode = 4'b0000; #10;
        if (result !== 8) begin errors = errors + 1; $display("FAIL [hand ADD]"); end
        a = 3; b = 1; opcode = 4'b0101; #10;
        if (result !== 6) begin errors = errors + 1; $display("FAIL [hand SLL]"); end
        a = MINNEG; b = 1; opcode = 4'b0111; #10;
        if (result !== (MINNEG | (MINNEG >> 1))) begin errors = errors + 1; $display("FAIL [hand SRA]"); end
        a = MINNEG; b = 1; opcode = 4'b0110; #10;
        if (result !== (MINNEG >> 1)) begin errors = errors + 1; $display("FAIL [hand SRL]"); end

        // ---- directed edge cases ----
        run_test(4'b0000, 0,       0,       "ADD-zero");
        run_test(4'b0000, ALLONES, 1,       "ADD-carry");
        run_test(4'b0000, MAXPOS,  1,       "ADD-ovf");
        run_test(4'b0000, MINNEG,  MINNEG,  "ADD-negneg");
        run_test(4'b0001, 5,       3,       "SUB-basic");
        run_test(4'b0001, 3,       5,       "SUB-borrow");
        run_test(4'b0001, MINNEG,  1,       "SUB-ovf");
        run_test(4'b0001, MAXPOS,  ALLONES, "SUB-ovf2");
        run_test(4'b0100, ALLONES, MAXPOS,  "XOR-basic");
        run_test(4'b0101, MAXPOS,  WIDTH,   "SLL-full");
        run_test(4'b0110, ALLONES, WIDTH,   "SRL-full");
        run_test(4'b0111, MINNEG,  WIDTH,   "SRA-full-neg");
        run_test(4'b0111, MAXPOS,  WIDTH,   "SRA-full-pos");
        run_test(4'b1000, 7,       7,       "EQ-true");
        run_test(4'b1001, 7,       3,       "GT-true");
        run_test(4'b1010, 3,       7,       "LT-true");

        // ---- random regression: every opcode (even unused ones) ----
        for (i = 0; i < 100; i = i + 1)
            for (op = 0; op < 16; op = op + 1)
                run_test(op, $random, $random, "random");

        // ---- random shifts with small shift amounts (so real shifting happens) ----
        for (i = 0; i < 100; i = i + 1)
            for (op = 5; op <= 7; op = op + 1)
                run_test(op, $random, {$random} % (WIDTH + 1), "rand-shift");

        if (errors == 0)
            $display(">>> ALL %0d TESTS PASSED (WIDTH=%0d)", tests, WIDTH);
        else
            $display(">>> %0d OF %0d TESTS FAILED (WIDTH=%0d)", errors, tests, WIDTH);
        $finish;
    end
endmodule
