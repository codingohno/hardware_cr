`timescale 1ns/1ps
module tracker_sensor(clk, reset, left_signal, right_signal, mid_signal, state);
    input clk;
    input reset;
    input left_signal, right_signal, mid_signal;
    output reg [1:0] state;

    // [TO-DO] Receive three signals and make your own policy.
    // Hint: You can use output state to change your action.

    parameter turn_left=2'b00;
    parameter turn_right=2'b01;
    parameter go_straight=2'b10;
    parameter stop_state=2'b11;

    always@(posedge clk)begin
        if(reset)begin
            state<=stop_state;
        end
        else begin
            if(!left_signal && !right_signal && !mid_signal) state <= stop_state;
            else if(!left_signal && mid_signal) state <= turn_right; //but slowly turn
            else if(!right_signal && mid_signal) state <= turn_left; //but slowly turn
            else if(!left_signal) state <= turn_right;
            else if(!right_signal) state <= turn_left;
            else state <= go_straight;
        end
    end

endmodule
