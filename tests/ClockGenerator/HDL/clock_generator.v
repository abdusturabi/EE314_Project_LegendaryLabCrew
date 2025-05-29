module clock_divider #(parameter DIVISOR = 2) (
    input wire clk_in,
    output reg clk_out
);

    reg [31:0] counter; // 32-bit counter to hold the count value

    always @(posedge clk_in) begin
        if (counter == DIVISOR - 1)
        begin
            clk_out <= ~clk_out; // Toggle the output clock
            counter <= 0; // Reset the counter
        end else begin
            counter <= counter + 1; // Increment the counter
        end
    end
endmodule

module game_clock_generator(
    input wire clk_50mhz,
    input wire switch,
    input wire step_btn,
    output wire game_clk,
    output wire vga_clk
);

    wire clk_60fps;
    reg game_clk_reg;

    // 50_000_000 / 60 = 833_333 (for 60 Hz)
    clock_divider #(.DIVISOR(833_333)) clkdiv_inst (
        .clk_in(clk_50mhz),
        .clk_out(clk_60fps)
    );

    clock_divider #(.DIVISOR(2)) vga_clock_inst (
        .clk_in(clk_50mhz),
        .clk_out(vga_clk)
    );

    always @(*) begin
        if (switch == 1'b0)
            game_clk_reg = clk_60fps;
        else
            game_clk_reg = step_btn;
    end

    assign game_clk = game_clk_reg;

endmodule