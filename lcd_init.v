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
               FUNC_SETNF_U     = 5'd4,
               FUNC_SETNF_L     = 5'd5,
               DISP_OFF_U       = 5'd6,
               DISP_OFF_L       = 5'd7,
               CLEAR_DISP_U     = 5'd8,
               CLEAR_DISP_L     = 5'd9,
               CLEAR_DELAY      = 5'd10,
               ENTRY_MODE_U     = 5'd11,
               ENTRY_MODE_L     = 5'd12,
               ENTRY_DELAY      = 5'd13,
               DISP_ON_U        = 5'd14,
               DISP_ON_L        = 5'd15,
               DISP_DELAY       = 5'd16,
               FIRST_NAME_U     = 5'd17,
               FIRST_NAME_L     = 5'd18,
               NEXT_LINE_U      = 5'd19,
               NEXT_LINE_L      = 5'd20,
               LAST_NAME_U      = 5'd21,
               LAST_NAME_L      = 5'd22,
               DELAY_20MS       = 5'd23,
               DELAY_5MS        = 5'd24,
               DELAY_200US      = 5'd25,
               DELAY_1MS        = 5'd26,
               ENABLE           = 5'd27,
               DISABLE          = 5'd28;

    reg [4:0] state;             // Current state
    reg [4:0] next_state;        // Next state after DISABLE
    reg [31:0] delay_counter;    // Delay counter

    // Clock frequencies and delays
    parameter M20   = 2000000;  // 20 ms delay
    parameter M5    = 500000;   // 5 ms delay
    parameter M1    = 100000;   // 1 ms delay
    parameter U200  = 20000;    // 200 µs delay
    parameter U10   = 1000;
    parameter S2    = 2000000000;
    
    reg [31:0] first_row; // Flat array to hold "MARK"
    integer char_index = 0; // Index for the current character (0 to 3)
    reg nibble_flag;       // 0 for upper nibble, 1 for lower nibble
    
    initial begin
        first_row = {8'b01001101,  // 'M'
            8'b01000001, // 'A'
            8'b01010010, // 'R'
            8'b01001011, // 'K'          
        };
    end

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            state <= FUNC_SET1;
            next_state <= FUNC_SET2; 
            delay_counter <= M20;
            data <= 4'b0000;
            rs <= 0;
            rw <= 0;
            en <= 0;
            char_index <= 0;
            nibble_flag <= 0;
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
                        next_state <= FUNC_SETNF_U; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                FUNC_SETNF_U: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0010;
                        next_state <= FUNC_SETNF_L; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                FUNC_SETNF_L: begin
                    if (delay_counter == 0) begin
                        data <= 4'b1000;
                        next_state <= DISP_OFF_U; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                DISP_OFF_U: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0000;
                        next_state <= DISP_OFF_L; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                DISP_OFF_L: begin
                    if (delay_counter == 0) begin
                        data <= 4'b1000;
                        next_state <= CLEAR_DISP_U; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                CLEAR_DISP_U: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0000;
                        next_state <= CLEAR_DISP_L; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                CLEAR_DISP_L: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0001;
                        next_state <= ENTRY_MODE_U; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                ENTRY_MODE_U: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0000;
                        next_state <= ENTRY_MODE_L; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                ENTRY_MODE_L: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0110;
                        next_state <= DISP_ON_U; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                DISP_ON_U: begin
                    if (delay_counter == 0) begin
                        data <= 4'b0000;
                        next_state <= DISP_ON_L; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

                DISP_ON_L: begin
                    if (delay_counter == 0) begin
                        data <= 4'b1111;
                        next_state <= FIRST_NAME_U; // Specify the next state after DISABLE
                        state <= ENABLE;
                        delay_counter <= M1;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end

            FIRST_NAME_U: begin
                if (delay_counter == 0) begin
                    rs <= 1'b1; // Data mode
                    if (!nibble_flag) begin
                        // Access the upper nibble of the current character
                        case (char_index)
                            0: data <= first_row[31:28]; // 'M'
                            1: data <= first_row[23:20]; // 'A'
                            2: data <= first_row[15:12]; // 'R'
                            3: data <= first_row[7:4];   // 'K'
                        endcase
                        nibble_flag <= 1; // Switch to lower nibble
                    end else begin
                        // Access the lower nibble of the current character
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

                    // Check if all characters are sent
                    if (char_index == 4 && nibble_flag == 0) begin
                        char_index <= 0; // Reset index for future use
                        state <= NEXT_LINE_U; // Move to the next state
                    end
                end else begin
                    delay_counter <= delay_counter - 1;
                end
            end

                FIRST_NAME_L: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b1;
                        data <= 4'b1101;
                        state <= ENABLE;
                        next_state <= NEXT_LINE_U;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                NEXT_LINE_U: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b0;
                        rw <= 1'b0;
                        data <= 4'b1100;
                        state <= ENABLE;
                        next_state <= NEXT_LINE_L;
                        delay_counter <= U10;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                NEXT_LINE_L: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b0;
                        rw <= 1'b0;
                        data <= 4'b0000;
                        state <= ENABLE;
                        next_state <= LAST_NAME_U;
                        delay_counter <= U200;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                LAST_NAME_U: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b0;
                        rw <= 1'b0;
                        data <= 4'b0100;
                        state <= ENABLE;
                        next_state <= LAST_NAME_L;
                        delay_counter <= U10;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                LAST_NAME_L: begin
                    if (delay_counter == 0) begin
                        rs <= 1'b0;
                        rw <= 1'b0;
                        data <= 4'b0011;
                        state <= ENABLE;
                        next_state <= CLEAR_DISP_U;
                        delay_counter <= S2;
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
