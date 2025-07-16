`timescale 1ns / 1ps

module top_kitchen_hood_controller (
    input wire clk,              
    input wire rst_n_raw,        
    input wire power_btn_raw,    
    input wire menu_btn,         
    input wire level1_btn_raw,   
    input wire level2_btn_raw,  
    input wire level3_btn_raw,  
    input wire self_clean_btn_raw, 
    input wire power_left_right_control,  
    input wire manual_reset_btn,  
    input wire hour_increment,   
    input wire minute_increment,  
    input wire query_upper_accumulated_time_switch,         
    input wire upper_hour_increase_switch,  
    input wire increase_gesture_time,  // New input
    input wire query_gesture_time,     // New input
    input wire lighting_switch,    // Switch input for lighting control
    input wire query_accumulated_time_switch,  // New input for querying accumulated time
    output wire [4:0] query_leds,    
    output wire [2:0] query_gesture_time_value,  // New output
    output wire [2:0] current_mode,
    output wire [1:0] extraction_level,
    output wire cleaning_active,
    output wire reminder_led,
    output wire [7:0] seg_en,     
    output wire [7:0] seg_out0,  
    output wire [7:0] seg_out1,
    output wire lighting_state    // Lighting status output   
);

    wire [5:0] current_hours;
    wire [5:0] current_minutes;
    wire [5:0] current_seconds;
    wire [7:0] countdown_seconds;
    wire display_countdown;
    wire [4:0] hours_display;  
    wire upper_hour_increase_switch_debounced;
    wire increase_gesture_time_debounced;  // New wire
    wire power_state;
    wire [7:0] gesture_countdown;
    wire display_gesture_countdown;
    wire [31:0] accumulated_seconds;    // New wire
    wire display_accumulated_time;      // New wire

    //for debounce buttons
    wire rst_n_debounced;
    wire level1_btn_debounced;
    wire level2_btn_debounced;
    wire level3_btn_debounced;
    wire self_clean_btn_debounced;

    power_controller power_ctrl (
        .clk(clk),
        .rst_n(rst_n_debounced),
        .power_btn_raw(power_btn_raw),
        .power_left_right_control(power_left_right_control), 
        .level1_btn_raw(level1_btn_raw),
        .level2_btn_raw(level2_btn_raw),
        .increase_gesture_time(increase_gesture_time_debounced),  // New connection
        .query_gesture_time(query_gesture_time),                  // New connection
        .power_state(power_state),
        .gesture_countdown(gesture_countdown),
        .display_gesture_countdown(display_gesture_countdown),
        .query_gesture_time_value(query_gesture_time_value)       // New connection
    );

    time_controller time_count(
        .clk(clk),
        .rst_n(rst_n_debounced),
        .power_state(power_state),
        .hour_increment(hour_increment),
        .minute_increment(minute_increment),
        .hours(current_hours),
        .minutes(current_minutes),
        .seconds(current_seconds),
        .current_mode(current_mode)
    );

    lighting_controller light_ctrl (
        .clk(clk),
        .rst_n(rst_n_debounced),
        .power_state(power_state),
        .lighting_switch(lighting_switch),
        .lighting_state(lighting_state)
    );

    segment_display_controller seg_controller1 (
        .clk(clk),
        .rst_n(rst_n_debounced),
        .hours(current_hours),
        .minutes(current_minutes),
        .seconds(current_seconds),
        .seg_en(seg_en),
        .seg_out0(seg_out0),
        .seg_out1(seg_out1),
        .gesture_countdown(gesture_countdown),
        .display_gesture_countdown(display_gesture_countdown),
        .countdown_seconds(countdown_seconds),
        .display_countdown(display_countdown),
        .accumulated_seconds(accumulated_seconds),     // New connection
        .display_accumulated_time(display_accumulated_time),  // New connection
        .power_state(power_state)
    );


        mode_controller controller (
        .clk(clk),
        .rst_n(rst_n_debounced),
        .power_state(power_state),
        .menu_btn(menu_btn),
        .level1_btn(level1_btn_debounced),
        .level2_btn(level2_btn_debounced),
        .level3_btn(level3_btn_debounced),
        .self_clean_btn(self_clean_btn_debounced),
        .power_left_right_control(power_left_right_control),
        .current_mode(current_mode),
        .manual_reset_btn(manual_reset_btn),
        .extraction_level(extraction_level),
        .countdown_seconds(countdown_seconds),
        .cleaning_active(cleaning_active),
        .reminder_led(reminder_led),
        .display_countdown(display_countdown),
        .query_upper_accumulated_time_switch(query_upper_accumulated_time_switch),
        .upper_hour_increase_switch(upper_hour_increase_switch_debounced),
        .query_leds(query_leds),
        .query_accumulated_time_switch(query_accumulated_time_switch),  // New connection
        .accumulated_seconds(accumulated_seconds),                      // New connection
        .display_accumulated_time(display_accumulated_time)            // New connection
    );

    button_debouncer_controller debounce_rst (
        .clk(clk),
        .btn_in(rst_n_raw),
        .btn_out(rst_n_debounced)
    );

    button_debouncer_controller debounce_level1 (
        .clk(clk),
        .btn_in(level1_btn_raw),
        .btn_out(level1_btn_debounced)
    );

    button_debouncer_controller debounce_level2 (
        .clk(clk),
        .btn_in(level2_btn_raw),
        .btn_out(level2_btn_debounced)
    );

    button_debouncer_controller debounce_level3 (
        .clk(clk),
        .btn_in(level3_btn_raw),
        .btn_out(level3_btn_debounced)
    );

    button_debouncer_controller debounce_self_clean (
        .clk(clk),
        .btn_in(self_clean_btn_raw),
        .btn_out(self_clean_btn_debounced)
    );

    button_debouncer_controller debounce_hour_increase (
        .clk(clk),
        .btn_in(upper_hour_increase_switch),
        .btn_out(upper_hour_increase_switch_debounced)
    );

    button_debouncer_controller debounce_gesture_time (
        .clk(clk),
        .btn_in(increase_gesture_time),
        .btn_out(increase_gesture_time_debounced)
    );

endmodule






