`timescale 1ns / 1ps

module tb_spi_top ();

    logic       clk;
    logic       reset;
    logic       cpol;
    logic       cpha;
    logic [7:0] clk_div;
    logic       start;
    logic [7:0] m_tx_data;
    logic [7:0] m_rx_data;
    logic       m_done;
    logic       busy;
    logic [7:0] s_tx_data;
    logic [7:0] s_rx_data;
    logic       s_done;

    SPI_top dut (
        .clk      (clk),
        .reset    (reset),
        .cpol     (cpol),
        .cpha     (cpha),
        .clk_div  (clk_div),
        .start    (start),
        .m_tx_data(m_tx_data),
        .m_rx_data(m_rx_data),
        .m_done   (m_done),
        .busy     (busy),
        .s_tx_data(s_tx_data),
        .s_rx_data(s_rx_data),
        .s_done   (s_done)
    );

    always #5 clk = ~clk;

    // ① mode 설정 task
    task spi_set_mode(input logic [1:0] mode);
        {cpol, cpha} = mode;
        @(posedge clk);
    endtask

    // ② 데이터 송수신 task
    task spi_send_data(input logic [7:0] m_data,  // Master가 보낼 데이터
                       input logic [7:0] s_data   // Slave가 보낼 데이터
    );
        m_tx_data = m_data;
        s_tx_data = s_data;
        start     = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask

    initial begin
        clk       = 0;
        reset     = 1;
        start     = 0;
        m_tx_data = 0;
        s_tx_data = 0;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);
        clk_div = 8'd4;
        @(posedge clk);

        // mode 0
        spi_set_mode(2'b00);
        spi_send_data(8'hA5, 8'h5A);
        spi_send_data(8'hFF, 8'h00);
        spi_send_data(8'h55, 8'hAA);
        spi_send_data(8'h12, 8'h34);
        spi_send_data(8'hDE, 8'hAD);
        @(posedge clk);
        #100;
        $finish;
    end
endmodule
