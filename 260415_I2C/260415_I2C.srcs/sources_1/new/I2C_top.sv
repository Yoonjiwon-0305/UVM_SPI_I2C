`timescale 1ns / 1ps
module I2C_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] m_tx_data,
    input  logic       ack_in,
    output logic [7:0] m_rx_data,
    output logic       m_done,
    output logic       m_ack_out,
    output logic       m_busy,
    input  logic [7:0] s_tx_data,
    output logic [7:0] s_rx_data,
    output logic       s_done,
    output logic       s_busy,
    output logic       scl,
    inout  wire        sda
);
    logic m_sda_o;
    logic sda_i;

    assign sda   = m_sda_o ? 1'bz : 1'b0;
    assign sda_i = (sda === 1'bz) ? 1'b1 : sda;

    I2C_master U_MASTER (
        .clk      (clk),
        .reset    (reset),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (m_tx_data),
        .ack_in   (ack_in),
        .rx_data  (m_rx_data),
        .done     (m_done),
        .ack_out  (m_ack_out),
        .busy     (m_busy),
        .scl      (scl),
        .sda_o    (m_sda_o),
        .sda_i    (sda_i)
    );

    I2C_slave #(
        .ADDR(7'h12)
    ) U_SLAVE (
        .clk    (clk),
        .reset  (reset),
        .tx_data(s_tx_data),
        .rx_data(s_rx_data),
        .done   (s_done),
        .busy   (s_busy),
        .scl    (scl),
        .sda    (sda)
    );

endmodule
