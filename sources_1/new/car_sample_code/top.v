module Top(
    input clk,
    input rst,
    input echo,
    input left_signal,
    input right_signal,
    input mid_signal,
    output trig,
    output left_motor,
    output reg [1:0]left,
    output right_motor,
    output reg [1:0]right
);

    wire Rst_n, rst_pb, stop;
    debounce d0(rst_pb, rst, clk);
    onepulse d1(rst_pb, clk, Rst_n);

    wire [2:0] state;

    parameter turn_left=3'b000;
    parameter turn_right=3'b001;
    parameter go_straight=3'b010;
    parameter stop_state=3'b011;
    parameter sharp_turn_left = 3'b100;
    parameter sharp_turn_right = 3'b101;

    motor A(
        .clk(clk),
        .rst(Rst_n),
        .mode(state),
        .pwm({left_motor, right_motor})
    );

    sonic_top B(
        .clk(clk), 
        .rst(Rst_n), 
        .Echo(echo), 
        .Trig(trig),
        .stop(stop)
    );
    
    tracker_sensor C(
        .clk(clk), 
        .reset(Rst_n), 
        .left_signal(left_signal), 
        .right_signal(right_signal),
        .mid_signal(mid_signal),
        .state(state)
       );

    always @(*) begin
        // [TO-DO] Use left and right to set your pwm
        // if(stop) {left, right} = 4'b0000;
 
        if(stop) {left,right}=4'b0000;
        else begin
        case(state)
            turn_left:begin
                {left,right}=4'b0010;
            end

            turn_right:begin
                {left,right}=4'b1000;
            end

            sharp_turn_left:begin 
                {left,right}=4'b0110;
            end 

            sharp_turn_right:begin 
                {left,right}=4'b1001;
            end

            go_straight:begin
                {left,right}=4'b1010;
            end

            stop_state:begin
                {left,right}=4'b0000;
            end

            default:begin
                {left,right}=4'b0000;
            end
        endcase
        end
    end

endmodule

module debounce (pb_debounced, pb, clk);
    output pb_debounced; 
    input pb;
    input clk;
    reg [4:0] DFF;
    
    always @(posedge clk) begin
        DFF[4:1] <= DFF[3:0];
        DFF[0] <= pb; 
    end
    assign pb_debounced = (&(DFF)); 
endmodule

module onepulse (PB_debounced, clk, PB_one_pulse);
    input PB_debounced;
    input clk;
    output reg PB_one_pulse;
    reg PB_debounced_delay;

    always @(posedge clk) begin
        PB_one_pulse <= PB_debounced & (! PB_debounced_delay);
        PB_debounced_delay <= PB_debounced;
    end 
endmodule
