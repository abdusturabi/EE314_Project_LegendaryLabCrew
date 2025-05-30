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
	input wire [9:0] char_x_pos, // Character top-left x position
    input wire [9:0] char_y_pos, // Character top-left y position
    input wire [3:0] char_state, // e.g., 0: idle, 1: left, 2: right, 3: attack, etc.
    output reg active,
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

    wire idle_active, neutral_active, dir_active;

	assign idle_active = ((x >= char_x_pos) & (x <= char_x_pos + CHAR_WIDTH)) &
                            ((y >= char_y_pos) & (y <= char_y_pos + CHAR_HEIGHT));
    
    assign hurtbox_active = ((
        ((x >= char_x_pos + 4'd10) & (x <= char_x_pos + CHAR_WIDTH - 4'd10)) &
        ((y >= char_y_pos + 4'd20) & (y <= char_y_pos + CHAR_HEIGHT - 4'd20)))
        |
        ((char_state == S_ATTACK_RECOVERY) & 
        ((x >= char_x_pos + (CHAR_WIDTH/2)) & (x <= char_x_pos + 3*(CHAR_WIDTH/2))) &
        ((y >= char_y_pos + CHAR_HEIGHT - 6'd60) & (y < char_y_pos + CHAR_HEIGHT - 6'd30)))
        |
        ((char_state == S_ATTACK_DIR_RECOVERY) & 
        ((x >= char_x_pos + (CHAR_WIDTH/2)) & (x <= char_x_pos + 3*(CHAR_WIDTH/2))) &
        ((y >= char_y_pos + CHAR_HEIGHT - 6'd150) & (y < char_y_pos + CHAR_HEIGHT)))
        );
    
    assign neutral_active = (char_state == S_ATTACK_ACTIVE) & (
        ((x >= (char_x_pos + (CHAR_WIDTH/2))) & (x <= (char_x_pos + 3*(CHAR_WIDTH/2)))) &
         ((y >= char_y_pos + CHAR_HEIGHT - 6'd60) & (y < char_y_pos + CHAR_HEIGHT))
    );

    assign dir_active = (char_state == S_ATTACK_DIR_ACTIVE) & (
        // First rectangle
        ((x >= (char_x_pos + (CHAR_WIDTH/2))) & (x < (char_x_pos + 3*(CHAR_WIDTH/2))) & // 128-pixel wide box
         (y >= (char_y_pos + CHAR_HEIGHT - 6'd60)) & (y < char_y_pos + CHAR_HEIGHT)) // 60-pixel tall box
        |
        // Second rectangle, with a gap below the first
        ((x >= (char_x_pos + (CHAR_WIDTH/2))) & (x < (char_x_pos + 3*(CHAR_WIDTH/2))) &
         (y >= (char_y_pos + CHAR_HEIGHT - 6'd150)) & (y < char_y_pos + CHAR_HEIGHT - 6'd90)) // another 60-pixel tall box, 30-pixel gap
    );
	
    // Sprite position is always (0,0) in its own coordinate system
    // Sprite size: 128x240
    always @(posedge clk) begin
        if ((neutral_active | dir_active | idle_active | hurtbox_active)) begin
            case (char_state)
                S_IDLE: begin pixel_color <= 8'b000_000_00; 
                end // Black
                S_LEFT: begin pixel_color <= 8'b000_000_00;
                end
                S_RIGHT: begin pixel_color <= 8'b000_000_00; 
                end
                S_ATTACK_START: begin pixel_color <= 8'b111_111_00; 
                end // Yellow
                S_ATTACK_ACTIVE: begin
                    if(idle_active)
                        pixel_color <= 8'b000_000_00; // Black
                    else if(neutral_active)
                    pixel_color <= 8'b111_000_00; // Red 
                end // Red
                S_ATTACK_RECOVERY: begin pixel_color <= 8'b000_111_00; 
                end // Green
                S_ATTACK_DIR_START: begin pixel_color <= 8'b111_111_00; 
                end // Yellow
                S_ATTACK_DIR_ACTIVE: begin
                    if(idle_active)
                        pixel_color <= 8'b000_000_00; // Black
                    else if(dir_active)
                        pixel_color <= 8'b111_000_00; // Red
                end 
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