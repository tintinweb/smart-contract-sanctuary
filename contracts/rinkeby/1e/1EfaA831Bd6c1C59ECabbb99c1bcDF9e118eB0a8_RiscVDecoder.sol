// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


pragma solidity ^0.7.0;

/// @title Bits Manipulation Library
/// @author Felipe Argento / Stephen Chen
/// @notice Implements bit manipulation helper functions
library BitsManipulationLibrary {

    /// @notice Sign extend a shorter signed value to the full int32
    /// @param number signed number to be extended
    /// @param wordSize number of bits of the signed number, ie, 8 for int8
    function int32SignExtension(int32 number, uint32 wordSize)
    public pure returns(int32)
    {
        uint32 uNumber = uint32(number);
        bool isNegative = ((uint64(1) << (wordSize - 1)) & uNumber) > 0;
        uint32 mask = ((uint32(2) ** wordSize) - 1);

        if (isNegative) {
            uNumber = uNumber | ~mask;
        }

        return int32(uNumber);
    }

    /// @notice Sign extend a shorter signed value to the full uint64
    /// @param number signed number to be extended
    /// @param wordSize number of bits of the signed number, ie, 8 for int8
    function uint64SignExtension(uint64 number, uint64 wordSize)
    public pure returns(uint64)
    {
        uint64 uNumber = number;
        bool isNegative = ((uint64(1) << (wordSize - 1)) & uNumber) > 0;
        uint64 mask = ((uint64(2) ** wordSize) - 1);

        if (isNegative) {
            uNumber = uNumber | ~mask;
        }

        return uNumber;
    }

    /// @notice Swap byte order of unsigned ints with 64 bytes
    /// @param num number to have bytes swapped
    function uint64SwapEndian(uint64 num) public pure returns(uint64) {
        uint64 output = ((num & 0x00000000000000ff) << 56)|
            ((num & 0x000000000000ff00) << 40)|
            ((num & 0x0000000000ff0000) << 24)|
            ((num & 0x00000000ff000000) << 8) |
            ((num & 0x000000ff00000000) >> 8) |
            ((num & 0x0000ff0000000000) >> 24)|
            ((num & 0x00ff000000000000) >> 40)|
            ((num & 0xff00000000000000) >> 56);

        return output;
    }

    /// @notice Swap byte order of unsigned ints with 32 bytes
    /// @param num number to have bytes swapped
    function uint32SwapEndian(uint32 num) public pure returns(uint32) {
        uint32 output = ((num >> 24) & 0xff) | ((num << 8) & 0xff0000) | ((num >> 8) & 0xff00) | ((num << 24) & 0xff000000);
        return output;
    }
}

// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



// @title RiscVDecoder
pragma solidity ^0.7.0;

import "@cartesi/util/contracts/BitsManipulationLibrary.sol";

/// @title RiscVDecoder
/// @author Felipe Argento
/// @notice Contract responsible for decoding the riscv's instructions
//      It applies different bitwise operations and masks to reach
//      specific positions and use that positions to identify the
//      correct function to be executed
library RiscVDecoder {
    /// @notice Get the instruction's RD
    /// @param insn Instruction
    function insnRd(uint32 insn) public pure returns(uint32) {
        return (insn >> 7) & 0x1F;
    }

    /// @notice Get the instruction's RS1
    /// @param insn Instruction
    function insnRs1(uint32 insn) public pure returns(uint32) {
        return (insn >> 15) & 0x1F;
    }

    /// @notice Get the instruction's RS2
    /// @param insn Instruction
    function insnRs2(uint32 insn) public pure returns(uint32) {
        return (insn >> 20) & 0x1F;
    }

    /// @notice Get the I-type instruction's immediate value
    /// @param insn Instruction
    function insnIImm(uint32 insn) public pure returns(int32) {
        return int32(insn) >> 20;
    }

    /// @notice Get the I-type instruction's unsigned immediate value
    /// @param insn Instruction
    function insnIUimm(uint32 insn) public pure returns(uint32) {
        return insn >> 20;
    }

    /// @notice Get the U-type instruction's immediate value
    /// @param insn Instruction
    function insnUImm(uint32 insn) public pure returns(int32) {
        return int32(insn & 0xfffff000);
    }

    /// @notice Get the B-type instruction's immediate value
    /// @param insn Instruction
    function insnBImm(uint32 insn) public pure returns(int32) {
        int32 imm = int32(
            ((insn >> (31 - 12)) & (1 << 12)) |
            ((insn >> (25 - 5)) & 0x7e0) |
            ((insn >> (8 - 1)) & 0x1e) |
            ((insn << (11 - 7)) & (1 << 11))
        );
        return BitsManipulationLibrary.int32SignExtension(imm, 13);
    }

    /// @notice Get the J-type instruction's immediate value
    /// @param insn Instruction
    function insnJImm(uint32 insn) public pure returns(int32) {
        int32 imm = int32(
            ((insn >> (31 - 20)) & (1 << 20)) |
            ((insn >> (21 - 1)) & 0x7fe) |
            ((insn >> (20 - 11)) & (1 << 11)) |
            (insn & 0xff000)
        );
        return BitsManipulationLibrary.int32SignExtension(imm, 21);
    }

    /// @notice Get the S-type instruction's immediate value
    /// @param insn Instruction
    function insnSImm(uint32 insn) public pure returns(int32) {
        int32 imm = int32(((insn & 0xfe000000) >> (25 - 5)) | ((insn >> 7) & 0x1F));
        return BitsManipulationLibrary.int32SignExtension(imm, 12);
    }

    /// @notice Get the instruction's opcode field
    /// @param insn Instruction
    function insnOpcode(uint32 insn) public pure returns (uint32) {
        return insn & 0x7F;
    }

    /// @notice Get the instruction's funct3 field
    /// @param insn Instruction
    function insnFunct3(uint32 insn) public pure returns (uint32) {
        return (insn >> 12) & 0x07;
    }

    /// @notice Get the concatenation of instruction's funct3 and funct7 fields
    /// @param insn Instruction
    function insnFunct3Funct7(uint32 insn) public pure returns (uint32) {
        return ((insn >> 5) & 0x380) | (insn >> 25);
    }

    /// @notice Get the concatenation of instruction's funct3 and funct5 fields
    /// @param insn Instruction
    function insnFunct3Funct5(uint32 insn) public pure returns (uint32) {
        return ((insn >> 7) & 0xE0) | (insn >> 27);
    }

    /// @notice Get the instruction's funct7 field
    /// @param insn Instruction
    function insnFunct7(uint32 insn) public pure returns (uint32) {
        return (insn >> 25) & 0x7F;
    }

    /// @notice Get the instruction's funct6 field
    /// @param insn Instruction
    function insnFunct6(uint32 insn) public pure returns (uint32) {
        return (insn >> 26) & 0x3F;
    }
}