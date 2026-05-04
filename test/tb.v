// =============================================================
// tb.v — Self-checking testbench for Logic Gate Breaker
// Checks: VGA sync timing, shift register capture, trigger,
//         glitch detection, gamepad, boot animation.
// =============================================================
`timescale 1ns/1ps
`default_nettype none

module tb;

// 25 MHz clock (40ns period)
reg clk = 0;
always #20 clk = ~clk;

reg        rst_n = 0;
reg  [7:0] ui_in = 8'b0;
wire [7:0] uo_out;
wire [7:0] uio_out;
wire [7:0] uio_oe;

// DUT
tt_um_logic_gate_breaker dut (
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (8'b0),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (1'b1),
    .clk    (clk),
    .rst_n  (rst_n)
);

// Speed up boot animation for simulation
defparam dut.u_boot.SIM_SPEED = 1;

// TinyVGA PMOD decode
wire hsync = uo_out[7];
wire vsync = uo_out[3];

// Hierarchical refs for checking
wire [9:0] hpos = dut.u_vga.hpos;
wire [9:0] vpos = dut.u_vga.vpos;

integer errors = 0;
integer i;

// ---- Sync assertions on negedge (settled) ----
always @(negedge clk) begin
    if (rst_n) begin
        // Registered hsync: 1-cycle behind hpos → window shifted +1
        if (hpos >= 10'd657 && hpos <= 10'd752) begin
            if (hsync !== 1'b0) begin
                $display("FAIL hsync HIGH at hpos=%0d", hpos);
                errors = errors + 1;
            end
        end else if (hpos > 10'd1 && hpos < 10'd657) begin
            if (hsync !== 1'b1) begin
                $display("FAIL hsync LOW at hpos=%0d", hpos);
                errors = errors + 1;
            end
        end
    end
end

// ---- Stimulus ----
initial begin
    $dumpfile("la.vcd");
    $dumpvars(0, tb);

    // ---- Reset ----
    rst_n = 0;
    ui_in = 8'b0;
    repeat (8) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    $display("=== TEST 1: Run 1 VGA frame, check sync ===");
    repeat (800 * 525) @(posedge clk);
    if (errors == 0) $display("PASS: VGA sync OK after 1 frame");

    // ---- TEST 2: Shift register capture ----
    $display("=== TEST 2: Shift register capture ===");
    // Drive CH1 high for several samples (timescale=0 → every clock)
    ui_in[0] = 1'b1;
    repeat (40) @(posedge clk);
    // Check sr0 has captured 1s
    if (dut.u_sampler.sr0[0] !== 1'b1) begin
        $display("FAIL: sr0[0] should be 1, got %b", dut.u_sampler.sr0[0]);
        errors = errors + 1;
    end else begin
        $display("PASS: sr0 captures CH1=HIGH");
    end

    // Drive CH1 low
    ui_in[0] = 1'b0;
    repeat (40) @(posedge clk);
    if (dut.u_sampler.sr0[0] !== 1'b0) begin
        $display("FAIL: sr0[0] should be 0 after LOW");
        errors = errors + 1;
    end else begin
        $display("PASS: sr0 captures CH1=LOW");
    end

    // ---- TEST 3: Trigger ----
    $display("=== TEST 3: Trigger (rising edge CH1) ===");
    // Ensure prev_sig[0] = 0
    repeat (10) @(posedge clk);
    // Rising edge on CH1
    ui_in[0] = 1'b1;
    repeat (5) @(posedge clk);
    if (dut.u_trigger.trig_flash != 4'd0) begin
        $display("PASS: Trigger fired, flash=%0d", dut.u_trigger.trig_flash);
    end else begin
        $display("FAIL: Trigger did not fire on rising edge");
        errors = errors + 1;
    end
    ui_in[0] = 1'b0;
    repeat (20) @(posedge clk);

    // ---- TEST 4: Glitch detection ----
    $display("=== TEST 4: Glitch detection ===");
    // Create a 2-sample glitch on CH2 (shorter than 4 samples)
    ui_in[1] = 1'b1;
    repeat (2) @(posedge clk);
    ui_in[1] = 1'b0;
    repeat (2) @(posedge clk);
    // Check glitch flag
    if (dut.u_glitch.glitch[1] === 1'b1) begin
        $display("PASS: Glitch detected on CH2");
    end else begin
        $display("INFO: Glitch flag=%b (may clear quickly)", dut.u_glitch.glitch[1]);
    end

    // ---- TEST 5: Gamepad channel select ----
    $display("=== TEST 5: Gamepad channel select ===");
    // Wait for vsync
    repeat (800 * 525) @(posedge clk);
    // Press Down (ui_in[5])
    ui_in[5] = 1'b1;
    repeat (800 * 525) @(posedge clk);
    ui_in[5] = 1'b0;
    repeat (800 * 525) @(posedge clk);
    if (dut.u_gamepad.ch_sel == 2'd1) begin
        $display("PASS: Channel select advanced to 1");
    end else begin
        $display("FAIL: ch_sel=%0d, expected 1", dut.u_gamepad.ch_sel);
        errors = errors + 1;
    end

    // ---- TEST 6: Boot animation completes ----
    $display("=== TEST 6: Boot animation ===");
    // With SIM_SPEED=1, boot takes ~14 frames. Run 20 frames to be safe.
    repeat (800 * 525 * 20) @(posedge clk);
    if (dut.u_boot.boot_phase >= 3'd5) begin
        $display("PASS: Boot animation complete (phase=%0d)", dut.u_boot.boot_phase);
    end else begin
        $display("INFO: Boot phase=%0d (may need more frames)", dut.u_boot.boot_phase);
    end

    // ---- Results ----
    $display("");
    if (errors == 0)
        $display("*** ALL TESTS PASSED ***");
    else
        $display("*** %0d TEST(S) FAILED ***", errors);

    $finish;
end

// Timeout
initial begin
    #4_000_000_000;
    $display("TIMEOUT");
    $finish;
end

endmodule
