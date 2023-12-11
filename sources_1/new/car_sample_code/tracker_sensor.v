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
            if((left_signal===1'b1)&&(right_signal===1'b1))begin
                state<=go_straight;
            end
            else if(left_signal===1'b0)begin
                state<=turn_right;
            end
            else if(right_signal===1'b0)begin
                state<=turn_left;
            end
            else begin
                state<=stop_state;
            end
        end
    end

endmodule
