`timescale 1ns / 1ps


module tb_watch ();

    reg clk, reset, btn_r, btn_l, btn_u, btn_d;
    reg  [2:0] sw;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    top_stopwatch_watch dut (
        .clk(clk),
        .reset(reset),
        .sw(sw),  //2: sel_display(sec_msec/hour_min), 1: watch/sw, 0: sw mode(up/down)
        .btn_r(btn_r),  //run_stop
        .btn_l(btn_l),  //clear
        .btn_u(btn_u),  //watch up
        .btn_d(btn_d),  //watch down
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk   = 0;  //Init
        reset = 1;
        sw    = 3'b000;  // sec_msec / watch / X
        btn_r = 0;
        btn_l = 0;  //default
        btn_u = 0;
        btn_d = 0;  //normal
        #10;

        reset = 0;
        #400_000_00;

        btn_u = 1;  //UP(sec)
        #100_000;

       
        btn_u = 0;
        #200_000_000;

        btn_d = 1;  //DOWN(sec)
        #100_000;

        btn_d = 0;
        #400_000_000;

        btn_u = 1;  //UP(sec)
        #100_000;

        btn_u = 0;
        #400_000_00;

        sw = 3'b100;  //hour_min
        #500_000_0;

        btn_u = 1;  //UP(hour)
        #100_000;

        btn_u = 0;
        #200_000_000;

        btn_r = 1;  //RIGHT
        #100_000;

        btn_r = 0;
        #200_000_000;

        btn_u = 1;  //UP(min)
        #100_000;

        btn_u = 0;

        #100_000_000_0;  

        $stop;

    end

 //10^-4  90_000 이상 1이어야 인식, 1msec = 10_7 : 100_000_00, 1sec = 100_000_000_0
 //1min = 6X10^9

endmodule
