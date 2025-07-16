`timescale 1ns / 1ps

module time_controller (
    input wire clk,
    input wire rst_n,
    input wire power_state,
    input wire hour_increment,
    input wire minute_increment,
    input wire [2:0] current_mode, 
    output reg [5:0] hours,
    output reg [5:0] minutes,
    output reg [5:0] seconds
);
    parameter DEBOUNCE_LIMIT = 50_000_000;
    parameter STANDBY = 3'b001;
    
    reg [25:0] hour_debounce_counter;
    reg [25:0] minute_debounce_counter;
    reg hour_stable;
    reg minute_stable;
    reg prev_hour_stable;
    reg prev_minute_stable;
    reg [26:0] clk_counter;

    // Hour debouncing
    always @(posedge clk) begin
        if (!rst_n || !power_state) begin  // Reset or power off
            hour_debounce_counter <= 0;
            hour_stable <= 0;
        end
        else begin
            if (hour_increment && current_mode == STANDBY) begin  
                if (hour_debounce_counter >= DEBOUNCE_LIMIT) begin
                    hour_stable <= 1;
                end
                else begin
                    hour_debounce_counter <= hour_debounce_counter + 1;
                end
            end
            else begin
                hour_debounce_counter <= 0;
                hour_stable <= 0;
            end
        end
    end

    // Minute debouncing
    always @(posedge clk) begin
        if (!rst_n || !power_state) begin  // Reset or power off
            minute_debounce_counter <= 0;
            minute_stable <= 0;
        end
        else begin
            if (minute_increment && current_mode == STANDBY) begin  
                if (minute_debounce_counter >= DEBOUNCE_LIMIT) begin
                    minute_stable <= 1;
                end
                else begin
                    minute_debounce_counter <= minute_debounce_counter + 1;
                end
            end
            else begin
                minute_debounce_counter <= 0;
                minute_stable <= 0;
            end
        end
    end

    // Main time counting and adjustment logic
    always @(posedge clk) begin
        if (!rst_n) begin  // System reset
            hours <= 6'd0;
            minutes <= 6'd0;
            seconds <= 6'd0;
            clk_counter <= 27'd0;
            prev_hour_stable <= 0;
            prev_minute_stable <= 0;
        end
        else if (!power_state) begin  // Power off state
            hours <= 6'd0;
            minutes <= 6'd0;
            seconds <= 6'd0;
            clk_counter <= 27'd0;
            prev_hour_stable <= 0;
            prev_minute_stable <= 0;
        end
        else begin  // Normal operation when powered on
            prev_hour_stable <= hour_stable;
            prev_minute_stable <= minute_stable;

            // Handle hour increment
            if (current_mode == STANDBY && hour_stable && !prev_hour_stable) begin
                hours <= (hours == 23) ? 0 : hours + 1;
            end

            // Handle minute increment
            if (current_mode == STANDBY && minute_stable && !prev_minute_stable) begin
                minutes <= (minutes == 59) ? 0 : minutes + 1;
            end

            // Normal time counting
            if (clk_counter >= 100000000 - 1) begin 
                clk_counter <= 27'd0;
                if (seconds >= 59) begin
                    seconds <= 0;
                    if (minutes >= 59) begin
                        minutes <= 0;
                        if (hours >= 23) begin
                            hours <= 0;
                        end
                        else begin
                            hours <= hours + 1;
                        end
                    end
                    else begin
                        minutes <= minutes + 1;
                    end
                end
                else begin
                    seconds <= seconds + 1;
                end
            end
            else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end
endmodule
