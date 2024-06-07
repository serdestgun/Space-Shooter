module vga_controller(
    input clk,
    input reset,
    output reg hsync,
    output reg vsync,
    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue,
    input [3:0] spaceship_angle,
    input [31:0] enemy_positions,  // 8 enemies with 4-bit positions
    input [31:0] enemy_types,      // 8 enemies with 4-bit types
    input [31:0] enemy_health      // 8 enemies with 4-bit health
);

    // VGA timing parameters
    parameter H_VISIBLE_AREA = 640;
    parameter H_FRONT_PORCH = 16;
    parameter H_SYNC_PULSE = 96;
    parameter H_BACK_PORCH = 48;
    parameter H_TOTAL = 800;
    parameter V_VISIBLE_AREA = 480;
    parameter V_FRONT_PORCH = 10;
    parameter V_SYNC_PULSE = 2;
    parameter V_BACK_PORCH = 33;
    parameter V_TOTAL = 525;

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    // Spaceship parameters
    parameter SPACESHIP_SIZE = 10;
    wire [9:0] spaceship_x = 320; // Fixed X position (center of the screen)
    wire [9:0] spaceship_y = 240; // Fixed Y position (center of the screen)

    // Enemy parameters
    parameter ENEMY_SIZE = 8;

    // LUT for cosine values of angles 0, 22.5, 45, ..., 337.5 degrees (scaled by 1024 for fixed-point arithmetic)
    reg [9:0] cos_lut [0:15];
    initial begin
        cos_lut[0] = 1024; // cos(0°)
        cos_lut[1] = 946;  // cos(22.5°)
        cos_lut[2] = 724;  // cos(45°)
        cos_lut[3] = 390;  // cos(67.5°)
        cos_lut[4] = 0;    // cos(90°)
        cos_lut[5] = -390; // cos(112.5°)
        cos_lut[6] = -724; // cos(135°)
        cos_lut[7] = -946; // cos(157.5°)
        cos_lut[8] = -1024;// cos(180°)
        cos_lut[9] = -946; // cos(202.5°)
        cos_lut[10] = -724;// cos(225°)
        cos_lut[11] = -390;// cos(247.5°)
        cos_lut[12] = 0;   // cos(270°)
        cos_lut[13] = 390; // cos(292.5°)
        cos_lut[14] = 724; // cos(315°)
        cos_lut[15] = 946; // cos(337.5°)
    end

    // LUT for sine values of angles 0, 22.5, 45, ..., 337.5 degrees (scaled by 1024 for fixed-point arithmetic)
    reg [9:0] sin_lut [0:15];
    initial begin
        sin_lut[0] = 0;    // sin(0°)
        sin_lut[1] = 390;  // sin(22.5°)
        sin_lut[2] = 724;  // sin(45°)
        sin_lut[3] = 946;  // sin(67.5°)
        sin_lut[4] = 1024; // sin(90°)
        sin_lut[5] = 946;  // sin(112.5°)
        sin_lut[6] = 724;  // sin(135°)
        sin_lut[7] = 390;  // sin(157.5°)
        sin_lut[8] = 0;    // sin(180°)
        sin_lut[9] = -390; // sin(202.5°)
        sin_lut[10] = -724;// sin(225°)
        sin_lut[11] = -946;// sin(247.5°)
        sin_lut[12] = -1024;// sin(270°)
        sin_lut[13] = -946;// sin(292.5°)
        sin_lut[14] = -724;// sin(315°)
        sin_lut[15] = -390;// sin(337.5°)
    end

    // Generate hsync and vsync signals
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
            hsync <= 1;
            vsync <= 1;
        end else begin
            // Horizontal counter
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                // Vertical counter
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 0;
                end else begin
                    v_count <= v_count + 1;
                end
            end else begin
                h_count <= h_count + 1;
            end

            // Hsync pulse
            if (h_count >= H_VISIBLE_AREA + H_FRONT_PORCH && h_count < H_VISIBLE_AREA + H_FRONT_PORCH + H_SYNC_PULSE) begin
                hsync <= 0;
            end else begin
                hsync <= 1;
            end

            // Vsync pulse
            if (v_count >= V_VISIBLE_AREA + V_FRONT_PORCH && v_count < V_VISIBLE_AREA + V_FRONT_PORCH + V_SYNC_PULSE) begin
                vsync <= 0;
            end else begin
                vsync <= 1;
            end
        end
    end

    // Display logic for spaceship and enemies
    always @(posedge clk) begin
        if (h_count < H_VISIBLE_AREA && v_count < V_VISIBLE_AREA) begin
            // Draw spaceship
            if ((h_count >= spaceship_x - SPACESHIP_SIZE && h_count <= spaceship_x + SPACESHIP_SIZE) &&
                (v_count >= spaceship_y - SPACESHIP_SIZE && v_count <= spaceship_y + SPACESHIP_SIZE)) begin
                red <= 4'b1111;
                green <= 4'b0000;
                blue <= 4'b0000;
            end
            // Draw enemies
            else begin
                integer i;
                reg [9:0] enemy_x, enemy_y;
                for (i = 0; i < 8; i = i + 1) begin
                    // Calculate enemy position based on angle and distance from the center using LUT
                    enemy_x = spaceship_x + (enemy_positions[i*4 +: 4] * cos_lut[enemy_positions[i*4 +: 4]]) / 1024;
                    enemy_y = spaceship_y + (enemy_positions[i*4 +: 4] * sin_lut[enemy_positions[i*4 +: 4]]) / 1024;
                    if ((h_count >= enemy_x - ENEMY_SIZE && h_count <= enemy_x + ENEMY_SIZE) &&
                        (v_count >= enemy_y - ENEMY_SIZE && v_count <= enemy_y + ENEMY_SIZE)) begin
                        case (enemy_types[i*4 +: 4])
                            1: begin
                                red <= 4'b0000;
                                green <= 4'b1111;
                                blue <= 4'b0000;
                            end
                            2: begin
                                red <= 4'b0000;
                                green <= 4'b0000;
                                blue <= 4'b1111;
                            end
                            3: begin
                                red <= 4'b1111;
                                green <= 4'b1111;
                                blue <= 4'b0000;
                            end
                            default: begin
                                red <= 4'b0000;
                                green <= 4'b0000;
                                blue <= 4'b0000;
                            end
                        endcase
                    end
                end
            end
        end else begin
            red <= 4'b0000;
            green <= 4'b0000;
            blue <= 4'b0000;
        end
    end

endmodule
