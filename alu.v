// =================================================================
// Parameterized Arithmetic Logic Unit (ALU)
// -----------------------------------------------------------------
// Project : Calculator SoC  (Logic Circuit Design, PBECT304, S3 ECE 2)
// Module  : alu
// -----------------------------------------------------------------
// WIDTH sets the operand size. Instantiate with #(.WIDTH(4)),
// #(.WIDTH(8)), #(.WIDTH(16)), etc. - no other change is needed;
// every internal signal scales automatically with WIDTH.
// =================================================================

module alu #(
    parameter WIDTH = 8                    // operand width in bits (default 8)
)(
    input  wire [WIDTH-1:0] a,             // Operand A
    input  wire [WIDTH-1:0] b,             // Operand B
    input  wire [2:0]       opcode,        // Operation select (see localparams below)
    output reg  [WIDTH-1:0] result,        // Result of the selected operation
    output reg              carry_borrow,  // Carry-out (ADD) / Borrow (SUB)
    output wire             zero,          // 1 when result == 0
    output wire             equal,         // 1 when a == b
    output wire             greater,       // 1 when a >  b
    output wire             less           // 1 when a <  b
);

    // -----------------------------------------------------------
    // Opcode encoding. Add more localparams here (e.g. XOR, SHL)
    // if you extend the instruction set later - nothing else in
    // this module needs to change except the case statement below.
    // -----------------------------------------------------------
    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_AND = 3'b010;
    localparam OP_OR  = 3'b011;
    localparam OP_CMP = 3'b100;

    // -----------------------------------------------------------
    // Both operands are extended by one extra bit (WIDTH+1 total)
    // before add/subtract. That extra top bit is exactly the
    // carry-out for addition, or the borrow flag for subtraction:
    // if a < b, the subtraction "wraps" and the top bit becomes 1.
    // These are computed continuously (wires), the ALU just picks
    // which one to use inside the always block below.
    // -----------------------------------------------------------
    wire [WIDTH:0] add_ext = {1'b0, a} + {1'b0, b};
    wire [WIDTH:0] sub_ext = {1'b0, a} - {1'b0, b};

    // -----------------------------------------------------------
    // Main operation-select logic. This block is combinational
    // (no clock) - it re-evaluates instantly whenever a, b, or
    // opcode changes. In hardware this synthesizes to a 4:1
    // multiplexer fed by four parallel units (adder/subtractor,
    // AND array, OR array, comparator), all computing at once.
    // -----------------------------------------------------------
    always @(*) begin
        carry_borrow = 1'b0;               // default; overwritten for ADD/SUB below

        case (opcode)
            OP_ADD: begin
                result       = add_ext[WIDTH-1:0]; // lower WIDTH bits = the sum
                carry_borrow = add_ext[WIDTH];      // extra bit = carry-out
            end

            OP_SUB: begin
                result       = sub_ext[WIDTH-1:0]; // lower WIDTH bits = the difference
                carry_borrow = sub_ext[WIDTH];      // extra bit = borrow (1 if a < b)
            end

            OP_AND:  result = a & b;               // bitwise AND, every bit independent
            OP_OR:   result = a | b;               // bitwise OR,  every bit independent

            OP_CMP:  result = {{(WIDTH-1){1'b0}}, (a == b)};
                     // equality packed into result's LSB, rest zero-padded

            default: result = {WIDTH{1'b0}};       // unused opcodes -> safe all-zero output
        endcase
    end

    // -----------------------------------------------------------
    // Flag outputs. These are plain combinational assigns, so they
    // are always valid regardless of which opcode is selected -
    // useful if your FSM controller wants the comparison flags
    // even while the ALU happens to be doing an ADD or AND.
    // -----------------------------------------------------------
    assign zero    = (result == {WIDTH{1'b0}}); // true when the selected result is all zero
    assign equal   = (a == b);                  // true when operands match exactly
    assign greater = (a > b);                   // unsigned magnitude comparison
    assign less    = (a < b);                   // unsigned magnitude comparison

endmodule
