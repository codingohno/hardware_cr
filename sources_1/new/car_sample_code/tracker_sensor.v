`timescale 1ns/1ps
module tracker_sensor(clk, reset, left_signal, right_signal, mid_signal, state);
    input clk;
    input reset;
    input left_signal, right_signal, mid_signal;
    output reg [2:0] state;

    // [TO-DO] Receive three signals and make your own policy.
    // Hint: You can use output state to change your action.

    parameter turn_left=3'b000;
    parameter turn_right=3'b001;
    parameter go_straight=3'b010;
    parameter stop_state=3'b011;
    parameter sharp_turn_left = 3'b100;
    parameter sharp_turn_right = 3'b101;

    always@(posedge clk)begin
        if(reset)begin
            state<=stop_state;
        end
        else begin
            if(!left_signal && !right_signal && !mid_signal) state <= stop_state; //maybe not stop state (or rotate around)
            else if(!left_signal && mid_signal) state <= turn_right; //but slowly turn
            else if(!right_signal && mid_signal) state <= turn_left; //but slowly turn
            else if(!left_signal) state <= sharp_turn_right;
            else if(!right_signal) state <= sharp_turn_left;
            else state <= go_straight;
        end
    end

endmodule
