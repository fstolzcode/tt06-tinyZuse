# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotbext.uart import UartSource, UartSink

##############
# Test writing to register and overwriting
##############
@cocotb.test()
async def test_setreadr1(dut):
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
  await uart_source.write(b'\x82\x85\xab\x00')
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x85')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x85\xab\x00')

@cocotb.test()
async def test_setreadr2(dut):
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
  await uart_source.write(b'\x83\x82\xe0\x00')
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x86')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x82\xe0\x00')

@cocotb.test()
async def test_setreadoverwrite(dut):
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
  await uart_source.write(b'\x82\x85\xab\x00\x83\x82\xe0\x00\x88')
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x83\xDE\xAD\x11')
  await uart_source.wait()
  await uart_source.write(b'\x86')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\xDE\xAD\x10')

##############
# Test combinations operations for R1 = 42.75, R2 = 7
##############

@cocotb.test()
async def test_alu11(dut):
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
  dut._log.info("Start")
  await uart_source.write(b'\x82\x85\xab\x00\x83\x82\xe0\x00') #R1 = 42.75, R2 = 7.0
  await uart_source.wait()

  dut._log.info("Testing ADD")
  await uart_source.write(b'\x88') # ADD
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\x85\xc7\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SUB")
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x85\x8f\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing MUL")
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x88\x95\xa0')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing DIV")
  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x82\xc3\x6c')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SQRT")
  await uart_source.write(b'\x8C') # SQRT
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x82\xd1\x3a')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')


#############################

@cocotb.test()
async def test_alu10(dut):
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
  dut._log.info("Start")
  await uart_source.write(b'\x82\x85\xab\x00\x83\x02\xe0\x00') #R1 = 42.75, R2 = -7.0
  await uart_source.wait()

  dut._log.info("Testing ADD")
  await uart_source.write(b'\x88') # ADD
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\x85\x8f\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SUB")
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x85\xc7\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing MUL")
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x08\x95\xa0')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing DIV")
  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x02\xc3\x6c')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SQRT")
  await uart_source.write(b'\x8C') # SQRT
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x82\xd1\x3a')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')


#############################

@cocotb.test()
async def test_alu01(dut):
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
  dut._log.info("Start")
  await uart_source.write(b'\x82\x05\xab\x00\x83\x82\xe0\x00') #R1 = -42.75, R2 = 7.0
  await uart_source.wait()

  dut._log.info("Testing ADD")
  await uart_source.write(b'\x88') # ADD
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\x05\x8f\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SUB")
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x05\xc7\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing MUL")
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x08\x95\xa0')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing DIV")
  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x02\xc3\x6c')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SQRT")
  await uart_source.write(b'\x8C') # SQRT
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x82\xd1\x3a')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

#############################

@cocotb.test()
async def test_alu00(dut):
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
  dut._log.info("Start")
  await uart_source.write(b'\x82\x05\xab\x00\x83\x02\xe0\x00') #R1 = -42.75, R2 = -7.0
  await uart_source.wait()

  dut._log.info("Testing ADD")
  await uart_source.write(b'\x88') # ADD
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\x05\xc7\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SUB")
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x05\x8f\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing MUL")
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x88\x95\xa0')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing DIV")
  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x82\xc3\x6c')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SQRT")
  await uart_source.write(b'\x8C') # SQRT
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x82\xd1\x3a')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')


##############
# Test combinations operations for R1 = 7, R2 = 42.75
##############

@cocotb.test()
async def test_alu11r(dut):
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
  dut._log.info("Start")
  await uart_source.write(b'\x83\x85\xab\x00\x82\x82\xe0\x00') # R1 = 7.0, R2 = 42.75
  await uart_source.wait()

  dut._log.info("Testing ADD")
  await uart_source.write(b'\x88') # ADD
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\x85\xc7\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SUB")
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x05\x8f\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing MUL")
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x88\x95\xa0')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing DIV")
  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\xfd\xa7\xac')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SQRT")
  await uart_source.write(b'\x8C') # SQRT
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x81\xa9\x52')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

#############################

@cocotb.test()
async def test_alu10r(dut):
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
  dut._log.info("Start")
  await uart_source.write(b'\x83\x05\xab\x00\x82\x82\xe0\x00') # R1 = 7.0, R2 = -42.75
  await uart_source.wait()

  dut._log.info("Testing ADD")
  await uart_source.write(b'\x88') # ADD
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\x05\x8f\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SUB")
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x85\xc7\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing MUL")
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x08\x95\xa0')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing DIV")
  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x7d\xa7\xac')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SQRT")
  await uart_source.write(b'\x8C') # SQRT
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x81\xa9\x52')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

#############################

@cocotb.test()
async def test_alu01r(dut):
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
  dut._log.info("Start")
  await uart_source.write(b'\x83\x85\xab\x00\x82\x02\xe0\x00') # R1 = -7.0, R2 = 42.75
  await uart_source.wait()

  dut._log.info("Testing ADD")
  await uart_source.write(b'\x88') # ADD
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\x85\x8f\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SUB")
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x05\xc7\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing MUL")
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x08\x95\xa0')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing DIV")
  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x7d\xa7\xac')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SQRT")
  await uart_source.write(b'\x8C') # SQRT
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x81\xa9\x52')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

#############################

@cocotb.test()
async def test_alu00r(dut):
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
  dut._log.info("Start")
  await uart_source.write(b'\x83\x05\xab\x00\x82\x02\xe0\x00') # R1 = -7.0, R2 = -42.75
  await uart_source.wait()

  dut._log.info("Testing ADD")
  await uart_source.write(b'\x88') # ADD
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\x05\xc7\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SUB")
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x85\x8f\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing MUL")
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x88\x95\xa0')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing DIV")
  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\xfd\xa7\xac')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing SQRT")
  await uart_source.write(b'\x8C') # SQRT
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\x81\xa9\x52')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

##############
# Test combinations for special values
##############

@cocotb.test()
async def test_zerohandling(dut):
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
  dut._log.info("Start")

  dut._log.info("Testing 42.75 - 42.75")
  await uart_source.write(b'\x82\x85\xab\x00\x83\x85\xab\x00') #R1 = 42.75, R2 = 42.75
  await uart_source.wait()
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  assert data == bytearray(b'\xc0\x80\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x01')

  dut._log.info("Testing 42.75 * 0")
  await uart_source.write(b'\x82\x85\xab\x00\x83\xc0\x80\x00') #R1 = 42.75, R2 = 0
  await uart_source.wait()

  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\xc0\x80\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x01')

  dut._log.info("Testing 42.75 / 0")

  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\xbf\x80\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

#############################

@cocotb.test()
async def test_infhandling(dut):
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
  dut._log.info("Start")

  dut._log.info("Testing 42.75 - inf")
  await uart_source.write(b'\x82\x85\xab\x00\x83\xbf\xab\x00') #R1 = 42.75, R2 = inf
  await uart_source.wait()
  await uart_source.write(b'\x89') # SUB
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  assert data == bytearray(b'\x3f\x80\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x00')

  dut._log.info("Testing 42.75 * inf")
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()
  
  assert data == bytearray(b'\xbf\x80\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x02')

  dut._log.info("Testing 42.75 / inf")

  await uart_source.write(b'\x8B') # DIV
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x87')
  await uart_source.wait()
  data = await uart_sink.read()
  data += await uart_sink.read()
  data += await uart_sink.read()

  assert data == bytearray(b'\xbf\x80\x00')

  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x01')

#############################

@cocotb.test()
async def test_overunderflow(dut):
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
  dut._log.info("Start")

  dut._log.info("Testing underflow")
  await uart_source.write(b'\x82\xc2\xab\x00\x83\x85\xe0\x00') #R1 exp = - 62, R2 exp = 5
  await uart_source.wait()
  await uart_source.write(b'\x88') # ADD
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x04')

  dut._log.info("Testing overflow (MUL)")
  await uart_source.write(b'\x82\xbe\xab\x00\x83\x85\xff\xff') #R1 exp = + 62, R2 exp = 5
  await uart_source.wait()
  await uart_source.write(b'\x8A') # MUL
  await uart_source.wait()
  await ClockCycles(dut.clk, 100)
  await uart_source.write(b'\x84')
  await uart_source.wait()
  data = await uart_sink.read()
  assert data == bytearray(b'\x02')