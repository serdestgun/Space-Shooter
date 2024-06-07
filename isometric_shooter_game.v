module isometric_shooter_game(
    input clk,
    input reset,
    input [2:0] btn,  // Buttons for rotation and firing
    input [1:0] sw,   // Switches for selecting shooting mode
    output [7:0] led, // LEDs for visual feedback
    //output [3:0] an,  // Seven segment display anode
    output [6:0] seg, // Seven segment display segments
    output hsync,
    output vsync,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue
);

    // Clock and reset management
    wire clk25;
    clock_divider clk_div(.clk(clk), .reset(reset), .clk_out(clk25));

    // Game state management
    reg [3:0] spaceship_angle;
    wire [15:0] score;
    wire [31:0] enemy_positions;
    wire [31:0] enemy_types;
    wire [31:0] enemy_health;
    reg [1:0] shooting_mode;
    reg fire;
    reg [3:0] fire_angle;
    reg [1:0] fire_mode;

    // Display management
    vga_controller vga_ctrl(
        .clk(clk25),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .red(vgaRed),
        .green(vgaGreen),
        .blue(vgaBlue),
        .spaceship_angle(spaceship_angle),
        .enemy_positions(enemy_positions),
        .enemy_types(enemy_types),
        .enemy_health(enemy_health)
    );

    // Spaceship control and firing logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            spaceship_angle <= 0;
            fire <= 0;
        end else begin
            if (btn[0]) spaceship_angle <= spaceship_angle + 4; // Clockwise rotation
            if (btn[1]) spaceship_angle <= spaceship_angle - 4; // Counterclockwise rotation
            if (btn[2]) begin // Fire projectile
                fire <= 1;
                fire_angle <= spaceship_angle;
                fire_mode <= shooting_mode;
            end else begin
                fire <= 0;
            end
        end
    end

    // Enemy management
    enemy_controller enemy_ctrl(
        .clk(clk25),
        .reset(reset),
        .enemy_positions(enemy_positions),
        .enemy_types(enemy_types),
        .enemy_health(enemy_health),
        .fire(fire),
        .fire_angle(fire_angle),
        .fire_mode(fire_mode),
        .score(score)
    );

    // Shooting mode control
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shooting_mode <= 2'b00;
        end else begin
            shooting_mode <= sw;
        end
    end
	 
	 wire [3:0] an = 1;

    // Scoring and game over management
    score_display score_disp(
        .clk(clk25),
        .reset(reset),
        .score(score),
        .an(an),
        .seg(seg)
    );

    // LEDs for visual feedback
    assign led = {spaceship_angle, shooting_mode};

endmodule
