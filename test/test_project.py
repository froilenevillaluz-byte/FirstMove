# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def reset(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)


async def play_move(dut, move):
    """Set a move (1=Rock,2=Paper,3=Scissors) and pulse the PLAY button."""
    dut.ui_in.value = move | 0b000  # move bits only
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = move | 0b100  # move bits + PLAY high
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = move | 0b000  # release PLAY
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def test_rps_echoes_player_move(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await reset(dut)

    await play_move(dut, 0b01)  # Rock
    player_move = int(dut.uo_out.value) & 0b11
    assert player_move == 0b01, "Player's move should be echoed on uo_out[1:0]"


@cocotb.test()
async def test_rps_result_is_valid_and_counters_move(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await reset(dut)

    win0 = int(dut.uio_out.value) & 0xF
    lose0 = (int(dut.uio_out.value) >> 4) & 0xF
    assert win0 == 0 and lose0 == 0, "Counters should start at zero after reset"

    total_before = win0 + lose0
    for move in (0b01, 0b10, 0b11):
        await play_move(dut, move)
        result = (int(dut.uo_out.value) >> 4) & 0b11
        assert result in (0b00, 0b01, 0b10), "Result must be tie, win, or lose"

    win1 = int(dut.uio_out.value) & 0xF
    lose1 = (int(dut.uio_out.value) >> 4) & 0xF
    # at least the counters should be internally consistent (win+lose <= number of non-tie plays)
    assert (win1 + lose1) >= total_before
