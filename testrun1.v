`timescale 1ns / 1ps

module lcd_init (
    input clk,        // Clock signal
    input nrst,       // Active-low reset signal
    input sw0,
    input btn0,
    input btn1,
    input btn2,
    input btn3,
    output reg [3:0] data, // 4-bit data output to LCD (DB7-DB4)
    output reg rs,    // Register Select (0 for commands, 1 for data)
    output reg rw,    // Read/Write (0 for write, 1 for read)
    output reg en     // Enable signal
);

    // States
    localparam FUNC_SET1        = 5'd0,
               FUNC_SET2        = 5'd1,
               FUNC_SET3        = 5'd2,
               FUNC_SET4        = 5'd3,
               FUNC_SETNF       = 5'd4,
               DISP_OFF         = 5'd5,
               CLEAR_DISP       = 5'd6,
               ENTRY_MODE       = 5'd7,
               DISP_ON          = 5'd8,
               FIRST_NAME_DELAY = 5'd9,
               FIRST_NAME       = 5'd10,
               NEXT_LINE_DELAY  = 5'd11,
               NEXT_LINE        = 5'd12,
               LAST_NAME_DELAY  = 5'd13,
               LAST_NAME        = 5'd14,
               ENABLE           = 5'd15,
               DISABLE          = 5'd16,
               DONE_DELAY       = 5'd17,
               DONE             = 5'd18;

    reg [5:0] state;             // Current state
    reg [5:0] next_state;        // Next state after DISABLE
    reg [31:0] delay_counter;    // Delay counter

    // Clock frequencies and delays
    parameter M30   = 3000000;  // 20 ms delay
    parameter M5    = 500000;   // 5 ms delay
    parameter M1    = 100000;   // 1 ms delay
    parameter U200  = 40000;    // 200 µs delay
    parameter U10   = 1000;
    parameter S2    = 2000000000;
    
    reg [31:0] first_row; 
    reg [39:0] second_row; 
    reg [2:0] char_index = 0;
    reg nibble_flag;      
    reg upper;
    

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            first_row = {8'b01001101,8'b01000001, 8'b01010010,8'b01001011};
            second_row = {8'b01000011,8'b01000001,8'b01000111,8'b01000001,8'b01010011};
            state <= FUNC_SET1;
            next_state <= FUNC_SET2; 
            delay_counter <= M30;
            data <= 4'b0000;
            rs <= 0;
            rw <= 0;
            en <= 0;
            char_index <= 0;
            nibble_flag <= 0;
            upper <= 1;
        end else begin
            case (state)
                FUNC_SET1: begin
                  if (delay_counter == 0) begin
                      data <= 4'b0011;
                      next_state <= FUNC_SET2; 
                      state <= ENABLE;
                      delay_counter <= M5;
                  end else begin
                      delay_counter <= delay_counter - 1;
                  end
                end

                FUNC_SET2: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0011;
                        next_state <= FUNC_SET3; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                FUNC_SET3: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0011;
                        next_state <= FUNC_SET4; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                FUNC_SET4: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0010;
                        next_state <= FUNC_SETNF; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                FUNC_SETNF: begin
                    if (delay_counter == 0) begin
                        if (upper) begin
                            data <= 4'b0010; // Upper nibble
                            next_state <= FUNC_SETNF; // Loop back to send lower nibble
                        end else begin
                            data <= 4'b1000; // Lower nibble
                            next_state <= DISP_OFF; // Move to the next state after sending both nibbles
                        end
                        upper = ~upper; // Toggle upper/lower nibble
                        state <= ENABLE;
                        delay_counter <= U200; // Delay for LCD to process nibble
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end 

                DISP_OFF: begin
                    if (delay_counter == 0) begin
                        if (upper) begin
                            data <= 4'b0000; // Upper nibble of DISP_OFF
                            next_state <= DISP_OFF; // Loop back for lower nibble
                            delay_counter <= U200;
                        end else begin
                            data <= 4'b1000; // Lower nibble of DISP_OFF
                            next_state <= CLEAR_DISP; // Move to CLEAR_DISP after sending both nibbles
                            delay_counter <= M30;
                        end
                        upper = ~upper; // Toggle between upper and lower nibble
                        state <= ENABLE;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                CLEAR_DISP: begin
                    if (delay_counter == 0) begin
                        if (upper) begin
                            data <= 4'b0000; // Upper nibble of CLEAR_DISP
                            next_state <= CLEAR_DISP; // Loop back for lower nibble
                        end else begin
                            data <= 4'b0001; // Lower nibble of CLEAR_DISP
                            next_state <= ENTRY_MODE; // Move to ENTRY_MODE after sending both nibbles
                        end
                        upper = ~upper; // Toggle between upper and lower nibble
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                ENTRY_MODE: begin
                    if (delay_counter == 0) begin
                        if (upper) begin
                            data <= 4'b0000; // Upper nibble of ENTRY_MODE
                            next_state <= ENTRY_MODE; // Loop back for lower nibble
                        end else begin
                            data <= 4'b0110; // Lower nibble of ENTRY_MODE
                            next_state <= DISP_ON; // Move to DISP_ON after sending both nibbles
                        end
                        upper = ~upper; // Toggle between upper and lower nibble
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                DISP_ON: begin
                    if (delay_counter == 0) begin
                        if (upper) begin
                            data <= 4'b0000; // Upper nibble of DISP_ON
                            next_state <= DISP_ON; // Loop back for lower nibble
                            delay_counter <= U200;
                        end else begin
                            data <= 4'b1111; // Lower nibble of DISP_ON
                            next_state <= FIRST_NAME_DELAY; // Move to FIRST_NAME after sending both nibbles
                            delay_counter <= M1;
                        end
                        upper = ~upper; // Toggle between upper and lower nibble
                        state <= ENABLE;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end 
                
                FIRST_NAME_DELAY: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b1;
                        state <= FIRST_NAME;
                        next_state <= FIRST_NAME;
                        delay_counter <= M1;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                FIRST_NAME: begin
                    if (delay_counter == 0) begin
                        if (!nibble_flag) begin
                            case (char_index)
                                0: data <= first_row[31:28]; // 'M'
                                1: data <= first_row[23:20]; // 'A'
                                2: data <= first_row[15:12]; // 'R'
                                3: data <= first_row[7:4];   // 'K'
                            endcase
                            nibble_flag <= 1; // Switch to lower nibble
                        end else begin
                            case (char_index)
                            0: data <= first_row[27:24]; // 'M'
                            1: data <= first_row[19:16]; // 'A'
                            2: data <= first_row[11:8];  // 'R'
                            3: data <= first_row[3:0];   // 'K'
                            endcase
                            nibble_flag <= 0; // Reset nibble flag
                            char_index <= char_index + 1; // Move to next character
                        end
                        state <= ENABLE;
                        delay_counter <= U200;

                        if (char_index == 4 && nibble_flag == 0) begin
                            char_index <= 0; // Reset index for future use
                            state <= NEXT_LINE_DELAY; // Move to the next state
                            delay_counter <= U200;
                        end
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                NEXT_LINE_DELAY: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b0; // Command mode
                        state <= NEXT_LINE; // Move to NEXT_LINE state
                        delay_counter <= M1; // Delay for processing
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                NEXT_LINE: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b0; // Command mode
                        if (upper) begin
                            data <= 4'b1100; // Upper nibble of 0xC0 (set DDRAM address for the second line)
                            next_state <= NEXT_LINE; // Loop back for lower nibble
                            delay_counter <= U200;
                        end else begin
                            data <= 4'b0000; // Lower nibble of 0xC0
                            next_state <= LAST_NAME_DELAY; // Move to the next state after sending both nibbles
                            delay_counter <= M1;
                        end
                        upper = ~upper; // Toggle between upper and lower nibble
                        state <= ENABLE;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                LAST_NAME_DELAY: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b1;
                        state <= LAST_NAME;
                        next_state <= LAST_NAME;
                        delay_counter <= M1;
                        nibble_flag <= 0;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
              
                LAST_NAME: begin
                    if (delay_counter == 0) begin
                        if (!nibble_flag) begin
                            case (char_index)
                                0: data <= second_row[39:36]; // 'C'
                                1: data <= second_row[31:28]; // 'A'
                                2: data <= second_row[23:20]; // 'G'
                                3: data <= second_row[15:12];  // 'A'
                                4: data <= second_row[7:4];   // 'S'
                            endcase
                            nibble_flag <= 1;
                        end else begin
                            case (char_index)
                                0: data <= second_row[35:32]; // 'C'
                                1: data <= second_row[27:24]; // 'A'
                                2: data <= second_row[19:16]; // 'G'
                                3: data <= second_row[11:8]; // 'A'
                                4: data <= second_row[3:0];   // 'S'
                            endcase
                            nibble_flag <= 0; // Reset nibble flag
                            char_index <= char_index + 1; // Move to next character
                        end
                        state <= ENABLE;
                        delay_counter <= U200;
    
                        if (char_index == 5 && nibble_flag == 0) begin
                            char_index <= 0; // Reset index
                            delay_counter <= U200;
                            state <= DONE_DELAY;
                        end
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                DONE_DELAY: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b0; // Command mode
                        if (upper) begin
                            data <= 4'b0000; // Upper nibble of the clear display command (0x01)
                            next_state <= DONE_DELAY; // Loop back for lower nibble
                        end else begin
                            data <= 4'b0001; // Lower nibble of the clear display command
                            next_state <= DONE; // Move to IDLE or final state after sending both nibbles
                        end
                        upper = ~upper; // Toggle between upper and lower nibble
                        state <= ENABLE;
                        delay_counter <= U200; // Set delay for LCD to process nibble
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end 
                end 
                
                DONE: begin
                    if (delay_counter == 0) begin
                        char_index <= 0;
                        nibble_flag <= 0;
                        data <= 4'b0000;
                        delay_counter <= 0;
                        state <= DONE; // System remains idle here indefinitely
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end 
                end
            
                ENABLE: begin
                    if (delay_counter == 0) begin
                        en <= 1;
                        state <= DISABLE;
                        delay_counter <= M1;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                DISABLE: begin
                    if (delay_counter == 0) begin
                        en <= 0;
                        state <= next_state;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                default: state <= FUNC_SET1;
            endcase 
        end
    end
endmodule
