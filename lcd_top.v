`timescale 1ns / 1ps

module lcd_top(
    input clk,
    input nrst,
    input sw0,
    input btn0,
    input btn1,
    input btn2,
    input btn3,
    output [3:0] data,  // Declare as wire (by default)
    output rs,
    output rw,
    output en   
);

    // Intermediate wires for module connection
    wire [3:0] data_internal;
    wire rs_internal;
    wire rw_internal;
    wire en_internal;

    lcd_init init (
        .clk(clk),
        .nrst(nrst),
        .sw0(sw0),
        .btn0(btn0),
        .btn1(btn1),
        .btn2(btn2),
        .btn3(btn3),
        .data(data_internal),  // Wire connection
        .rs(rs_internal),      
        .rw(rw_internal),      
        .en(en_internal)       
    );

    // Output assignments
    assign data = data_internal;
    assign rs   = rs_internal;
    assign rw   = rw_internal;
    assign en   = en_internal;

endmodule
