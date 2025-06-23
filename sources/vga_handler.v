module mif_renderer_ali (
    input  wire clk,
    input  wire [3:0] char_state,
    input  wire [9:0] pixel_x,    // 0..639
    input  wire [8:0] pixel_y,    // 0..479
    input  wire [9:0] start_x,    // Başlangıç X koordinatı
    input  wire [9:0] start_y,    // Başlangıç Y koordinatı
    output wire in_bounds, // Koordinatların sprite içinde olup olmadığını kontrol eder
    output wire [7:0] color_out
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
    S_STUN =                4'b1001;

    wire [7:0] SPRITE_W, SPRITE_H; 

    assign SPRITE_W = char_state == S_IDLE ? 85 :
                      char_state == S_LEFT ? 95 :
                      char_state == S_RIGHT ? 95 :
                      char_state == S_ATTACK_START ? 120 :
                      char_state == S_ATTACK_ACTIVE ? 185 :
                      char_state == S_ATTACK_RECOVERY ? 132 :
                      char_state == S_ATTACK_DIR_START ? 132 :
                      char_state == S_ATTACK_DIR_ACTIVE ? 198 :
                      char_state == S_ATTACK_DIR_RECOVERY ? 132 : 
                      char_state == S_STUN ? 85 : 0;

    assign SPRITE_H = char_state == S_IDLE ? 230 :
                      char_state == S_LEFT ? 230 :
                      char_state == S_RIGHT ? 230 :
                      char_state == S_ATTACK_START ? 230 :
                      char_state == S_ATTACK_ACTIVE ? 242 :
                      char_state == S_ATTACK_RECOVERY ? 230 :
                      char_state == S_ATTACK_DIR_START ? 230 :
                      char_state == S_ATTACK_DIR_ACTIVE ? 230 :
                      char_state == S_ATTACK_DIR_RECOVERY ? 230 :
                      char_state == S_STUN ? 230 : 0;

    wire [14:0] addr = ((pixel_y - (start_y)) * SPRITE_W) + (pixel_x - (start_x)) + 2'd2;

    assign in_bounds = (pixel_x >= start_x) && (pixel_x < start_x + SPRITE_W) &&
                     (pixel_y >= start_y) && (pixel_y < start_y + SPRITE_H);
    wire [7:0] idle_data, walk_data, attack_start_data, attack_active_data, attack_recovery_data, attack_dir_active_data, stun_data;

    ali_idle aliidle_inst (
        .address(addr),
        .clock(clk),
        .q(idle_data)
    );

    ali_walk aliwalk_inst (
        .address(addr),
        .clock(clk),
        .q(walk_data)
    );

    ali_attack_start aliattackstart_inst (
        .address(addr),
        .clock(clk),
        .q(attack_start_data)
    );

    ali_attack_active aliattackactive_inst (
        .address(addr),
        .clock(clk),
        .q(attack_active_data)
    );

    ali_attack_dir_active aliattackdiractive_inst (
        .address(addr),
        .clock(clk),
        .q(attack_dir_active_data)
    );

    ali_stun alistun_inst (
        .address(addr),
        .clock(clk),
        .q(stun_data) // Stun state is not defined, using a placeholder color
    );

    assign color_out = in_bounds ? (
        (char_state == S_IDLE) ? idle_data :
        (char_state == S_LEFT) ? walk_data :
        (char_state == S_RIGHT) ? walk_data :
        (char_state == S_ATTACK_START) ? attack_start_data :
        (char_state == S_ATTACK_ACTIVE) ? attack_active_data :
        (char_state == S_ATTACK_RECOVERY) ? attack_start_data :
        (char_state == S_ATTACK_DIR_START) ? attack_start_data :
        (char_state == S_ATTACK_DIR_ACTIVE) ? attack_dir_active_data :
        (char_state == S_ATTACK_DIR_RECOVERY) ? attack_start_data :
        (char_state == S_STUN) ? stun_data :
        8'b111_111_11
    ) : 8'b111_111_11;

endmodule

module mif_renderer_kalp #(
    parameter SPRITE_W = 40,      // Sprite genişliği
    parameter SPRITE_H = 40       // Sprite yüksekliği
)(
    input  wire clk,
    input  wire [9:0] pixel_x,    // 0..639
    input  wire [8:0] pixel_y,    // 0..479
    input  wire [9:0] start_x,    // Başlangıç X koordinatı
    input  wire [9:0] start_y,    // Başlangıç Y koordinatı
    output wire [7:0] color_out
);
    wire [14:0] addr = ((pixel_y - start_y) * SPRITE_W) + (pixel_x - start_x) + 2'd2;

    wire in_bounds = (pixel_x >= start_x) && (pixel_x < start_x + SPRITE_W) &&
                     (pixel_y >= start_y) && (pixel_y < start_y + SPRITE_H);
    wire [7:0] rom_data;

    kalp image1_inst ( //kalp
        .address(addr),
        .clock(clk),
        .q(rom_data)
    );

    assign color_out = in_bounds ? rom_data : 8'b001_111_11;
endmodule

module mif_renderer_digit #(
    parameter SPRITE_W = 30,      // Sprite genişliği
    parameter SPRITE_H = 60       // Sprite yüksekliği
)(
    input  wire clk,
    input  wire enable,    // Enable sinyali
    input  wire [3:0] digit,      // 0..9
    input  wire [9:0] pixel_x,    // 0..639
    input  wire [8:0] pixel_y,    // 0..479
    input  wire [9:0] start_x,    // Başlangıç X koordinatı
    input  wire [9:0] start_y,    // Başlangıç Y koordinatı
    output wire [7:0] color_out
);
    wire [14:0] addr = ((pixel_y - start_y) * SPRITE_W) + (pixel_x - start_x);

    wire in_bounds = enable & ((pixel_x >= start_x) && (pixel_x < start_x + SPRITE_W) &&
                     (pixel_y >= start_y) && (pixel_y < start_y + SPRITE_H));
    wire [7:0] rom_data0, rom_data1, rom_data2, rom_data3, rom_data4, rom_data5, rom_data6, rom_data7, rom_data8, rom_data9;

    digit0 digit0_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data0)
    );

    digit1 digit1_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data1)
    );

    digit2 digit2_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data2)
    );

    digit3 digit3_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data3)
    );

    digit4 digit4_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data4)
    );

    digit5 digit5_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data5)
    );

    digit6 digit6_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data6)
    );

    digit7 digit7_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data7)
    );

    digit8 digit8_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data8)
    );

    digit9 digit9_inst (
        .address(addr),
        .clock(clk),
        .q(rom_data9)
    );

    assign color_out = in_bounds ? (
        (digit == 4'd0) ? rom_data0 :
        (digit == 4'd1) ? rom_data1 :
        (digit == 4'd2) ? rom_data2 :
        (digit == 4'd3) ? rom_data3 :
        (digit == 4'd4) ? rom_data4 :
        (digit == 4'd5) ? rom_data5 :
        (digit == 4'd6) ? rom_data6 :
        (digit == 4'd7) ? rom_data7 :
        (digit == 4'd8) ? rom_data8 :
        (digit == 4'd9) ? rom_data9 :
        8'b000_000_00
    ) : 8'b000_000_00;
endmodule

module counter_renderer #(
    parameter X_LEFT = 10'd285,
    parameter X_RIGHT = 10'd355,
    parameter Y_TOP = 10'd10,
    parameter Y_BOTTOM = 10'd70
)(
    input wire clk,
    input wire [9:0] x, // VGA x coordinate
    input wire [9:0] y, // VGA y coordinate
    input wire enable, // Enable signal for the counter
    input wire [7:0] counter_value, // Counter value to display
    input wire [3:0] fight_state,
    output wire [7:0] pixel_color // RRRGGGBB
);

    assign pixel_color = (tens_color) | (ones_color);

    reg [3:0] digit_tens, digit_ones;
    wire [7:0] tens_color, ones_color;
    mif_renderer_digit digit_tens_inst(
        .clk(clk),
        .digit(digit_tens),
        .enable(counter_enable[1]),
        .pixel_x(x),
        .pixel_y(y),
        .start_x(X_LEFT), // Offset for tens digit
        .start_y(Y_TOP), // Offset for tens digit
        .color_out(tens_color)
    );

    mif_renderer_digit digit_ones_inst(
        .clk(clk),
        .digit(digit_ones),
        .enable(counter_enable[0]),
        .pixel_x(x),
        .pixel_y(y),
        .start_x(X_LEFT + 10'd40), // Offset for ones digit
        .start_y(Y_TOP), // Offset for ones digit
        .color_out(ones_color)
    );

    localparam
    // Fight Controller States
    FIGHT_STATE_IDLE = 3'b000,
    FIGHT_STATE_START = 3'b001,
    FIGHT_STATE_ACTIVE = 3'b010,
    FIGHT_STATE_END_P1  = 3'b011,
    FIGHT_STATE_END_P2  = 3'b100,
    FIGHT_STATE_END_DRAW = 3'b101;

    localparam
    // Counter Box States
    COUNTER_BOX_IDLE = 3'b000,
    COUNTER_BOX_COUNTDOWN = 3'b001,
    COUNTER_BOX_ACTIVE = 3'b010,
    COUNTER_BOX_END = 3'b011;

    reg [2:0] counter_state;
    reg [1:0] counter_enable;
    wire [3:0] counter_tens = (counter_state == COUNTER_BOX_COUNTDOWN) ? ((counter_value / 10) % 10) : (((counter_value - 8'd3) / 8'd10) % 8'd10);
    wire [3:0] counter_ones = (counter_state == COUNTER_BOX_COUNTDOWN) ? (counter_value % 10) : ((counter_value - 8'd3) % 8'd10);

    always @(posedge clk) begin

        if (~enable) begin
            counter_state <= COUNTER_BOX_IDLE; // Reset counter state on disable
            counter_enable <= 2'b00; // Disable counter
            digit_tens <= 3'd0; // Reset tens digit
            digit_ones <= 3'd0; // Reset ones digit
        end
        case (counter_state)
            COUNTER_BOX_IDLE: begin
                if (fight_state == FIGHT_STATE_START) begin
                    counter_state <= COUNTER_BOX_COUNTDOWN;
                end else begin
                    counter_enable <= 2'b00; // Disable counter
                end    
            end

            COUNTER_BOX_COUNTDOWN: begin
                if (fight_state == FIGHT_STATE_START) begin
                    case (counter_value)
                        8'd0: begin
                            digit_tens <= 3'd3;
                            digit_ones <= 3'd0;
                            counter_enable <= 2'b10; // Enable counter
                        end

                        8'd1: begin
                            digit_tens <= 3'd0;
                            digit_ones <= 3'd2;
                            counter_enable <= 2'b01; // Enable counter
                        end

                        8'd2: begin
                            digit_tens <= 3'd1;
                            digit_ones <= 3'd0;
                            counter_enable <= 2'b10; // Enable counter
                        end

                        8'd3: begin
                            digit_tens <= 3'd0;
                            digit_ones <= 3'd0;
                            counter_enable <= 2'b11; // Enable counter
                            counter_state <= COUNTER_BOX_ACTIVE; // Move to active state
                        end
                    endcase
                end
            end

            COUNTER_BOX_ACTIVE: begin
                if ((fight_state == FIGHT_STATE_END_P1) | (fight_state == FIGHT_STATE_END_P2) | (fight_state == FIGHT_STATE_END_DRAW)) begin
                    counter_state <= COUNTER_BOX_END;
                end else begin
                    digit_tens <= counter_tens;
                    digit_ones <= counter_ones;
                    counter_enable <= 2'b11; // Enable both digits
                end
            end
            COUNTER_BOX_END: begin
                if ((fight_state == FIGHT_STATE_END_P1) | (fight_state == FIGHT_STATE_END_P2) | (fight_state == FIGHT_STATE_END_DRAW)) begin
                    counter_enable <= 2'b11; 
                end else begin
                    counter_state <= COUNTER_BOX_IDLE; // Reset to idle state
                end
            end
            default: counter_state <= COUNTER_BOX_IDLE;
        endcase
    end


endmodule

module background_renderer #(
    parameter X_LEFT = 10'd40,
    parameter X_RIGHT = 10'd600,
    parameter X_OFFSET = 10'd40,
    parameter Y_TOP = 10'd80,
    parameter Y_BOTTOM = 10'd380
)(
    input wire clk,
    input wire [2:0] game_state,
    input wire [3:0] fight_state, // Fight state
    input wire [9:0] x, // VGA x coordinate
    input wire [9:0] y, // VGA y coordinate
    input wire [2:0] char1_health, // Character 1 health
    input wire [2:0] char1_block,
    input wire [2:0] char2_health, // Character 2 health
    input wire [2:0] char2_block,
    input wire [7:0] counter_value, // Counter value to display
    output reg [7:0] pixel_color, // RRRGGGBB
    output wire active
);
    localparam
    // Game Controller States
    S_MENU  = 2'b00,
    S_GAME  = 2'b01;

    localparam
    // Heart - Block positions
    HEART1 = 6'b000001,
    HEART2 = 6'b000010,
    HEART3 = 6'b000100,
    HEART4 = 6'b001000,
    HEART5 = 6'b010000,
    HEART6 = 6'b100000;

    localparam
    heart1_x = 10'd100,
    heart2_x = 10'd160,
    heart3_x = 10'd220,
    heart4_x = 10'd380,
    heart5_x = 10'd440,
    heart6_x = 10'd500;

    wire window_active, timerbox_active;

    wire [9:0] heart_x;
    wire [5:0] heart_active;
    wire [5:0] block_active;
    wire [7:0] mif_color;
    wire [7:0] heart_color;
    wire [7:0] counter_color;

    assign timerbox_active = ((x >= 10'd285) && (x < 10'd355)) &&
                             ((y >= 10'd10) && (y < 10'd70));

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

    assign heart_x = heart_active[0] ? heart1_x :
                     heart_active[1] ? heart2_x :
                     heart_active[2] ? heart3_x :
                     heart_active[3] ? heart4_x :
                     heart_active[4] ? heart5_x :
                     heart_active[5] ? heart6_x : 10'd0;

    // Block Pixel Flags
    assign block_active[0] = ((x >= 10'd100) && (x < 10'd140)) &&
                             ((y >= 10'd460) && (y < 10'd470));

    assign block_active[1] = ((x >= 10'd160) && (x < 10'd200)) &&
                             ((y >= 10'd460) && (y < 10'd470));

    assign block_active[2] = ((x >= 10'd220) && (x < 10'd260)) &&
                             ((y >= 10'd460) && (y < 10'd470));

    assign block_active[3] = ((x >= 10'd380) && (x < 10'd420)) &&
                             ((y >= 10'd460) && (y < 10'd470));

    assign block_active[4] = ((x >= 10'd440) && (x < 10'd480)) &&
                             ((y >= 10'd460) && (y < 10'd470));
    
    assign block_active[5] = ((x >= 10'd500) && (x < 10'd540)) &&
                             ((y >= 10'd460) && (y < 10'd470));

    assign active = window_active | timerbox_active | ((heart_active | block_active) != 6'b000000);

    mif_renderer_kalp heart_mif_inst(
        .clk(clk),
        .pixel_x(x),
        .pixel_y(y),
        .start_x(heart_x),
        .start_y(10'd410),
        .color_out(heart_color)
    );

    counter_renderer counter_renderer_inst(
        .clk(clk),
        .x(x),
        .y(y),
        .enable(game_state),
        .counter_value(counter_value),
        .fight_state(fight_state),
        .pixel_color(counter_color)
    );

    always @(posedge clk) begin
        if (window_active) begin
            case (game_state)

                S_GAME: begin
                    pixel_color <= 8'b111_111_11; // White
                end

                S_MENU: begin
                    pixel_color <= 8'b000_000_10; // Koyu lacivert
                end

                default: pixel_color <= 8'b000_000_00; // Black for other states
            endcase
        end else begin

            // Health bar rendering
            if(heart_active > 6'b000000) begin
                case (heart_active)
                    HEART1: begin
                        if (char1_health[0] == 1'b1) begin
                            pixel_color <= heart_color; // Red for heart 1
                        end else begin
                            pixel_color <= 8'b000_000_00; // Black for empty heart
                        end
                    end

                    HEART2: begin
                        if (char1_health[1] == 1'b1) begin
                            pixel_color <= heart_color; // Red for heart 2
                        end else begin
                            pixel_color <= 8'b000_000_00; // Black for empty heart
                        end
                    end

                    HEART3: begin
                        if (char1_health[2] == 1'b1) begin
                            pixel_color <= heart_color; // Red for heart 3
                        end else begin
                            pixel_color <= 8'b000_000_00; // Black for empty heart
                        end
                    end

                    HEART4: begin
                        case (char2_health[2])
                            1'b1: pixel_color <= heart_color; // Red for heart 5
                            1'b0: pixel_color <= 8'b000_000_00; // Black for empty heart
                        endcase
                    end

                    HEART5: begin
                        case (char2_health[1])
                            1'b1: pixel_color <= heart_color; // Red for heart 5
                            1'b0: pixel_color <= 8'b000_000_00; // Black for empty heart
                        endcase
                    end

                    HEART6: begin
                        case (char2_health[0])
                            1'b1: pixel_color <= heart_color; // Red for heart 6
                            1'b0: pixel_color <= 8'b000_000_00; // Black for empty heart
                        endcase
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
            end else if (timerbox_active) begin
                // Timer box rendering
                pixel_color <= counter_color;
            end else begin
                // Default background color
                pixel_color <= 8'b000_000_00; // Black
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

    /*
    wire idle_active, prep_active, prep_dir_active, neutral_active, dir_active, hurtbox_active;

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
	*/

    wire [7:0] mif_color;

    mif_renderer_ali sprite_mif_inst(
        .clk(clk),
        .pixel_x(x),
        .pixel_y(y),
        .start_x(char_x_pos),
        .start_y(char_y_pos),
        .char_state(char_state),
        .in_bounds(active),
        .color_out(mif_color)
    );

    // Sprite position is always (0,0) in its own coordinate system
    // Sprite size: 128x240
    always @(posedge clk) begin
        if ((active)) begin
            pixel_color <= mif_color;
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
    input wire [3:0] fight_state, // Fight state
    input wire [7:0] counter_value, // Counter value to display
    output reg [7:0] pixel_color, // RRRGGGBB
    input wire [7:0] game_finish_time
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
        .fight_state(fight_state),
        .counter_value(counter_value),
        .x(x),
        .y(y),
        .char1_health(char1_health),
        .char1_block(char1_block),
        .char2_health(char2_health),
        .char2_block(char2_block)
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