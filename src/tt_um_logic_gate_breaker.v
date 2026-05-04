// =============================================================
// tt_um_logic_gate_breaker.v
// Top module: 4-Channel Hardware Logic Analyzer
// Tiny Tapeout SKY26a Demoscene Competition Entry
//
// Inputs:
//   ui_in[3:0] = 4 digital signal channels (CH1-CH4)
//   ui_in[7:4] = gamepad {Right, Left, Down, Up}
//
// Outputs:
//   uo_out = TinyVGA PMOD: {hsync, B0, G0, R0, vsync, B1, G1, R1}
// =============================================================
`default_nettype none

module tt_um_logic_gate_breaker (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Bidirectional pins unused
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Suppress unused-input warnings
    wire _unused_ok = &{ena, uio_in, 1'b0};

    // ---- Signal and button extraction ----
    wire [3:0] sig_in  = ui_in[3:0];    // CH1-CH4
    wire [3:0] buttons = ui_in[7:4];    // Up, Down, Left, Right

    // ---- Internal wires ----
    wire [9:0] hpos, vpos;
    wire       hsync, vsync, active;

    wire [31:0] sr0, sr1, sr2, sr3;
    wire [3:0]  prev_sig;
    wire        sample_tick;

    wire [1:0] ch_sel;
    wire [1:0] timescale_sel;

    wire [4:0] trig_pos;
    wire       trig_fire;
    wire [3:0] trig_flash;

    wire [3:0] glitch;
    wire [2:0] boot_phase;
    wire [7:0] liquid_level;
    wire [7:0] frame_in_phase;

    wire [1:0] r, g, b;

    // ---- VGA timing ----
    vga_timing u_vga (
        .clk   (clk),
        .rst_n (rst_n),
        .hpos  (hpos),
        .vpos  (vpos),
        .hsync (hsync),
        .vsync (vsync),
        .active(active)
    );

    // ---- Gamepad controller ----
    gamepad u_gamepad (
        .clk          (clk),
        .rst_n        (rst_n),
        .buttons      (buttons),
        .vsync        (vsync),
        .ch_sel       (ch_sel),
        .timescale_sel(timescale_sel)
    );

    // ---- Signal sampler + shift registers ----
    sampler u_sampler (
        .clk          (clk),
        .rst_n        (rst_n),
        .sig_in       (sig_in),
        .timescale_sel(timescale_sel),
        .sr0          (sr0),
        .sr1          (sr1),
        .sr2          (sr2),
        .sr3          (sr3),
        .prev_sig     (prev_sig),
        .sample_tick  (sample_tick)
    );

    // ---- Trigger system ----
    trigger u_trigger (
        .clk        (clk),
        .rst_n      (rst_n),
        .sig_in     (sig_in),
        .prev_sig   (prev_sig),
        .ch_sel     (ch_sel),
        .sample_tick(sample_tick),
        .trig_pos   (trig_pos),
        .trig_fire  (trig_fire),
        .trig_flash (trig_flash)
    );

    // ---- Glitch detector ----
    glitch_detect u_glitch (
        .clk        (clk),
        .rst_n      (rst_n),
        .sig_in     (sig_in),
        .sample_tick(sample_tick),
        .glitch     (glitch)
    );

    // ---- Boot animation ----
    boot_anim u_boot (
        .clk           (clk),
        .rst_n         (rst_n),
        .vsync         (vsync),
        .boot_phase    (boot_phase),
        .liquid_level  (liquid_level),
        .frame_in_phase(frame_in_phase)
    );

    // ---- Renderer (combinational pixel pipeline) ----
    renderer u_renderer (
        .hpos         (hpos),
        .vpos         (vpos),
        .active       (active),
        .sr0          (sr0),
        .sr1          (sr1),
        .sr2          (sr2),
        .sr3          (sr3),
        .sig_in       (sig_in),
        .ch_sel       (ch_sel),
        .timescale_sel(timescale_sel),
        .glitch       (glitch),
        .trig_pos     (trig_pos),
        .trig_flash     (trig_flash),
        .boot_phase     (boot_phase),
        .liquid_level   (liquid_level),
        .frame_in_phase (frame_in_phase),
        .r            (r),
        .g            (g),
        .b            (b)
    );

    // ---- TinyVGA PMOD pin mapping ----
    // uo_out = { hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1] }
    assign uo_out = {hsync, b[0], g[0], r[0], vsync, b[1], g[1], r[1]};

endmodule
