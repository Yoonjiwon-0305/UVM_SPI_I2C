`timescale 1ns / 1ps

module demo_i2c (
    input  logic       clk,
    input  logic       reset,
    input  logic [9:0] sw,
    output logic [7:0] led,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);

    typedef enum logic [2:0] {
        IDLE,
        SEND_START,
        SEND_ADDR,
        SEND_DATA,
        SEND_STOP,
        READ_DATA
    } demo_state_e;

    demo_state_e       state;

    logic              scl;
    wire               sda;
    logic              m_sda_o;
    logic              sda_i;

    logic              cmd_start;
    logic              cmd_write;
    logic              cmd_read;
    logic              cmd_stop;
    logic        [7:0] m_tx_data;
    logic              ack_in;
    logic        [7:0] m_rx_data;
    logic              m_done;
    logic              m_ack_out;
    logic              m_busy;
    logic        [7:0] s_tx_data;
    logic        [7:0] s_rx_data;
    logic              s_done;
    logic              s_busy;
    logic              is_write;

    assign sda = m_sda_o ? 1'bz : 1'b0;
    assign sda_i = (sda === 1'bz) ? 1'b1 : sda;

    // slave rx_data → LED
    assign led = s_rx_data;

    // slave tx_data 고정값
    assign s_tx_data = 8'hA5;

    // 1. I2C_master
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

    // 2. I2C_slave
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

    // 3. fnd_hex_controller
    fnd_hex_controller U_FND (
        .clk      (clk),
        .reset    (reset),
        .hex_data ({8'h00, m_rx_data}),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cmd_start <= 0;
            cmd_write <= 0;
            cmd_read  <= 0;
            cmd_stop  <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cmd_start <= 0;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    if (sw[8]) begin
                        is_write <= 1;
                        state <= SEND_START;
                    end else if (sw[9]) begin
                        is_write <= 0;
                        state <= SEND_START;
                    end
                end
                SEND_START: begin
                    cmd_start <= 1;
                    m_tx_data <= is_write ? {7'h12, 1'b0} : {7'h12, 1'b1};
                    if (m_done) begin
                        cmd_start <= 0;
                        state <= SEND_ADDR;
                    end
                end
                SEND_ADDR: begin
                    cmd_write <= 1;
                    if (m_done) begin
                        cmd_write <= 0;
                        m_tx_data <= sw[7:0];  // SEND_DATA를 위해 미리 준비
                        if (is_write) begin
                            state <= SEND_DATA;
                        end else begin
                            state <= READ_DATA;
                        end
                    end
                end
                SEND_DATA: begin
                    cmd_write <= 1;
                    if (m_done) begin
                        cmd_write <= 0;
                        state     <= SEND_STOP;
                    end
                end
                SEND_STOP: begin
                    cmd_stop <= 1;
                    if (m_done) begin
                        cmd_stop <= 0;
                        state    <= IDLE;
                    end
                end
                READ_DATA: begin
                    cmd_read <= 1;
                    ack_in   <= 1;  // NACK
                    if (m_done) begin
                        cmd_read <= 0;
                        state    <= SEND_STOP;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
