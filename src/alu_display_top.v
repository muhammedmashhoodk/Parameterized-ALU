// =================================================================
// alu_display_top.v  --  ALU result on the seven-segment display
// -----------------------------------------------------------------
// Target : Xilinx Spartan-6 (XC6SLX16, CSG324) - Digilent Nexys 3 pinout
// Uses   : alu.v (the parameterized ALU), instantiated with WIDTH = 5
//
// Inputs
//   sw[3:0]  = operand A (0 to 15)
//   sw[7:4]  = operand B (0 to 15)
//   btnU     = ADD mode  (A + B)      <- default after configuration
//   btnD     = SUB mode  (A - B)
// Outputs
//   Right-most digits show the result in DECIMAL, with a minus sign
//   when A - B is negative  (e.g.  12,  30,  -3,  -15).
//   LED0 = ADD mode, LED1 = SUB mode, LED2 = negative result,
//   LED7..LED3 = raw 5-bit ALU result (binary, for cross-checking).
// =================================================================
module alu_display_top #(
    parameter REFRESH_BITS = 17     // display scan counter: 17 bits -> ~760 Hz at 100 MHz
)(
    input  wire       clk,          // 100 MHz board clock
    input  wire [7:0] sw,
    input  wire       btnU,
    input  wire       btnD,
    output reg  [6:0] seg,          // {g,f,e,d,c,b,a}, active LOW (common-anode display)
    output wire       dp,           // decimal point, active LOW (kept off)
    output reg  [3:0] an,           // digit enables, active LOW; an[0] = right-most digit
    output wire [7:0] led
);

    // ---------------------------------------------------------------
    // 1. Button synchronizers and operation mode (0 = ADD, 1 = SUB)
    // ---------------------------------------------------------------
    reg [1:0] syncU = 2'b00;
    reg [1:0] syncD = 2'b00;
    reg       mode  = 1'b0;

    always @(posedge clk) begin
        syncU <= {syncU[0], btnU};
        syncD <= {syncD[0], btnD};
        if      (syncU[1]) mode <= 1'b0;     // ADD
        else if (syncD[1]) mode <= 1'b1;     // SUB
    end

    // ---------------------------------------------------------------
    // 2. The parameterized ALU, built 5 bits wide:
    //    A and B are 0..15, so A+B (max 30) fits in 5 bits with no carry,
    //    and A-B wraps below zero, which the borrow flag reports.
    // ---------------------------------------------------------------
    wire [4:0] res;
    wire       cb;

    alu #(.WIDTH(5)) u_alu (
        .a            ({1'b0, sw[3:0]}),
        .b            ({1'b0, sw[7:4]}),
        .opcode       ({2'b00, mode}),       // 000 = ADD, 001 = SUB
        .result       (res),
        .carry_borrow (cb),
        .zero         (),
        .equal        (),
        .greater      (),
        .less         ()
    );

    // ---------------------------------------------------------------
    // 3. Sign and magnitude.  Borrow = 1 in SUB means A < B, so the true
    //    answer is negative and 'res' holds its 5-bit two's complement.
    // ---------------------------------------------------------------
    wire       neg = mode & cb;
    wire [4:0] mag = neg ? (~res + 5'd1) : res;     // 0..30

    // ---------------------------------------------------------------
    // 4. Binary to decimal (mag is at most 30, so tens is 0..3)
    // ---------------------------------------------------------------
    wire [1:0] tens     = (mag >= 5'd30) ? 2'd3 :
                          (mag >= 5'd20) ? 2'd2 :
                          (mag >= 5'd10) ? 2'd1 : 2'd0;
    wire [4:0] tens_val = (tens == 2'd3) ? 5'd30 :
                          (tens == 2'd2) ? 5'd20 :
                          (tens == 2'd1) ? 5'd10 : 5'd0;
    wire [3:0] ones     = mag - tens_val;           // 0..9

    // Digit codes: 0-9 = numerals, 10 = blank, 11 = minus sign
    localparam BLANK = 4'd10;
    localparam MINUS = 4'd11;

    wire [3:0] d0 = ones;
    wire [3:0] d1 = (tens != 2'd0) ? {2'b00, tens} : (neg ? MINUS : BLANK);
    wire [3:0] d2 = (tens != 2'd0 && neg) ? MINUS : BLANK;
    wire [3:0] d3 = BLANK;

    // ---------------------------------------------------------------
    // 5. Time-multiplexed display scan (one digit lit at a time)
    // ---------------------------------------------------------------
    reg [REFRESH_BITS-1:0] cnt = 0;
    always @(posedge clk) cnt <= cnt + 1'b1;

    wire [1:0] sel = cnt[REFRESH_BITS-1:REFRESH_BITS-2];

    reg [3:0] digit;
    always @(*) begin
        case (sel)
            2'd0:    begin digit = d0; an = 4'b1110; end
            2'd1:    begin digit = d1; an = 4'b1101; end
            2'd2:    begin digit = d2; an = 4'b1011; end
            default: begin digit = d3; an = 4'b0111; end
        endcase
    end

    // Seven-segment decoder, active LOW, bit order {g,f,e,d,c,b,a}
    always @(*) begin
        case (digit)
            4'd0:    seg = 7'b1000000;
            4'd1:    seg = 7'b1111001;
            4'd2:    seg = 7'b0100100;
            4'd3:    seg = 7'b0110000;
            4'd4:    seg = 7'b0011001;
            4'd5:    seg = 7'b0010010;
            4'd6:    seg = 7'b0000010;
            4'd7:    seg = 7'b1111000;
            4'd8:    seg = 7'b0000000;
            4'd9:    seg = 7'b0010000;
            MINUS:   seg = 7'b0111111;     // only segment g lit
            default: seg = 7'b1111111;     // blank
        endcase
    end

    assign dp  = 1'b1;
    assign led = {res, neg, mode, ~mode};

endmodule
