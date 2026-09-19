<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

ui_in[1:0] selects your move (01=Rock, 10=Paper, 11=Scissors) and ui_in[2] is the PLAY button. On a rising edge of PLAY, the design samples your move and, in the same cycle, derives the chip's own move from a free-running 8-bit LFSR that keeps spinning every clock cycle so its value is unpredictable when you press PLAY. The two moves are compared: same move is a tie, otherwise standard rock-paper-scissors rules decide the winner. The result and both moves are shown on uo_out. Running win and loss counts (each saturating at 15) are tracked internally and shown on the uio pins.

## How to test

1. Hold reset low then release it (rst_n) with the clock running.
2. Set ui_in[1:0] to your move: 01 for Rock, 10 for Paper, 11 for Scissors.
3. Pulse ui_in[2] high for at least one clock cycle, then back low, to submit your move.
   
4. Read the result:
    uo_out[1:0] — your move, echoed back
    uo_out[3:2] — the chip's move
    uo_out[5:4] — result: 00=tie, 01=you win, 10=you lose
    uio_out[3:0] — running win count
    uio_out[7:4] — running loss count

5. Repeat from step 2 for another round; the counts persist until reset.
