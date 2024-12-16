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
        FS_8bit1            = 5'd0,
        FS_8bit2            = 5'd1,
        FS_8bit3            = 5'd2,
        FS_4bit             = 5'd3,
        FS_NF               = 5'd4,
        DISPLAY_OFF         = 5'd5,
        CLEAR_DISPLAY       = 5'd6,
        ENTRY_MODE          = 5'd7,
        DISPLAY_ON          = 5'd8,
        FN_DELAY            = 5'd9,
        FIRST_NAME          = 5'd10,
        NEXT_LINE_DELAY     = 5'd11,
        NEXT_LINE           = 5'd12,
        LN_DELAY            = 5'd13,
        LAST_NAME           = 5'd14,
        CLEAR_NAME_DELAY    = 5'd15,
        CLEAR_NAME          = 5'd16,  
        ENABLE              = 5'd17,
        DONE                = 5'd18;

    reg [5:0]   state;
    reg [5:0]   next_state;
    reg [31:0]  delay_counter;
    reg         flag;
    reg         next_flag;
    reg [31:0]  first_row;
    reg [39:0]  second_row;
    reg [2:0]   char_index;

    parameter S2    = 200000000;
    parameter M30   =   3000000;
    parameter M6    =    600000;
    parameter M1    =    100000;
    parameter U400  =     40000;

    // Helper task for repeated patterns
    task handle_state;
        input [3:0] upper;
        input [3:0] lower;
        input [5:0] next;
        begin
            if ((state != CLEAR_NAME_DELAY && delay_counter == U400) || 
            (state == CLEAR_NAME_DELAY && delay_counter == S2)) begin
                data <= (flag) ? upper : lower;
                next_state <= (flag) ? state : next;
                state <= ENABLE;
                next_flag <= ~flag;
                flag <= 1;
                delay_counter <= 0;
            end else begin
                delay_counter <= delay_counter + 1;
            end
        end
    endtask

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            first_row  = {8'b01001101, 8'b01000001, 8'b01010010, 8'b01001011};
            second_row = {8'b01000011, 8'b01000001, 8'b01000111, 8'b01000001, 8'b01010011};
            state           <= FS_8bit1;
            next_state      <= FS_8bit2;
            delay_counter   <= 0;
            data            <= 4'b0000;
            rs              <= 0;
            en              <= 0;
            flag            <= 1;
            next_flag       <= 1;
            char_index      <= 0;
        end else begin
            case (state)
                ENABLE: begin
                    if (flag) begin // Assert Enable after 400us
                        if (delay_counter == U400) begin
                            en <= 1'b1;
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

                FS_8bit1, FS_8bit2, FS_8bit3, FS_4bit: begin
                    if (delay_counter == (state == FS_8bit1 ? M30 : (state == FS_8bit2 ? M6 : U400))) begin
                        data <= (state == FS_4bit) ? 4'b0010 : 4'b0011; // 4-bit or 8-bit initialization
                        next_state <= state + 1;
                        state <= ENABLE;
                        flag <= 1;
                        next_flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                FS_NF: handle_state(4'b0010, 4'b1000, DISPLAY_OFF);
                DISPLAY_OFF: handle_state(4'b0000, 4'b1000, CLEAR_DISPLAY);
                CLEAR_DISPLAY: handle_state(4'b0000, 4'b0001, ENTRY_MODE);
                ENTRY_MODE: handle_state(4'b0000, 4'b0110, DISPLAY_ON);
                DISPLAY_ON: handle_state(4'b0000, 4'b1111, FN_DELAY);

                FN_DELAY, LN_DELAY: begin // Assert RS
                    if (delay_counter == U400) begin
                        rs <= 1'b1;
                        state <= (state == FN_DELAY) ? FIRST_NAME : LAST_NAME;
                        next_state <= (state == FN_DELAY) ? FIRST_NAME : LAST_NAME;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                FIRST_NAME: begin
                    if (delay_counter == U400) begin
                        if (flag == 1) begin            // Upper
                            case (char_index)
                                0: data <= first_row[31:28]; // 'M'
                                1: data <= first_row[23:20]; // 'A'
                                2: data <= first_row[15:12]; // 'R'
                                3: data <= first_row[7:4];   // 'K'
                            endcase
                            flag <= 1;
                            next_flag <= 0; 
                        end else begin
                            case (char_index)
                                0: data <= first_row[27:24]; // 'M'
                                1: data <= first_row[19:16]; // 'A'
                                2: data <= first_row[11:8];  // 'R'
                                3: data <= first_row[3:0];   // 'K'
                            endcase
                            flag <= 1;
                            next_flag <= 1;
                            char_index <= char_index + 1; 
                        end
                        state <= ENABLE;
                        delay_counter <= 0;

                        if (char_index == 4 && flag == 1) begin
                            char_index <= 0;
                            state <= NEXT_LINE_DELAY;
                        end
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                NEXT_LINE_DELAY: begin
                    if (delay_counter == U400) begin
                        rs <= 1'b0;
                        state <= NEXT_LINE;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                NEXT_LINE: handle_state(4'b1100, 4'b0000, LN_DELAY);

                LAST_NAME: begin
                    if (delay_counter == U400) begin
                        if (flag == 1) begin            // Upper
                            case (char_index)
                                0: data <= second_row[39:36]; // 'C'
                                1: data <= second_row[31:28]; // 'A'
                                2: data <= second_row[23:20]; // 'G'
                                3: data <= second_row[15:12]; // 'A'
                                4: data <= second_row[7:4];   // 'S'
                            endcase
                            flag <= 1;
                            next_flag <= 0; 
                        end else begin
                            case (char_index)
                                0: data <= second_row[35:32]; // 'C'
                                1: data <= second_row[27:24]; // 'A'
                                2: data <= second_row[19:16]; // 'G'
                                3: data <= second_row[11:8];  // 'A'
                                4: data <= second_row[3:0];   // 'S'
                            endcase
                            flag <= 1;
                            next_flag <= 1;
                            char_index <= char_index + 1; 
                        end
                        state <= ENABLE;
                        delay_counter <= 0;

                        if (char_index == 5 && flag == 1) begin
                            char_index <= 0;
                            state <= CLEAR_NAME_DELAY;
                        end
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                CLEAR_NAME_DELAY: begin
                    if (delay_counter == S2) begin
                        rs <= 1'b0;
                        state <= CLEAR_NAME;
                        flag <= 1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                CLEAR_NAME: handle_state(4'b0000, 4'b0001, DONE);

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
