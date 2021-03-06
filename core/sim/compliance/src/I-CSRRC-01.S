# RISC-V Compliance Test I-CSRRC-01
#
# Copyright (c) 2017, Codasip Ltd.
# Copyright (c) 2018, Imperas Software Ltd. Additions
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#      * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#      * Neither the name of the Codasip Ltd., Imperas Software Ltd. nor the
#        names of its contributors may be used to endorse or promote products
#        derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Codasip Ltd., Imperas Software Ltd.
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Specification: RV32I Base Integer Instruction Set, Version 2.0
# Description: Testing instruction CSRRC.

#include "compliance_test.h"
#include "compliance_io.h"
#include "test_macros.h"

# Test Virtual Machine (TVM) used by program.
RV_COMPLIANCE_RV32M

# Test code region.
RV_COMPLIANCE_CODE_BEGIN

  RVTEST_IO_INIT
  RVTEST_IO_ASSERT_GPR_EQ(sp, x0, 0x00000000)
  RVTEST_IO_WRITE_STR(sp, "# Test Begin\n")

  # ---------------------------------------------------------------------------------------------
  RVTEST_IO_WRITE_STR(sp, "# Test part A1 - general test of csrrc\n");

  # Address for test results
  la x2, test_A1_res

  # Register initialization
  li x4, 1
  li x5, 0
  li x6, 0x7FF0FFFF
  li x7, 0x80000000
  li x8, -1
  csrrw x0, mepc, x8

  # Test
  csrrc x4, mepc, x4
  csrrw x4, mepc, x8

  csrrc x5, mepc, x5
  csrrw x5, mepc, x8

  csrrc x6, mepc, x6
  csrrw x6, mepc, x8

  csrrc x7, mepc, x7
  csrrw x7, mepc, x8

  csrrc x8, mepc, x8
  csrrw x8, mepc, x0

  # Store results
  sw x0, 0(x2)
  sw x4, 4(x2)
  sw x5, 8(x2)
  sw x6, 12(x2)
  sw x7, 16(x2)
  sw x8, 20(x2)

  //
  // Assert
  //
  RVTEST_IO_CHECK()
  RVTEST_IO_ASSERT_GPR_EQ(sp, x0, 0x00000000)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x4, 0xFFFFFFFC)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x5, 0xFFFFFFFC)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x6, 0x800F0000)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x7, 0x7FFFFFFC)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x8, 0x00000000)

  RVTEST_IO_WRITE_STR(sp, "# Test part A1 - Complete\n");

  # ---------------------------------------------------------------------------------------------
  RVTEST_IO_WRITE_STR(sp, "# Test part A2 - general test of csrrc\n");

  # Address for test results
  la x2, test_A2_res

  # Register initialization
  li x4, 1
  li x5, 0
  li x6, 0x7FF0FFFF
  li x7, 0x80000000
  li x8, -1
  csrrw x0, mepc, x8

  # Test
  csrrc x4, mepc, x4
  csrrc x5, mepc, x5
  csrrc x6, mepc, x6
  csrrc x7, mepc, x7
  csrrc x8, mepc, x8
  csrrc x9, mepc, x0

  # Store results
  sw x4, 0(x2)
  sw x5, 4(x2)
  sw x6, 8(x2)
  sw x7, 12(x2)
  sw x8, 16(x2)
  sw x9, 20(x2)

  RVTEST_IO_ASSERT_GPR_EQ(sp, x4, 0xFFFFFFFC)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x5, 0xFFFFFFFC)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x6, 0xFFFFFFFC)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x7, 0x800F0000)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x8, 0x000F0000)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x9, 0x00000000)

  RVTEST_IO_WRITE_STR(sp, "# Test part A2 - Complete\n");

  # ---------------------------------------------------------------------------------------------
  RVTEST_IO_WRITE_STR(sp, "# Test part B - testing forwarding between instructions\n");

  # Address for test results
  la x2, test_B_res

  # Register initialization
  li x4, 0x12345678
  li x3, -1
  csrrw x0, mepc, x3

  # Test
  csrrc x5, mepc, x4
  csrrc x4, mepc, x5
  csrrw x6, mepc, x3
  csrrc x7, mepc, x6
  csrrc x8, mepc, x0

  # store results
  sw x4, 0(x2)
  sw x5, 4(x2)
  sw x6, 8(x2)
  sw x7, 12(x2)
  sw x8, 16(x2)

  RVTEST_IO_ASSERT_GPR_EQ(sp, x4, 0xEDCBA984)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x5, 0xFFFFFFFC)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x6, 0x00000000)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x7, 0xFFFFFFFC)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x8, 0xFFFFFFFC)

  RVTEST_IO_WRITE_STR(sp, "# Test part B - Complete\n");

  # ---------------------------------------------------------------------------------------------
  RVTEST_IO_WRITE_STR(sp, "# Test part C - testing writing to x0 and reading from x0\n");

  # Address for test results
  la x2, test_C_res

  # Register initialization
  li x4, 0x42726E6F
  csrrw x0, mepc, x4

  # Test
  csrrc x0, mepc, x4

  # store results
  sw x0, 0(x2)
  sw x4, 4(x2)

  RVTEST_IO_ASSERT_GPR_EQ(sp, x0, 0x00000000)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x4, 0x42726e6f)

  RVTEST_IO_WRITE_STR(sp, "# Test part C - Complete\n");

  # ---------------------------------------------------------------------------------------------
  RVTEST_IO_WRITE_STR(sp, "# Test part D - testing forwarding throught x0\n");

  # Address for test results
  la x2, test_D_res

  # Register initialization
  li x4, 0xF7FF8818
  csrrw x0, mepc, x4

  # Test
  csrrc x0, mepc, x0
  csrrc x0, mepc, x0
  csrrc x4, mepc, x0

  # store results
  sw x0, 0(x2)
  sw x4, 4(x2)

  RVTEST_IO_ASSERT_GPR_EQ(sp, x0, 0x00000000)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x4, 0xF7FF8818)

  RVTEST_IO_WRITE_STR(sp, "# Test part D - Complete\n");

  # ---------------------------------------------------------------------------------------------
  RVTEST_IO_WRITE_STR(sp, "# Test part E - testing csrrc with same dst and src registers\n");

  # Address for test results
  la x2, test_E_res

  # Register initialization
  li x4, -1
  li x5, 0x96385274
  li x7, 0x32165498
  csrrw x0, mepc, x4

  # Test
  csrrc x5, mepc, x5
  csrrc x7, mepc, x7
  csrrc x8, mepc, x8

  # Store results
  sw x5, 0(x2)
  sw x7, 4(x2)
  sw x8, 8(x2)

  RVTEST_IO_ASSERT_GPR_EQ(sp, x5, 0xFFFFFFFC)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x7, 0x69C7AD88)
  RVTEST_IO_ASSERT_GPR_EQ(sp, x8, 0x49C1A900)

  RVTEST_IO_WRITE_STR(sp, "# Test part E - Complete\n");

  RVTEST_IO_WRITE_STR(sp, "# Test End\n")

 # ---------------------------------------------------------------------------------------------
  # HALT
  RV_COMPLIANCE_HALT

RV_COMPLIANCE_CODE_END

# Input data section.
  .section .rodata
  .align 4


# Output data section.
RV_COMPLIANCE_DATA_BEGIN
  .align 4

test_A1_res:
  .fill 6, 4, -1
test_A2_res:
  .fill 6, 4, -1
test_B_res:
  .fill 5, 4, -1
test_C_res:
  .fill 2, 4, -1
test_D_res:
  .fill 2, 4, -1
test_E_res:
  .fill 3, 4, -1

RV_COMPLIANCE_DATA_END     # End of test output data region.
