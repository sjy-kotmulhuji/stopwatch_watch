`timescale 1ns / 1ps

module tb_stopwatch ();

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
        .btn_u(btn_u),
        .btn_d(btn_d),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk   = 0;
        reset = 1;
        sw    = 3'b010;  //sec_msec / stopwatch / up
        btn_r = 0;
        btn_l = 0;
        btn_u = 0;
        btn_d = 0;
        #10;

        reset = 0;
        #100_000_0;

        btn_r = 1;  //run
        #100_000;

        btn_r = 0;
        #500_000_00;

        btn_r = 1;  //stop
        #100_000;

        btn_r = 0;
        #500_000_00;

        btn_l = 1;  //clear
        #100_000;

        btn_l = 0;
        #300_000_00;

        btn_r = 1;  //run
        #100_000;

        btn_r = 0;
        sw = 3'b110;  //hour_min /sw / up
        #400_000_00;

        sw = 3'b111;  //hour_min / sw / down
        #200_000_00;

        btn_l = 1;  //run 상태에서 clear 불가
        #100_000;

        btn_l = 0;
        #100_000_00;

        $stop;


    end

endmodule
