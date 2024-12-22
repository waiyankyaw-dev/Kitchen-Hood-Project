`timescale 1ns / 1ps


module mode_controller (
    input wire clk,
    input wire rst_n,
    input wire power_state,
    input wire menu_btn,
    input wire level1_btn,
    input wire level2_btn,
    input wire level3_btn,
    input wire self_clean_btn,
    input wire manual_reset_btn, 
    input wire query_upper_accumulated_time_switch,         
    input wire upper_hour_increase_switch,
    input wire power_left_right_control,
    input wire query_accumulated_time_switch,  // New input
    output reg [31:0] accumulated_seconds,     // Make this an output
    output reg display_accumulated_time,        // New output 
    output reg [4:0] query_leds,    
    output reg [2:0] current_mode,
    output reg [1:0] extraction_level,
    output reg [7:0] countdown_seconds,
    output reg cleaning_active,
    output reg reminder_led,
    output reg display_countdown       
);
    localparam POWER_OFF      = 3'b000;
    localparam STANDBY        = 3'b001;
    localparam EXTRACTION     = 3'b010;
    localparam SELF_CLEANING  = 3'b011;
    localparam LEVEL_OFF = 2'b00;
    localparam LEVEL_1   = 2'b01;
    localparam LEVEL_2   = 2'b10;
    localparam LEVEL_3   = 2'b11;
    localparam ONE_SECOND = 100000000;
    parameter DEBOUNCE_LIMIT = 50_000_000;  // 0.5 second (100MHz clock)

    reg [31:0] counter;
    reg prev_menu_btn;
    reg in_hurricane_exit;
    reg [7:0] hurricane_exit_counter;
    reg [7:0] level3_counter;
    reg [31:0] accumulated_seconds;
    reg hurricane_used_internal;
    reg [25:0] hour_increase_counter;   
    reg hour_increase_stable;
    reg prev_hour_increase_stable;
    reg [5:0] reminder_hours;

    reg [2:0] next_mode;
    reg [1:0] next_extraction_level;
    reg [7:0] next_countdown_seconds;
    reg next_cleaning_active;
    reg next_hurricane_used_internal; 
    reg [31:0] next_counter;
    reg next_prev_menu_btn;
    reg next_in_hurricane_exit;
    reg [7:0] next_hurricane_exit_counter;
    reg [7:0] next_level3_counter;
    reg [31:0] next_accumulated_seconds;
    reg next_reminder_led;
    reg next_display_countdown;

    // 0.5s debouncing block
    always @(posedge clk) begin
        if (!rst_n || !power_state) begin
            hour_increase_counter <= 0;
            hour_increase_stable <= 0;
        end
        else begin
            if (upper_hour_increase_switch && current_mode == STANDBY) begin  
                if (hour_increase_counter >= DEBOUNCE_LIMIT) begin
                    hour_increase_stable <= 1;
                end
                else begin
                    hour_increase_counter <= hour_increase_counter + 1;
                end
            end
            else begin
                hour_increase_counter <= 0;
                hour_increase_stable <= 0;
            end
        end
    end

    // Hour increase handling block
    always @(posedge clk) begin
        if (!rst_n || !power_state) begin
            prev_hour_increase_stable <= 0;
            reminder_hours <= 6'd10;  // Default 10 hours
        end
        else begin
            prev_hour_increase_stable <= hour_increase_stable;
            if (current_mode == STANDBY && hour_increase_stable && !prev_hour_increase_stable) begin
                if (reminder_hours >= 32) begin
                    reminder_hours <= 6'd1;  // Wrap around to 1
                end
                else begin
                    reminder_hours <= reminder_hours + 1;
                end
            end
        end
    end

    always @(*) begin
        next_mode = current_mode;
        next_extraction_level = extraction_level;
        next_countdown_seconds = countdown_seconds;
        next_cleaning_active = cleaning_active;
        next_hurricane_used_internal = hurricane_used_internal;
        next_counter = counter;
        next_prev_menu_btn = menu_btn;
        next_in_hurricane_exit = in_hurricane_exit;
        next_hurricane_exit_counter = hurricane_exit_counter;
        next_level3_counter = level3_counter;
        next_accumulated_seconds = accumulated_seconds;
        next_reminder_led = reminder_led;
        next_display_countdown = display_countdown;
        query_leds = 5'b00000;
        display_accumulated_time = 0;

        if (current_mode == STANDBY && query_accumulated_time_switch) begin
        display_accumulated_time = 1;
        end

        if (current_mode == STANDBY && query_upper_accumulated_time_switch) begin
            query_leds = reminder_hours[4:0];
        end

        if (manual_reset_btn && current_mode == STANDBY) begin
            next_accumulated_seconds = 0;
            next_reminder_led = 0;
        end

        if (!power_state) begin
            next_mode = POWER_OFF;
            next_extraction_level = LEVEL_OFF;
            next_countdown_seconds = 0;
            next_cleaning_active = 0;
            next_accumulated_seconds = 0;
            next_reminder_led = 0;
            next_hurricane_used_internal = 0;
            next_display_countdown = 0;
        end
        else begin
            case (current_mode)
                POWER_OFF: begin
                    if (power_state) begin
                        next_mode = STANDBY;
                        next_extraction_level = LEVEL_OFF;
                        next_countdown_seconds = 0;
                        next_cleaning_active = 0;
                    end
                end

                STANDBY: begin
                    if (menu_btn && !power_left_right_control) begin
                        if (level1_btn) begin
                            next_mode = EXTRACTION;
                            next_extraction_level = LEVEL_1;
                            next_in_hurricane_exit = 0;
                        end
                        else if (level2_btn) begin
                            next_mode = EXTRACTION;
                            next_extraction_level = LEVEL_2;
                            next_in_hurricane_exit = 0;
                        end
                        else if (level3_btn && !hurricane_used_internal) begin
                            next_mode = EXTRACTION;
                            next_extraction_level = LEVEL_3;
                            next_level3_counter = 60;
                            next_countdown_seconds = 60;
                            next_hurricane_used_internal = 1;
                            next_in_hurricane_exit = 0;
                            next_display_countdown = 1;
                        end
                        else if (self_clean_btn) begin
                            next_mode = SELF_CLEANING;
                            next_countdown_seconds = 180;
                            next_display_countdown = 1;
                        end
                    end
                end

                EXTRACTION: begin
                    if (extraction_level == LEVEL_3 && !in_hurricane_exit) begin
                        next_display_countdown = 1;
                    end
                    if (in_hurricane_exit) begin
                        next_display_countdown = 1;
                    end
                    if (counter >= ONE_SECOND) begin
                        next_counter = 0;
                        next_accumulated_seconds = accumulated_seconds + 1;
                        if (accumulated_seconds >= (reminder_hours   - 1)) begin //the actual implementation here is (reminder_hours * 3600 - 1), this is now just for testing purpose
                            next_reminder_led = 1;
                        end
                    end
                    else begin
                        next_counter = counter + 1;
                    end

                    if (extraction_level == LEVEL_3 && !in_hurricane_exit) begin
                        if (counter >= ONE_SECOND) begin
                            if (level3_counter > 0) begin
                                next_level3_counter = level3_counter - 1;
                                next_countdown_seconds = level3_counter - 1;
                            end
                            else begin
                                next_extraction_level = LEVEL_2;
                                next_display_countdown = 0;
                            end
                        end
                    end

                    if (in_hurricane_exit) begin
                        if (counter >= ONE_SECOND) begin
                            if (hurricane_exit_counter > 0) begin
                                next_hurricane_exit_counter = hurricane_exit_counter - 1;
                                next_countdown_seconds = hurricane_exit_counter - 1;
                            end
                            else begin
                                next_mode = STANDBY;
                                next_extraction_level = LEVEL_OFF;
                                next_in_hurricane_exit = 0;
                                next_countdown_seconds = 0;
                                next_display_countdown = 0;
                            end
                        end
                    end

                    if (menu_btn && !power_left_right_control) begin
                        if (level1_btn && extraction_level != LEVEL_3)
                            next_extraction_level = LEVEL_1;
                        else if (level2_btn && extraction_level != LEVEL_3)
                            next_extraction_level = LEVEL_2;
                    end
                    else if (!menu_btn && prev_menu_btn) begin
                        if (extraction_level == LEVEL_3 && level3_counter > 0) begin
                            next_in_hurricane_exit = 1;
                            next_hurricane_exit_counter = 60;
                            next_countdown_seconds = 60;
                            next_display_countdown = 1;
                        end
                        else if (extraction_level != LEVEL_3) begin
                            next_mode = STANDBY;
                            next_extraction_level = LEVEL_OFF;
                            next_countdown_seconds = 0;
                            next_display_countdown = 0;
                        end
                    end
                end

                SELF_CLEANING: begin
                    if (counter >= ONE_SECOND) begin
                        next_counter = 0;
                        if (countdown_seconds > 0) begin
                            next_countdown_seconds = countdown_seconds - 1;
                        end
                        else begin
                            next_mode = STANDBY;
                            next_cleaning_active = 1;
                            next_accumulated_seconds = 0;
                            next_reminder_led = 0;
                            next_display_countdown = 0;
                        end
                    end
                    else begin
                        next_counter = counter + 1;
                    end
                end

                default: next_mode = STANDBY;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_mode <= POWER_OFF;
            extraction_level <= LEVEL_OFF;
            countdown_seconds <= 0;
            cleaning_active <= 0;
            hurricane_used_internal <= 0;
            counter <= 0;
            prev_menu_btn <= 0;
            in_hurricane_exit <= 0;
            hurricane_exit_counter <= 0;
            level3_counter <= 0;
            accumulated_seconds <= 0;
            reminder_led <= 0;
            display_countdown <= 0;
        end
        else begin
            current_mode <= next_mode;
            extraction_level <= next_extraction_level;
            countdown_seconds <= next_countdown_seconds;
            cleaning_active <= next_cleaning_active;
            hurricane_used_internal <= next_hurricane_used_internal;
            counter <= next_counter;
            prev_menu_btn <= next_prev_menu_btn;
            in_hurricane_exit <= next_in_hurricane_exit;
            hurricane_exit_counter <= next_hurricane_exit_counter;
            level3_counter <= next_level3_counter;
            accumulated_seconds <= next_accumulated_seconds;
            reminder_led <= next_reminder_led;
            display_countdown <= next_display_countdown;
        end
    end
endmodule
