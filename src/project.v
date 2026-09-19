`default_nettype none

module tt_um_froileneee_rps (
    input  wire [7:0] ui_in,   
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,  
    output wire [7:0] uio_out, 
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire        rst_n    
);

    assign uio_oe = 8'hFF;

    wire _unused = &{ui_in[7:3], uio_in, ena, 1'b0};

    localparam NONE     = 2'b00;
    localparam ROCK     = 2'b01;
    localparam PAPER    = 2'b10;
    localparam SCISSORS = 2'b11;

    reg [1:0] player_choice, cpu_choice, result;
    reg [3:0] win_cnt, lose_cnt;
    reg [7:0] lfsr;
    reg       play_prev;

    wire [1:0] player_in = ui_in[1:0];
    wire       play_btn  = ui_in[2];
    wire       play_edge = play_btn & ~play_prev;   

    wire lfsr_fb = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    wire [1:0] cpu_raw = lfsr[1:0];
    wire [1:0] cpu_pick = (cpu_raw == NONE) ? ROCK : cpu_raw;

    wire player_wins = (player_in == ROCK     && cpu_pick == SCISSORS) ||
                        (player_in == PAPER    && cpu_pick == ROCK)     ||
                        (player_in == SCISSORS && cpu_pick == PAPER);
    wire is_tie      = (player_in == cpu_pick);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            player_choice <= NONE;
            cpu_choice    <= NONE;
            result        <= 2'b00;
            win_cnt       <= 4'd0;
            lose_cnt      <= 4'd0;
            lfsr          <= 8'hA5;  
            play_prev     <= 1'b0;
        end else begin
            lfsr      <= {lfsr[6:0], lfsr_fb};  
            play_prev <= play_btn;

            if (play_edge && player_in != NONE) begin
                player_choice <= player_in;
                cpu_choice    <= cpu_pick;

                if (is_tie) begin
                    result <= 2'b00;
                end else if (player_wins) begin
                    result  <= 2'b01;
                    win_cnt <= (win_cnt == 4'hF) ? win_cnt : win_cnt + 4'd1;
                end else begin
                    result   <= 2'b10;
                    lose_cnt <= (lose_cnt == 4'hF) ? lose_cnt : lose_cnt + 4'd1;
                end
            end
        end
    end

    assign uo_out[1:0] = player_choice;
    assign uo_out[3:2] = cpu_choice;
    assign uo_out[5:4] = result;
    assign uo_out[7:6] = 2'b00;

    assign uio_out[3:0] = win_cnt;
    assign uio_out[7:4] = lose_cnt;

endmodule
