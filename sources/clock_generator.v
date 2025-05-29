module clk25MHz (
    input  wire clk50MHz,   // 50 MHz giriş saati
    output reg  clk25MHz    // 25 MHz çıkış saati
);

// Her pozitif kenarda çıkışı tersle
always @(posedge clk50MHz) begin
    clk25MHz <= ~clk25MHz;
end

endmodule

module clock_divider #(
    parameter hardware_clock = 50000000,
    parameter DIVISOR = 2
)(
    input clk_in,
    output reg clk_out
);

    reg [31:0] counter;

    always @(posedge clk_in) begin
        if (counter >= DIVISOR - 1) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end

        clk_out <= (counter < hardware_clock/DIVISOR) ? 1'b1 : 1'b0;
    end

endmodule

module game_clock_generator(
    input wire clk_50mhz,
    input wire switch,
    input wire step_btn,
    output game_clk,
    output vga_clk
);
    wire clk_60fps;
    reg game_clk_reg;

    // 50_000_000 / 833_333 = 60 Hz
    clock_divider #(.DIVISOR(833_333)) clkdiv_inst (
        .clk_in(clk_50mhz),
        .clk_out(clk_60fps)
    );

    clk25MHz vga_clk_gen (
        .clk50MHz(clk_50mhz),
        .clk25MHz(vga_clk)
    );

    always @(*) begin
        if (switch == 1'b0)
            game_clk_reg = clk_60fps;
        else
            game_clk_reg = step_btn;
    end

    assign game_clk = game_clk_reg;

endmodule