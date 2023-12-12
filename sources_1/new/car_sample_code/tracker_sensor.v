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
            case({left_signal,right_signal,mid_signal}):
                3'b000:begin
                    state <= state;//unable to decide the next direction just remain the last operation
                end

                3'b001:begin
                    state <= sharp_turn_right;//sharp turn right
                end

                3'b010:begin
                    state <= state;//unable to decide the next direction just remain the last operation
                end

                3'b011:begin
                    state <= turn_right;//slow turn
                end

                3'b100:begin
                    state <= sharp_turn_left;
                end

                3'b101:begin
                    state <= state;//undetermined state
                end

                3'b110:begin
                    state <= turn_left;
                end

                3'b111:begin
                    state <= go_straight;
                end
                
                default:begin
                    state <= state;//undetermined state
                end
            endcase
        end
    end

endmodule
