`timescale 1ns / 1ps

module button_debouncer_controller (
    input wire clk,          // Clock input
    input wire btn_in,      // Button input (raw signal)
    output reg btn_out      // Debounced button output
);
    reg [19:0] counter;     // Counter for debouncing
    reg btn_prev;           // Previous state of the button

    always @(posedge clk) begin
        // Check if the button input has changed
        if (btn_in != btn_prev) begin
            counter <= 20'd0;  // Reset the counter on state change
            btn_prev <= btn_in; // Update previous button state
        end
        // If the counter has not yet reached the debounce threshold
        else if (counter < 20'd1000000) begin  
            counter <= counter + 1; // Increment the counter
        end
        // If the counter has reached the threshold, update the output
        else begin
            btn_out <= btn_prev;  // Set the debounced output to previous state
        end
    end
endmodule
