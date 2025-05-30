module char_pos_handler #(
    parameter INIT_X = 10'd40,         // Başlangıç x konumu
    parameter INIT_Y = 10'd200,         // Başlangıç y konumu (örnek: 0)
    parameter MIN_X = 10'd40,          // Minimum x konumu
    parameter MAX_X = 10'd600,         // Maksimum x konumu (örnek)
    parameter CHAR_WIDTH = 10'd128,     // Karakterin genişliği
    parameter CHAR_HEIGHT = 10'd240    // Karakterin yüksekliği
)(
    input  wire        clk,
    input  wire        rst,        // Senkron reset
    input  wire [3:0]  state,      // char_state_handler'dan gelen state
    output reg  [9:0]  char_x,     // Karakterin x konumu (örnek: 10 bit)
    output reg  [9:0]  char_y     // Karakterin y konumu (örnek: 10 bit)
);

// State tanımlamaları
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

initial begin
	char_y = INIT_Y; // Y konumu sabit, başlangıçta INIT_Y olarak ayarlanır
	char_x = INIT_X;
end

always @(posedge clk) begin
    if (rst) begin
        char_x <= INIT_X;
    end else begin
        case (state)
            S_LEFT: begin
                if (char_x - 2'd2 >= MIN_X) begin
                    char_x <= char_x - 2'd2; // Sol hareket
                end else begin
                    char_x <= MIN_X; // Minimum x konumuna ulaşınca sabit kalır
                end
            end
            S_RIGHT: begin
                if (char_x + 3'd2 <= MAX_X - CHAR_WIDTH) begin
                    char_x <= char_x + 3'd2; // Sağ hareket
                end else begin
                    char_x <= MAX_X - CHAR_WIDTH; // Maksimum x konumuna ulaşınca sabit kalır
                end
            end
            default: begin
                char_x <= char_x; // Konum değişmez
            end
        endcase
    end
end

endmodule