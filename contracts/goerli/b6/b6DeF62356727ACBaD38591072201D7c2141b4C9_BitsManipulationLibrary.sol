// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

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

