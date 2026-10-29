// Self-checking testbench for alu_display_top: tries every A, B and both
// modes (512 cases), reads the multiplexed display and compares the text
// it shows with the expected decimal answer.
`timescale 1ns/1ps
module alu_display_tb;
    reg        clk = 0;
    reg  [7:0] sw  = 8'd0;
    reg        btnU = 0, btnD = 0;
    wire [6:0] seg;
    wire       dp;
    wire [3:0] an;
    wire [7:0] led;
    integer    errors = 0, tests = 0;

    // small scan counter so each digit is refreshed within a few clock cycles
    alu_display_top #(.REFRESH_BITS(6)) dut (
        .clk(clk), .sw(sw), .btnU(btnU), .btnD(btnD),
        .seg(seg), .dp(dp), .an(an), .led(led)
    );

    always #5 clk = ~clk;

    function [7:0] decode;
        input [6:0] s;
        begin
            case (s)
                7'b1000000: decode = "0";   7'b1111001: decode = "1";
                7'b0100100: decode = "2";   7'b0110000: decode = "3";
                7'b0011001: decode = "4";   7'b0010010: decode = "5";
                7'b0000010: decode = "6";   7'b1111000: decode = "7";
                7'b0000000: decode = "8";   7'b0010000: decode = "9";
                7'b0111111: decode = "-";   7'b1111111: decode = " ";
                default:    decode = "?";
            endcase
        end
    endfunction

    task check;
        input integer a;
        input integer b;
        input integer m;               // 0 = ADD, 1 = SUB
        reg [7:0] c0, c1, c2, c3;
        reg [8*4-1:0] got, expd;
        integer k, val;
        begin
            tests = tests + 1;
            @(negedge clk);
            sw   = {b[3:0], a[3:0]};
            btnU = (m == 0);
            btnD = (m == 1);
            repeat (6) @(negedge clk);
            btnU = 0; btnD = 0;
            repeat (6) @(negedge clk);
            c0 = "?"; c1 = "?"; c2 = "?"; c3 = "?";
            for (k = 0; k < 80; k = k + 1) begin
                @(negedge clk);
                if (!an[0]) c0 = decode(seg);
                if (!an[1]) c1 = decode(seg);
                if (!an[2]) c2 = decode(seg);
                if (!an[3]) c3 = decode(seg);
            end
            got = {c3, c2, c1, c0};
            val = (m == 0) ? (a + b) : (a - b);
            $sformat(expd, "%4d", val);
            if (got !== expd) begin
                errors = errors + 1;
                $display("[FAIL] %0d %s %0d : display shows '%0s', expected '%0s'",
                          a, (m == 0) ? "+" : "-", b, got, expd);
            end
        end
    endtask

    integer a, b, m;
    initial begin
        $dumpfile("alu_display.vcd");
        $dumpvars(0, alu_display_tb);
        repeat (4) @(negedge clk);
        for (m = 0; m < 2; m = m + 1)
            for (a = 0; a < 16; a = a + 1)
                for (b = 0; b < 16; b = b + 1)
                    check(a, b, m);
        $display("----------------------------------------------------");
        if (errors == 0) $display(">>> ALL %0d DISPLAY TESTS PASSED", tests);
        else             $display(">>> %0d of %0d TESTS FAILED", errors, tests);
        $display("----------------------------------------------------");
        $finish;
    end
endmodule
