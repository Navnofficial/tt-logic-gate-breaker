// =============================================================
// tb_plasma.v  —  smoke-test testbench
// Runs ~3 full VGA frames and checks:
//   1. hsync fires within the correct hpos window
//   2. vsync fires within the correct vpos window
//   3. Active area pixels produce non-zero plasma (colour output)
//   4. Gamepad A (freeze) stops frame counter
//   5. Gamepad Right advances palette
// =============================================================
`timescale 1ns/1ps
`default_nettype none

module tb_plasma;

// 25 MHz clock  (period = 40 ns)
reg clk = 0;
always #20 clk = ~clk;

reg        rst_n = 0;
reg  [7:0] ui_in = 8'b0;
wire [7:0] uo_out;
wire [7:0] uio_out;
wire [7:0] uio_oe;

// DUT
tt_um_zen_v_plasma_visualizer dut (
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (8'b0),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (1'b1),
    .clk    (clk),
    .rst_n  (rst_n)
);

// Convenience aliases matching info.yaml
wire hsync = uo_out[7];
wire vsync = uo_out[3];
wire r1    = uo_out[4];
wire r0    = uo_out[0];
wire g1    = uo_out[5];
wire g0    = uo_out[1];
wire b1    = uo_out[6];
wire b0    = uo_out[2];

// ---- VGA timing: use DUT's own counters via hierarchical refs ----
// Avoids any sync/async reset mismatch between TB and DUT counters.
// (The TB already uses hierarchical refs for frame and palette_sel.)
wire [9:0] hcnt = dut.u_vga_timing.hpos;
wire [9:0] vcnt = dut.u_vga_timing.vpos;

// ---- Test tracking ----
integer errors   = 0;
integer pixels   = 0;
integer nz_pixels = 0;   // pixels with non-zero colour inside active area

// ---- Assertions running every clock (negedge = signals fully settled) ----
// hsync/vsync are registered (1-cycle pipeline delay), so at negedge:
//   hpos  = N   (updated at preceding posedge)
//   hsync = f(N-1)  (registered from previous hpos)
// Window shifts by +1:  hsync LOW when hcnt ∈ [657, 752]
//                        vsync LOW when vcnt ∈ [491, 492]
always @(negedge clk) begin
    if (rst_n) begin
        // CHECK 1: hsync (registered, 1-cycle behind hpos)
        if (hcnt >= 657 && hcnt <= 752) begin
            if (hsync !== 1'b0) begin
                $display("FAIL hsync: expected LOW at hcnt=%0d, got HIGH", hcnt);
                errors = errors + 1;
            end
        end else begin
            if (hsync !== 1'b1) begin
                $display("FAIL hsync: expected HIGH at hcnt=%0d, got LOW", hcnt);
                errors = errors + 1;
            end
        end

        // CHECK 2: vsync (registered, 1-cycle behind vpos)
        if (vcnt >= 491 && vcnt <= 492) begin
            if (vsync !== 1'b0) begin
                $display("FAIL vsync: expected LOW at vcnt=%0d, got HIGH", vcnt);
                errors = errors + 1;
            end
        end else begin
            if (vsync !== 1'b1) begin
                $display("FAIL vsync: expected HIGH at vcnt=%0d, got LOW", vcnt);
                errors = errors + 1;
            end
        end

        // CHECK 3: count non-zero colour pixels inside active area
        // (active is combinational, tracks current hpos — no offset)
        if (hcnt < 640 && vcnt < 480) begin
            pixels = pixels + 1;
            if (r1|r0|g1|g0|b1|b0)
                nz_pixels = nz_pixels + 1;
        end

        // CHECK 4: outside active area, colour bits must be 0
        if (!(hcnt < 640 && vcnt < 480)) begin
            if (r1|r0|g1|g0|b1|b0) begin
                $display("FAIL blank: colour output outside active area h=%0d v=%0d", hcnt, vcnt);
                errors = errors + 1;
            end
        end
    end
end

// ---- Stimulus ----
integer frame_before, frame_after;
integer pal_before,   pal_after;

initial begin
    $dumpfile("plasma.vcd");
    $dumpvars(0, tb_plasma);

    // Reset for 4 cycles
    rst_n = 0;
    repeat(4) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Run 2 full VGA frames (800*525*2 = 840000 clocks)
    repeat(840000) @(posedge clk);

    // CHECK 3 result: at least 50% of active pixels should be non-zero
    if (nz_pixels < pixels / 2) begin
        $display("FAIL colour: only %0d/%0d active pixels non-zero", nz_pixels, pixels);
        errors = errors + 1;
    end else begin
        $display("PASS colour: %0d/%0d active pixels non-zero", nz_pixels, pixels);
    end

    // ---- CHECK 4: Freeze (button A = ui[7]) stops frame counter ----
    // Wait for next vsync falling edge, sample frame counter via proxy
    // (we can't read internal reg directly in pure Verilog SV — use
    //  hierarchical reference if supported, else observe colour change)
    // Use hierarchical reference (iverilog supports this)
    frame_before = dut.u_gamepad_ctrl.frame;

    // Press A (ui[7] = 1) for one vsync
    ui_in = 8'b1000_0000;   // BTN_A
    // Wait 2 full frames
    repeat(800*525*2) @(posedge clk);
    ui_in = 8'b0;
    // Wait 1 more frame for the toggle to register
    repeat(800*525) @(posedge clk);

    // Now frozen should be 1 — run 2 frames and check frame didn't advance
    frame_before = dut.u_gamepad_ctrl.frame;
    repeat(800*525*2) @(posedge clk);
    frame_after = dut.u_gamepad_ctrl.frame;

    if (frame_after !== frame_before) begin
        $display("FAIL freeze: frame advanced from %0d to %0d while frozen",
                 frame_before, frame_after);
        errors = errors + 1;
    end else begin
        $display("PASS freeze: frame held at %0d while frozen", frame_before);
    end

    // Unfreeze
    ui_in = 8'b1000_0000;
    repeat(800*525) @(posedge clk);
    ui_in = 8'b0;
    repeat(800*525) @(posedge clk);

    // ---- CHECK 5: Right button cycles palette ----
    pal_before = dut.u_gamepad_ctrl.palette_sel;
    ui_in = 8'b0000_0001;   // BTN_RIGHT
    repeat(800*525) @(posedge clk);
    ui_in = 8'b0;
    repeat(800*525) @(posedge clk);
    pal_after = dut.u_gamepad_ctrl.palette_sel;

    if (pal_after !== (pal_before + 1) % 8) begin
        $display("FAIL palette: expected %0d, got %0d", (pal_before+1)%8, pal_after);
        errors = errors + 1;
    end else begin
        $display("PASS palette: advanced from %0d to %0d", pal_before, pal_after);
    end

    // ---- Final result ----
    if (errors == 0)
        $display("\n*** ALL TESTS PASSED ***");
    else
        $display("\n*** %0d TEST(S) FAILED ***", errors);

    $finish;
end

// Timeout guard
initial begin
    #500_000_000;  // 500 ms sim time
    $display("TIMEOUT");
    $finish;
end

endmodule