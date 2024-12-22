`timescale 1ns / 1ps

module button_debouncer_controller (
    input wire clk,
    input wire btn_in,
    output reg btn_out
);
    reg [19:0] counter;  
    reg btn_prev;
    
    always @(posedge clk) begin
        if (btn_in != btn_prev) begin
            counter <= 20'd0;  
            btn_prev <= btn_in;
        end
        else if (counter < 20'd1000000) begin  
            counter <= counter + 1;
        end
        else begin
            btn_out <= btn_prev;  
        end
    end
endmodule
