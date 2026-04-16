`timescale 1ns / 1ps

module tb_i2c_master ();

    logic       clk;
    logic       reset;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] tx_data;
    logic       ack_in;  // master가 주는거
    logic [7:0] rx_data;
    logic       done;
    logic       ack_out;  // master가 받는거 
    logic       busy;
    logic       scl;
    wire        sda;

    // pull-up
    //assign scl = 1'b1;
    //assign sda = 1'b1;

    //pullup (scl);
    //pullup (sda);

    localparam SLA = 8'h12;

    I2C_Master_top dut (.*);

    always #5 clk = ~clk;

    task i2c_start();
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_addr(byte addr);
        // tx_data = address(8'h12) + read/write 
        tx_data   = addr;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  // wait ack
        @(posedge clk);
    endtask

    task i2c_write(byte data);
        // tx_data = address(8'h12) + read/write 
        tx_data   = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  // wait ack
        @(posedge clk);
    endtask

    task i2c_read(byte data);
        // tx_data = address(8'h12) + read/write 
        tx_data   = data;
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  // wait ack
        @(posedge clk);
    endtask

    task i2c_stop();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    initial begin
        clk   = 0;
        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);

        i2c_start();
        i2c_addr((SLA << 1) + 1'b1);
        i2c_write(8'h55);
        i2c_write(8'haa);
        i2c_write(8'h01);
        i2c_write(8'h02);
        i2c_write(8'h03);
        i2c_write(8'h04);
        i2c_stop();

        ////start 
        //cmd_start = 1'b1;
        //cmd_write = 1'b0;
        //cmd_read  = 1'b0;
        //cmd_stop  = 1'b0;
        //@(posedge clk);
        //wait (done);
        //
        //@(posedge clk);
        //// tx_data = address(8'h12) + read/write 
        //tx_data   = (SLA << 1) + 1'b0;
        //cmd_start = 1'b0;
        //cmd_write = 1'b1;
        //cmd_read  = 1'b0;
        //cmd_stop  = 1'b0;
        //@(posedge clk);
        //wait (done);  // wait ack
        //@(posedge clk);
        //
        //// tx_data = data 
        //tx_data   = 8'h55;
        //cmd_start = 1'b0;
        //cmd_write = 1'b1;
        //cmd_read  = 1'b0;
        //cmd_stop  = 1'b0;
        //@(posedge clk);
        //wait (done);  //wait ack
        //@(posedge clk);
        //
        ////stop
        //cmd_start = 1'b0;
        //cmd_write = 1'b0;
        //cmd_read  = 1'b0;
        //cmd_stop  = 1'b1;
        //@(posedge clk);
        //wait (done);
        //@(posedge clk);

        // IDLE 
        #100;
        $finish;
    end

endmodule
