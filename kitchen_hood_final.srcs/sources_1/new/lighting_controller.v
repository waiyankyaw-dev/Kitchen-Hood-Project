`timescale 1ns / 1ps

module lighting_controller (
    input wire clk,
    input wire rst_n,
    input wire power_state,
    input wire lighting_switch,    // Switch input instead of button
    output reg lighting_state
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || !power_state) begin
            lighting_state <= 0;
        end
        else begin
            // Simply follow the switch state when powered on
            lighting_state <= lighting_switch;
        end
    end
endmodule
