// =============================================================
// boot_anim.v — 7-phase boot animation state machine
// 0=black, 1=circle outline, 2=liquid fill, 3=full+pause,
// 4=title text, 5=credits, 6=fade+slide, 7=done
// =============================================================
`default_nettype none

module boot_anim #(
    parameter SIM_SPEED = 0
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       vsync,
    output reg  [2:0] boot_phase,
    output reg  [7:0] liquid_level,   // 0..160 rise height
    output reg  [7:0] frame_in_phase
);

reg vsync_prev;
wire vsync_fall = vsync_prev & ~vsync;

wire [7:0] phase_dur = SIM_SPEED ? 8'd2 :
                       (boot_phase == 3'd0) ? 8'd15  :
                       (boot_phase == 3'd1) ? 8'd20  :
                       (boot_phase == 3'd2) ? 8'd80  :
                       (boot_phase == 3'd3) ? 8'd20  :
                       (boot_phase == 3'd4) ? 8'd50  :
                       (boot_phase == 3'd5) ? 8'd50  :
                       (boot_phase == 3'd6) ? 8'd30  :
                                              8'd255 ;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        boot_phase     <= 3'd0;
        liquid_level   <= 8'd0;
        frame_in_phase <= 8'd0;
        vsync_prev     <= 1'b1;
    end else begin
        vsync_prev <= vsync;
        if (vsync_fall && boot_phase < 3'd7) begin
            if (frame_in_phase >= phase_dur - 8'd1) begin
                frame_in_phase <= 8'd0;
                boot_phase     <= boot_phase + 3'd1;
            end else begin
                frame_in_phase <= frame_in_phase + 8'd1;
            end
            if (boot_phase == 3'd2 && liquid_level < 8'd160)
                liquid_level <= liquid_level + (SIM_SPEED ? 8'd80 : 8'd2);
        end
    end
end

endmodule
