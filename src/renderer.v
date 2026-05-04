// =============================================================
// renderer.v — Racing-the-beam pixel pipeline
// Handles both boot animation (phases 0-6) and main LA UI (7+)
// =============================================================
`default_nettype none

module renderer (
    input  wire [9:0]  hpos,
    input  wire [9:0]  vpos,
    input  wire        active,
    input  wire [31:0] sr0, sr1, sr2, sr3,
    input  wire [3:0]  sig_in,
    input  wire [1:0]  ch_sel,
    input  wire [1:0]  timescale_sel,
    input  wire [3:0]  glitch,
    input  wire [4:0]  trig_pos,
    input  wire [3:0]  trig_flash,
    input  wire [2:0]  boot_phase,
    input  wire [7:0]  liquid_level,
    input  wire [7:0]  frame_in_phase,
    output reg  [1:0]  r, g, b
);

// ============================================================
// BOOT ANIMATION GEOMETRY
// ============================================================

// Octagonal distance from center (320, 240)
wire [8:0] bdx = (hpos >= 10'd320) ? hpos[8:0] - 9'd320 : 9'd320 - hpos[8:0];
wire [8:0] bdy = (vpos >= 10'd240) ? vpos[8:0] - 9'd240 : 9'd240 - vpos[8:0];
wire [8:0] bmn = (bdx < bdy) ? bdx : bdy;
wire [8:0] bmx = (bdx >= bdy) ? bdx : bdy;
wire [8:0] oct_dist = bmx + bmn[8:1] - bmn[8:3]; // ≈ max + min*3/8

wire in_circle      = (oct_dist < 9'd80);
wire on_circle_edge = (oct_dist >= 9'd76) && (oct_dist < 9'd80);

// Liquid surface: rises from circle bottom (vpos=320) upward
// surface_y = 320 - liquid_level
wire [9:0] surface_base = 10'd320 - {2'd0, liquid_level};

// Triangle wave ripple: period 64px, amplitude ±3
wire [5:0] wphase = hpos[5:0];
wire [2:0] ripple = wphase[5] ? ~wphase[4:2] : wphase[4:2];
wire [9:0] surface_y = surface_base - {7'd0, ripple};

wire in_liquid = in_circle && (vpos > surface_y);

// 8 bubble dots (2x2 blocks) at hardcoded positions
wire is_bubble = in_circle && (
    (hpos[9:1]==9'd155 && vpos[9:1]==9'd132) ||
    (hpos[9:1]==9'd165 && vpos[9:1]==9'd128) ||
    (hpos[9:1]==9'd158 && vpos[9:1]==9'd124) ||
    (hpos[9:1]==9'd162 && vpos[9:1]==9'd136) ||
    (hpos[9:1]==9'd152 && vpos[9:1]==9'd120) ||
    (hpos[9:1]==9'd168 && vpos[9:1]==9'd126) ||
    (hpos[9:1]==9'd160 && vpos[9:1]==9'd118) ||
    (hpos[9:1]==9'd156 && vpos[9:1]==9'd130)
);

// ============================================================
// BOOT TEXT: "NANOTRACE-4" centered, 2x scale
// 11 chars × 16px = 176px, centered at 320 → start at x=232
// ============================================================
wire in_title_area = (hpos >= 10'd232) && (hpos < 10'd408) &&
                     (vpos >= 10'd220) && (vpos < 10'd236);

wire [7:0] title_x = hpos[7:0] - 8'd232;  // 0..175
wire [3:0] title_y = vpos[3:0] - 4'd12;    // 0..15

wire [3:0] title_char_idx = title_x[7:4];  // 0..10
wire [2:0] title_col = title_x[3:1];       // column in char (2x)
wire [2:0] title_row = title_y[3:1];       // row in char (2x)

// "NANOTRACE-4" character map
reg [4:0] title_char;
always @(*) begin
    case (title_char_idx)
        4'd0:  title_char = 5'd10; // N
        4'd1:  title_char = 5'd11; // A
        4'd2:  title_char = 5'd10; // N
        4'd3:  title_char = 5'd12; // O
        4'd4:  title_char = 5'd8;  // T
        4'd5:  title_char = 5'd13; // R
        4'd6:  title_char = 5'd11; // A
        4'd7:  title_char = 5'd0;  // C
        4'd8:  title_char = 5'd14; // E
        4'd9:  title_char = 5'd15; // -
        4'd10: title_char = 5'd5;  // 4
        default: title_char = 5'd31; // blank
    endcase
end

// Boot font instance
wire [7:0] title_pixels;
pixel_font u_boot_font (
    .char_sel(title_char),
    .row(title_row),
    .pixels(title_pixels)
);
wire title_pixel = in_title_area && title_pixels[3'd7 - title_col];

// ============================================================
// BOOT TEXT: "- NAVN" bottom-left at (180, 280), 2x scale
// ============================================================
wire in_credit_area = (hpos >= 10'd200) && (hpos < 10'd296) &&
                      (vpos >= 10'd280) && (vpos < 10'd296);

wire [6:0] cr_x = hpos[6:0] - 7'd72;  // adjusted
wire [3:0] cr_y = vpos[3:0] - 4'd8;
wire [2:0] cr_char_idx = (hpos - 10'd200) >> 4;
wire [2:0] cr_col = hpos[3:1];
wire [2:0] cr_row = cr_y[3:1];

reg [4:0] credit_char;
always @(*) begin
    case (cr_char_idx)
        3'd0: credit_char = 5'd15; // -
        3'd1: credit_char = 5'd31; // space
        3'd2: credit_char = 5'd10; // N
        3'd3: credit_char = 5'd11; // A
        3'd4: credit_char = 5'd16; // V
        3'd5: credit_char = 5'd10; // N
        default: credit_char = 5'd31;
    endcase
end

wire [7:0] credit_pixels;
pixel_font u_credit_font (
    .char_sel(credit_char),
    .row(cr_row),
    .pixels(credit_pixels)
);
wire credit_pixel = in_credit_area && credit_pixels[3'd7 - cr_col];

// ============================================================
// MAIN LA: Zone detection
// ============================================================
wire in_wave   = (hpos >= 10'd64) && (hpos < 10'd576);
wire in_lside  = (hpos < 10'd64);
wire in_rside  = (hpos >= 10'd576);
wire in_status = (vpos >= 10'd448);

wire [1:0] ch = (vpos < 10'd112) ? 2'd0 :
                (vpos < 10'd224) ? 2'd1 :
                (vpos < 10'd336) ? 2'd2 : 2'd3;

wire [6:0] y_lane = (ch == 2'd0) ? vpos[6:0] :
                    (ch == 2'd1) ? vpos[6:0] - 7'd112 :
                    (ch == 2'd2) ? vpos[6:0] - 7'd96  :
                                   vpos[6:0] - 7'd80  ;

// Waveform readout
wire [8:0] wave_x = hpos[8:0] - 9'd64;
wire [4:0] bit_idx = wave_x[8:4];

wire [31:0] sr_cur = (ch == 2'd0) ? sr0 :
                     (ch == 2'd1) ? sr1 :
                     (ch == 2'd2) ? sr2 : sr3;

wire bit_val = sr_cur[5'd31 - bit_idx];
wire [4:0] prev_bidx = bit_idx - 5'd1;
wire prev_val = (bit_idx == 5'd0) ? bit_val : sr_cur[5'd31 - prev_bidx];
wire at_edge = (bit_val != prev_val) && (wave_x[3:0] == 4'd0);

wire high_line = (y_lane == 7'd24);
wire low_line  = (y_lane == 7'd88);
wire in_wave_y = (y_lane >= 7'd24) && (y_lane <= 7'd88);
wire on_signal = bit_val ? high_line : low_line;
wire in_fill   = bit_val && (y_lane >= 7'd24) && (y_lane <= 7'd88);
wire on_trans  = at_edge && in_wave_y;

reg [1:0] ch_r, ch_g, ch_b;
always @(*) begin
    case (ch)
        2'd0: begin ch_r=2'd3; ch_g=2'd0; ch_b=2'd0; end
        2'd1: begin ch_r=2'd0; ch_g=2'd3; ch_b=2'd0; end
        2'd2: begin ch_r=2'd0; ch_g=2'd2; ch_b=2'd3; end
        2'd3: begin ch_r=2'd3; ch_g=2'd3; ch_b=2'd0; end
    endcase
end

wire on_grid = in_wave && (wave_x[5:0] == 6'd0) && in_wave_y;
wire on_dot = (hpos[3:0] == 4'd0) && (vpos[3:0] == 4'd0);

wire [8:0] trig_x = {trig_pos, 4'd8};
wire on_trig = in_wave && in_wave_y && (wave_x == trig_x) && (trig_flash != 4'd0);

wire ch_glitch = glitch[ch];

// Left sidebar label
wire in_label = in_lside && !in_status &&
                (hpos >= 10'd4) && (hpos < 10'd52) &&
                (y_lane >= 7'd48) && (y_lane < 7'd64);

wire [5:0] lbl_x = hpos[5:0] - 6'd4;
wire [3:0] lbl_y = y_lane[3:0];
wire [4:0] lbl_fx = lbl_x[5:1];
wire [2:0] lbl_fy = lbl_y[3:1];
wire [1:0] lbl_pos = (lbl_fx < 5'd8) ? 2'd0 : (lbl_fx < 5'd16) ? 2'd1 : 2'd2;
wire [2:0] lbl_col = lbl_fx[2:0];

reg [4:0] lbl_char;
always @(*) begin
    case (lbl_pos)
        2'd0: lbl_char = 5'd0;
        2'd1: lbl_char = 5'd1;
        2'd2: lbl_char = {3'd0, ch} + 5'd2;
        default: lbl_char = 5'd31;
    endcase
end

wire [7:0] lbl_pix;
pixel_font u_font (
    .char_sel(lbl_char),
    .row(lbl_fy),
    .pixels(lbl_pix)
);
wire label_pixel = in_label && lbl_pix[3'd7 - lbl_col];

// Right sidebar H/L
wire in_hl = in_rside && !in_status &&
             (hpos >= 10'd592) && (hpos < 10'd624) &&
             (y_lane >= 7'd48) && (y_lane < 7'd64);
wire [2:0] hl_col = hpos[3:1];
wire [2:0] hl_row = (y_lane[3:0]) >> 1;
wire [4:0] hl_ch = sig_in[ch] ? 5'd1 : 5'd6;

wire [7:0] hl_pix;
pixel_font u_font_hl (
    .char_sel(hl_ch),
    .row(hl_row),
    .pixels(hl_pix)
);
wire hl_pixel = in_hl && hl_pix[3'd7 - hl_col];

// Status bar text
wire in_stat = in_status && (hpos >= 10'd8) && (hpos < 10'd72) &&
               (vpos >= 10'd456) && (vpos < 10'd472);
wire [1:0] st_pos = (hpos - 10'd8) >> 4;
wire [2:0] st_col = hpos[3:1];
wire [2:0] st_row = (vpos[3:0] - 4'd8) >> 1;

reg [4:0] st_char;
always @(*) begin
    case (timescale_sel)
        2'd0: st_char = (st_pos==2'd0) ? 5'd2 : (st_pos==2'd1) ? 5'd7 : 5'd31;
        2'd1: st_char = (st_pos==2'd0) ? 5'd5 : (st_pos==2'd1) ? 5'd7 : 5'd31;
        2'd2: st_char = (st_pos==2'd0) ? 5'd2 : (st_pos==2'd1) ? 5'd9 : (st_pos==2'd2) ? 5'd7 : 5'd31;
        2'd3: st_char = (st_pos==2'd0) ? 5'd9 : (st_pos==2'd1) ? 5'd5 : (st_pos==2'd2) ? 5'd7 : 5'd31;
    endcase
end

wire [7:0] st_pix;
pixel_font u_font_st (
    .char_sel(st_char),
    .row(st_row),
    .pixels(st_pix)
);
wire stat_pixel = in_stat && st_pix[3'd7 - st_col];

wire is_sel = (ch == ch_sel) && !in_status;
wire on_sep = (vpos==10'd111 || vpos==10'd223 || vpos==10'd335 || vpos==10'd447) && in_wave;

// Boot: channel slide-in mask (phase 6)
wire [1:0] slide_ch = frame_in_phase[7:5]; // 0..3 over 120 frames
wire ch_visible_main = (boot_phase >= 3'd7) ||
                       (boot_phase == 3'd6 && {1'b0,ch} <= {1'b0,slide_ch[1:0]});

// ============================================================
// PIXEL OUTPUT MUX
// ============================================================
always @(*) begin
    r = 2'd0; g = 2'd0; b = 2'd0;

    if (!active) begin
        // blanking
    end else if (boot_phase < 3'd6) begin
        // ==== BOOT ANIMATION ====
        case (boot_phase)
            3'd0: begin end // black

            3'd1: begin // circle outline
                if (on_circle_edge) begin r=2'd3; g=2'd3; b=2'd3; end
            end

            3'd2: begin // liquid filling
                if (on_circle_edge) begin r=2'd3; g=2'd3; b=2'd3; end
                else if (is_bubble && !in_liquid) begin r=2'd0; g=2'd0; b=2'd0; end
                else if (in_liquid) begin r=2'd3; g=2'd3; b=2'd3; end
            end

            3'd3: begin // full circle
                if (in_circle) begin r=2'd3; g=2'd3; b=2'd3; end
            end

            3'd4: begin // title "NANOTRACE-4"
                if (in_circle) begin r=2'd2; g=2'd2; b=2'd2; end
                if (title_pixel) begin r=2'd3; g=2'd3; b=2'd3; end
            end

            3'd5: begin // credits
                if (title_pixel) begin r=2'd3; g=2'd3; b=2'd3; end
                if (credit_pixel) begin r=2'd2; g=2'd2; b=2'd2; end
            end

            default: begin end
        endcase

    end else if (boot_phase == 3'd6) begin
        // ==== TRANSITION: channels slide in ====
        if (!in_status && ch_visible_main) begin
            if (in_wave && in_wave_y) begin
                if (on_signal || on_trans) begin r=ch_r; g=ch_g; b=ch_b; end
                else if (in_fill) begin r=ch_r>>1; g=ch_g>>1; b=ch_b>>1; end
                else if (on_grid) begin b=2'd1; end
            end else if (label_pixel) begin r=ch_r; g=ch_g; b=ch_b; end
        end

    end else begin
        // ==== MAIN LA UI ====
        if (!in_status) begin
            if (in_wave && in_wave_y) begin
                if (on_trig) begin r=2'd3; g=2'd3; b=2'd3; end
                else if (ch_glitch && on_signal) begin r=2'd3; g=2'd3; b=2'd3; end
                else if (on_signal || on_trans) begin r=ch_r; g=ch_g; b=ch_b; end
                else if (in_fill) begin r=ch_r>>1; g=ch_g>>1; b=ch_b>>1; end
                else if (on_grid) begin b=2'd1; end
                else if (on_sep) begin g=2'd1; end
                else if (on_dot) begin b=2'd1; end
            end else if (label_pixel) begin
                r=ch_r; g=ch_g; b=ch_b;
            end else if (hl_pixel) begin
                r=ch_r; g=ch_g; b=ch_b;
            end else if (on_sep) begin
                g=2'd1;
            end
        end else begin
            if (stat_pixel) begin r=2'd2; g=2'd2; b=2'd2; end
            else if (vpos == 10'd448) begin r=2'd1; g=2'd1; b=2'd1; end
        end

        // Active channel boost
        if (is_sel && (r!=2'd0 || g!=2'd0 || b!=2'd0)) begin
            if (r<2'd3) r=r+2'd1;
            if (g<2'd3 && ch_g!=2'd0) g=g+2'd1;
            if (b<2'd3 && ch_b!=2'd0) b=b+2'd1;
        end

        // CRT scanline
        if (vpos[0]) begin
            if (r>2'd0) r=r-2'd1;
            if (g>2'd0) g=g-2'd1;
            if (b>2'd0) b=b-2'd1;
        end

        // Trigger flash
        if (trig_flash > 4'd12) begin r=2'd3; g=2'd3; b=2'd3; end
    end
end

endmodule
