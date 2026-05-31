`timescale 1ns / 1ps


module tb_btn_debounce ();

    reg clk, reset, i_btn;
    wire o_btn;

    btn_debounce dut (
        .clk  (clk),
        .reset(reset),
        .i_btn(i_btn),
        .o_btn(o_btn)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk   = 0;
        reset = 1;
        i_btn = 0;
        #10;

        reset = 0;
        #100_000;

        i_btn = 1;
        #100_00;

        i_btn = 0;
        #100_00;

        i_btn = 1;
        #800_00;

        i_btn = 0;
        #100_00;

        i_btn = 1;
        #100_000;

        i_btn = 0;
        #100_000;

        i_btn = 1;
        #100_000_0;

        i_btn = 0;

        #100_000_0;
        $stop;

    end

endmodule
