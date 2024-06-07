module enemy_controller(
    input clk,
    input reset,
    output reg [31:0] enemy_positions,  // 8 enemies with 4-bit positions
    output reg [31:0] enemy_types,      // 8 enemies with 4-bit types
    output reg [31:0] enemy_health,     // 8 enemies with 4-bit health
    input fire,
    input [3:0] fire_angle,
    input [1:0] fire_mode,
    output reg [15:0] score
);

    // Initial values for enemy positions, types, and health
    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            enemy_positions[i*4 +: 4] = i * 2; // Example starting positions
            enemy_types[i*4 +: 4] = (i % 3) + 1; // Assign types 1, 2, 3
            enemy_health[i*4 +: 4] = (i % 3) + 1; // Example health values
        end
    end

    // Enemy movement, spawning, and firing logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) begin
                enemy_positions[i*4 +: 4] <= i * 2; // Example reset positions
                enemy_types[i*4 +: 4] <= (i % 3) + 1; // Reset types
                enemy_health[i*4 +: 4] <= (i % 3) + 1; // Reset health
            end
            score <= 0;
        end else begin
            // Handle projectile firing and enemy collision
            if (fire) begin
                for (i = 0; i < 8; i = i + 1) begin
                    if (enemy_health[i*4 +: 4] > 0) begin
                        if (fire_mode == 2'b00) begin
                            // Shooting mode 1: wider spray
                            if (fire_angle == enemy_positions[i*4 +: 4] || 
                                fire_angle + 4 == enemy_positions[i*4 +: 4] ||
                                fire_angle - 4 == enemy_positions[i*4 +: 4]) begin
                                enemy_health[i*4 +: 4] <= enemy_health[i*4 +: 4] - 1;
                                if (enemy_health[i*4 +: 4] == 0) score <= score + 10;
                            end
                        end else if (fire_mode == 2'b01) begin
                            // Shooting mode 2: narrower spray
                            if (fire_angle == enemy_positions[i*4 +: 4]) begin
                                enemy_health[i*4 +: 4] <= enemy_health[i*4 +: 4] - 2;
                                if (enemy_health[i*4 +: 4] == 0) score <= score + 10;
                            end
                        end
                    end
                end
            end
            
            // Handle enemy movement and respawning
            for (i = 0; i < 8; i = i + 1) begin
                if (enemy_health[i*4 +: 4] > 0) begin
                    // Move enemies towards the center
                    if (enemy_positions[i*4 +: 4] > 0) enemy_positions[i*4 +: 4] <= enemy_positions[i*4 +: 4] - 1;
                end else begin
                    // Respawn enemy if health is 0
                    enemy_positions[i*4 +: 4] <= 15; // Example respawn position
                    enemy_types[i*4 +: 4] <= (enemy_types[i*4 +: 4] % 3) + 1; // Cycle types
                    enemy_health[i*4 +: 4] <= (enemy_health[i*4 +: 4] % 3) + 1; // Reset health
                end
            end
        end
    end

endmodule
