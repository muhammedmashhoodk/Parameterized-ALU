// =================================================================
// Parameterized ALU - extended operation set
//   Arithmetic : ADD, SUB   (carry/borrow + signed overflow flags)
//   Logic      : AND, OR, XOR
//   Shifts     : logical left, logical right, arithmetic right
//   Comparison : equal, greater-than, less-than (1-bit result)
// WIDTH sets the operand size; opcode is now 4 bits.
// =================================================================
module alu #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,             // Operand A
    input  wire [WIDTH-1:0] b,             // Operand B (also the shift amount for shifts)
    input  wire [3:0]       opcode,        // Operation select (4 bits now)
    output reg  [WIDTH-1:0] result,        // Result of the selected operation
    output reg              carry_borrow,  // Unsigned carry-out (ADD) / borrow (SUB)
    output reg              overflow,      // Signed overflow (ADD / SUB)
    output wire             zero,          // 1 when result == 0
    output wire             equal,         // 1 when a == b
    output wire             greater,       // 1 when a >  b (unsigned)
    output wire             less           // 1 when a <  b (unsigned)
);

    // ---- Opcode encoding ----
    localparam OP_ADD = 4'b0000;
    localparam OP_SUB = 4'b0001;
    localparam OP_AND = 4'b0010;
    localparam OP_OR  = 4'b0011;
    localparam OP_XOR = 4'b0100;
    localparam OP_SLL = 4'b0101;   // logical shift left   (a << b)
    localparam OP_SRL = 4'b0110;   // logical shift right  (a >> b)
    localparam OP_SRA = 4'b0111;   // arithmetic shift right (sign bit copied in)
    localparam OP_EQ  = 4'b1000;   // result = (a == b)
    localparam OP_GT  = 4'b1001;   // result = (a >  b)
    localparam OP_LT  = 4'b1010;   // result = (a <  b)

    // One extra bit catches carry-out (ADD) / borrow (SUB)
    wire [WIDTH:0] add_ext = {1'b0, a} + {1'b0, b};
    wire [WIDTH:0] sub_ext = {1'b0, a} - {1'b0, b};

    always @(*) begin
        carry_borrow = 1'b0;           // defaults, overwritten only by ADD / SUB
        overflow     = 1'b0;

        case (opcode)
            OP_ADD: begin
                result       = add_ext[WIDTH-1:0];
                carry_borrow = add_ext[WIDTH];
                // signed overflow: both inputs same sign, result sign differs
                overflow     = (a[WIDTH-1] == b[WIDTH-1]) && (add_ext[WIDTH-1] != a[WIDTH-1]);
            end

            OP_SUB: begin
                result       = sub_ext[WIDTH-1:0];
                carry_borrow = sub_ext[WIDTH];
                // signed overflow: inputs have different signs, result sign differs from a
                overflow     = (a[WIDTH-1] != b[WIDTH-1]) && (sub_ext[WIDTH-1] != a[WIDTH-1]);
            end

            OP_AND: result = a & b;
            OP_OR:  result = a | b;
            OP_XOR: result = a ^ b;

            OP_SLL: result = a << b;                 // shifting by >= WIDTH gives 0
            OP_SRL: result = a >> b;                 // zeros shifted in from the left
            OP_SRA: result = $signed(a) >>> b;       // sign bit shifted in from the left

            OP_EQ:  result = {{(WIDTH-1){1'b0}}, (a == b)};
            OP_GT:  result = {{(WIDTH-1){1'b0}}, (a >  b)};
            OP_LT:  result = {{(WIDTH-1){1'b0}}, (a <  b)};

            default: result = {WIDTH{1'b0}};         // unused opcodes -> all zero
        endcase
    end

    assign zero    = (result == {WIDTH{1'b0}});
    assign equal   = (a == b);
    assign greater = (a > b);
    assign less    = (a < b);

endmodule
