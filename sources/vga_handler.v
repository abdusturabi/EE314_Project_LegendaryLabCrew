module background_renderer(
    input wire clk,
    input wire active,
    output reg [7:0] pixel_color // RRRGGGBB
);
    always @(posedge clk) begin
        if (active)
            pixel_color <= 8'b111_111_11; // White
        else
            pixel_color <= 8'b000_000_00; // High impedance when not active
    end
endmodule

module sprite_renderer(
    input wire clk,
    input wire active,
    input wire [3:0] char_state, // e.g., 0: idle, 1: left, 2: right, 3: attack, etc.
    output reg [7:0] pixel_color // RRRGGGBB
);
    localparam 
    S_IDLE = 		      4'b0000,
    S_LEFT = 		      4'b0001,
    S_RIGHT = 		      4'b0010,
    S_ATTACK_START =      4'b0011,
    S_ATTACK_ACTIVE =     4'b0100,
    S_ATTACK_RECOVERY =   4'b0101,
    S_ATTACK_DIR_START =  4'b0110,
    S_ATTACK_DIR_ACTIVE = 4'b0111,
    S_ATTACK_DIR_RECOVERY = 4'b1000;

    // Sprite position is always (0,0) in its own coordinate system
    // Sprite size: 128x240
    always @(posedge clk) begin
        if (active) begin
            case (char_state)
                S_IDLE: begin pixel_color <= 8'b000_000_00; 
                end // Black
                S_LEFT: begin pixel_color <= 8'b000_000_00;
                end
                S_RIGHT: begin pixel_color <= 8'b000_000_00; 
                end
                S_ATTACK_START: begin pixel_color <= 8'b000_111_00; 
                end // Green
                S_ATTACK_ACTIVE: begin pixel_color <= 8'b111_000_00; 
                end // Red
                S_ATTACK_RECOVERY: begin pixel_color <= 8'b111_111_00; 
                end // Yellow
                S_ATTACK_DIR_START: begin pixel_color <= 8'b000_111_11; 
                end // Cyan
                S_ATTACK_DIR_ACTIVE: begin pixel_color <= 8'b111_000_11; 
                end // Magenta
                S_ATTACK_DIR_RECOVERY: begin pixel_color <= 8'b111_111_00; 
                end // Yellow
                default: begin pixel_color <= 8'b000_000_01; 
                end // Black
            endcase

        end else begin
            pixel_color <= 8'b000_000_01;
        end
    end
endmodule

module vga_handler(
    input wire vga_clk,
    input wire [9:0] x, // VGA x coordinate
    input wire [9:0] y, // VGA y coordinate
    input wire [9:0] char_x_pos, // Character top-left x position
    input wire [9:0] char_y_pos, // Character top-left y position
    input wire [3:0] char_state,
    output reg [7:0] pixel_color // RRRGGGBB
);
    localparam
    CHAR_WIDTH = 8'd128, // Character width
    CHAR_HEIGHT = 8'd240; // Character height

    wire [7:0] bg_color, sprite_color;
    wire sprite_active, bg_active;

    assign sprite_active = ((x >= char_x_pos) & (x < char_x_pos + CHAR_WIDTH)) &
                            ((y >= char_y_pos) & (y < char_y_pos + CHAR_HEIGHT));
    assign bg_active = ~sprite_active;

    background_renderer bg_inst(
        .clk(vga_clk),
        .active(bg_active),
        .pixel_color(bg_color)
    );

    sprite_renderer sprite_inst(
        .clk(vga_clk),
        .active(sprite_active),
        .char_state(char_state),
        .pixel_color(sprite_color)
    );

    always @(posedge vga_clk) begin
        if (sprite_active)
            pixel_color <= sprite_color;
        else
            pixel_color <= bg_color;
    end
endmodule