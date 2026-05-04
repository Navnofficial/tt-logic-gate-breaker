// =============================================================
// gamepad.v
// Debounced gamepad: Up/Down = channel select, Left/Right = timescale.
// Samples once per vsync falling edge (~60 Hz).
// =============================================================
`default_nettype none

module gamepad (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] buttons,   // {right, left, down, up} = ui_in[7:4]
    input  wire       vsync,
    output reg  [1:0] ch_sel,
    output reg  [1:0] timescale_sel
);

localparam BTN_UP    = 0;
localparam BTN_DOWN  = 1;
localparam BTN_LEFT  = 2;
localparam BTN_RIGHT = 3;

reg [3:0] btn_prev;
reg       vsync_prev;
wire      vsync_fall = vsync_prev & ~vsync;
wire [3:0] btn_rose  = buttons & ~btn_prev;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ch_sel        <= 2'd0;
        timescale_sel <= 2'd0;
        btn_prev      <= 4'd0;
        vsync_prev    <= 1'b1;
    end else begin
        vsync_prev <= vsync;
        if (vsync_fall) begin
            btn_prev <= buttons;
            if (btn_rose[BTN_UP]    && ch_sel != 2'd0)
                ch_sel <= ch_sel - 2'd1;
            if (btn_rose[BTN_DOWN]  && ch_sel != 2'd3)
                ch_sel <= ch_sel + 2'd1;
            if (btn_rose[BTN_LEFT]  && timescale_sel != 2'd0)
                timescale_sel <= timescale_sel - 2'd1;
            if (btn_rose[BTN_RIGHT] && timescale_sel != 2'd3)
                timescale_sel <= timescale_sel + 2'd1;
        end
    end
end

endmodule
