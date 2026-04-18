`timescale 1ns / 1ps

module tb_i2c_top ();
    logic       clk;
    logic       reset;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] m_tx_data;
    logic       ack_in;
    logic [7:0] m_rx_data;
    logic       m_done;
    logic       m_ack_out;
    logic       m_busy;
    logic [7:0] s_tx_data;
    logic [7:0] s_rx_data;
    logic       s_done;
    logic       s_busy;
    logic       scl;
    wire        sda;

    I2C_top dut (
        .clk      (clk),
        .reset    (reset),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .m_tx_data(m_tx_data),
        .ack_in   (ack_in),
        .m_rx_data(m_rx_data),
        .m_done   (m_done),
        .m_ack_out(m_ack_out),
        .m_busy   (m_busy),
        .s_tx_data(s_tx_data),
        .s_rx_data(s_rx_data),
        .s_done   (s_done),
        .s_busy   (s_busy),
        .scl      (scl),
        .sda      (sda)
    );

    task i2c_start();
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
        cmd_start = 1'b0;
    endtask

    task i2c_write(input logic [7:0] data);
        m_tx_data = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
        cmd_write = 1'b0;
    endtask

    task i2c_read(input logic ack);
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        ack_in    = ack;   // 0=ACK, 1=NACK
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
        cmd_read = 1'b0;
    endtask

    task i2c_stop();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
        cmd_stop = 1'b0;
    endtask

    always #5 clk = ~clk;

    initial begin
        // 초기화
        clk       = 0;
        reset     = 1;
        cmd_start = 0;
        cmd_write = 0;
        cmd_read  = 0;
        cmd_stop  = 0;
        m_tx_data = 0;
        s_tx_data = 0;
        ack_in    = 1;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);

        i2c_start();
        i2c_write({7'h12, 1'b0});  // 주소 + Write
        i2c_write(8'hAB);  // 데이터
        i2c_stop();
        @(posedge clk);
        #1000;
        s_tx_data = 8'h5A;  // Slave가 보낼 데이터
        i2c_start();
        i2c_write({7'h12, 1'b1});  // 주소 + Read
        i2c_read(1'b1);  // NACK (마지막 바이트)
        i2c_stop();

        @(posedge clk);

        #1000;
        $finish;
    end

endmodule
