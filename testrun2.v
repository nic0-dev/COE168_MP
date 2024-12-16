`timescale 1ns / 1ps

module lcd_init (
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
    localparam 
        FS_8bit1       = 5'd0,
        FS_8bit2       = 5'd1,
        FS_8bit3       = 5'd2,
        FS_4bit        = 5'd3,
        FS_NF           = 5'd4,
        DISPLAY_OFF     = 5'd5,
        CLEAR_DISPLAY   = 5'd6,
        CLEAR_DELAY     = 5'd7,
        ENTRY_MODE      = 5'd8,
        DISPLAY_ON      = 5'd9,
        FN_DELAY        = 5'd10,
        WRITE1          = 5'd11,
        WRITE2          = 5'd12,
        WRITE3          = 5'd13,
        WRITE4          = 5'd14,
        NEXT_LINE_DELAY = 5'd15,
        NEXT_LINE       = 5'd16,
        LN_DELAY        = 5'd17,
        WRITE5          = 5'd18,
        WRITE6          = 5'd19,
        WRITE7          = 5'd20,
        WRITE8          = 5'd21,
        WRITE9          = 5'd22,
        CLEAR_NAME_DELAY= 5'd23,
        CLEAR_NAME      = 5'd24,  
        ENABLE          = 5'd25,
        DONE            = 5'd26;

    reg [5:0]   state;
    reg [5:0]   next_state;
    reg [31:0]  delay_counter;
    reg         flag;
    reg         next_flag;

    parameter S2    = 20000000;
    parameter M30   =  3000000;
    parameter M6    =   600000;
    parameter M1    =   100000;
    parameter U400  =    40000;
    
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            state           <= FS_8bit1;
            next_state      <= FS_8bit2;
            delay_counter   <= 0;
            data            <= 4'b0000;
            rs              <= 0;
            en              <= 0;
            flag            <= 1;
            next_flag       <= 1;
        end else begin
            case (state)
                ENABLE: begin
                    if(flag == 1) begin // Assert Enable after 400us
                        if (delay_counter == U400) begin
                            en <= 1'b1;
                            state <= ENABLE;
                            delay_counter <= 0;
                            flag <= 0;  
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin // Deassert Enable after 1ms
                        if (delay_counter == M1) begin
                            en <= 1'b0;
                            state <= next_state;
                            delay_counter <= 0;
                            flag <= next_flag;  
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                FS_8bit1: begin
                    if (delay_counter == M30) begin
                        data <= 4'b0011;
                        state <= ENABLE;
                        next_state <= FS_8bit2;
                        next_flag <= 1;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                FS_8bit2: begin
                    if (delay_counter == M6) begin
                        data <= 4'b0011;
                        state <= ENABLE;
                        next_state <= FS_8bit3;
                        next_flag <= 1;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                FS_8bit3: begin
                    if (delay_counter == U400) begin
                        data <= 4'b0011;
                        state <= ENABLE;
                        next_state <= FS_4bit;
                        next_flag <= 1;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                FS_4bit: begin
                    if (delay_counter == U400) begin
                        data <= 4'b0010;
                        state <= ENABLE;
                        next_state <= FS_NF;
                        next_flag <= 1;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                FS_NF: begin
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0010;
                            state <= ENABLE;
                            next_state <= FS_NF;    // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower; N = 1, F = 0
                        if (delay_counter == U400) begin
                            data <= 4'b1000;
                            state <= ENABLE;
                            next_state <= DISPLAY_OFF;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                DISPLAY_OFF: begin
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0000;
                            state <= ENABLE;
                            next_state <= DISPLAY_OFF;    // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower; N = 1, F = 0
                        if (delay_counter == U400) begin
                            data <= 4'b1000;
                            state <= ENABLE;
                            next_state <= CLEAR_DISPLAY;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                CLEAR_DISPLAY: begin
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0000;
                            state <= ENABLE;
                            next_state <= CLEAR_DISPLAY;    // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower; N = 1, F = 0
                        if (delay_counter == U400) begin
                            data <= 4'b0001;
                            state <= ENABLE;
                            next_state <= ENTRY_MODE;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                ENTRY_MODE: begin
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0000;
                            state <= ENABLE;
                            next_state <= ENTRY_MODE;    // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower; N = 1, F = 0
                        if (delay_counter == U400) begin
                            data <= 4'b0110;
                            state <= ENABLE;
                            next_state <= DISPLAY_ON;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                DISPLAY_ON: begin
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0000;
                            state <= ENABLE;
                            next_state <= DISPLAY_ON;    // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower; N = 1, F = 0
                        if (delay_counter == U400) begin
                            data <= 4'b1111;
                            state <= ENABLE;
                            next_state <= FN_DELAY;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                FN_DELAY: begin // Assert RS
                    if (delay_counter == U400) begin
                        rs <= 1'b1;
                        state <= WRITE1;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                WRITE1: begin // M
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0100;
                            state <= ENABLE;
                            next_state <= WRITE1;   // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == U400) begin
                            data <= 4'b1101;
                            state <= ENABLE;
                            next_state <= WRITE2;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                WRITE2: begin // A
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0100;
                            state <= ENABLE;
                            next_state <= WRITE2;   // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == U400) begin
                            data <= 4'b0001;
                            state <= ENABLE;
                            next_state <= WRITE3;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                WRITE3: begin // R
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0101;
                            state <= ENABLE;
                            next_state <= WRITE3;   // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == U400) begin
                            data <= 4'b0010;
                            state <= ENABLE;
                            next_state <= WRITE4;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                WRITE4: begin // K
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0100;
                            state <= ENABLE;
                            next_state <= WRITE4;   // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == U400) begin
                            data <= 4'b1011;
                            state <= ENABLE;
                            next_state <= NEXT_LINE_DELAY;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                NEXT_LINE_DELAY: begin // Deassert RS
                    if (delay_counter == U400) begin
                        rs <= 1'b0;
                        state <= NEXT_LINE;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                NEXT_LINE: begin // Head of 2nd line
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b1100;
                            state <= ENABLE;
                            next_state <= NEXT_LINE; // Same State
                            next_flag <= 0;          // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == M1) begin
                            data <= 4'b0000;
                            state <= ENABLE;
                            next_state <= LN_DELAY;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                LN_DELAY: begin // Assert RS
                    if (delay_counter == U400) begin
                        rs <= 1'b1;
                        state <= WRITE5;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                WRITE5: begin // C
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0100;
                            state <= ENABLE;
                            next_state <= WRITE5;   // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == U400) begin
                            data <= 4'b0011;
                            state <= ENABLE;
                            next_state <= WRITE6;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                WRITE6: begin // A
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0100;
                            state <= ENABLE;
                            next_state <= WRITE6;   // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == U400) begin
                            data <= 4'b0001;
                            state <= ENABLE;
                            next_state <= WRITE7;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                WRITE7: begin // G
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0100;
                            state <= ENABLE;
                            next_state <= WRITE7;   // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == U400) begin
                            data <= 4'b0111;
                            state <= ENABLE;
                            next_state <= WRITE8;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                WRITE8: begin // A
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0100;
                            state <= ENABLE;
                            next_state <= WRITE8;   // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == U400) begin
                            data <= 4'b0001;
                            state <= ENABLE;
                            next_state <= WRITE9;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                WRITE9: begin // S
                    if (flag == 1) begin            // Upper
                        if (delay_counter == U400) begin
                            data <= 4'b0101;
                            state <= ENABLE;
                            next_state <= WRITE9;   // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower
                        if (delay_counter == U400) begin
                            data <= 4'b0011;
                            state <= ENABLE;
                            next_state <= CLEAR_NAME_DELAY;
                            next_flag <= 1;
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                CLEAR_NAME_DELAY: begin // Deassert RS
                    if (delay_counter == U400) begin
                        rs <= 1'b0;
                        state <= CLEAR_NAME;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                CLEAR_NAME: begin
                    if (flag == 1) begin            // Upper
                        if (delay_counter == S2) begin
                            data <= 4'b0000;
                            state <= ENABLE;
                            next_state <= CLEAR_NAME;    // Same State
                            next_flag <= 0;         // Lower Nibble
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin                  // Lower; N = 1, F = 0
                        if (delay_counter == U400) begin
                            data <= 4'b0001;
                            state <= ENABLE;
                            next_state <= DONE; // Last State
                            next_flag <= 0;           
                            flag <= 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end
                end

                DONE: begin
                    if (delay_counter == U400) begin
                        data <= 4'b0000;
                        state <= ENABLE;
                        next_state <= DONE;
                        next_flag <= 0;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
            endcase
        end
    end
endmodule