module second_counter (
    input  wire        clk,
    input  wire        clk_pref, // Determines which clock using
    input  wire        active, // Active high signal to indicate fight state
    input  wire        rst, // Asynchronous reset

    output reg [7:0]   second_counter // Counter for finding 1 second
);

reg [7:0] clock_counter; // Counter for finding 1 second

always @(posedge clk or posedge rst) begin
    if (rst) begin
        second_counter <= 8'd0; // Reset counter on reset signal
        clock_counter <= 8'd0; // Reset clock counter
    end else if (active) begin
        if (~clk_pref) begin
            // If using 60Hz clock, increment every 60 cycles
            if (clock_counter >= 8'd60) begin
                second_counter <= second_counter + 1'b1;
                clock_counter <= 8'd0; // Reset clock counter after 60 cycles
            end else begin
                clock_counter <= clock_counter + 1'b1; // Increment clock counter
            end
        end else begin
            // If using button clock, increment every press
            second_counter <= second_counter + 1'b1;
        end    
    end
end

endmodule

module fight_controller (
    input  wire        clk,
    input  wire        clk_pref,               // Determines which clock using
    input  wire        fight_active,           // Active high signal to indicate fight state

    input  wire [9:0]   char1_x_pos,      // Character 1 X position
    input  wire [9:0]   char1_y_pos,      // Character 1 Y position
    input  wire [3:0]  char1_state,       // Character 1 state
    input  wire [1:0]  char1_frame_state, // Character 1 frame state
    input  wire [4:0]  char1_frameCounter, // Character 1 frame counter

    input  wire [9:0]  char2_x_pos,      // Character 2 X position
    input  wire [9:0]  char2_y_pos,      // Character 2 Y position
    input  wire [3:0]  char2_state,       // Character 2 state
    input  wire [1:0]  char2_frame_state, // Character 2 frame state
    input  wire [4:0]  char2_frameCounter, // Character 2 frame counter

    output reg [4:0]   char1_load_frame, // Character 1 load frame
    output reg [4:0]   char2_load_frame, // Character 2 load frame
    output reg [2:0]   char1_health,    // Character 1 health
    output reg [2:0]   char2_health,    // Character 2 health
    output reg [2:0]   char1_block,
    output reg [2:0]   char2_block,
    output reg [3:0]   fight_state,
    output reg         input_active     // Input active flag for fight controller

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
// Character States
S_IDLE = 		      4'b0000,
S_LEFT = 		      4'b0001,
S_RIGHT = 		      4'b0010,
S_ATTACK_START =      4'b0011,
S_ATTACK_ACTIVE =     4'b0100,
S_ATTACK_RECOVERY =   4'b0101,
S_ATTACK_DIR_START =  4'b0110,
S_ATTACK_DIR_ACTIVE = 4'b0111,
S_ATTACK_DIR_RECOVERY = 4'b1000,
S_STUN =              4'b1001;

localparam
S_NOHIT =      2'b00,
S_HITSTUN =   2'b01,
S_BLOCKSTUN = 2'b10;

reg  [7:0] start_counter; // Counter for start state
wire [7:0] second_counter; // Counter for finding 1 second
reg [7:0] game_finish_time;
reg counter_rst, counter_active;

second_counter sec_count(
    .clk(clk),
    .clk_pref(clk_pref),
    .active(counter_active),
    .rst(counter_rst),
    .second_counter(second_counter)
);

always @(posedge clk) begin

    case (fight_state)
        FIGHT_STATE_IDLE: begin
            // Game Init Logic
            char1_health <= 3'b111;
            char2_health <= 3'b111;

            char1_block <= 3'b111;
            char2_block <= 3'b111;

            counter_rst <= 1'b1; // Reset second counter
            input_active <= 1'b0; // Deactivate input for fight controller
            if (fight_active) begin
                fight_state <= FIGHT_STATE_START; // Transition to start state
                counter_active <= 1'b0; // Deactivate second counter
            end
        end
        
        FIGHT_STATE_START: begin
            counter_rst <= 1'b0; // Keep second counter active
            counter_active <= 1'b1; // Activate second counter

            case(second_counter)
                8'd0: begin
                    // 3
                end
                8'd1: begin
                    // 2
                end
                8'd2: begin
                    // 1
                end
                8'd3: begin
                    // FIGHT!
                    fight_state <= FIGHT_STATE_ACTIVE; // Transition to active state after start counter
                    //counter_rst <= 1'b1; // Reset second counter
                    input_active <= 1'b1; // Activate input for fight controller
                end
                default: begin
                    // Nothing
                end
            endcase
            
        end
        
        FIGHT_STATE_ACTIVE: begin
            // Active fight logic

            // Check for end conditions
            if ((char1_health & char2_health == 3'b000) | (second_counter == 8'd103)) begin 
                if(char1_health == 3'b000 && char2_health == 3'b000) begin
                    fight_state <= FIGHT_STATE_END_DRAW; // Both characters lose all health
                    game_finish_time <= second_counter; // Store finish time
                end else if (char1_health == 3'b000) begin
                    fight_state <= FIGHT_STATE_END_P2; // Character 2 wins
                    game_finish_time <= second_counter; // Store finish time
                end else if (char2_health == 3'b000) begin
                    fight_state <= FIGHT_STATE_END_P1; // Character 1 wins
                    game_finish_time <= second_counter; // Store finish time
                end else if (second_counter == 8'd103) begin
                    fight_state <= FIGHT_STATE_END_DRAW; // Draw condition after 99 seconds
                    game_finish_time <= second_counter; // Store finish time
                end
            end
            
            if ((char1_frame_state == S_HITSTUN) | (char2_frame_state == S_HITSTUN)) begin
                // Both characters in hitstun: apply penalty to both
                if ((char1_frame_state == S_HITSTUN) & (char2_frame_state == S_HITSTUN)) begin
                    char1_load_frame <= char1_frameCounter + 5'd15;
                    char2_load_frame <= char1_frameCounter + 5'd15;
                    char1_health <= (char1_health >> 1);
                    char2_health <= (char2_health >> 1);
                end
                // Only char1 in hitstun
                else if (char1_frame_state == S_HITSTUN) begin
                    if (char2_state == S_ATTACK_ACTIVE) begin
                        char1_load_frame <= char2_frameCounter + 5'd15;
                    end else if (char2_state == S_ATTACK_DIR_ACTIVE) begin
                        char1_load_frame <= char2_frameCounter + 5'd14;
                    end
                    char1_health <= (char1_health >> 1);
                end
                // Only char2 in hitstun
                else if (char2_frame_state == S_HITSTUN) begin
                    if (char1_state == S_ATTACK_ACTIVE) begin
                        char2_load_frame <= char1_frameCounter + 5'd15;
                        char2_health <= (char2_health >> 1);
                    end else if (char1_state == S_ATTACK_DIR_ACTIVE) begin
                        char2_load_frame <= char1_frameCounter + 5'd14;
                        char2_health <= (char2_health >> 1);
                    end
                end
                
            end else if ((char1_frame_state == S_BLOCKSTUN) | (char2_frame_state == S_BLOCKSTUN)) begin
                if(char1_frame_state == S_BLOCKSTUN) begin
                    // Character 1 in blockstun
                    if (char2_state == S_ATTACK_ACTIVE) begin
                        char1_load_frame <= char2_frameCounter + 5'd13;
                    end else if (char2_state == S_ATTACK_DIR_ACTIVE) begin
                        char1_load_frame <= char2_frameCounter + 5'd12;
                    end
                    char1_block <= (char1_block >> 1); 

                end else if (char2_frame_state == S_BLOCKSTUN) begin
                    // Character 2 in blockstun
                    if (char1_state == S_ATTACK_ACTIVE) begin
                        char2_load_frame <= char1_frameCounter + 5'd13;
                    end else if (char1_state == S_ATTACK_DIR_ACTIVE) begin
                        char2_load_frame <= char1_frameCounter + 5'd12;
                    char2_block <= (char2_block >> 1);
                    end
                end
            end
        end
        
        FIGHT_STATE_END_P1: begin
            // End fight logic for character 1 win
            input_active <= 1'b0; // Deactivate input for fight controller
            if(second_counter >= game_finish_time + 8'd5) begin
                // After 5 seconds, reset fight state
                fight_state <= FIGHT_STATE_IDLE; // Reset to idle state
            end                
        end
        
        FIGHT_STATE_END_P2: begin
            // End fight logic for character 2 win
            input_active <= 1'b0; // Deactivate input for fight controller
            if(second_counter >= game_finish_time + 8'd5) begin
                // After 5 seconds, reset fight state
                fight_state <= FIGHT_STATE_IDLE; // Reset to idle state
            end 
        end
        FIGHT_STATE_END_DRAW: begin
            // End fight logic for draw condition
            input_active <= 1'b0; // Deactivate input for fight controller
            if(second_counter >= game_finish_time + 8'd5) begin
                // After 5 seconds, reset fight state
                fight_state <= FIGHT_STATE_IDLE; // Reset to idle state
            end 
        end
        default: begin
            // Default case to handle unexpected states
            fight_state <= FIGHT_STATE_IDLE; // Reset to idle state
        end
    endcase
	 
	 if (~fight_active) begin
		fight_state <= FIGHT_STATE_IDLE; // Reset fight state when not active
	 end
end
endmodule

module game_controller (
    input  wire        clk,
    input  wire        clk_pref,      // Determines which clock using (SW0 bağlanacak)
    input  wire        rst,           // Asynchronous reset
    input  wire        start_btn,     // Start button (active high)
    input  wire        mode_switch,   // Game mode select switch (0: Mode1, 1: Mode2)
    output reg [2:0]   game_state,     // Game state input 

    input  wire [9:0]  char1_x_pos,      // Character 1 X position
    input  wire [9:0]  char1_y_pos,      // Character 1 Y position
    input  wire [3:0]  char1_state,       // Character 1 state
    input  wire [1:0]  char1_frame_state, // Character 1 frame state
    input  wire [4:0]  char1_frameCounter, // Character 1 frame counter
    output wire [4:0]  char1_load_frame, // Character 1 load frame

    input  wire [9:0]   char2_x_pos,      // Character 2 X position
    input  wire [9:0]   char2_y_pos,      // Character 2 Y position
    input  wire [3:0]   char2_state,       // Character 2 state
    input  wire [1:0]   char2_frame_state, // Character 2 frame state
    input wire  [4:0]   char2_frameCounter, // Character 2 frame counter
    output wire [4:0]   char2_load_frame, // Character 2 load frame

    output wire [2:0]   char1_health,    // Character 1 health
    output wire [2:0]   char1_health_led, // Character 1 health for LED
    output wire [2:0]   char1_block,     // Character 1 block for LED
    output wire [2:0]   char2_health,    // Character 2 health
    output wire [2:0]   char2_health_led, // Character 2 health for LED
    output wire [2:0]   char2_block,     // Character 2 block for LED

    output wire [3:0]   fight_state,
    
    output wire        input_active, // Input active flag
    output reg         menu_active,   // Menu flag
    output reg         game_active,   // Game flag
    output wire  [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,  // 7-segment display output (assume common cathode)
    output reg         mode_selected // 0: Mode1, 1: Mode2
);

reg [41:0] seg7; // 7-segment display output

localparam
// Game Controller States
S_MENU  = 2'b00,
S_GAME  = 2'b01;

localparam
// Fight Controller States
FIGHT_STATE_IDLE = 3'b000,
FIGHT_STATE_START = 3'b001,
FIGHT_STATE_ACTIVE = 3'b010,
FIGHT_STATE_END_P1  = 3'b011,
FIGHT_STATE_END_P2  = 3'b100,
FIGHT_STATE_END_DRAW = 3'b101;

localparam
SEG_FIGHT = 42'b0111000_1111001_0100000_1001000_0001111_0111001,
SEG_1P    = 42'b1111111_1111111_1111001_0011000_1111111_1111111, // "1P"
SEG_2P    = 42'b1111111_1111111_0010010_0011000_1111111_1111111; // "2P"

assign HEX5 = seg7[6:0];
assign HEX4 = seg7[13:7];
assign HEX3 = seg7[20:14];
assign HEX2 = seg7[27:21];
assign HEX1 = seg7[34:28];
assign HEX0 = seg7[41:35];

reg match_over;
assign char1_health_led = (game_state == S_GAME) ? char1_health : 3'b000; // Assign health for LED display
assign char2_health_led = (game_state == S_GAME) ? char2_health : 3'b000; // Assign health for LED display

fight_controller fight_ctrl(
    .clk(clk),
    .clk_pref(clk_pref),
    .fight_active(game_active), // Fight active signal
    .char1_x_pos(char1_x_pos),
    .char1_y_pos(char1_y_pos),
    .char1_state(char1_state),
    .char1_frame_state(char1_frame_state),
    .char1_frameCounter(char1_frameCounter),
    .char2_x_pos(char2_x_pos),
    .char2_y_pos(char2_y_pos),
    .char2_state(char2_state),
    .char2_frame_state(char2_frame_state),
    .char2_frameCounter(char2_frameCounter),
    .char1_load_frame(char1_load_frame),
    .char2_load_frame(char2_load_frame),
    .char1_health(char1_health),
    .char2_health(char2_health),
    .char1_block(char1_block),
    .char2_block(char2_block),
    .fight_state(fight_state),
    .input_active(input_active) // Input active flag for fight controller
);
    
always @(posedge clk or posedge rst) begin
    if (rst) begin
        game_state    <= S_MENU;
        menu_active   <= 1'b1;
        game_active   <= 1'b0;
        seg7          <= SEG_2P;
        mode_selected <= 1'b0;
    end else begin
        case (game_state)
            S_MENU: begin
                menu_active   <= 1'b1;
                game_active   <= 1'b0;
                if (mode_switch) begin
                    seg7 <= SEG_1P; 
                    mode_selected <= 1'b1; 
                end else begin
                    seg7 <= SEG_2P; // Default to 2P mode on reset
                    mode_selected <= 1'b0; // 0: Mode1, 1: Mode2
                end

                if (start_btn) begin
                    game_state <= S_GAME; // Transition to game state on start button press
                    game_active <= 1'b1; // Activate game state
                    menu_active <= 1'b0; // Deactivate menu state
						  seg7 <= SEG_FIGHT;
                end else begin
                    game_state <= S_MENU; // Stay in menu state
                end
            end
            S_GAME: begin
                if ((fight_state == FIGHT_STATE_END_P1) | (fight_state == FIGHT_STATE_END_P2) | (fight_state == FIGHT_STATE_END_DRAW)) begin
                    match_over <= 1'b1; // Match is over
                end
                if (match_over & (fight_state == FIGHT_STATE_IDLE)) begin
                    game_state <= S_MENU; // Return to menu state after match over
                    match_over <= 1'b0; // Reset match over flag
                end
            end
            default: begin
                game_state <= S_MENU; // Default to menu state on unexpected states
                menu_active <= 1'b1; // Ensure menu is active
                game_active <= 1'b0; // Ensure game is inactive
            end
        endcase
    end
end

endmodule