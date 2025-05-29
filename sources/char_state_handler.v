module char_state_handler (
    input KEY_LEFT, // KEYS MUST BE INVERTED
    input KEY_RIGHT,
    input KEY_ATTACK,
    input CLOCK,

    output reg [3:0] STATE // 7-bit state output
);
//=======================================================
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

//=======================================================

reg [4:0] FrameCounter = 5'd0; // Frame counter for animation

initial begin
	STATE = S_IDLE; // Initialize state to S_IDLE
end

// MAIN FSM ========================================================

assign LEDR = STATE;

always @(posedge CLOCK)
begin
	case(STATE)
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
			if (KEY_LEFT) begin
				STATE <= S_LEFT;
			end else if (KEY_RIGHT) begin
				STATE <= S_RIGHT;
			end else if (KEY_ATTACK) begin
				FrameCounter <= 5'd4; 
				STATE <= S_ATTACK_DIR_START;
			end else begin
				STATE <= S_IDLE;
			end
		end

		S_RIGHT: begin
			if (KEY_LEFT) begin
				STATE <= S_LEFT;
			end else if (KEY_RIGHT) begin
				STATE <= S_RIGHT;
			end else if (KEY_ATTACK) begin
				FrameCounter <= 5'd4; 
				STATE <= S_ATTACK_DIR_START;
			end else begin
				STATE <= S_IDLE;

			end
		end

		S_ATTACK_START: begin
			if (FrameCounter > 0) begin
				FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
			end else begin
				FrameCounter <= 5'd2;
				STATE <= S_ATTACK_ACTIVE;
			end
		end

		S_ATTACK_ACTIVE: begin
			if (FrameCounter > 0) begin
				FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
			end else begin
				FrameCounter <= 5'd16;
				STATE <= S_ATTACK_RECOVERY;
			end
		end

		S_ATTACK_RECOVERY: begin
			if (FrameCounter > 0) begin
				FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
			end else begin
				STATE <= S_IDLE; // Return to idle state after recovery
			end
		end

		S_ATTACK_DIR_START: begin
			if (FrameCounter > 0) begin
				FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
			end else begin
				FrameCounter <= 5'd3;
				STATE <= S_ATTACK_DIR_ACTIVE;
			end
		end

		S_ATTACK_DIR_ACTIVE: begin
			if (FrameCounter > 0) begin
				FrameCounter <= FrameCounter - 5'd1; // Decrement frame counter
			end else begin
				FrameCounter <= 5'd15;
				STATE <= S_ATTACK_DIR_RECOVERY;
			end
		end

		S_ATTACK_DIR_RECOVERY: begin
			if (FrameCounter > 0) begin
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

endmodule
