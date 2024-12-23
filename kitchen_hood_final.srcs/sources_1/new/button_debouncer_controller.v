`timescale 1ns / 1ps

module button_debouncer_controller (
    input wire clk,           // Clock input
    input wire btn_in,       // Input button signal
    output reg btn_out       // Debounced output button signal
);
    reg [19:0] counter;      // Counter for debounce timing
    reg btn_prev;            // Previous button state
    
    always @(posedge clk) begin
        if (btn_in != btn_prev) begin
            counter <= 20'd0; // Reset counter if button state changes
            btn_prev <= btn_in; // Update previous button state
        end
        else if (counter < 20'd1000000) begin  // Check if counter has reached debounce time
            counter <= counter + 1; // Increment counter
        end
        else begin
            btn_out <= btn_prev; // Set output to the stable button state
        end
    end
endmodule
