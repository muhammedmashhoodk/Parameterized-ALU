`timescale 1ns/1ps

module alu_tb;

    // Parameters
    parameter WIDTH = 2;

    // Inputs
    reg [WIDTH-1:0] a;
    reg [WIDTH-1:0] b;
    reg [3:0] opcode;

    // Outputs
    wire [WIDTH-1:0] result;
    wire carry_borrow;
    wire overflow;
    wire zero;
    wire equal;
    wire greater;
    wire less;

    // Instantiate the Unit Under Test (UUT)
    alu #( .WIDTH(WIDTH) ) uut (
        .a(a), 
        .b(b), 
        .opcode(opcode), 
        .result(result), 
        .carry_borrow(carry_borrow), 
        .overflow(overflow), 
        .zero(zero), 
        .equal(equal), 
        .greater(greater), 
        .less(less)
    );

    initial begin
        // Initialize Inputs
        a = 2'b00; b = 2'b00; opcode = 4'b0000;

        // Wait 100 ns for global reset to finish
        #100;

        // Test 1: ADD (1 + 2 = 3)
        // Expected: result = 11, carry_borrow = 0
        opcode = 4'b0000; a = 2'b01; b = 2'b10; 
        #10;

        // Test 2: ADD with Carry (2 + 3 = 5)
        // Expected: result = 01, carry_borrow = 1 (overflows 2 bits)
        opcode = 4'b0000; a = 2'b10; b = 2'b11; 
        #10;

        // Test 3: SUB (3 - 1 = 2)
        // Expected: result = 10, carry_borrow = 0
        opcode = 4'b0001; a = 2'b11; b = 2'b01; 
        #10;

        // Test 4: SUB with Borrow (1 - 2 = -1)
        // Expected: result = 11, carry_borrow = 1
        opcode = 4'b0001; a = 2'b01; b = 2'b10; 
        #10;

        // Test 5: AND (3 AND 2)
        // Expected: result = 10 (11 & 10 = 10)
        opcode = 4'b0010; a = 2'b11; b = 2'b10; 
        #10;

        // Test 6: Logical Shift Left (1 << 1)
        // Expected: result = 10
        opcode = 4'b0101; a = 2'b01; b = 2'b01; 
        #10;

        // Test 7: Equality check (2 == 2)
        // Expected: result = 01, equal = 1
        opcode = 4'b1000; a = 2'b10; b = 2'b10; 
        #10;

        // Test 8: Less Than check (1 < 3)
        // Expected: result = 01, less = 1
        opcode = 4'b1010; a = 2'b01; b = 2'b11; 
        #10;

        // End simulation
        $finish;
    end
      
endmodule
