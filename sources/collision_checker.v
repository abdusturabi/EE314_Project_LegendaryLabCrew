module collision_checker #(
    parameter CHAR_WIDTH = 10'd128,     // Karakterin genişliği
    parameter CHAR_HEIGHT = 10'd240    // Karakterin yüksekliği
)(
    input  wire       clk,
    input  wire [9:0] char1_pos_x,
    input  wire [9:0] char1_pos_y,
    input  wire [3:0] char1_state,
    input  wire       char1_block_flag,

    input  wire [9:0] char2_pos_x,
    input  wire [9:0] char2_pos_y,
    input  wire [3:0] char2_state,
    input  wire       char2_block_flag,

    output wire       collision_flag,
    
    // Frame States for Game Controller to give penalties
    output reg [1:0] char1_frame_state,
    output reg [1:0] char2_frame_state
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
    S_STUN =              4'b1001;
	 
	localparam
	S_NOHIT =     2'b00,
    S_HITSTUN =   2'b01,
    S_BLOCKSTUN = 2'b10;

    wire char1_hit_flag, char2_hit_flag;

    assign collision_flag = ((char1_pos_x + CHAR_WIDTH) >= char2_pos_x - 3'd5);

    assign char1_hit_flag = (char1_state == S_ATTACK_ACTIVE | S_ATTACK_DIR_ACTIVE) && (char2_state != S_STUN) &&
                            ((char1_pos_x + (3*CHAR_WIDTH/2)) >= char2_pos_x); // hurtboxa göre değiştirilecek

    assign char2_hit_flag = (char2_state == S_ATTACK_ACTIVE | S_ATTACK_DIR_ACTIVE) && (char1_state != S_STUN) &&
                            ((char2_pos_x - (3*CHAR_WIDTH/2)) <= char1_pos_x + CHAR_WIDTH); // directionalı değiştirmemiz gerekecek
                            
    always @(posedge clk) begin
        if (char1_hit_flag && char2_hit_flag) begin
            // Both characters hit each other
            char1_frame_state <= S_HITSTUN;
            char2_frame_state <= S_HITSTUN;
        end else if (char1_hit_flag) begin
            // Character 1 hits Character 2
            if(char2_block_flag) begin
                char2_frame_state <= S_BLOCKSTUN;
            end else begin
                char2_frame_state <= S_HITSTUN;
            end
        end else if (char2_hit_flag) begin
            // Character 2 hits Character 1
            if(char1_block_flag) begin
                char1_frame_state <= S_BLOCKSTUN;
            end else begin
                char1_frame_state <= S_HITSTUN;
            end
        end else begin
            // No hits, both characters in idle state
            char1_frame_state <= S_NOHIT;
            char2_frame_state <= S_NOHIT;
        end 
    end
endmodule