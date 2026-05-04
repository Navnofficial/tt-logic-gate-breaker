// =============================================================
// vga_timing.v
// 640x480 @ 60Hz, 25.175MHz pixel clock
// H: 640 visible + 16 FP + 96 sync + 48 BP = 800 total
// V: 480 visible + 10 FP +  2 sync + 33 BP = 525 total
// Sync polarity: hsync negative, vsync negative (standard VGA)
// =============================================================
`default_nettype none

module vga_timing (
    input  wire        clk,
    input  wire        rst_n,
    output reg  [9:0]  hpos,
    output reg  [9:0]  vpos,
    output reg         hsync,
    output reg         vsync,
    output wire        active
);

localparam H_VISIBLE = 640;
localparam H_FRONT   =  16;
localparam H_SYNC    =  96;
localparam H_BACK    =  48;
localparam H_TOTAL   = 800;

localparam V_VISIBLE = 480;
localparam V_FRONT   =  10;
localparam V_SYNC    =   2;
localparam V_BACK    =  33;
localparam V_TOTAL   = 525;

// Active-area flag (combinational — gates pixel output same cycle)
assign active = (hpos < H_VISIBLE && vpos < V_VISIBLE);

// Registered counter + sync (matches standard TT hvsync_generator pattern).
// hsync/vsync are computed from the CURRENT hpos/vpos and registered,
// so they appear on the output one cycle later — standard for VGA.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hpos  <= 10'd0;
        vpos  <= 10'd0;
        hsync <= 1'b1;
        vsync <= 1'b1;
    end else begin
        // Registered sync pulses (active-low)
        hsync <= ~(hpos >= (H_VISIBLE + H_FRONT) &&
                   hpos <  (H_VISIBLE + H_FRONT + H_SYNC));
        vsync <= ~(vpos >= (V_VISIBLE + V_FRONT) &&
                   vpos <  (V_VISIBLE + V_FRONT + V_SYNC));

        // Pixel counter
        if (hpos == H_TOTAL - 1) begin
            hpos <= 10'd0;
            if (vpos == V_TOTAL - 1)
                vpos <= 10'd0;
            else
                vpos <= vpos + 10'd1;
        end else begin
            hpos <= hpos + 10'd1;
        end
    end
end

endmodule