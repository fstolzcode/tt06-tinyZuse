# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotbext.uart import UartSource, UartSink

@cocotb.test()
async def test_adder(dut):
  dut._log.info("Start")
  
  # Our example module doesn't use clock and reset, but we show how to use them here anyway.
  clock = Clock(dut.clk, 100, units="ns")
  cocotb.start_soon(clock.start())

  uart_source = UartSource(dut.rx, baud=9600, bits=8)
  uart_sink = UartSink(dut.tx, baud=9600, bits=8)
  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 10)
  await uart_source.write(b'\x81\x82\x70\x00\x82\x85\x55\x80\xA0')
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x90')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x85c\x80')
 