/*
 * Tiny Tapeout - Rock, Paper, Scissors vs the Chip
 * -------------------------------------------------
 * ui_in[1:0] = your move: 01=Rock, 10=Paper, 11=Scissors (00=none)
 * ui_in[2]   = PLAY button: press to lock in your move against the chip
 *
 * uo_out[1:0] = your move, echoed back
 * uo_out[3:2] = the chip's move (same encoding)
 * uo_out[5:4] = result: 00=tie, 01=you win, 10=you lose
 * uo_out[7:6] = unused
 *
 * uio_out[3:0] = running win count   (saturates at 15)
 * uio_out[7:4] = running loss count  (saturates at 15)
 */

`default_nettype none

module tt_um_rock_paper_scissors (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: input path
    output wire [7:0] uio_out,  // IOs: output path
    output wire [7:0] uio_oe,   // IOs: enable path (active high)
    input  wire       ena,      // goes high when design is powered/selected
    input  wire       clk,      // clock
    input  wire        rst_n    // active-low reset
);

    // Bidirectional pins are used as outputs here for the score counters
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
    wire       play_edge = play_btn & ~play_prev;   // rising edge = new play

    // 8-bit Fibonacci LFSR, free-running for the chip's "randomness"
    wire lfsr_fb = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    // Map two raw LFSR bits onto {Rock, Paper, Scissors}; fold the unused
    // 00 case into Rock so the chip never picks an invalid move.
    wire [1:0] cpu_raw = lfsr[1:0];
    wire [1:0] cpu_pick = (cpu_raw == NONE) ? ROCK : cpu_raw;

    // player wins if: rock beats scissors, paper beats rock, scissors beats paper
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
            lfsr          <= 8'hA5;   // non-zero seed
            play_prev     <= 1'b0;
        end else begin
            lfsr      <= {lfsr[6:0], lfsr_fb};   // keep spinning every cycle
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
