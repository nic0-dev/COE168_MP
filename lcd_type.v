`timescale 1ns / 1ps

module lcd_type (
    input clk,
    input nrst,
    input sw0,
    input btn0,
    input btn1,
    input btn2,
    input btn3,
    output reg [3:0] data,
    output reg rs,
    output reg rw,
    output reg en
);

    reg [31:0]  delay_counter;

    parameter M1    =    100000;
    parameter U400  =     40000;

    task enable;
        input en_flag;
        begin 
            if (delay_counter == (en_flag == 1) ? U400 : M1) begin
                en <= (en_flag == 1) ? 1'b1 : 1'b0;
                delay_counter <= 0;
            end else begin
                delay_counter <= delay_counter + 1;
            end
        end
    endtask

    task set_data;
        input [3:0] nibble;
        begin
            if (delay_counter == U400) begin
                data <= nibble;
                delay_counter <= 0;
                enable(1); // Assert
                enable(0); // Deassert
            end else begin
                delay_counter <= delay_counter + 1;
            end
        end
    endtask

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            delay_counter   <= 0;
            data            <= 4'b0000;
            rs              <= 0;
            en              <= 0;
        end else begin
            if (sw0) begin // Move Cursor
                if (btn2) begin // Move Right
                    set_data(4'b0001);
                    set_data(4'b0100);
                end else if (btn3) begin // Move Left
                    set_data(4'b0001);
                    set_data(4'b0000);
                end // else begin // Move UP/DOWN

                // end
            end
        end
    end
endmodule
