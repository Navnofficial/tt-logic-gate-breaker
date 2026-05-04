// =============================================================
// sampler.v
// 4-channel signal sampler with prescaler and 32-bit shift registers.
// Timescale: 0=every clk, 1=every 4, 2=every 16, 3=every 64
// =============================================================
`default_nettype none

module sampler (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  sig_in,
    input  wire [1:0]  timescale_sel,
    output reg  [31:0] sr0, sr1, sr2, sr3,
    output reg  [3:0]  prev_sig,
    output reg         sample_tick
);

// Prescaler counter (6-bit, max 63)
reg [5:0] prescaler;

wire [5:0] prescaler_max = (timescale_sel == 2'd0) ? 6'd0  :
                           (timescale_sel == 2'd1) ? 6'd3  :
                           (timescale_sel == 2'd2) ? 6'd15 :
                                                     6'd63 ;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prescaler   <= 6'd0;
        sr0         <= 32'd0;
        sr1         <= 32'd0;
        sr2         <= 32'd0;
        sr3         <= 32'd0;
        prev_sig    <= 4'd0;
        sample_tick <= 1'b0;
    end else begin
        if (prescaler >= prescaler_max) begin
            prescaler   <= 6'd0;
            sample_tick <= 1'b1;
            prev_sig    <= sig_in;
            sr0 <= {sr0[30:0], sig_in[0]};
            sr1 <= {sr1[30:0], sig_in[1]};
            sr2 <= {sr2[30:0], sig_in[2]};
            sr3 <= {sr3[30:0], sig_in[3]};
        end else begin
            prescaler   <= prescaler + 6'd1;
            sample_tick <= 1'b0;
        end
    end
end

endmodule
