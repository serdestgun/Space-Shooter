module clock_divider(
    input clk,
    input reset,
    output reg clk_out
);

    reg [15:0] counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == 0) begin
                clk_out <= ~clk_out;
            end
        end
    end

endmodule
