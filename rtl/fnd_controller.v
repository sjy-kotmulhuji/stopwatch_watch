`timescale 1ns / 1ps

module fnd_controller (
    input clk,
    input reset,
    input sel_display,
    input [23:0] fnd_in_data,
    output [3:0] fnd_digit,
    output [7:0] fnd_data   //bcd 모듈에서 이 값을 drive 하기 때문에 이 모듈에서는 drive 하면 안 됨. 연결만
);
    wire [3:0] w_digit_msec_1, w_digit_msec_10;
    wire [3:0] w_digit_sec_1, w_digit_sec_10;
    wire [3:0] w_digit_min_1, w_digit_min_10;
    wire [3:0] w_digit_hour_1, w_digit_hour_10;
    wire [3:0] w_mux_hour_min_out, w_mux_sec_msec_out;
    wire [3:0] w_mux_2x1_out;
    wire [2:0] w_digit_sel;
    wire w_1khz, w_dot_onoff;


    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_HOUR_DS (
        .in_data (fnd_in_data[23:19]),
        .digit_1 (w_digit_hour_1),
        .digit_10(w_digit_hour_10)
    );

    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_MIN_DS (
        .in_data (fnd_in_data[18:13]),
        .digit_1 (w_digit_min_1),
        .digit_10(w_digit_min_10)
    );

    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_SEC_DS (
        .in_data (fnd_in_data[12:7]),
        .digit_1 (w_digit_sec_1),
        .digit_10(w_digit_sec_10)
    );

    digit_splitter #(
        .BIT_WIDTH(7)
    ) U_MSEC_DS (
        .in_data (fnd_in_data[6:0]),
        .digit_1 (w_digit_msec_1),
        .digit_10(w_digit_msec_10)
    );

    dot_onoff U_DOT_COMP (
        .msec     (fnd_in_data[6:0]),
        .dot_onoff(w_dot_onoff)
    );

    mux_8X1 U_Mux_SEC_MSEC (
        .digit_1       (w_digit_msec_1),
        .digit_10      (w_digit_msec_10),
        .digit_100     (w_digit_sec_1),
        .digit_1000    (w_digit_sec_10),
        .digit_dot_1   (4'hf),
        .digit_dot_10  (4'hf),
        .digit_dot_100 ({3'b111, w_dot_onoff}),
        .digit_dot_1000(4'hf),
        .sel           (w_digit_sel),
        .mux_out       (w_mux_sec_msec_out)
    );

    mux_8X1 U_Mux_HOUR_MIN (
        .digit_1       (w_digit_min_1),
        .digit_10      (w_digit_min_10),
        .digit_100     (w_digit_hour_1),
        .digit_1000    (w_digit_hour_10),
        .digit_dot_1   (4'hf),
        .digit_dot_10  (4'hf),
        .digit_dot_100 ({3'b111, w_dot_onoff}),
        .digit_dot_1000(4'hf),
        .sel           (w_digit_sel),
        .mux_out       (w_mux_hour_min_out)
    );

    mux_2x1 U_MUX_2x1 (
        .sel   (sel_display),
        .i_sel0(w_mux_sec_msec_out),
        .i_sel1(w_mux_hour_min_out),
        .o_mux (w_mux_2x1_out)

    );

    clk_div U_CLK_DIV (
        .clk   (clk),
        .reset (reset),
        .o_1khz(w_1khz)
    );

    counter_8 U_COUNTER_8 (
        .clk      (w_1khz),
        .reset    (reset),
        .digit_sel(w_digit_sel)
    );


    decoder_2x4 U_DEC_2x4 (
        .digit_sel(w_digit_sel[1:0]),
        .dec_out  (fnd_digit)
    );

    bcd U_BCD (
        .bcd     (w_mux_2x1_out),
        .fnd_data(fnd_data)
    );

endmodule

module dot_onoff (
    input  [6:0] msec,
    output       dot_onoff
);
    assign dot_onoff = (msec < 50);         //dot_onoff = (msec >= 50 || msec <= 99) ? 1 : 0;
endmodule

module mux_2x1 (
    input sel,
    input [3:0] i_sel0,
    input [3:0] i_sel1,
    output [3:0] o_mux

);

    assign o_mux = (sel) ? i_sel1 : i_sel0;

endmodule

module clk_div (        //fnd 동작은 눈으로 확인할 수 있도록 클락 속도 조정
    input      clk,
    input      reset,
    output reg o_1khz
);

    reg [16:0] counter_r;  //[$clog2(100000):0] 이렇게도 가능 

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;  //초기화 안 하면 X(Uninitialized)
            o_1khz <= 1'b0;
        end else begin
            if (counter_r == 99_999) begin  //17bit라 10만 이후로도 카운트 가능하기 때문에 0으로 떨궈줌
                counter_r <= 0;  //duty비 1:100_000
                o_1khz    <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                o_1khz <= 1'b0;
            end
        end
    end

endmodule

module counter_8 (
    input        clk,
    input        reset,
    output [2:0] digit_sel      //0~8 반복
);

    reg [2:0] counter_r;

    assign digit_sel = counter_r;

    always@(posedge clk, posedge reset) begin   //동일 프로젝트 내에선 상승 엣지, 하강 엣지 하나로 통일
        if (reset) begin
            counter_r <= 0;
        end else begin
            counter_r <= counter_r + 1; //3 이상이 돼도 overflow로 발생한 carry가 그냥 사라지므로 0~3 반복
        end
    end

endmodule


module decoder_2x4 (
    input [1:0] digit_sel,
    output reg [3:0] dec_out
);
    always @(*) begin
        case (digit_sel)
            2'b00: dec_out = 4'b1110;
            2'b01: dec_out = 4'b1101;
            2'b10: dec_out = 4'b1011;
            2'b11: dec_out = 4'b0111;
        endcase
    end

endmodule

module mux_8X1 (
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [3:0] digit_dot_1,
    input [3:0] digit_dot_10,
    input [3:0] digit_dot_100,
    input [3:0] digit_dot_1000,
    input [2:0] sel,

    output reg [3:0] mux_out
);

    always @(*) begin
        case (sel)
            3'b000: mux_out = digit_1;
            3'b001: mux_out = digit_10;
            3'b010: mux_out = digit_100;
            3'b011: mux_out = digit_1000;
            3'b100: mux_out = digit_dot_1;
            3'b101: mux_out = digit_dot_10;
            3'b110: mux_out = digit_dot_100;
            3'b111: mux_out = digit_dot_1000;
        endcase

    end

endmodule


module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10
);

    assign digit_1  = in_data % 10;
    assign digit_10 = (in_data / 10) % 10;

endmodule

module bcd (
    input [3:0] bcd,
    output reg [7:0] fnd_data
);
    always @(bcd) begin         //assign 쓰면 코드 너무 길어져서 case문 쓰기 위해 always문 사용
        case (bcd)
            4'd0:    fnd_data = 8'hc0;
            4'd1:    fnd_data = 8'hf9;
            4'd2:    fnd_data = 8'ha4;
            4'd3:    fnd_data = 8'hb0;
            4'd4:    fnd_data = 8'h99;
            4'd5:    fnd_data = 8'h92;
            4'd6:    fnd_data = 8'h82;
            4'd7:    fnd_data = 8'hf8;
            4'd8:    fnd_data = 8'h80;
            4'd9:    fnd_data = 8'h90;
            4'd10:    fnd_data = 8'hFF;
            4'd11:    fnd_data = 8'hFF;
            4'd12:    fnd_data = 8'hFF;
            4'd13:    fnd_data = 8'hFF;
            4'd14:    fnd_data = 8'h7F;
            4'd15:    fnd_data = 8'hFF;
            default: fnd_data = 8'hFF;  //bcd가 다른 값일 때
        endcase
    end
endmodule
