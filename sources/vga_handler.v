module background_renderer #(
    parameter X_LEFT = 8'd40,
    parameter X_RIGHT = 8'd600,
    parameter X_OFFSET = 8'd40,
    parameter Y_TOP = 8'd80,
    parameter Y_BOTTOM = 8'd380,
)(
    input wire clk,
    input wire [2:0] game_state,
    input wire [9:0] x, // VGA x coordinate
    input wire [9:0] y, // VGA y coordinate
    input wire [2:0] char1_health, // Character 1 health
    input wire [2:0] char1_block,
    input wire [2:0] char2_health, // Character 2 health
    input wire [2:0] char2_block,
    output reg [7:0] pixel_color, // RRRGGGBB
    output reg active
);
    localparam
    // Game Controller States
    S_MENU  = 2'b00,
    S_GAME  = 2'b01;

    localparam
    // Heart - Block positions
    HEART1 = 6'b000001
    HEART2 = 6'b000010,
    HEART3 = 6'b000100,
    HEART4 = 6'b001000,
    HEART5 = 6'b010000,
    HEART6 = 6'b100000;

    wire window_active, timerbox_active;

    wire [5:0] heart_active;
    wire [5:0] block_active;



    assign window_active = ((x >= X_OFFSET) && (x < 10'd640 - X_OFFSET)) &&
                       ((y >= Y_TOP) && (y < Y_BOTTOM));
    // Heart Pixel Flags
    assign heart_active[0] = ((x >= 10'd100) && (x < 10'd140)) &&
                             ((y >= 10'd410) && (y < 10'd450));

    assign heart_active[1] = ((x >= 10'd160) && (x < 10'd200)) &&
                             ((y >= 10'd410) && (y < 10'd450));

    assign heart_active[2] = ((x >= 10'd220) && (x < 10'd260)) &&
                             ((y >= 10'd410) && (y < 10'd450));

    assign heart_active[3] = ((x >= 10'd380) && (x < 10'd420)) &&
                             ((y >= 10'd410) && (y < 10'd450));

    assign heart_active[4] = ((x >= 10'd440) && (x < 10'd480)) &&
                             ((y >= 10'd410) && (y < 10'd450));

    assign heart_active[5] = ((x >= 10'd500) && (x < 10'd540)) &&
                             ((y >= 10'd410) && (y < 10'd450));

    // Block Pixel Flags
    assign block_active[0] = ((x >= 10'd80) && (x < 10'd120)) &&
                             ((y >= 10'd100) && (y < 10'd140));

    assign block_active[1] = ((x >= 10'd140) && (x < 10'd180)) &&
                             ((y >= 10'd100) && (y < 10'd140));

    assign block_active[2] = ((x >= 10'd200) && (x < 10'd240)) &&
                             ((y >= 10'd100) && (y < 10'd140));

    assign block_active[3] = ((x >= 10'd400) && (x < 10'd440)) &&
                             ((y >= 10'd100) && (y < 10'd140));

    assign block_active[4] = ((x >= 10'd460) && (x < 10'd500)) &&
                             ((y >= 10'd100) && (y < 10'd140));
    
    assign block_active[5] = ((x >= 10'd520) && (x < 10'd560)) &&
                             ((y >= 10'd100) && (y < 10'd140));




    assign active = window_active | timerbox_active | ((heart_active | block_active) != 6'b000000);

    always @(posedge clk) begin
        if (window_active) begin
            case (game_state)

                S_GAME: begin
                    pixel_color <= 8'b111_111_11; // White
                end

                S_MENU: begin
                    pixel_color <= 8'b001_001_01; // Dark gray for menu background
                end

                default: pixel_color <= 8'b000_000_00; // Black for other states
            endcase
        end else begin

            // Health bar rendering
            if(heart_active > 6'b000000) begin
                case (heart_active)
                    HEART1: begin
                        if (char1_health[0] == 1'b1) begin
                            pixel_color <= 8'b111_000_00; // Red for heart 1
                        end else begin
                            pixel_color <= 8'b000_000_00; // Black for empty heart
                        end
                    end

                    HEART2: begin
                        if (char1_health[1] == 1'b1) begin
                            pixel_color <= 8'b111_000_00; // Red for heart 2
                        end else begin
                            pixel_color <= 8'b000_000_00; // Black for empty heart
                        end
                    end

                    HEART3: begin
                        if (char1_health[2] == 1'b1) begin
                            pixel_color <= 8'b111_000_00; // Red for heart 3
                        end else begin
                            pixel_color <= 8'b000_000_00; // Black for empty heart
                        end
                    end

                    HEART4: begin
                        if (char2_health[2] == 1'b1) begin
                            pixel_color <= 8'b111_000_00; // Red for heart 4
                        end else begin
                            pixel_color <= 8'b000_000_00; // Black for empty heart
                        end
                    end

                    HEART5: begin
                        if (char2_health[1] == 1'b1) begin
                            pixel_color <= 8'b111_000_00; // Red for heart 5
                        end else begin
                            pixel_color <= 8'b000_000_00; // Black for empty heart
                        end
                    end

                    HEART6: begin
                        if (char2_health[0] == 1'b1) begin
                            pixel_color <= 8'b111_000_00; // Red for heart 6
                        end else begin
                            pixel_color <= 8'b000_000_00; // Black for empty heart
                        end
                    end

                    default: pixel_color <= 8'b000_000_00; // Black for other hearts
                endcase
            // Health bar rendering end
            end else if (block_active > 6'b000000) begin
            // Block bar rendering
                case(block_active)
                
                    HEART1: begin
                        if (char1_block[0] == 1'b1) begin
                            pixel_color <= 8'b000_000_11; // Blue for block 1
                        end else begin
                            pixel_color <= 8'b111_111_11; //White for empty block
                        end
                    end

                    HEART2: begin
                        if (char1_block[1] == 1'b1) begin
                            pixel_color <= 8'b000_000_11; // Blue for block 2
                        end else begin
                            pixel_color <= 8'b111_111_11; // White for empty block
                        end
                    end

                    HEART3: begin
                        if (char1_block[2] == 1'b1) begin
                            pixel_color <= 8'b000_000_11; // Blue for block 3
                        end else begin
                            pixel_color <= 8'b111_111_11; //White for empty block
                        end
                    end

                    HEART4: begin
                        if (char2_block[2] == 1'b1) begin
                            pixel_color <= 8'b000_000_11; // Blue for block 4
                        end else begin
                            pixel_color <= 8'b111_111_11; //White for empty block
                        end
                    end

                    HEART5: begin
                        if (char2_block[1] == 1'b1) begin
                            pixel_color <= 8'b000_000_11; // Blue for block 5
                        end else begin
                            pixel_color <= 8'b111_111_11; //White for empty block
                        end
                    end

                    HEART6: begin
                        if (char2_block[0] == 1'b1) begin
                            pixel_color <= 8'b000_000_11; // Blue for block 6
                        end else begin
                            pixel_color <= 8'b111_111_11; //White for empty block
                        end
                    end

                    default: pixel_color <= 8'b111_111_11; // White for other blocks
                endcase
            end

            

        end
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
    input wire [9:0] char1_x_pos, // Character top-left x position
    input wire [9:0] char1_y_pos, // Character top-left y position
    input wire [3:0] char1_state,
    input wire [2:0] char1_health, // Character 1 health
    input wire [2:0] char1_block,
    input wire [9:0] char2_x_pos,
    input wire [9:0] char2_y_pos,
    input wire [3:0] char2_state,
    input wire [2:0] char2_health, // Character 2 health
    input wire [2:0] char2_block,
    input wire [2:0] game_state,
    output reg [7:0] pixel_color // RRRGGGBB
);
	 
    localparam
    // Game Controller States
    S_MENU  = 2'b00,
    S_GAME  = 2'b01;

    wire [7:0] bg_color, sprite1_color, sprite2_color;
    wire sprite1_active, sprite2_active, bg_active;

    background_renderer bg_inst(
        .clk(vga_clk),
        .active(bg_active),
        .pixel_color(bg_color),
        .game_state(game_state),
        .x(x),
        .y(y),
        .char1_health(char1_health),
        .char1_block(char1_block),
        .char2_health(char2_health),
        .char2_block(char2_block),
        .active(bg_active)
    );

    sprite_renderer sprite1_inst(
        .clk(vga_clk),
        .char_state(char1_state),
        .x(x),
        .y(y),
        .char_x_pos(char1_x_pos),
        .char_y_pos(char1_y_pos),
        .active(sprite1_active),
        .pixel_color(sprite1_color)
    );

    sprite_renderer sprite2_inst(
        .clk(vga_clk),
        .char_state(char2_state),
        .x(x),
        .y(y),
        .char_x_pos(char2_x_pos),
        .char_y_pos(char2_y_pos),
        .active(sprite2_active),
        .pixel_color(sprite2_color)
    );

    always @(posedge vga_clk) begin
        case (game_state)
            S_MENU: begin
                if (bg_active) begin
                    pixel_color <= bg_color;
                end else begin
                    pixel_color <= 8'b000_000_00; // Black
                end
            end
            S_GAME: begin
                if (sprite1_active)
                    pixel_color <= sprite1_color;
                else if (sprite2_active)
                    pixel_color <= sprite2_color;
                else if (bg_active)
                    pixel_color <= bg_color;
                else begin
                    pixel_color <= 8'b000_000_00; // Black
                end
            end
            default: begin
                pixel_color <= 8'b000_000_00; // Default to black
            end
        endcase
    end
endmodule