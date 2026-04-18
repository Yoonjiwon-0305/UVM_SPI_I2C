`timescale 1ns / 1ps

module SPI_top (
    input  logic       clk,
    input  logic       reset,
    // Master 제어 신호 
    input  logic       cpol,
    input  logic       cpha,
    input  logic [7:0] clk_div,
    input  logic       start,
    input  logic [7:0] m_tx_data,
    output logic [7:0] m_rx_data,
    output logic       m_done,
    output logic       busy,
    // Slave 제어 신호
    input  logic [7:0] s_tx_data,
    output logic [7:0] s_rx_data,
    output logic       s_done
);

    logic sclk;
    logic mosi;
    logic miso;
    logic cs_n;

    SPI_master U_MASTER (
        .clk    (clk),
        .reset  (reset),
        .cpol   (cpol),       // idle 0: Low idle 1: high
        .cpha   (cpha),       // first sampling , 0:first edge, 1:second edge
        .clk_div(clk_div),
        .tx_data(m_tx_data),
        .start  (start),
        .rx_data(m_rx_data),
        .done   (m_done),
        .busy   (busy),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n)
    );

    SPI_slave U_SLAVE (
        .clk    (clk),
        .reset  (reset),
        .tx_data(s_tx_data),  // MISO로 보낼 데이터 (Slave → Master)
        .rx_data(s_rx_data),  // MOSI로 받은 데이터 (Master → Slave)
        .done   (s_done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n)
    );
endmodule
