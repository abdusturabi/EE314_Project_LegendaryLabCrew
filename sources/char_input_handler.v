// Frame counter module
module frame_counter_module (
    input wire clk,
    input wire reset,
    input wire enable,
    output reg [6:0] frame_value
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            frame_value <= 0;
        else if (enable) begin
            if (frame_value == 7'd119)
                frame_value <= 0;
            else
                frame_value <= frame_value + 7'd1;
        end
    end
endmodule

module bot_input_generator (
    input wire clk_game,
    input wire reset,
    input wire p1_input_valid,
    input wire [6:0] current_frame,
    output reg bot_input_valid,
    output reg [2:0] bot_input_code
);

    localparam
        IN_LEFT = 3'b100,
        IN_RIGHT = 3'b001,
        IN_ATTACK = 3'b010,
        IN_DIR_LEFT = 3'b110,
        IN_DIR_RIGHT = 3'b011;

    localparam
        BOT_IDLE = 2'b00,
        BOT_INPUT = 2'b01,
        BOT_DELAY = 2'b10,
        BOT_ACTION = 2'b11;

    reg [1:0] bot_state;
    reg [6:0] input_frame_value;
    reg [5:0] remaining_delay;
    reg [5:0] input_hold_counter;
    reg [2:0] selected_input;
    reg is_walking_input;

    always @(posedge clk_game or posedge reset) begin
        if (reset) begin
            bot_state <= BOT_IDLE;
            input_frame_value <= 7'd0;
            remaining_delay <= 6'd0;
            input_hold_counter <= 6'd0;
            selected_input <= 3'b000;
            is_walking_input <= 1'b0;
            bot_input_valid <= 1'b0;
            bot_input_code <= 3'd0;
        end else begin
            case (bot_state)
                BOT_IDLE: begin
                    bot_input_valid <= 1'b0;
                    if (p1_input_valid) begin
                        input_frame_value <= current_frame;
                        bot_state <= BOT_INPUT;
                    end
                end

                BOT_INPUT: begin
                    selected_input <= {input_frame_value[5], input_frame_value[3], input_frame_value[1]};
                    remaining_delay <= ({input_frame_value[4], input_frame_value[2], input_frame_value[0]} * 6'd7);
                    is_walking_input <= ((selected_input == IN_LEFT) | (selected_input == IN_RIGHT));
                    input_hold_counter <= ({input_frame_value[4], input_frame_value[2], input_frame_value[0]} * 6'd7);
                    bot_state <= BOT_DELAY;
                end

                BOT_DELAY: begin
                    bot_input_valid <= 1'b0;
                    if (remaining_delay > 1'b0)
                        remaining_delay <= remaining_delay - 6'd1;
                    else
                        bot_state <= BOT_ACTION;
                end

                BOT_ACTION: begin
                    if (is_walking_input) begin
                        if (input_hold_counter > 0) begin
                            input_hold_counter <= input_hold_counter - 6'd1;
                            bot_input_valid <= 1'b1;
                            bot_input_code <= selected_input;
                        end else begin
                            bot_input_valid <= 1'b0;
                            bot_state <= BOT_IDLE;
                        end
                    end else begin
                        bot_input_valid <= 1'b1;
                        bot_input_code <= selected_input;
                        bot_state <= BOT_IDLE;
                    end
                end
            endcase
        end
    end

endmodule

// char_input_handler with frame counter instantiation
module char_input_handler (
    input wire clk_game,
    input wire reset,
    input wire p1_input_valid,
    input wire char_left,
    input wire char_right,
    input wire char_attack,
    input wire game_mode,           // 0 = Player, 1 = Bot
    output wire char_out_left,
    output wire char_out_right,
    output wire char_out_attack
);

    wire [6:0] current_frame;
    frame_counter_module frame_counter_inst (
        .clk(clk_game),
        .reset(reset),
        .frame_value(current_frame),
        .enable(game_mode) // Enable frame counter based on game mode
    );

    wire bot_input_valid;
    wire [2:0] bot_input_code;
    wire bot_reset;
    assign bot_reset = reset | (~game_mode);
    bot_input_generator botgen (
        .clk_game(clk_game),
        .reset(bot_reset),
        .p1_input_valid(p1_input_valid),
        .current_frame(current_frame),
        .bot_input_valid(bot_input_valid),
        .bot_input_code(bot_input_code)
    );

    assign char_out_left   = (game_mode) ? (bot_input_valid & bot_input_code[2]) : char_left;
    assign char_out_right  = (game_mode) ? (bot_input_valid & bot_input_code[1]) : char_right;
    assign char_out_attack = (game_mode) ? (bot_input_valid & bot_input_code[0]) : char_attack;

endmodule
