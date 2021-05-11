// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

/// @title Bit Mask Library
/// @author Stephen Chen
/// @notice Implements bit mask with dynamic array
library Bitmask {
    /// @notice Set a bit in the bit mask
    function setBit(
        mapping(uint248 => uint256) storage bitmask,
        uint256 _bit,
        bool _value
    ) public {
        // calculate the number of bits has been store in bitmask now
        uint248 positionOfMask = uint248(_bit / 256);
        uint256 positionOfBit = _bit % 256;

        if (_value) {
            bitmask[positionOfMask] =
                bitmask[positionOfMask] |
                (1 << positionOfBit);
        } else {
            bitmask[positionOfMask] =
                bitmask[positionOfMask] &
                ~(1 << positionOfBit);
        }
    }

    /// @notice Get a bit in the bit mask
    function getBit(mapping(uint248 => uint256) storage bitmask, uint256 _bit)
        public
        view
        returns (bool)
    {
        // calculate the number of bits has been store in bitmask now
        uint248 positionOfMask = uint248(_bit / 256);
        uint256 positionOfBit = _bit % 256;

        return ((bitmask[positionOfMask] & (1 << positionOfBit)) != 0);
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}