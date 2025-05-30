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
    input wire [9:0] x, // VGA x coordinate
    input wire [9:0] y, // VGA y coordinate
	input wire [9:0] char_x_pos, // Character top-left x position
    input wire [9:0] char_y_pos, // Character top-left y position
    input wire [3:0] char_state, // e.g., 0: idle, 1: left, 2: right, 3: attack, etc.
    output wire active,
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
    S_ATTACK_DIR_RECOVERY = 4'b1000,
    CHAR_WIDTH =            10'd128, // Character width in pixels
    CHAR_HEIGHT =           10'd240; // Character height in pixels

    wire idle_active, prep_active, prep_dir_active, neutral_active, dir_active;

	assign idle_active = ((x >= char_x_pos) & (x <= char_x_pos + CHAR_WIDTH)) &
                            ((y >= char_y_pos) & (y <= char_y_pos + CHAR_HEIGHT));
    
    assign prep_active = (char_state == S_ATTACK_START) & (
        ((x >= char_x_pos + (CHAR_WIDTH/2)) & (x <= char_x_pos + 4*(CHAR_WIDTH/2))) & // 128-pixel wide box
        ((y >= char_y_pos + CHAR_HEIGHT - 8'd100 ) & (y < char_y_pos + CHAR_HEIGHT)) // 60-pixel tall box
    );

    assign prep_dir_active = (char_state == S_ATTACK_DIR_START) & (
        // First rectangle
        ((x >= (char_x_pos + (CHAR_WIDTH/2))) & (x < (char_x_pos + 3*(CHAR_WIDTH/2) + 4'd10)) & 
         (y >= (char_y_pos + CHAR_HEIGHT - 8'd190)) & (y < char_y_pos + CHAR_HEIGHT)) 
    );

    assign hurtbox_active = ((
        ((x >= char_x_pos - 4'd10) & (x <= char_x_pos + CHAR_WIDTH + 4'd10)) &
        ((y >= char_y_pos - 6'd40) & (y <= char_y_pos + CHAR_HEIGHT)))
        |
        ((char_state == S_ATTACK_RECOVERY) & 
        ((x >= char_x_pos + (CHAR_WIDTH/2)) & (x <= char_x_pos + 3*(CHAR_WIDTH/2))) &
        ((y >= char_y_pos + CHAR_HEIGHT - 6'd60) & (y < char_y_pos + CHAR_HEIGHT)))
        |
        ((char_state == S_ATTACK_DIR_RECOVERY) & 
        ((x >= char_x_pos + (CHAR_WIDTH/2)) & (x <= char_x_pos + 3*(CHAR_WIDTH/2))) &
        ((y >= char_y_pos + CHAR_HEIGHT - 8'd190) & (y < char_y_pos + CHAR_HEIGHT)))
        );
    
    assign neutral_active = (char_state == S_ATTACK_ACTIVE) & (
        ((x >= (char_x_pos + (CHAR_WIDTH/2))) & (x <= (char_x_pos + 3*(CHAR_WIDTH/2)))) &
         ((y >= char_y_pos + CHAR_HEIGHT - 6'd60) & (y < char_y_pos + CHAR_HEIGHT))
    );

    assign dir_active = (char_state == S_ATTACK_DIR_ACTIVE) & (
        // First rectangle
        ((x >= (char_x_pos + (CHAR_WIDTH/2))) & (x < (char_x_pos + 3*(CHAR_WIDTH/2))) & // 128-pixel wide box
         (y >= (char_y_pos + CHAR_HEIGHT - 8'd80)) & (y < char_y_pos + CHAR_HEIGHT)) // 60-pixel tall box
        |
        // Second rectangle, with a gap below the first
        ((x >= (char_x_pos + (CHAR_WIDTH/2))) & (x < (char_x_pos + 3*(CHAR_WIDTH/2))) &
         (y >= (char_y_pos + CHAR_HEIGHT - 8'd190)) & (y < char_y_pos + CHAR_HEIGHT - 7'd110)) // another 60-pixel tall box, 30-pixel gap
    );
	
    assign active = idle_active | neutral_active | dir_active | hurtbox_active | prep_active | prep_dir_active;

    // Sprite position is always (0,0) in its own coordinate system
    // Sprite size: 128x240
    always @(posedge clk) begin
        if ((active)) begin
            if(neutral_active) begin
                pixel_color <= 8'b111_000_00; // Red for attack direction
            end else if (dir_active) begin
                pixel_color <= 8'b111_000_00; // Red for attack direction
            end else if(prep_active | prep_dir_active) begin
                pixel_color <= 8'b001_001_00; // Dark gray for attack preparation
            end else if (idle_active) begin
                pixel_color <= 8'b000_000_00; // Black for sprite
            end else if (hurtbox_active) begin
                pixel_color <= 8'b111_111_10; // Açık sarı 
            end
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
	 
    wire [7:0] bg_color, sprite_color;
    wire sprite1_active;

    assign bg_active = (~sprite1_active);

    background_renderer bg_inst(
        .clk(vga_clk),
        .active(bg_active),
        .pixel_color(bg_color)
    );

    sprite_renderer sprite1_inst(
        .clk(vga_clk),
        .char_state(char_state),
        .x(x),
        .y(y),
        .char_x_pos(char_x_pos),
        .char_y_pos(char_y_pos),
        .active(sprite1_active),
        .pixel_color(sprite_color)
    );

    always @(posedge vga_clk) begin
        if (sprite1_active)
            pixel_color <= sprite_color;
        else
            pixel_color <= bg_color;
    end
endmodule