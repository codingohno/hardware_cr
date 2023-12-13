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
            case({left_signal,mid_signal,right_signal})
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

module modulation_wrapper(left_signal,mid_signal,right_signal,clk,reset,modulation_left,modulation_right);
    //from the infrared
    input left_signal,mid_signal,right_signal;
    input clk;
    input reset;

    output [10-1:0] modulation_left;
    output [10-1:0] modulation_right; 


    wire oot_done_output;
    wire [31:0] oot_time_output;
    wire [2-1:0] oot_side_output;

    out_of_track_counter oot_counter(left_signal,mid_signal,right_signal,clk,reset,oot_done_output,oot_time_output,oot_side_output);
    curvature_module curve (oot_done_output,oot_time_output,oot_side_output,clk,reset,modulation_left,modulation_right);
endmodule

module out_of_track_counter(left_signal,mid_signal,right_signal,clk,reset,oot_done_output,oot_time_output,oot_side_output);
    input left_signal,mid_signal,right_signal;
    input clk;
    input reset;
    output reg oot_done_output;
    output  reg[31:0] oot_time_output;
    output  reg[2-1:0] oot_side_output;

    parameter LEFT=2'b11;
    parameter RIGHT=2'b10;
    parameter NONE=2'b00;

    //for calculation of the curvature
    //developing
    reg[31:0] out_of_track_time=32'b0;
    reg[1:0] oot_state=2'b00;

    parameter oot_wait=2'b00;
    parameter oot_out=2'b01;
    parameter oot_back=2'b10;
    

    always@(posedge clk)begin
        if(reset)begin
            out_of_track_time=32'b0;
            oot_state<=oot_wait;
            oot_done_output<=1'b0;
            oot_time_output<=32'b0;
            oot_side_output<=NONE;
        end
        else begin
            case(oot_state)
                oot_wait:begin
                    //if out of track on right side
                    if(({left_signal,mid_signal,right_signal}==3'b100)||({left_signal,mid_signal,right_signal}==3'b110))begin
                        oot_state<=oot_out;
                        out_of_track_time<=out_of_track_time+32'b1;
                        oot_done_output<=1'b0;
                        oot_time_output<=32'b0;
                        oot_side_output<=RIGHT;
                    end
                    //out of track on the left side
                    else if (({left_signal,mid_signal,right_signal}==3'b001)||({left_signal,mid_signal,right_signal}==3'b011))begin
                        oot_state<=oot_out;
                        out_of_track_time<=out_of_track_time+32'b1;
                        oot_done_output<=1'b0;
                        oot_time_output<=32'b0;
                        oot_side_output<=LEFT;
                    end
                    else begin
                        out_of_track_time<=32'b0;
                        oot_state<=oot_wait;
                        oot_done_output<=1'b0;
                        oot_time_output<=32'b0;
                        oot_side_output<=NONE;
                    end
                end

                oot_out:begin
                    //if back to the lane
                    if({left_signal,mid_signal,right_signal}===3'b111)begin
                        out_of_track_time<=32'b0;
                        oot_state<=oot_back;

                        oot_done_output<=1'b1;
                        oot_time_output<=out_of_track_time;
                        oot_side_output<=oot_side_output;

                    end
                    else begin
                        //kept counting the time
                        out_of_track_time<=(out_of_track_time<32'd4294967200)?(out_of_track_time+32'b1):out_of_track_time;
                        oot_state<=oot_out;
                        oot_done_output<=1'b0;
                        oot_time_output<=32'b0;
                        oot_side_output<=oot_side_output;
                    end
                end

                oot_back:begin
                    oot_state<=oot_wait;
                    out_of_track_time<=32'b0;

                    oot_done_output<=1'b0;
                    oot_time_output<=32'b0;
                    oot_side_output<=NONE;
                end

                default:begin
                    out_of_track_time<=32'b0;
                    oot_state<=oot_wait;
                    oot_done_output<=1'b0;
                    oot_time_output<=32'b0;
                    oot_side_output<=NONE;
                end
            endcase
        end
    end
endmodule


//full speed right now take speed as 1023*constant
//calculate the curvature

module curvature_module (oot_done,oot_time,oot_side,clk,reset,modulation_left,modulation_right);
    input  oot_done;
    input[31:0] oot_time;
    input[2-1:0] oot_side;
    input clk;
    input reset;

    //for the advance modulation
    //input speed;//by duty cycle

    output reg[10-1:0] modulation_left;
    output reg[10-1:0] modulation_right; 

    
    parameter LEFT=2'b11;
    parameter RIGHT=2'b10;
    parameter NONE=2'b00;

    reg[2:0] block_streak_left=3'd0;
    reg[2:0] block_streak_right=3'd0;


    //easier version of modulation
    always@(posedge clk)begin
        if(reset)begin
            block_streak_left<=3'd0;
            block_streak_right<=3'd0;
            modulation_left<=10'b1111111111;
            modulation_right<=10'b1111111111;
        end

        else begin
            if(oot_done===1'b1)begin
                //check if which side
                if(oot_side===LEFT)begin
                    //check block streak & update block streak

                    //break the right streak if there is previous right streak and 
                    // -------------go normal-----
                    if(block_streak_right>3'd0)begin
                        //update streak
                        block_streak_left<=3'd0;
                        block_streak_right<=3'd0;

                        //update modulation
                        modulation_right<=10'b1111111111;
                        modulation_left<=10'b1111111111;
                    end

                    //if is continuous streak
                    else begin/*if(block_streak_left>=3'd0)*/
                        //update streak
                        block_streak_left<=(block_streak_left+3'd1<=3'd5)?(block_streak_left+3'd1):3'd5;
                        block_streak_right<=3'd0;

                        //update modulation
                        modulation_right<=10'b1111111111-(10'd300/10'd5)*((block_streak_left+3'd1<=3'd5)?({7'd0,block_streak_left}+10'd1):10'd5);
                        modulation_left<=10'b1111111111;

                    end
                end
                else if(oot_side===RIGHT)begin
                    //check block streak & update block streak

                    //break the left streak if there is previous left streak and 
                    // -------------go normal-----
                    if(block_streak_left>3'd0)begin
                        //update streak
                        block_streak_left<=3'd0;
                        block_streak_right<=3'd0;

                        //update modulation
                        modulation_right<=10'b1111111111;
                        modulation_left<=10'b1111111111;
                    end

                    //if is continuous streak
                    else begin/*if(block_streak_right>=3'd0)*/
                        //update streak
                        block_streak_left<=3'd0;
                        block_streak_right<=(block_streak_right+3'd1<=3'd5)?(block_streak_right+3'd1):3'd5;
                        

                        //update modulation
                        modulation_right<=10'b1111111111;
                        modulation_left<=10'b1111111111-(10'd300/10'd5)*((block_streak_right+3'd1<=3'd5)?({7'd0,block_streak_right}+10'd1):10'd5);

                    end
                end
                else begin
                    modulation_left<=10'b1111111111;
                    modulation_right<=10'b1111111111;
                end
            end

            //remain the current modulation
            else begin
                modulation_left<=modulation_left;
                modulation_right<=modulation_right;

            end
        end
    end

    //using timing
    //more difficult

    // always@(posedge clk)begin
    //     if(reset)begin
    //         modulation_left<=10'b1111111111;
    //         modulation_right<=10'b1111111111;
    //     end

    //     else begin
    //         if(oot_done)begin
    //             if(oot_side===LEFT)begin
    //                 //based on the oot time we can modulate
    //                 modulation_right<=10b'1111111111;
    //                 modulation_left<=10b'1111111111-(10'd200/10'd5)*block_streak_left;
    //             end
    //             else if(oot_side===RIGHT)begin
    //                 //based on the oot time we can modulate
    //                 modulation_right<=10b'1111111111-(10'd200/10'd5)*block_streak_right;
    //                 modulation_left<=10b'1111111111;
    //             end
    //             else begin
    //                 modulation_left<=10'b1111111111;
    //                 modulation_right<=10'b1111111111;
    //             end
    //         end
    //         else begin
    //             //remain the modulation
    //             modulation_left<=modulation_left;
    //             modulation_right<=modulation_right;
    //         end
    //     end
    // end
endmodule
