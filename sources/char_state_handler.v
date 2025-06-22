module char_state_handler (
    input KEY_LEFT, // KEYS MUST BE INVERTED
    input KEY_RIGHT,
    input KEY_ATTACK,
    input CLOCK,
	input char_no,
	input [4:0] load_frame,
	input enable,

	output wire [4:0] load_frame_led,
    output reg [3:0] STATE, // 7-bit state output
	output wire [3:0] state_led, // State LED output
	output wire button_flag,
	output wire block_flag,
	output reg [4:0] FrameCounter
);
//=======================================================
assign state_led = STATE; // Output the current state to LEDs
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
S_STUN =              4'b1001;

//=======================================================
reg [4:0] prev_load_frame; // Previous load frame value
wire load_frame_valid; // Flag to indicate if load frame is valid


initial begin
	STATE = S_IDLE; // Initialize state to S_IDLE
end

// MAIN FSM ========================================================

assign button_flag = KEY_LEFT | KEY_RIGHT;
assign block_flag = ((char_no == 1'b0) & (STATE == S_LEFT)) | ((char_no == 1'b1) & (STATE == S_RIGHT));
assign load_frame_led = load_frame; // Output the load frame to LEDs

//=======================================================

assign load_frame_valid = (load_frame != 5'd0) & (prev_load_frame == 5'd0); // Check if load frame is valid

always @(posedge CLOCK)
begin
	
	prev_load_frame <= load_frame; // Store the previous load frame value
	
	if(enable) begin
		if (load_frame_valid & (STATE != S_STUN)) begin
			FrameCounter <= (load_frame > 0) ? (load_frame - 1'b1) : 5'd0; 
			STATE <= S_STUN;
		end else begin
			// Eğer stun yoksa FSM'i çalıştır
			case(STATE)

				S_STUN: begin
					if (FrameCounter == 1) begin
						STATE <= S_IDLE; // Return to idle state after stun
					end else begin
						FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
					end
				end
				S_IDLE: begin
					if (KEY_LEFT) begin
						STATE <= S_LEFT;
					end else if (KEY_RIGHT) begin
						STATE <= S_RIGHT;
					end else if (KEY_ATTACK) begin
						FrameCounter <= 5'd5; 
						STATE <= S_ATTACK_START;
					end
				end

				S_LEFT: begin
					if (KEY_ATTACK) begin
						FrameCounter <= 5'd4; 
						STATE <= S_ATTACK_DIR_START;
					end else if (KEY_RIGHT) begin
						STATE <= S_RIGHT;
					end else if (KEY_LEFT) begin
						STATE <= S_LEFT;
					end else begin
						STATE <= S_IDLE;
					end
				end

				S_RIGHT: begin
					if(KEY_ATTACK) begin
						FrameCounter <= 5'd4; 
						STATE <= S_ATTACK_DIR_START;
					end else if (KEY_LEFT) begin
						STATE <= S_LEFT;
					end else if (KEY_RIGHT) begin
						STATE <= S_RIGHT;
					end else begin
						STATE <= S_IDLE;
					end
				end

				S_ATTACK_START: begin
					if (FrameCounter > 1) begin
						FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
					end else begin
						FrameCounter <= 5'd2;
						STATE <= S_ATTACK_ACTIVE;
					end
				end

				S_ATTACK_ACTIVE: begin
					if (FrameCounter > 1) begin
						FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
					end else begin
						FrameCounter <= 5'd16;
						STATE <= S_ATTACK_RECOVERY;
					end
				end

				S_ATTACK_RECOVERY: begin
					if (FrameCounter > 1) begin
						FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
					end else begin
						STATE <= S_IDLE; // Return to idle state after recovery
					end
				end

				S_ATTACK_DIR_START: begin
					if (FrameCounter > 1) begin
						FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
					end else begin
						FrameCounter <= 5'd3;
						STATE <= S_ATTACK_DIR_ACTIVE;
					end
				end

				S_ATTACK_DIR_ACTIVE: begin
					if (FrameCounter > 1) begin
						FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
					end else begin
						FrameCounter <= 5'd15;
						STATE <= S_ATTACK_DIR_RECOVERY;
					end
				end

				S_ATTACK_DIR_RECOVERY: begin
					if (FrameCounter > 1) begin
						FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
					end else begin
						STATE <= S_IDLE; // Return to idle state after recovery
					end
				end

				default: begin
					STATE <= S_IDLE; // Default case to handle unexpected states
				end
			endcase
		end
	end else begin
		// If enable is low, reset the state and frame counter
		STATE <= S_IDLE;
		FrameCounter <= 5'd1; // Reset frame counter
	end
end

endmodule
