// =============================================================
// pixel_font.v — 8x8 pixel font, pure case statements
// 0:C 1:H 2:1 3:2 4:3 5:4 6:L 7:x 8:T 9:6
// 10:N 11:A 12:O 13:R 14:E 15:- 16:V
// =============================================================
`default_nettype none

module pixel_font (
    input  wire [4:0] char_sel,
    input  wire [2:0] row,
    output reg  [7:0] pixels
);

always @(*) begin
    case (char_sel)
        5'd0: case(row) // C
            3'd0:pixels=8'b00111100; 3'd1:pixels=8'b01100110;
            3'd2:pixels=8'b11000000; 3'd3:pixels=8'b11000000;
            3'd4:pixels=8'b11000000; 3'd5:pixels=8'b01100110;
            3'd6:pixels=8'b00111100; default:pixels=8'd0; endcase
        5'd1: case(row) // H
            3'd0:pixels=8'b11000110; 3'd1:pixels=8'b11000110;
            3'd2:pixels=8'b11000110; 3'd3:pixels=8'b11111110;
            3'd4:pixels=8'b11000110; 3'd5:pixels=8'b11000110;
            3'd6:pixels=8'b11000110; default:pixels=8'd0; endcase
        5'd2: case(row) // 1
            3'd0:pixels=8'b00011000; 3'd1:pixels=8'b00111000;
            3'd2:pixels=8'b00011000; 3'd3:pixels=8'b00011000;
            3'd4:pixels=8'b00011000; 3'd5:pixels=8'b00011000;
            3'd6:pixels=8'b01111110; default:pixels=8'd0; endcase
        5'd3: case(row) // 2
            3'd0:pixels=8'b01111100; 3'd1:pixels=8'b11000110;
            3'd2:pixels=8'b00001100; 3'd3:pixels=8'b00111000;
            3'd4:pixels=8'b01100000; 3'd5:pixels=8'b11000000;
            3'd6:pixels=8'b11111110; default:pixels=8'd0; endcase
        5'd4: case(row) // 3
            3'd0:pixels=8'b01111100; 3'd1:pixels=8'b11000110;
            3'd2:pixels=8'b00000110; 3'd3:pixels=8'b00111100;
            3'd4:pixels=8'b00000110; 3'd5:pixels=8'b11000110;
            3'd6:pixels=8'b01111100; default:pixels=8'd0; endcase
        5'd5: case(row) // 4
            3'd0:pixels=8'b00001100; 3'd1:pixels=8'b00011100;
            3'd2:pixels=8'b00111100; 3'd3:pixels=8'b01101100;
            3'd4:pixels=8'b11111110; 3'd5:pixels=8'b00001100;
            3'd6:pixels=8'b00001100; default:pixels=8'd0; endcase
        5'd6: case(row) // L
            3'd0:pixels=8'b11000000; 3'd1:pixels=8'b11000000;
            3'd2:pixels=8'b11000000; 3'd3:pixels=8'b11000000;
            3'd4:pixels=8'b11000000; 3'd5:pixels=8'b11000000;
            3'd6:pixels=8'b11111110; default:pixels=8'd0; endcase
        5'd7: case(row) // x
            3'd0:pixels=8'b00000000; 3'd1:pixels=8'b00000000;
            3'd2:pixels=8'b11000110; 3'd3:pixels=8'b01101100;
            3'd4:pixels=8'b00111000; 3'd5:pixels=8'b01101100;
            3'd6:pixels=8'b11000110; default:pixels=8'd0; endcase
        5'd8: case(row) // T
            3'd0:pixels=8'b11111110; 3'd1:pixels=8'b00011000;
            3'd2:pixels=8'b00011000; 3'd3:pixels=8'b00011000;
            3'd4:pixels=8'b00011000; 3'd5:pixels=8'b00011000;
            3'd6:pixels=8'b00011000; default:pixels=8'd0; endcase
        5'd9: case(row) // 6
            3'd0:pixels=8'b00111100; 3'd1:pixels=8'b01100000;
            3'd2:pixels=8'b11000000; 3'd3:pixels=8'b11111100;
            3'd4:pixels=8'b11000110; 3'd5:pixels=8'b11000110;
            3'd6:pixels=8'b01111100; default:pixels=8'd0; endcase
        5'd10: case(row) // N
            3'd0:pixels=8'b11000110; 3'd1:pixels=8'b11100110;
            3'd2:pixels=8'b11110110; 3'd3:pixels=8'b11011110;
            3'd4:pixels=8'b11001110; 3'd5:pixels=8'b11000110;
            3'd6:pixels=8'b11000110; default:pixels=8'd0; endcase
        5'd11: case(row) // A
            3'd0:pixels=8'b00111000; 3'd1:pixels=8'b01101100;
            3'd2:pixels=8'b11000110; 3'd3:pixels=8'b11000110;
            3'd4:pixels=8'b11111110; 3'd5:pixels=8'b11000110;
            3'd6:pixels=8'b11000110; default:pixels=8'd0; endcase
        5'd12: case(row) // O
            3'd0:pixels=8'b01111100; 3'd1:pixels=8'b11000110;
            3'd2:pixels=8'b11000110; 3'd3:pixels=8'b11000110;
            3'd4:pixels=8'b11000110; 3'd5:pixels=8'b11000110;
            3'd6:pixels=8'b01111100; default:pixels=8'd0; endcase
        5'd13: case(row) // R
            3'd0:pixels=8'b11111100; 3'd1:pixels=8'b11000110;
            3'd2:pixels=8'b11000110; 3'd3:pixels=8'b11111100;
            3'd4:pixels=8'b11011000; 3'd5:pixels=8'b11001100;
            3'd6:pixels=8'b11000110; default:pixels=8'd0; endcase
        5'd14: case(row) // E
            3'd0:pixels=8'b11111110; 3'd1:pixels=8'b11000000;
            3'd2:pixels=8'b11000000; 3'd3:pixels=8'b11111100;
            3'd4:pixels=8'b11000000; 3'd5:pixels=8'b11000000;
            3'd6:pixels=8'b11111110; default:pixels=8'd0; endcase
        5'd15: case(row) // -
            3'd0:pixels=8'b00000000; 3'd1:pixels=8'b00000000;
            3'd2:pixels=8'b00000000; 3'd3:pixels=8'b11111110;
            3'd4:pixels=8'b00000000; 3'd5:pixels=8'b00000000;
            3'd6:pixels=8'b00000000; default:pixels=8'd0; endcase
        5'd16: case(row) // V
            3'd0:pixels=8'b11000110; 3'd1:pixels=8'b11000110;
            3'd2:pixels=8'b11000110; 3'd3:pixels=8'b11000110;
            3'd4:pixels=8'b01101100; 3'd5:pixels=8'b00111000;
            3'd6:pixels=8'b00010000; default:pixels=8'd0; endcase
        default: pixels = 8'd0;
    endcase
end

endmodule
