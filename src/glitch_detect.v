// =============================================================
// glitch_detect.v
// Flags pulses shorter than 4 sample periods per channel.
// Uses 2-bit saturating counters, flags on edge if count < 3.
// =============================================================
`default_nettype none

module glitch_detect (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] sig_in,
    input  wire       sample_tick,
    output reg  [3:0] glitch
);

reg [3:0] prev;
reg [1:0] cnt0, cnt1, cnt2, cnt3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev   <= 4'd0;
        cnt0   <= 2'd3;
        cnt1   <= 2'd3;
        cnt2   <= 2'd3;
        cnt3   <= 2'd3;
        glitch <= 4'd0;
    end else if (sample_tick) begin
        prev <= sig_in;

        // Channel 0
        if (sig_in[0] != prev[0]) begin
            glitch[0] <= (cnt0 < 2'd3);
            cnt0 <= 2'd0;
        end else begin
            if (cnt0 < 2'd3) cnt0 <= cnt0 + 2'd1;
            glitch[0] <= 1'b0;
        end

        // Channel 1
        if (sig_in[1] != prev[1]) begin
            glitch[1] <= (cnt1 < 2'd3);
            cnt1 <= 2'd0;
        end else begin
            if (cnt1 < 2'd3) cnt1 <= cnt1 + 2'd1;
            glitch[1] <= 1'b0;
        end

        // Channel 2
        if (sig_in[2] != prev[2]) begin
            glitch[2] <= (cnt2 < 2'd3);
            cnt2 <= 2'd0;
        end else begin
            if (cnt2 < 2'd3) cnt2 <= cnt2 + 2'd1;
            glitch[2] <= 1'b0;
        end

        // Channel 3
        if (sig_in[3] != prev[3]) begin
            glitch[3] <= (cnt3 < 2'd3);
            cnt3 <= 2'd0;
        end else begin
            if (cnt3 < 2'd3) cnt3 <= cnt3 + 2'd1;
            glitch[3] <= 1'b0;
        end
    end
end

endmodule
