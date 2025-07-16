`timescale 1ns / 1ps

module segment_display_controller (
   input wire clk,
   input wire rst_n,
   input wire [5:0] hours,
   input wire [5:0] minutes,
   input wire [5:0] seconds,
   input wire display_countdown,
   input wire [7:0] countdown_seconds,
   input wire [7:0] gesture_countdown,
   input wire display_gesture_countdown,
   input wire [31:0] accumulated_seconds,     // New input
   input wire display_accumulated_time,       // New input
   input wire power_state, 
   output reg [7:0] seg_en,      
   output reg [7:0] seg_out0,    
   output reg [7:0] seg_out1     
);

   reg [31:0] refresh_counter;
   reg [2:0] scan_cnt;
   
   wire [3:0] hour_tens = hours / 10;
   wire [3:0] hour_ones = hours % 10;
   wire [3:0] min_tens = minutes / 10;
   wire [3:0] min_ones = minutes % 10;
   wire [3:0] sec_tens = seconds / 10;
   wire [3:0] sec_ones = seconds % 10;

   wire [3:0] countdown_min_tens = countdown_seconds / 60 / 10;
   wire [3:0] countdown_min_ones = (countdown_seconds / 60) % 10;
   wire [3:0] countdown_sec_tens = (countdown_seconds % 60) / 10;
   wire [3:0] countdown_sec_ones = (countdown_seconds % 60) % 10;

   // New wires for accumulated time
   wire [5:0] acc_hours = accumulated_seconds / 3600;
   wire [5:0] acc_minutes = (accumulated_seconds % 3600) / 60;
   wire [5:0] acc_seconds = accumulated_seconds % 60;
   wire [3:0] acc_hour_tens = acc_hours / 10;
   wire [3:0] acc_hour_ones = acc_hours % 10;
   wire [3:0] acc_min_tens = acc_minutes / 10;
   wire [3:0] acc_min_ones = acc_minutes % 10;
   wire [3:0] acc_sec_tens = acc_seconds / 10;
   wire [3:0] acc_sec_ones = acc_seconds % 10;

   function [7:0] seven_seg;
       input [3:0] digit;
       begin
           case (digit)
               4'd0: seven_seg = 8'b11111100;
               4'd1: seven_seg = 8'b01100000;
               4'd2: seven_seg = 8'b11011010;
               4'd3: seven_seg = 8'b11110010;
               4'd4: seven_seg = 8'b01100110;
               4'd5: seven_seg = 8'b10110110;
               4'd6: seven_seg = 8'b10111110;
               4'd7: seven_seg = 8'b11100000;
               4'd8: seven_seg = 8'b11111110;
               4'd9: seven_seg = 8'b11110110;
               default: seven_seg = 8'b00000000;
           endcase
       end
   endfunction

   always @(posedge clk or negedge rst_n) begin
       if (!rst_n) begin
           refresh_counter <= 0;
           scan_cnt <= 0;
       end
       else begin
           refresh_counter <= refresh_counter + 1;
           if (refresh_counter >= 32'd100000) begin  
               refresh_counter <= 0;
               if (scan_cnt == 3'd7)
                   scan_cnt <= 0;
               else
                   scan_cnt <= scan_cnt + 1;
           end
       end
   end

   always @(scan_cnt) begin
       case(scan_cnt)
           3'b000: seg_en = 8'h01;
           3'b001: seg_en = 8'h02;
           3'b010: seg_en = 8'h04;
           3'b011: seg_en = 8'h08;
           3'b100: seg_en = 8'h10;
           3'b101: seg_en = 8'h20;
           3'b110: seg_en = 8'h40;
           3'b111: seg_en = 8'h80;
           default: seg_en = 8'h00;
       endcase
   end

   always @(*) begin
   if (!power_state) begin
              // Turn off all segments when power is off
              seg_out0 = 8'b00000000;
              seg_out1 = 8'b00000000;
          end
          
    else if (display_gesture_countdown) begin
            case (scan_cnt)
                3'd0, 3'd1, 3'd2, 3'd3, 3'd4, 3'd5: begin 
                    seg_out0 = 8'b00000000;
                    seg_out1 = 8'b00000000;
                end
                3'd6: begin
                    seg_out0 = seven_seg(gesture_countdown / 10);
                    seg_out1 = seven_seg(gesture_countdown / 10);
                end
                3'd7: begin
                    seg_out0 = seven_seg(gesture_countdown % 10);
                    seg_out1 = seven_seg(gesture_countdown % 10);
                end
                default: begin
                    seg_out0 = 8'b00000000;
                    seg_out1 = 8'b00000000;
                end
            endcase
        end
    else if (display_accumulated_time) begin
            case (scan_cnt)
                3'd0: begin 
                    seg_out0 = seven_seg(acc_hour_tens);
                    seg_out1 = seven_seg(acc_hour_tens);
                end
                3'd1: begin
                    seg_out0 = seven_seg(acc_hour_ones);
                    seg_out1 = seven_seg(acc_hour_ones);
                end
                3'd2: begin
                    seg_out0 = 8'b00000010;
                    seg_out1 = 8'b00000010;
                end
                3'd3: begin
                    seg_out0 = seven_seg(acc_min_tens);
                    seg_out1 = seven_seg(acc_min_tens);
                end
                3'd4: begin
                    seg_out0 = seven_seg(acc_min_ones);
                    seg_out1 = seven_seg(acc_min_ones);
                end
                3'd5: begin
                    seg_out0 = 8'b00000010;
                    seg_out1 = 8'b00000010;
                end
                3'd6: begin
                    seg_out0 = seven_seg(acc_sec_tens);
                    seg_out1 = seven_seg(acc_sec_tens);
                end
                3'd7: begin
                    seg_out0 = seven_seg(acc_sec_ones);
                    seg_out1 = seven_seg(acc_sec_ones);
                end
                default: begin
                    seg_out0 = 8'b00000000;
                    seg_out1 = 8'b00000000;
                end
            endcase
        end
       else if (!display_countdown || countdown_seconds == 0) begin
           case (scan_cnt)
               3'd0: begin 
                   seg_out0 = seven_seg(hour_tens);
                   seg_out1 = seven_seg(hour_tens);
               end
               3'd1: begin
                   seg_out0 = seven_seg(hour_ones);
                   seg_out1 = seven_seg(hour_ones);
               end
               3'd2: begin
                   seg_out0 = 8'b00000010;
                   seg_out1 = 8'b00000010;
               end
               3'd3: begin
                   seg_out0 = seven_seg(min_tens);
                   seg_out1 = seven_seg(min_tens);
               end
               3'd4: begin
                   seg_out0 = seven_seg(min_ones);
                   seg_out1 = seven_seg(min_ones);
               end
               3'd5: begin
                   seg_out0 = 8'b00000010;
                   seg_out1 = 8'b00000010;
               end
               3'd6: begin
                   seg_out0 = seven_seg(sec_tens);
                   seg_out1 = seven_seg(sec_tens);
               end
               3'd7: begin
                   seg_out0 = seven_seg(sec_ones);
                   seg_out1 = seven_seg(sec_ones);
               end
               default: begin
                   seg_out0 = 8'b00000000;
                   seg_out1 = 8'b00000000;
               end
           endcase
       end
       else begin
           case (scan_cnt)
               3'd0, 3'd1: begin 
                   seg_out0 = 8'b00000000;
                   seg_out1 = 8'b00000000;
               end
               3'd2: begin
                   seg_out0 = 8'b00000010;
                   seg_out1 = 8'b00000010;
               end
               3'd3: begin
                   seg_out0 = seven_seg(countdown_min_tens);
                   seg_out1 = seven_seg(countdown_min_tens);
               end
               3'd4: begin
                   seg_out0 = seven_seg(countdown_min_ones);
                   seg_out1 = seven_seg(countdown_min_ones);
               end
               3'd5: begin
                   seg_out0 = 8'b00000010;
                   seg_out1 = 8'b00000010;
               end
               3'd6: begin
                   seg_out0 = seven_seg(countdown_sec_tens);
                   seg_out1 = seven_seg(countdown_sec_tens);
               end
               3'd7: begin
                   seg_out0 = seven_seg(countdown_sec_ones);
                   seg_out1 = seven_seg(countdown_sec_ones);
               end
               default: begin
                   seg_out0 = 8'b00000000;
                   seg_out1 = 8'b00000000;
               end
           endcase
       end
   end

endmodule
