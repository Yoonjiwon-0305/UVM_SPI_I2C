`timescale 1ns / 1ps
module I2C_slave #(
    parameter [6:0] ADDR = 7'h12
) (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done,
    output logic       busy,
    input  logic       scl,
    inout  wire        sda
);
    logic sda_o_r;
    wire  sda_i;

    assign sda   = sda_o_r ? 1'bz : 2'b0;
    assign sda_i = (sda === 1'bz) ? 1'b1 : sda;

    logic scl_1, scl_2;
    logic sda_1, sda_2;
    logic scl_rising, scl_falling;
    logic start_det, stop_det;

    logic [7:0] rx_shift_reg;
    logic [7:0] tx_shift_reg;
    logic [2:0] bit_cnt;
    logic       is_read;
    logic       addr_match;
    logic [6:0] addr_reg;

    always_ff @(posedge clk) begin
        scl_1 <= scl;
        scl_2 <= scl_1;
    end

    always_ff @(posedge clk) begin
        sda_1 <= sda_i;
        sda_2 <= sda_1;
    end

    assign scl_rising  = (~scl_2) & scl_1;
    assign scl_falling = scl_2 & (~scl_1);
    assign start_det   = scl_2 & sda_2 & (~sda_1);
    assign stop_det    = scl_2 & (~sda_2) & sda_1;

    typedef enum logic [2:0] {
        IDLE,
        ADDR_DET,
        ADDR_ACK,
        DATA,
        DATA_ACK
    } state_e;
    state_e state;
    assign busy = (state != IDLE);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            rx_shift_reg <= 0;
            tx_shift_reg <= 0;
            bit_cnt      <= 0;
            is_read      <= 0;
            addr_match   <= 0;
            addr_reg     <= 0;
            rx_data      <= 0;
            done         <= 0;
            sda_o_r      <= 1;
        end else begin
            done <= 0;
            case (state)
                IDLE: begin
                    sda_o_r <= 1'b1;
                    if (start_det) begin
                        state   <= ADDR_DET;
                        bit_cnt <= 0;
                    end
                end

                ADDR_DET: begin
                    if (stop_det) begin
                        state <= IDLE;
                    end else if (scl_rising) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                        if (bit_cnt == 7) begin
                            addr_reg <= rx_shift_reg[6:0];
                            is_read  <= sda_i;
                            bit_cnt  <= 0;
                            state    <= ADDR_ACK;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end

                ADDR_ACK: begin
                    if (stop_det) begin
                        state <= IDLE;
                    end else if (scl_falling) begin
                        if (!addr_match) begin
                            if (addr_reg == ADDR) begin
                                sda_o_r    <= 1'b0;  // ACK
                                addr_match <= 1'b1;
                                if (is_read) begin
                                    tx_shift_reg <= tx_data;
                                end else begin
                                    rx_shift_reg <= 8'h00;
                                end
                            end else begin
                                sda_o_r <= 1'b1;
                                state   <= IDLE;
                            end
                        end
                    end else if (scl_rising) begin
                        // ACK 비트의 scl_rising → DATA로 전환
                        if (addr_match) begin
                            bit_cnt    <= 0;
                            addr_match <= 1'b0;
                            state      <= DATA;
                        end
                    end
                end

                DATA: begin
                    if (stop_det) begin
                        state <= IDLE;
                    end else if (start_det) begin
                        state   <= ADDR_DET;
                        bit_cnt <= 0;
                    end else if (is_read) begin
                        if (scl_falling) begin
                            sda_o_r      <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            if (bit_cnt == 7) begin
                                bit_cnt <= 0;
                                state   <= DATA_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end else begin
                        if (scl_falling) begin
                            sda_o_r <= 1'b1;
                        end else if (scl_rising) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                            if (bit_cnt == 7) begin
                                bit_cnt <= 0;
                                state   <= DATA_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                end

                DATA_ACK: begin
                    if (stop_det) begin
                        state <= IDLE;
                    end else if (scl_falling) begin
                        if (is_read) begin
                            sda_o_r <= 1'b1;  // Master ACK/NACK 대기, 버스 해제
                        end else begin
                            sda_o_r <= 1'b0;  // Slave ACK 출력
                        end
                    end else if (scl_rising) begin
                        if (is_read) begin
                            if (sda_i == 1'b0) begin
                                // Master ACK → 다음 바이트
                                tx_shift_reg <= tx_data;
                                bit_cnt      <= 0;
                                state        <= DATA;
                            end else begin
                                // Master NACK → 종료
                                done    <= 1'b1;
                                sda_o_r <= 1'b1;
                                state   <= IDLE;
                            end
                        end else begin
                            // Slave ACK 후 rx_data 래치
                            rx_data <= rx_shift_reg;
                            done    <= 1'b1;
                            bit_cnt <= 0;
                            state   <= DATA;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
