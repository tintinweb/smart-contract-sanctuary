// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// This library extracts data from Block header encoded in RLP format.
// It is not a complete implementation, but optimized for specific cases - thus many hardcoded values.
// Here's the current RLP structure and the values we're looking for:
//
// idx  Element                 element length with 1 byte storing its length
// ==========================================================================
// Static elements (always same size):
//
// 0    RLP length              1+2
// 1    parentHash              1+32
// 2    ommersHash              1+32
// 3    beneficiary             1+20
// 4    stateRoot               1+32
// 5    TransactionRoot         1+32
// 6    receiptsRoot            1+32
//      logsBloom length        1+2
// 7    logsBloom               256
//                              =========
//  Total static elements size: 448 bytes
//
// Dynamic elements (need to read length) start at position 448
// and each one is preceeded with 1 byte length (if element is >= 128)
// or if element is < 128 - then length byte is skipped and it is just the 1-byte element:
//
// 8	difficulty  - starts at pos 448
// 9	number      - blockNumber
// 10	gasLimit
// 11	gasUsed
// 12	timestamp
// 13	extraData
// 14	mixHash
// 15	nonce

// SAFEMATH DISCLAIMER:
// We and don't use SafeMath here intentionally, because input values are bytes in a byte-array, thus limited to 255
library HeaderRLP {
    function checkBlockHash(bytes calldata rlp) external view returns (uint256) {
        uint256 rlpBlockNumber = getBlockNumber(rlp);

        require(
            blockhash(rlpBlockNumber) == keccak256(rlp), // blockhash() costs 20 now but it may cost 5000 in the future
            "HeaderRLP.checkBlockHash: Block hashes don't match"
        );
        return rlpBlockNumber;
    }

    function nextElementJump(uint8 prefix) public pure returns (uint8) {
        // RLP has much more options for element lenghts
        // But we are safe between 56 bytes and 2MB
        if (prefix <= 128) {
            return 1;
        } else if (prefix <= 183) {
            return prefix - 128 + 1;
        }
        revert("HeaderRLP.nextElementJump: Given element length not implemented");
    }

    // no loop saves ~300 gas
    function getBlockNumberPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    // no loop saves ~300 gas
    function getGasLimitPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        //3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    // no loop saves ~300 gas
    function getTimestampPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        //3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));
        //4th element - gas used
        pos += nextElementJump(uint8(rlp[pos]));
        //timestamp - jackpot!
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    function getBaseFeePositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        //jumping straight to the 1st dynamic element at pos 448 - difficulty
        uint256 pos = 448;

        // 2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        // 3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));
        // 4th element - gas used
        pos += nextElementJump(uint8(rlp[pos]));
        // timestamp
        pos += nextElementJump(uint8(rlp[pos]));
        // extradata
        pos += nextElementJump(uint8(rlp[pos]));
        // mixhash
        pos += nextElementJump(uint8(rlp[pos]));
        // nonce
        pos += nextElementJump(uint8(rlp[pos]));
        // nonce
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    function extractFromRLP(bytes calldata rlp, uint256 elementPosition) public pure returns (uint256 element) {
        // RLP hint: If the byte is less than 128 - than this byte IS the value needed - just return it.
        if (uint8(rlp[elementPosition]) < 128) {
            return uint256(uint8(rlp[elementPosition]));
        }

        // RLP hint: Otherwise - this byte stores the length of the element needed (in bytes).
        uint8 elementSize = uint8(rlp[elementPosition]) - 128;

        // ABI Encoding hint for dynamic bytes element:
        //  0x00-0x04 (4 bytes): Function signature
        //  0x05-0x23 (32 bytes uint): Offset to raw data of RLP[]
        //  0x24-0x43 (32 bytes uint): Length of RLP's raw data (in bytes)
        //  0x44-.... The RLP raw data starts here
        //  0x44 + elementPosition: 1 byte stores a length of our element
        //  0x44 + elementPosition + 1: Raw data of the element

        // Copies the element from calldata to uint256 stored in memory
        assembly {
            calldatacopy(
                add(mload(0x40), sub(32, elementSize)), // Copy to: Memory 0x40 (free memory pointer) + 32bytes (uint256 size) - length of our element (in bytes)
                add(0x44, add(elementPosition, 1)), // Copy from: Calldata 0x44 (RLP raw data offset) + elementPosition + 1 byte for the size of element
                elementSize
            )
            element := mload(mload(0x40)) // Load the 32 bytes (uint256) stored at memory 0x40 pointer - into return value
        }
        return element;
    }

    function getBlockNumber(bytes calldata rlp) public pure returns (uint256 bn) {
        return extractFromRLP(rlp, getBlockNumberPositionNoLoop(rlp));
    }

    function getTimestamp(bytes calldata rlp) external pure returns (uint256 ts) {
        return extractFromRLP(rlp, getTimestampPositionNoLoop(rlp));
    }

    function getDifficulty(bytes calldata rlp) external pure returns (uint256 diff) {
        return extractFromRLP(rlp, 448);
    }

    function getGasLimit(bytes calldata rlp) external pure returns (uint256 gasLimit) {
        return extractFromRLP(rlp, getGasLimitPositionNoLoop(rlp));
    }

    function getBaseFee(bytes calldata rlp) external pure returns (uint256 baseFee) {
        return extractFromRLP(rlp, getBaseFeePositionNoLoop(rlp));
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}