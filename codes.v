`timescale 1ns / 1ps

module restaurant_display(
    input wire clk,               // 100 MHz clock
    input wire btnU, btnD, btnL, btnR, // 4 buttons for menu
    input wire sw15,              // Switch V16: controls OPEN/CLOSE
    input wire sw16,              // Switch V17: enables menu operation
    output reg [6:0] seg,         // 7-segment segments (a-g)
    output reg [3:0] an           // 4-digit anode control
);

    // ---------------- CLOCK DIVIDER ----------------
    reg [31:0] slow_clk = 0;
    always @(posedge clk)
        slow_clk <= slow_clk + 1;

    // ~1Hz scroll tick
    wire scroll_tick = slow_clk[26];
    // ~1kHz refresh tick
    wire refresh_tick = slow_clk[15];

    // ---------------- MENU SELECTION ----------------
    reg [3:0] menu_select = 0;
    always @(posedge clk) begin
        if (sw15 && sw16) begin // Only allow menu buttons when both switches are ON
            if (btnU) menu_select <= 1;      // BURGER
            else if (btnD) menu_select <= 2; // PIZZA
            else if (btnL) menu_select <= 3; // KACCHI
            else if (btnR) menu_select <= 4; // PASTA
            else menu_select <= 0;           // Default (OPEN)
        end 
        else begin
            menu_select <= 0; // Force to OPEN/CLOSE mode
        end
    end

    // ---------------- MESSAGE DEFINITIONS ----------------
    reg [7:0] message [0:15];
    integer length;

    reg [3:0] scroll_index = 0;
    always @(posedge scroll_tick) begin
        if (scroll_index == 15)
            scroll_index <= 0;
        else
            scroll_index <= scroll_index + 1;
    end

    // ---------------- DISPLAY LOGIC ----------------
    always @(*) begin
        case(menu_select)
            0: begin
                if (sw15) begin
                    message[0]="O"; message[1]="P"; message[2]="E"; message[3]="N";
                    length = 4;
                end else begin
                    message[0]="C"; message[1]="L"; message[2]="O"; message[3]="S"; message[4]="E";
                    length = 5;
                end
            end
            1: begin
                message[0]="B"; message[1]="U"; message[2]="R";
                message[3]="G"; message[4]="E"; message[5]="R";
                length = 6;
            end
            2: begin
                message[0]="P"; message[1]="I"; message[2]="Z";
                message[3]="Z"; message[4]="A";
                length = 5;
            end
            3: begin
                message[0]="K"; message[1]="A"; message[2]="C";
                message[3]="C"; message[4]="H"; message[5]="I";
                length = 6;
            end
            4: begin
                message[0]="P"; message[1]="A"; message[2]="S";
                message[3]="T"; message[4]="A";
                length = 5;
            end
            default: begin
                message[0]="S"; message[1]="O"; message[2]="U"; message[3]="P";
                length = 4;
            end
        endcase
    end

    // ---------------- SCROLLING LEFT TO RIGHT ----------------
    reg [7:0] display_chars [3:0];
    integer i;
    always @(*) begin
        for (i = 0; i < 4; i = i + 1)
            // Reversed direction: show characters decreasing in index
            display_chars[i] = message[(length + scroll_index - i) % length];
    end

    // ---------------- 7-SEGMENT DECODER ----------------
    function [6:0] decode_char;
        input [7:0] c;
        case (c)
            "A": decode_char = 7'b0001000;
            "B": decode_char = 7'b0000011;
            "C": decode_char = 7'b1000110;
            "D": decode_char = 7'b0100001;
            "E": decode_char = 7'b0000110;
            "F": decode_char = 7'b0001110;
            "G": decode_char = 7'b1000010;
            "H": decode_char = 7'b0001001;
            "I": decode_char = 7'b1111001;
            "K": decode_char = 7'b0001010;
            "L": decode_char = 7'b1000111;
            "N": decode_char = 7'b0101011;
            "O": decode_char = 7'b1000000;
            "P": decode_char = 7'b0001100;
            "R": decode_char = 7'b0101111;
            "S": decode_char = 7'b0010010;
            "T": decode_char = 7'b0000111;
            "U": decode_char = 7'b1000001;
            "Z": decode_char = 7'b0010010;
            " ": decode_char = 7'b1111111;
            default: decode_char = 7'b1111111;
        endcase
    endfunction

    // ---------------- DISPLAY REFRESH ----------------
    reg [1:0] digit = 0;
    always @(posedge refresh_tick)
        digit <= digit + 1;

    always @(*) begin
        case(digit)
            2'b00: begin an = 4'b1110; seg = decode_char(display_chars[0]); end
            2'b01: begin an = 4'b1101; seg = decode_char(display_chars[1]); end
            2'b10: begin an = 4'b1011; seg = decode_char(display_chars[2]); end
            2'b11: begin an = 4'b0111; seg = decode_char(display_chars[3]); end
        endcase
    end

endmodule
