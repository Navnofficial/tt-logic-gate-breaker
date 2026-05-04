// =============================================================
// trigger.v
// Rising-edge trigger on selected channel.
// Latches bit position and produces a flash counter for visual.
// =============================================================
`default_nettype none

module trigger (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  sig_in,
    input  wire [3:0]  prev_sig,
    input  wire [1:0]  ch_sel,
    input  wire        sample_tick,
    output reg  [4:0]  trig_pos,
    output reg         trig_fire,
    output reg  [3:0]  trig_flash
);

wire cur_bit  = (ch_sel == 2'd0) ? sig_in[0]  :
                (ch_sel == 2'd1) ? sig_in[1]  :
                (ch_sel == 2'd2) ? sig_in[2]  : sig_in[3];

wire prev_bit = (ch_sel == 2'd0) ? prev_sig[0] :
                (ch_sel == 2'd1) ? prev_sig[1] :
                (ch_sel == 2'd2) ? prev_sig[2] : prev_sig[3];

wire rising = cur_bit & ~prev_bit;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        trig_pos   <= 5'd0;
        trig_fire  <= 1'b0;
        trig_flash <= 4'd0;
    end else begin
        trig_fire <= 1'b0;
        if (sample_tick) begin
            if (rising) begin
                trig_fire  <= 1'b1;
                trig_pos   <= 5'd31;
                trig_flash <= 4'd15;
            end else if (trig_flash != 4'd0) begin
                trig_flash <= trig_flash - 4'd1;
            end
        end
    end
end

endmodule
