`timescale 1ns / 1ps

module SPI_slave (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,  // MISO로 보낼 데이터 (Slave → Master)
    output logic [7:0] rx_data,  // MOSI로 받은 데이터 (Master → Slave)
    output logic       done,
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       cs_n
);

    logic sclk_1, sclk_2;

    logic sclk_rising;
    logic sclk_falling;

    logic [7:0] rx_shift_reg;
    logic [7:0] tx_shift_reg;

    logic [2:0] bit_cnt;

    always_ff @(posedge clk) begin
        sclk_1 <= sclk;
        sclk_2 <= sclk_1;
    end

    assign sclk_rising = (~sclk_2) & sclk_1;  //(0→1 감지)
    assign sclk_falling = sclk_2 & (~sclk_1);  //(1→0 감지)

    assign miso = cs_n ? 1'bz : tx_shift_reg[7];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_shift_reg <= 8'h00;
            tx_shift_reg <= 8'h00;
            rx_data      <= 8'h00;
            bit_cnt      <= 3'd0;
            done         <= 1'b0;
        end else begin
            if (cs_n) begin  //동작 안함 
                tx_shift_reg <= tx_data;
                bit_cnt      <= 3'd0;
                done         <= 1'b0;
            end else begin
                if (sclk_rising) begin  // 상승엣지에서 수신 왼쪽으로 밀면서 오른쪽에 mosi 추가 , 8번 반복 {rx_shitf_reg[6;0],mosi}
                    rx_shift_reg <= {rx_shift_reg[6:0], mosi};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        rx_data <= {rx_shift_reg[6:0], mosi};
                        done <= 1'b1;
                    end else begin
                        done <= 0;
                    end
                end
                if (sclk_falling) begin
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                end
            end

        end
    end

endmodule
