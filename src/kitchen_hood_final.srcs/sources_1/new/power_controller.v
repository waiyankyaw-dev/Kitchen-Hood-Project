`timescale 1ns / 1ps

module power_controller (
    input wire clk,
    input wire rst_n,
    input wire power_btn_raw,
    input wire power_left_right_control,
    input wire level1_btn_raw,
    input wire level2_btn_raw,
    input wire increase_gesture_time,
    input wire query_gesture_time,
    output reg power_state,
    output reg [7:0] gesture_countdown,
    output reg display_gesture_countdown,
    output reg [2:0] query_gesture_time_value
);

    // States for gesture control
    localparam IDLE = 2'b00;
    localparam WAIT_FOR_RIGHT = 2'b01;
    localparam WAIT_FOR_LEFT = 2'b10;
    
    reg [31:0] power_press_counter;
    wire power_btn_debounced;
    reg prev_power_btn;
    reg [26:0] countdown_counter;
    reg [1:0] gesture_state;
    reg long_press_detected;
    reg waiting_for_release;
    reg left_btn_prev;
    reg right_btn_prev;
    wire level1_btn_debounced;
    wire level2_btn_debounced;
    
    // Gesture time control
    reg [2:0] current_gesture_time;
    reg [25:0] time_increase_counter;   
    reg time_increase_stable;
    reg prev_time_increase_stable;
    reg in_standby;
    
    // Constants
    localparam LONG_PRESS_TIME = 32'd300_000_000;
    localparam ONE_SECOND = 32'd100_000_000;
    parameter GESTURE_TIME_DEBOUNCE_LIMIT = 50_000_000;  // 0.5 second (100MHz clock)

    // Button debouncers
    button_debouncer_controller power_btn_debouncer (
        .clk(clk),
        .btn_in(power_btn_raw),
        .btn_out(power_btn_debounced)
    );

    button_debouncer_controller left_btn_debouncer (
        .clk(clk),
        .btn_in(level1_btn_raw),
        .btn_out(level1_btn_debounced)
    );

    button_debouncer_controller right_btn_debouncer (
        .clk(clk),
        .btn_in(level2_btn_raw),
        .btn_out(level2_btn_debounced)
    );

    // Determine if we're in standby mode
    always @(*) begin
        in_standby = (power_state && gesture_state == IDLE && !display_gesture_countdown);
    end

    // 0.5s debouncing block for gesture time increase
    always @(posedge clk) begin
        if (!rst_n) begin
            time_increase_counter <= 0;
            time_increase_stable <= 0;
        end
        else begin
            if (increase_gesture_time && in_standby) begin  // Only in standby mode
                if (time_increase_counter >= GESTURE_TIME_DEBOUNCE_LIMIT) begin
                    time_increase_stable <= 1;
                end
                else begin
                    time_increase_counter <= time_increase_counter + 1;
                end
            end
            else begin
                time_increase_counter <= 0;
                time_increase_stable <= 0;
            end
        end
    end

    // Gesture time handling block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_gesture_time <= 3'd5;  // Default 5 seconds
            prev_time_increase_stable <= 0;
            query_gesture_time_value <= 3'd0;
        end
        else begin
            prev_time_increase_stable <= time_increase_stable;
            
            // Handle gesture time increase - only in standby mode
            if (in_standby && time_increase_stable && !prev_time_increase_stable) begin
                if (current_gesture_time >= 3'd7) begin
                    current_gesture_time <= 3'd0;
                end
                else begin
                    current_gesture_time <= current_gesture_time + 1;
                end
            end
            
            // Handle query display - only in standby mode
            if (query_gesture_time && in_standby) begin
                query_gesture_time_value <= current_gesture_time;
            end
            else begin
                query_gesture_time_value <= 3'd0;
            end
        end
    end
    
    // Main power control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
//            power_state <= 0;
            power_press_counter <= 0;
            prev_power_btn <= 0;
            gesture_state <= IDLE;
            gesture_countdown <= 0;
            display_gesture_countdown <= 0;
            countdown_counter <= 0;
            long_press_detected <= 0;
            waiting_for_release <= 0;
            left_btn_prev <= 0;
            right_btn_prev <= 0;
        end
        else begin
            prev_power_btn <= power_btn_debounced;
            left_btn_prev <= level1_btn_debounced;
            right_btn_prev <= level2_btn_debounced;
            
            // Power button handling
            if (power_btn_debounced) begin
                if (power_state && !waiting_for_release) begin
                    power_press_counter <= power_press_counter + 1;
                    if (power_press_counter >= LONG_PRESS_TIME) begin
                        power_state <= 0;
                        waiting_for_release <= 1;
                        long_press_detected <= 1;
                    end
                end
            end
            else if (!power_btn_debounced) begin
                if (prev_power_btn) begin
                    if (!waiting_for_release && !long_press_detected && 
                        power_press_counter < LONG_PRESS_TIME) begin
                        if (!power_state) begin
                            power_state <= 1;
                        end
                    end
                end
                power_press_counter <= 0;
                if (!prev_power_btn) begin
                    long_press_detected <= 0;
                    waiting_for_release <= 0;
                end
            end
            
            // Gesture control
            if (power_left_right_control) begin
                // Update countdown timer
                if (countdown_counter >= ONE_SECOND) begin
                    countdown_counter <= 0;
                    if (gesture_countdown > 0) begin
                        gesture_countdown <= gesture_countdown - 1;
                    end
                end
                else begin
                    countdown_counter <= countdown_counter + 1;
                end

                case (gesture_state)
                    IDLE: begin
                        if (!power_state && level1_btn_debounced && !left_btn_prev) begin
                            gesture_state <= WAIT_FOR_RIGHT;
                            gesture_countdown <= current_gesture_time;
                            display_gesture_countdown <= 1;
                            countdown_counter <= 0;
                        end
                        else if (power_state && level2_btn_debounced && !right_btn_prev) begin
                            gesture_state <= WAIT_FOR_LEFT;
                            gesture_countdown <= current_gesture_time;
                            display_gesture_countdown <= 1;
                            countdown_counter <= 0;
                        end
                    end

                    WAIT_FOR_RIGHT: begin
                        if (gesture_countdown == 0) begin
                            gesture_state <= IDLE;
                            display_gesture_countdown <= 0;
                        end
                        else if (level2_btn_debounced && !right_btn_prev) begin
                            power_state <= 1;
                            gesture_state <= IDLE;
                            display_gesture_countdown <= 0;
                        end
                    end

                    WAIT_FOR_LEFT: begin
                        if (gesture_countdown == 0) begin
                            gesture_state <= IDLE;
                            display_gesture_countdown <= 0;
                        end
                        else if (level1_btn_debounced && !left_btn_prev) begin
                            power_state <= 0;
                            gesture_state <= IDLE;
                            display_gesture_countdown <= 0;
                        end
                    end

                    default: gesture_state <= IDLE;
                endcase
            end
            else begin
                gesture_state <= IDLE;
                display_gesture_countdown <= 0;
            end
        end
    end

endmodule




