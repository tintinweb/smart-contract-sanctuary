/**
 *Submitted for verification at polygonscan.com on 2021-12-01
*/

// File: IRelay.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IRelay {
    /**
    * @param digest block header hash of block header submitted for storage
    * @param height height of the stored block
    */
    event StoreHeader(bytes32 indexed digest, uint32 indexed height);

    /**
    * @param mintCounter new mint counter
    */
    event MintCounter( uint256 indexed mintCounter);

    /**
    * @param from previous best block hash
    * @param to new best block hash
    * @param id identifier of the fork triggering the reorg
    */
    event ChainReorg(bytes32 indexed from, bytes32 indexed to, uint256 indexed id);

    /**
    * @param from sender's address
    * @param relaydata bitcoin data
    */
    event Data(address indexed from, bytes relaydata);

    /**
    * @param from sender's address
    * @param relaydata bitcoin data
    */
    event DataMRC20(address indexed from, bytes relaydata);

    /**
    * @param from sender's address
    * @param btcAddress bitcoin address
    * @param id UUID
    */
    event txProcessed(address indexed from, bytes btcAddress, uint256 id);

    /**
    * @param from sender's address
    * @param relaydata bitcoin data
    * @param confirmations current confirmations
    * @param txfees bridging fee
    */
    event ConfirmationsData(address indexed from, bytes relaydata, uint256 indexed confirmations, uint256 indexed txfees);

    /**
    * @notice Parses, validates and stores a block header
    * @param height Height of block that included transaction
    * @param header Raw block header bytes (80 bytes)
    */
    function reinitialize(bytes calldata header, uint32 height) external;

    /**
    * @notice Parses, validates and stores a block header
    * @param header Raw block header bytes (80 bytes)
    */
    function submitBlockHeader(bytes calldata header) external;

    /**
    * @notice Parses, validates and sets current height
    * @param height current heigh
    */
    function setCurrentHeight(uint32 height) external;

    /**
    * @notice Parses, validates and stores a batch of headers
    * @param headers Raw block headers (80* bytes)
    */
    function submitBlockHeaderBatch(bytes calldata headers) external;

    /**
    * @notice Gets the height of an included block
    * @param digest Hash of the referenced block
    * @return Height of the stored block, reverts if not found
    */
    function getBlockHeight(bytes32 digest) external view returns (uint32);

    /**
    * @notice Gets the hash of an included block
    * @param height Height of the referenced block
    * @return Hash of the stored block, reverts if not found
    */
    function getBlockHash(uint32 height) external view returns (bytes32);

    /**
    * @notice Gets the hash and height for the best tip
    * @return digest Hash of stored block
    * @return height Height of stored block
    */
    function getBestBlock() external view returns (bytes32 digest, uint32 height);

    /**
    * @notice Gets the hash and height for the current tip
    * @return digest Hash of stored block
    * @return height Height of stored block
    */
    function getCurrentBlock() external view returns (bytes32 digest, uint32 height);


    /**
    * @notice Set mint counter
    * @param id Id to be set as a current mint
    * @return True if Mint counter is set
    */
    function setMintCounter(uint id) external returns (bool);

    /**
    * @notice Processes tx
    * @param btcAddress Bitcoin address
    * @param id UUID
    * @return True if Tx is processed
    */
    function processTx(bytes memory btcAddress, uint256 id) external returns (bool);

    /**
    * @notice Return list of pending mints of an account
    * @param ethAddress user's ethereum address
    * @return list of ids of pending mints
    */
    function getPendingMints(address ethAddress) external view returns(uint[] memory);

    /**
    * @notice Return list of completed mints of an account
    * @param ethAddress user's ethereum address
    * @return list of ids of completed mints
    */
    function getCompletedMints(address ethAddress) external view returns(uint[] memory);
}

// File: BytesLib.sol



pragma solidity ^0.6.12;

/*

https://github.com/GNSPS/solidity-bytes-utils/

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
*/


/** @title BytesLib **/
/** @author https://github.com/GNSPS **/

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
            tempBytes := mload(0x40)

        // Store the length of the first bytes array at the beginning of
        // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

        // Maintain a memory counter for the current write location in the
        // temp bytes array by adding the 32 bytes for the array length to
        // the starting location.
            let mc := add(tempBytes, 0x20)
        // Stop copying when the memory counter reaches the length of the
        // first bytes array.
            let end := add(mc, length)

            for {
            // Initialize a copy counter to the start of the _preBytes data,
            // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
            // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
            // Write the _preBytes data into the tempBytes memory 32 bytes
            // at a time.
                mstore(mc, mload(cc))
            }

        // Add the length of _postBytes to the current length of tempBytes
        // and store it as the new length in the first 32 bytes of the
        // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

        // Move the memory counter back from a multiple of 0x20 to the
        // actual end of the _preBytes data.
            mc := end
        // Stop copying when the memory counter reaches the new combined
        // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

        // Update the free-memory pointer by padding our last write location
        // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
        // next 32 byte block, then round down to the nearest multiple of
        // 32. If the sum of the length of the two arrays is zero then add
        // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
        // Read the first 32 bytes of _preBytes storage, which is the length
        // of the array. (We don't need to use the offset into the slot
        // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
        // Arrays of 31 bytes or less have an even value in their slot,
        // while longer arrays have an odd value. The actual length is
        // the slot divided by two for odd values, and the lowest order
        // byte divided by two for even values.
        // If the slot is even, bitwise and the slot with 255 and divide by
        // two to get the length. If the slot is odd, bitwise and the slot
        // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
            // Since the new array still fits in the slot, we just need to
            // update the contents of the slot.
            // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                _preBytes_slot,
                // all the modifications to the slot are inside this
                // next block
                add(
                // we can just add to the slot contents because the
                // bytes we want to change are the LSBs
                fslot,
                add(
                mul(
                div(
                // load the bytes from memory
                mload(add(_postBytes, 0x20)),
                // zero all bytes to the right
                exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
                ),
                // increase length by the double of the memory
                // bytes length
                mul(mlength, 2)
                )
                )
                )
            }
            case 1 {
            // The stored value fits in the slot, but the combined value
            // will exceed it.
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

            // The contents of the _postBytes array start 32 bytes into
            // the structure. Our first read should obtain the `submod`
            // bytes that can fit into the unused space in the last word
            // of the stored array. To get this, we read 32 bytes starting
            // from `submod`, so the data we read overlaps with the array
            // contents by `submod` bytes. Masking the lowest-order
            // `submod` bytes allows us to add that value directly to the
            // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                sc,
                add(
                and(
                fslot,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ),
                and(mload(mc), mask)
                )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
            // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

            // Copy over the first `submod` bytes of the new data as in
            // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint _start, uint _length) internal pure returns (bytes memory res) {
        if (_length == 0) {
            return hex"";
        }
        uint _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
        // Alloc bytes array with additional 32 bytes afterspace and assign it's size
            res := mload(0x40)
            mstore(0x40, add(add(res, 64), _length))
            mstore(res, _length)

        // Compute distance between source and destination pointers
            let diff := sub(res, add(_bytes, _start))

            for {
                let src := add(add(_bytes, 32), _start)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
            } {
                mstore(add(src, diff), mload(src))
            }
        }
    }

    function toAddress(bytes memory _bytes, uint _start) internal pure returns (address) {
        uint _totalLen = _start + 20;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Address conversion out of bounds.");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes memory _bytes, uint _start) internal pure returns (uint256) {
        uint _totalLen = _start + 32;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Uint conversion out of bounds.");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

        // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                    // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
        // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
        // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

        // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                    // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                        // unsuccess:
                            success := 0
                        }
                    }
                    default {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                        let cb := 1

                    // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                            // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function toBytes32(bytes memory _source) pure internal returns (bytes32 result) {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(bytes memory _bytes, uint _start, uint _length) pure internal returns (bytes32 result) {
        uint _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}

// File: SafeMath32.sol



pragma solidity ^0.6.12;

/*
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath32 {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint32 _a, uint32 _b) internal pure returns (uint32 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b, "Overflow during multiplication.");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint32 _a, uint32 _b) internal pure returns (uint32) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint32 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint32 _a, uint32 _b) internal pure returns (uint32) {
        require(_b <= _a, "Underflow during subtraction.");
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint32 _a, uint32 _b) internal pure returns (uint32 c) {
        c = _a + _b;
        require(c >= _a, "Overflow during addition.");
        return c;
    }
}

// File: SafeMath.sol



pragma solidity ^0.6.12;

/*
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b, "Overflow during multiplication.");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "Underflow during subtraction.");
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a, "Overflow during addition.");
        return c;
    }
}

// File: BTCUtils.sol



pragma solidity ^0.6.12;

/** @title BitcoinSPV */
/** @author Summa (https://summa.one) */



library BTCUtils {
    using BytesLib for bytes;
    using SafeMath for uint256;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 public constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

    uint256 public constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds
    uint256 public constant RETARGET_PERIOD_BLOCKS = 2016;  // 2 weeks in blocks

    uint256 public constant ERR_BAD_ARG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /* ***** */
    /* UTILS */
    /* ***** */

    /// @notice         Determines the length of a VarInt in bytes
    /// @dev            A VarInt of >1 byte is prefixed with a flag indicating its length
    /// @param _flag    The first byte of a VarInt
    /// @return         The number of non-flag bytes in the VarInt
    function determineVarIntDataLength(bytes memory _flag) internal pure returns (uint8) {
        if (uint8(_flag[0]) == 0xff) {
            return 8;
            // one-byte flag, 8 bytes data
        }
        if (uint8(_flag[0]) == 0xfe) {
            return 4;
            // one-byte flag, 4 bytes data
        }
        if (uint8(_flag[0]) == 0xfd) {
            return 2;
            // one-byte flag, 2 bytes data
        }

        return 0;
        // flag is data
    }

    /// @notice     Parse a VarInt into its data length and the number it represents
    /// @dev        Useful for Parsing Vins and Vouts. Returns ERR_BAD_ARG if insufficient bytes.
    ///             Caller SHOULD explicitly handle this case (or bubble it up)
    /// @param _b   A byte-string starting with a VarInt
    /// @return     number of bytes in the encoding (not counting the tag), the encoded int
    function parseVarInt(bytes memory _b) internal pure returns (uint256, uint256) {
        uint8 _dataLen = determineVarIntDataLength(_b);

        if (_dataLen == 0) {
            return (0, uint8(_b[0]));
        }
        if (_b.length < 1 + _dataLen) {
            return (ERR_BAD_ARG, 0);
        }
        uint256 _number = bytesToUint(reverseEndianness(_b.slice(1, _dataLen)));
        return (_dataLen, _number);
    }

    /// @notice          Changes the endianness of a byte array
    /// @dev             Returns a new, backwards, bytes
    /// @param _b        The bytes to reverse
    /// @return          The reversed bytes
    function reverseEndianness(bytes memory _b) internal pure returns (bytes memory) {
        bytes memory _newValue = new bytes(_b.length);

        for (uint i = 0; i < _b.length; i++) {
            _newValue[_b.length - i - 1] = _b[i];
        }

        return _newValue;
    }

    /// @notice          Changes the endianness of a uint256
    /// @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
        ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
        ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
        ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
        ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /// @notice          Converts big-endian bytes to a uint
    /// @dev             Traverses the byte array and sums the bytes
    /// @param _b        The big-endian bytes-encoded integer
    /// @return          The integer representation
    function bytesToUint(bytes memory _b) internal pure returns (uint256) {
        uint256 _number;

        for (uint i = 0; i < _b.length; i++) {
            _number = _number + uint8(_b[i]) * (2 ** (8 * (_b.length - (i + 1))));
        }

        return _number;
    }

    /// @notice          Get the last _num bytes from a byte array
    /// @param _b        The byte array to slice
    /// @param _num      The number of bytes to extract from the end
    /// @return          The last _num bytes of _b
    function lastBytes(bytes memory _b, uint256 _num) internal pure returns (bytes memory) {
        uint256 _start = _b.length.sub(_num);

        return _b.slice(_start, _num);
    }

    /// @notice          Implements bitcoin's hash160 (rmd160(sha2()))
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash160(bytes memory _b) internal pure returns (bytes memory) {
        return abi.encodePacked(ripemd160(abi.encodePacked(sha256(_b))));
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash256(bytes memory _b) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(_b)));
    }

    /* ************ */
    /* Legacy Input */
    /* ************ */

    /// @notice          Extracts the nth input from the vin (0-indexed)
    /// @dev             Iterates over the vin. If you need to extract several, write a custom function
    /// @param _vin      The vin as a tightly-packed byte array
    /// @param _index    The 0-indexed location of the input to extract
    /// @return          The input as a byte array
    function extractInputAtIndex(bytes memory _vin, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index < _nIns, "Vin read overrun");

        bytes memory _remaining;

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _remaining = _vin.slice(_offset, _vin.length - _offset);
            _len = determineInputLength(_remaining);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
            _offset = _offset + _len;
        }

        _remaining = _vin.slice(_offset, _vin.length - _offset);
        _len = determineInputLength(_remaining);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _vin.slice(_offset, _len);
    }

    /// @notice          Determines whether an input is legacy
    /// @dev             False if no scriptSig, otherwise True
    /// @param _input    The input
    /// @return          True for legacy, False for witness
    function isLegacyInput(bytes memory _input) internal pure returns (bool) {
        return _input.keccak256Slice(36, 1) != keccak256(hex"00");
    }

    /// @notice          Determines the length of a scriptSig in an input
    /// @dev             Will return 0 if passed a witness input.
    /// @param _input    The LEGACY input
    /// @return          The length of the script sig
    function extractScriptSigLen(bytes memory _input) internal pure returns (uint256, uint256) {
        if (_input.length < 37) {
            return (ERR_BAD_ARG, 0);
        }
        bytes memory _afterOutpoint = _input.slice(36, _input.length - 36);

        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = parseVarInt(_afterOutpoint);

        return (_varIntDataLen, _scriptSigLen);
    }

    /// @notice          Determines the length of an input from its scriptSig
    /// @dev             36 for outpoint, 1 for scriptSig length, 4 for sequence
    /// @param _input    The input
    /// @return          The length of the input in bytes
    function determineInputLength(bytes memory _input) internal pure returns (uint256) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        if (_varIntDataLen == ERR_BAD_ARG) {
            return ERR_BAD_ARG;
        }

        return 36 + 1 + _varIntDataLen + _scriptSigLen + 4;
    }

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The LEGACY input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLELegacy(bytes memory _input) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice(36 + 1 + _varIntDataLen + _scriptSigLen, 4);
    }

    /// @notice          Extracts the sequence from the input
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The LEGACY input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceLegacy(bytes memory _input) internal pure returns (uint32) {
        bytes memory _leSeqence = extractSequenceLELegacy(_input);
        bytes memory _beSequence = reverseEndianness(_leSeqence);
        return uint32(bytesToUint(_beSequence));
    }
    /// @notice          Extracts the VarInt-prepended scriptSig from the input in a tx
    /// @dev             Will return hex"00" if passed a witness input
    /// @param _input    The LEGACY input
    /// @return          The length-prepended scriptSig
    function extractScriptSig(bytes memory _input) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice(36, 1 + _varIntDataLen + _scriptSigLen);
    }


    /* ************* */
    /* Witness Input */
    /* ************* */

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The WITNESS input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLEWitness(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(37, 4);
    }

    /// @notice          Extracts the sequence from the input in a tx
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The WITNESS input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceWitness(bytes memory _input) internal pure returns (uint32) {
        bytes memory _leSeqence = extractSequenceLEWitness(_input);
        bytes memory _inputeSequence = reverseEndianness(_leSeqence);
        return uint32(bytesToUint(_inputeSequence));
    }

    /// @notice          Extracts the outpoint from the input in a tx
    /// @dev             32-byte tx id with 4-byte index
    /// @param _input    The input
    /// @return          The outpoint (LE bytes of prev tx hash + LE bytes of prev tx index)
    function extractOutpoint(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(0, 36);
    }

    /// @notice          Extracts the outpoint tx id from an input
    /// @dev             32-byte tx id
    /// @param _input    The input
    /// @return          The tx id (little-endian bytes)
    function extractInputTxIdLE(bytes memory _input) internal pure returns (bytes32) {
        return _input.slice(0, 32).toBytes32();
    }

    /// @notice          Extracts the LE tx input index from the input in a tx
    /// @dev             4-byte tx index
    /// @param _input    The input
    /// @return          The tx index (little-endian bytes)
    function extractTxIndexLE(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(32, 4);
    }

    /* ****** */
    /* Output */
    /* ****** */

    /// @notice          Determines the length of an output
    /// @dev             Works with any properly formatted output
    /// @param _output   The output
    /// @return          The length indicated by the prefix, error if invalid length
    function determineOutputLength(bytes memory _output) internal pure returns (uint256) {
        if (_output.length < 9) {
            return ERR_BAD_ARG;
        }
        bytes memory _afterValue = _output.slice(8, _output.length - 8);

        uint256 _varIntDataLen;
        uint256 _scriptPubkeyLength;
        (_varIntDataLen, _scriptPubkeyLength) = parseVarInt(_afterValue);

        if (_varIntDataLen == ERR_BAD_ARG) {
            return ERR_BAD_ARG;
        }

        // 8-byte value, 1-byte for tag itself
        return 8 + 1 + _varIntDataLen + _scriptPubkeyLength;
    }

    /// @notice          Extracts the output at a given index in the TxOuts vector
    /// @dev             Iterates over the vout. If you need to extract multiple, write a custom function
    /// @param _vout     The _vout to extract from
    /// @param _index    The 0-indexed location of the output to extract
    /// @return          The specified output
    function extractOutputAtIndex(bytes memory _vout, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index < _nOuts, "Vout read overrun");

        bytes memory _remaining;

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _remaining = _vout.slice(_offset, _vout.length - _offset);
            _len = determineOutputLength(_remaining);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
            _offset += _len;
        }

        _remaining = _vout.slice(_offset, _vout.length - _offset);
        _len = determineOutputLength(_remaining);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
        return _vout.slice(_offset, _len);
    }

    /// @notice          Extracts the value bytes from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value as LE bytes
    function extractValueLE(bytes memory _output) internal pure returns (bytes memory) {
        return _output.slice(0, 8);
    }

    /// @notice          Extracts the value from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value
    function extractValue(bytes memory _output) internal pure returns (uint64) {
        bytes memory _leValue = extractValueLE(_output);
        bytes memory _beValue = reverseEndianness(_leValue);
        return uint64(bytesToUint(_beValue));
    }

    /// @notice          Extracts the data from an op return output
    /// @dev             Returns hex"" if no data or not an op return
    /// @param _output   The output
    /// @return          Any data contained in the opreturn output, null if not an op return
    function extractOpReturnData(bytes memory _output) internal pure returns (bytes memory) {
        if (_output.keccak256Slice(9, 1) != keccak256(hex"6a")) {
            return hex"";
        }
        bytes memory _dataLen = _output.slice(10, 1);
        return _output.slice(11, bytesToUint(_dataLen));
    }

    /// @notice          Extracts the hash from the output script
    /// @dev             Determines type by the length prefix and validates format
    /// @param _output   The output
    /// @return          The hash committed to by the pk_script, or null for errors
    function extractHash(bytes memory _output) internal pure returns (bytes memory) {
        uint8 _scriptLen = uint8(_output[8]);

        // don't have to worry about overflow here.
        // if _scriptLen + 9 overflows, then output.length would have to be < 9
        // for this check to pass. if it's < 9, then we errored when assigning
        // _scriptLen
        if (_scriptLen + 9 != _output.length) {
            return hex"";
        }

        if (uint8(_output[9]) == 0) {
            if (_scriptLen < 2) {
                return hex"";
            }
            uint256 _payloadLen = uint8(_output[10]);
            // Check for maliciously formatted witness outputs.
            // No need to worry about underflow as long b/c of the `< 2` check
            if (_payloadLen != _scriptLen - 2 || (_payloadLen != 0x20 && _payloadLen != 0x14)) {
                return hex"";
            }
            return _output.slice(11, _payloadLen);
        } else {
            bytes32 _tag = _output.keccak256Slice(8, 3);
            // p2pkh
            if (_tag == keccak256(hex"1976a9")) {
                // Check for maliciously formatted p2pkh
                // No need to worry about underflow, b/c of _scriptLen check
                if (uint8(_output[11]) != 0x14 ||
                    _output.keccak256Slice(_output.length - 2, 2) != keccak256(hex"88ac")) {
                    return hex"";
                }
                return _output.slice(12, 20);
                //p2sh
            } else if (_tag == keccak256(hex"17a914")) {
                // Check for maliciously formatted p2sh
                // No need to worry about underflow, b/c of _scriptLen check
                if (uint8(_output[_output.length - 1]) != 0x87) {
                    return hex"";
                }
                return _output.slice(11, 20);
            }
        }
        return hex"";
        /* NB: will trigger on OPRETURN and any non-standard that doesn't overrun */
    }

    /* ********** */
    /* Witness TX */
    /* ********** */


    /// @notice      Checks that the vin passed up is properly formatted
    /// @dev         Consider a vin with a valid vout in its scriptsig
    /// @param _vin  Raw bytes length-prefixed input vector
    /// @return      True if it represents a validly formatted vin
    function validateVin(bytes memory _vin) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);

        // Not valid if it says there are too many or no inputs
        if (_nIns == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nIns; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vin.length) {
                return false;
            }

            // Grab the next input and determine its length.
            bytes memory _next = _vin.slice(_offset, _vin.length - _offset);
            uint256 _nextLen = determineInputLength(_next);
            if (_nextLen == ERR_BAD_ARG) {
                return false;
            }

            // Increase the offset by that much
            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vin.length;
    }

    /// @notice      Checks that the vout passed up is properly formatted
    /// @dev         Consider a vout with a valid scriptpubkey
    /// @param _vout Raw bytes length-prefixed output vector
    /// @return      True if it represents a validly formatted vout
    function validateVout(bytes memory _vout) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);

        // Not valid if it says there are too many or no outputs
        if (_nOuts == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nOuts; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vout.length) {
                return false;
            }

            // Grab the next output and determine its length.
            // Increase the offset by that much
            bytes memory _next = _vout.slice(_offset, _vout.length - _offset);
            uint256 _nextLen = determineOutputLength(_next);
            if (_nextLen == ERR_BAD_ARG) {
                return false;
            }

            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vout.length;
    }



    /* ************ */
    /* Block Header */
    /* ************ */

    /// @notice          Extracts the transaction merkle root from a block header
    /// @dev             Use verifyHash256Merkle to verify proofs with this root
    /// @param _header   The header
    /// @return          The merkle root (little-endian)
    function extractMerkleRootLE(bytes memory _header) internal pure returns (bytes memory) {
        return _header.slice(36, 32);
    }

    /// @notice          Extracts the target from a block header
    /// @dev             Target is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _header   The header
    /// @return          The target threshold
    function extractTarget(bytes memory _header) internal pure returns (uint256) {
        bytes memory _m = _header.slice(72, 3);
        uint8 _e = uint8(_header[75]);
        uint256 _mantissa = bytesToUint(reverseEndianness(_m));
        uint _exponent = _e - 3;

        return _mantissa * (256 ** _exponent);
    }

    /// @notice          Calculate difficulty from the difficulty 1 target and current target
    /// @dev             Difficulty 1 is 0x1d00ffff on mainnet and testnet
    /// @dev             Difficulty 1 is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _target   The current target
    /// @return          The block difficulty (bdiff)
    function calculateDifficulty(uint256 _target) internal pure returns (uint256) {
        // Difficulty 1 calculated from 0x1d00ffff
        return DIFF1_TARGET.div(_target);
    }

    /// @notice          Extracts the previous block's hash from a block header
    /// @dev             Block headers do NOT include block number :(
    /// @param _header   The header
    /// @return          The previous block's hash (little-endian)
    function extractPrevBlockLE(bytes memory _header) internal pure returns (bytes memory) {
        return _header.slice(4, 32);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (little-endian bytes)
    function extractTimestampLE(bytes memory _header) internal pure returns (bytes memory) {
        return _header.slice(68, 4);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (uint)
    function extractTimestamp(bytes memory _header) internal pure returns (uint32) {
        return uint32(bytesToUint(reverseEndianness(extractTimestampLE(_header))));
    }

    /// @notice          Extracts the expected difficulty from a block header
    /// @dev             Does NOT verify the work
    /// @param _header   The header
    /// @return          The difficulty as an integer
    function extractDifficulty(bytes memory _header) internal pure returns (uint256) {
        return calculateDifficulty(extractTarget(_header));
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return          The double-sha256 of the concatenated hashes
    function _hash256MerkleStep(bytes memory _a, bytes memory _b) internal pure returns (bytes32) {
        return hash256(abi.encodePacked(_a, _b));
    }

    /// @notice          Verifies a Bitcoin-style merkle tree
    /// @dev             Leaves are 0-indexed.
    /// @param _proof    The proof. Tightly packed LE sha256 hashes. The last hash is the root
    /// @param _index    The index of the leaf
    /// @return          true if the proof is valid, else false
    function verifyHash256Merkle(bytes memory _proof, uint _index) internal pure returns (bool) {
        // Not an even number of hashes
        if (_proof.length % 32 != 0) {
            return false;
        }

        // Special case for coinbase-only blocks
        if (_proof.length == 32) {
            return true;
        }

        // Should never occur
        if (_proof.length == 64) {
            return false;
        }

        uint _idx = _index;
        bytes32 _root = _proof.slice(_proof.length - 32, 32).toBytes32();
        bytes32 _current = _proof.slice(0, 32).toBytes32();

        for (uint i = 1; i < (_proof.length.div(32)) - 1; i++) {
            if (_idx % 2 == 1) {
                _current = _hash256MerkleStep(_proof.slice(i * 32, 32), abi.encodePacked(_current));
            } else {
                _current = _hash256MerkleStep(abi.encodePacked(_current), _proof.slice(i * 32, 32));
            }
            _idx = _idx >> 1;
        }
        return _current == _root;
    }

    /*
    NB: https://github.com/bitcoin/bitcoin/blob/78dae8caccd82cfbfd76557f1fb7d7557c7b5edb/src/pow.cpp#L49-L72
    NB: We get a full-bitlength target from this. For comparison with
        header-encoded targets we need to mask it with the header target
        e.g. (full & truncated) == truncated
    */
    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp.sub(_firstTimestamp);

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD.div(4)) {
            _elapsedTime = RETARGET_PERIOD.div(4);
        }
        if (_elapsedTime > RETARGET_PERIOD.mul(4)) {
            _elapsedTime = RETARGET_PERIOD.mul(4);
        }

        /*
          NB: high targets e.g. ffff0020 can cause overflows here
              so we divide it by 256**2, then multiply by 256**2 later
              we know the target is evenly divisible by 256**2, so this isn't an issue
        */

        uint256 _adjusted = _previousTarget.div(65536).mul(_elapsedTime);
        return _adjusted.div(RETARGET_PERIOD).mul(65536);
    }
}

// File: Parser.sol


pragma solidity ^0.6.12;



contract Parser {
    using BytesLib for bytes;
    struct vin {
        bytes hash;
        uint index;
        bytes script;
        uint sequence;
        bytes[] witness;
    }

    struct vout {
        uint value;
        bytes script;
        bool isProcessed;
    }

    vin[] ins;
    vout[] outs;
    bytes version;
    uint8 constant ADVANCED_TRANSACTION_MARKER = 0x00;
    uint8 constant ADVANCED_TRANSACTION_FLAG = 0x01;

    constructor() public {

    }
    function decryptData(bytes memory txRaw) internal {
        delete ins;
        delete outs;
        uint offset = 4;
        version = txRaw.slice(0, offset);
        uint marker;
        uint flag;
        bool hasWitnesses = false;
        (marker, offset) = readUInt8(txRaw, offset);
        (flag, offset) = readUInt8(txRaw, offset);
        (hasWitnesses, offset) = witness(marker, flag, offset);
        uint vinLen;
        (vinLen, offset) = readVarInt(txRaw, offset);
        for (uint i = 0; i < vinLen; ++i) {
            bytes memory hash;
            (hash, offset) = readSlice(txRaw, offset, 32);
            uint index;
            (index, offset) = readUInt32(txRaw, offset);
            bytes memory script;
            (script, offset) = readVarSlice(txRaw, offset);
            uint sequence;
            (sequence, offset) = readUInt32(txRaw, offset);
            bytes[] memory witness;
            vin memory v;
            v.hash = hash;
            v.index = index;
            v.script = script;
            v.sequence = sequence;
            v.witness = witness;
            ins.push(v);
        }
        uint voutLen;
        (voutLen, offset) = readVarInt(txRaw, offset);
        for (uint i = 0; i < voutLen; ++i) {
            uint value;
            (value, offset) = readValueInt(txRaw, offset);
            bytes memory script;
            (script, offset) = readVarSlice(txRaw, offset);
            vout memory v;
            v.value = value;
            v.script = script;
            outs.push(v);
        }
    }

    function readUInt8(bytes memory txRaw, uint offset) pure internal returns (uint, uint) {
        uint offsetValue = offset + 1;
        uint result = uint8(BTCUtils.bytesToUint(txRaw.slice(offset, 1)));
        return (result, offsetValue);
    }

    function readUInt32(bytes memory txRaw, uint offset) pure internal returns (uint, uint) {
        uint offsetValue = offset;
        uint result;
        for (uint i = 0; i < 4; i++) {
            if (i == 0) {
                result += uint8(BTCUtils.bytesToUint(txRaw.slice(offset, 1)));
            } else {
                result += uint8(BTCUtils.bytesToUint(txRaw.slice(offset + i, 1))) * 2 ** (8 * i);
            }
            offsetValue++;
        }
        return (result, offsetValue);
    }

    function readSlice(bytes memory txRaw, uint offset, uint n) pure internal returns (bytes memory, uint) {
        uint offsetValue = offset + n;
        bytes memory result = txRaw.slice(offset, n);
        return (result, offsetValue);
    }

    function witness(uint marker, uint flag, uint offset) pure internal returns (bool, uint) {
        bool hasWitnesses = false;
        if (marker == ADVANCED_TRANSACTION_MARKER && flag == ADVANCED_TRANSACTION_FLAG) {
            hasWitnesses = true;
        } else {
            offset -= 2;
        }
        return (hasWitnesses, offset);
    }

    function readVarInt(bytes memory txRaw, uint offset) pure internal returns (uint, uint) {
        uint8 first = uint8(BTCUtils.bytesToUint(txRaw.slice(offset, 1)));
        if (first < 0xfd) {
            offset += 1;
            return (first, offset);
        } else if (first == 0xfd) {
            uint vi;
            for (uint i = 0; i < 2; i++) {
                if (i == 0) {
                    vi += uint8(BTCUtils.bytesToUint(txRaw.slice(offset + 1, 1)));
                } else {
                    vi += uint8(BTCUtils.bytesToUint(txRaw.slice(offset + 1 + i, 1))) * 2 ** (8 * i);
                }
            }
            offset += 3;
            return (vi, offset);
        } else if (first == 0xfe) {
            uint vi;
            for (uint i = 0; i < 4; i++) {
                if (i == 0) {
                    vi += uint8(BTCUtils.bytesToUint(txRaw.slice(offset + 1, 1)));
                } else {
                    vi += uint8(BTCUtils.bytesToUint(txRaw.slice(offset + 1 + i, 1))) * 2 ** (8 * i);
                }
            }
            offset += 5;
            return (vi, offset);
        } else if (first == 0xff) {
            uint vi;
            for (uint i = 0; i < 8; i++) {
                if (i == 0) {
                    vi += uint8(BTCUtils.bytesToUint(txRaw.slice(offset + 1, 1)));
                } else {
                    vi += uint8(BTCUtils.bytesToUint(txRaw.slice(offset + 1 + i, 1))) * 2 ** (8 * i);
                }
            }
            offset += 9;
            return (vi, offset);
        }
    }

    function readValueInt(bytes memory txRaw, uint offset) pure internal returns (uint, uint) {
        uint offsetValue = offset;
        uint result;
        for (uint i = 0; i < 8; i++) {
            if (i == 0) {
                result += uint8(BTCUtils.bytesToUint(txRaw.slice(offset, 1)));
            } else {
                result += uint8(BTCUtils.bytesToUint(txRaw.slice(offset + i, 1))) * 2 ** (8 * i);
            }
            offsetValue++;
        }
        return (result, offsetValue);
    }

    function readVarSlice(bytes memory txRaw, uint offset) pure internal returns (bytes memory, uint) {
        bytes memory result;
        uint vi;
        uint offsetValue;
        (vi, offsetValue) = readVarInt(txRaw, offset);
        (result, offsetValue) = readSlice(txRaw, offsetValue, vi);
        return (result, offsetValue);
    }

    function decode(bytes memory data) public pure returns(bytes memory, bytes memory){
        (string memory txhex, string memory toaddress) = abi.decode(data, (string, string));
        bytes memory txhexBytes = fromHex(txhex);
        bytes memory toaddressBytes = fromHex(toaddress);
        return(txhexBytes.slice(1, txhexBytes.length - 1), toaddressBytes.slice(1, toaddressBytes.length - 1));
    }

    function fromHex(string memory s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 + fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }

    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
    }

    /**
     * @dev Compare two strings
     *
     */
    function compareStringsByBytes(string memory s1, string memory s2) internal pure returns(bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}

// File: ValidateSPV.sol



pragma solidity ^0.6.12;

/** @title ValidateSPV*/
/** @author Summa (https://summa.one) */





library ValidateSPV {

    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using BytesLib for bytes;
    using SafeMath for uint256;

    enum InputTypes {NONE, LEGACY, COMPATIBILITY, WITNESS}
    enum OutputTypes {NONE, WPKH, WSH, OP_RETURN, PKH, SH, NONSTANDARD}

    uint256 constant ERR_BAD_LENGTH = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant ERR_INVALID_CHAIN = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
    uint256 constant ERR_LOW_WORK = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd;

    function getErrBadLength() internal pure returns (uint256) {
        return ERR_BAD_LENGTH;
    }

    function getErrInvalidChain() internal pure returns (uint256) {
        return ERR_INVALID_CHAIN;
    }

    function getErrLowWork() internal pure returns (uint256) {
        return ERR_LOW_WORK;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root (as in the block header)
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove(
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes memory _intermediateNodes,
        uint _index
    ) internal pure returns (bool) {
        // Shortcut the empty-block case
        if (_txid == _merkleRoot && _index == 0 && _intermediateNodes.length == 0) {
            return true;
        }

        bytes memory _proof = abi.encodePacked(_txid, _intermediateNodes, _merkleRoot);

        // If the Merkle proof failed, bubble up error
        return _proof.verifyHash256Merkle(_index);
    }

    /// @notice             Hashes transaction to get txid
    /// @dev                Supports Legacy and Witness
    /// @param _version     4-bytes version
    /// @param _vin         Raw bytes length-prefixed input vector
    /// @param _vout        Raw bytes length-prefixed output vector
    /// @param _locktime   4-byte tx locktime
    /// @return             32-byte transaction id, little endian
    function calculateTxId(
        bytes memory _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes memory _locktime
    ) internal pure returns (bytes32) {
        // Get transaction hash double-Sha256(version + nIns + inputs + nOuts + outputs + locktime)
        return abi.encodePacked(_version, _vin, _vout, _locktime).hash256();
    }

    /// @notice                     Checks validity of header chain
    /// @notice                     Compares the hash of each header to the prevHash in the next header
    /// @param _headers             Raw byte array of header chain
    /// @return _totalDifficulty    The total accumulated difficulty of the header chain, or an error code
    function validateHeaderChain(bytes memory _headers) internal pure returns (uint256 _totalDifficulty) {

        // Check header chain length
        if (_headers.length % 80 != 0) {return ERR_BAD_LENGTH;}

        // Initialize header start index
        bytes32 _digest;

        _totalDifficulty = 0;

        for (uint256 _start = 0; _start < _headers.length; _start += 80) {

            // ith header start index and ith header
            bytes memory _header = _headers.slice(_start, 80);

            // After the first header, check that headers are in a chain
            if (_start != 0) {
                if (!validateHeaderPrevHash(_header, _digest)) {return ERR_INVALID_CHAIN;}
            }

            // ith header target
            uint256 _target = _header.extractTarget();

            // Require that the header has sufficient work
            _digest = _header.hash256();
            if (uint256(_digest).reverseUint256() > _target) {
                return ERR_LOW_WORK;
            }

            // Add ith header difficulty to difficulty sum
            _totalDifficulty = _totalDifficulty.add(_target.calculateDifficulty());
        }
    }

    /// @notice             Checks validity of header work
    /// @param _digest      Header digest
    /// @param _target      The target threshold
    /// @return             true if header work is valid, false otherwise
    function validateHeaderWork(bytes32 _digest, uint256 _target) internal pure returns (bool) {
        if (_digest == bytes32(0)) {return false;}
        return (abi.encodePacked(_digest).reverseEndianness().bytesToUint() < _target);
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header prevHash to previous header's digest
    /// @param _header              The raw bytes header
    /// @param _prevHeaderDigest    The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function validateHeaderPrevHash(bytes memory _header, bytes32 _prevHeaderDigest) internal pure returns (bool) {

        // Extract prevHash of current header
        bytes32 _prevHash = _header.extractPrevBlockLE().toBytes32();

        // Compare prevHash of current header to previous header's digest
        if (_prevHash != _prevHeaderDigest) {return false;}

        return true;
    }
}

// File: Relay.sol



pragma solidity ^0.6.12;








// MRC20 BTCpx
interface IBTCpx {

    /**
     * @dev Set the relay data
     *
     */
    function setData(bytes memory _relayData) external;

}

/// @title BTCpx Relay
contract BTCpxRelay is IRelay, Parser {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using BytesLib for bytes;
    using BTCUtils for bytes;

    struct Header {
        // height of this block header (cannot be zero)
        uint32 height;
        // identifier of chain fork
        uint64 chainId;
    }

    uint internal uuid;

    struct TxData {
        // BTC Tx hex
        bytes txHex;
        // Ethereum address
        address ethAddress;
        // BTC To address
        bytes toAddress;
        // BTC Tx hash
        bytes txId;
        // BTC Tx amount
        uint256 amount;
        // BTC Tx fee
        uint256 fees;
        // uuid
        uint uuid;
        //transferred
        bool transferred;
        //status
        bool status;
        //confirmations
        uint256 confirmations;
        //Address type
        uint256 addressType;

    }

    struct VerifyTxData {
        uint32 height;
        uint256 index;
        bytes32 txId;
        bytes header;
        bytes proof;
        uint256 requiredConfirmations;
        bytes relayData;
        address ethAddress;
        uint256 addressType;
        uint256 txFees;
    }

    mapping(uint => TxData) internal txsInformation;
    mapping(address => uint[]) internal pendingMints;
    mapping(address => uint[]) internal completedMints;
    mapping(bytes => uint) internal relaysMapped;
    // mapping(bytes => bytes) relayDataMapped;

    // mapping of block hashes to block headers (ALL ever submitted, i.e., incl. forks)
    mapping(bytes32 => Header) public _headers;
    // main chain mapping for constant time inclusion check
    mapping(uint32 => bytes32) public _chain;

    struct Fork {
        uint32 height; // best height of fork
        bytes32 ancestor; // branched from this
        bytes32[] descendants; // references to submitted block headers
    }

    // mapping of ids to forks
    mapping(uint256 => Fork) public _forks;

    // MRC20 BTCpx contract
    IBTCpx public btcpx;

    // incrementing counter to track forks
    // OPTIMIZATION: default to zero value
    uint256 private _chainCounter;

    // target of the difficulty period
    uint256 public _epochStartTarget;
    uint256 public _epochEndTarget;

    uint64 public _epochStartTime;
    uint64 public _epochEndTime;

    // block with the most accumulated work, i.e., blockchain tip
    uint32 internal _bestHeight;
    bytes32 internal _bestBlock;
    uint32 internal _currHeight;
    bytes32 internal _currBlock;

    // CONSTANTS
    uint256 public constant DIFFICULTY_ADJUSTMENT_INTERVAL = 2016;
    uint256 public constant MAIN_CHAIN_ID = 0;
    uint256 public constant CONFIRMATIONS = 6;
    uint256 public constant ADDRESS_TYPE = 1;

    // EXCEPTION MESSAGES
    // OPTIMIZATION: limit string length to 32 bytes
    string internal constant ERR_INVALID_HEADER_SIZE = "Invalid block header size";
    string internal constant ERR_INVALID_GENESIS_HEIGHT = "Invalid genesis height";
    string internal constant ERR_INVALID_HEADER_BATCH = "Invalid block header batch";
    string internal constant ERR_DUPLICATE_BLOCK = "Block already stored";
    string internal constant ERR_PREVIOUS_BLOCK = "Previous block hash not found";
    string internal constant ERR_LOW_DIFFICULTY = "Insufficient difficulty";
    string internal constant ERR_DIFF_TARGET_HEADER = "Incorrect difficulty target";
    string internal constant ERR_DIFF_PERIOD = "Invalid difficulty period";
    string internal constant ERR_BLOCK_NOT_FOUND = "Block not found";
    string internal constant ERR_CONFIRMS = "Insufficient confirmations";
    string internal constant ERR_VERIFY_TX = "Incorrect merkle proof";
    string internal constant ERR_INVALID_TX_ID = "Invalid tx identifier";
    string internal constant ERR_MINIMUM_CONFIRMATION = "Minimum 3 confirmations are required to be set";
    string internal constant ERR_INVALID_AMOUNT = "Invalid amount";
    string internal constant ERR_MINT_ID_NOT_FOUND = "Corresponding minting id not found";
    string internal constant ERR_MINT_ID_INVALID = "Invalid Mint Id";
    string internal constant ERR_MINT_COUNTER_INVALID = "Counter must be above the current value";
    string internal constant ERR_INVALID_ADDRESS = "Invalid address";
    string internal constant ERR_TX_PROCESSED = "Transaction is already processed";
    string internal constant ERR_TX_NOT_FOUND = "Transaction not found";
    string internal constant ERR_INVALID_RELAY_DATA = "Invalid relay data";
    string internal constant ERR_INVALID_TX_FEE = "Transaction fees is greater than bitcoin transaction amount";
    string internal constant ERR_TX_FEE_NEGATIVE = "Transaction fees can't be less than 0";
    string internal constant ERR_CURRENT_HEIGHT = "Provided height is wrong";

    /**
    * @notice Initializes the relay with the provided block.
    * @param header Genesis block header
    * @param height Genesis block height
    */
    function reinitialize(
        bytes memory header,
        uint32 height
    )
    external
    override
    {
        require(header.length == 80, ERR_INVALID_HEADER_SIZE);
        require(height > 0, ERR_INVALID_GENESIS_HEIGHT);

        bytes32 digest = header.hash256();
        uint256 target = header.extractTarget();
        uint64 timestamp = header.extractTimestamp();
        uint256 chainId = MAIN_CHAIN_ID;

        if (uuid == 0)
            uuid = 1;
        _bestBlock = digest;
        _bestHeight = height;
        _currHeight = height;
        _currBlock = digest;

        _forks[chainId].height = height;
        _chain[height] = digest;


        _epochStartTarget = target;
        _epochStartTime = timestamp;
        _epochEndTarget = target;
        _epochEndTime = timestamp;

        _storeBlockHeader(
            digest,
            height,
            chainId
        );
    }

    /**
     * @dev See {IRelay-submitBlockHeader}.
     */
    function submitBlockHeader(
        bytes calldata header
    )
    external
    override
    {
        _submitBlockHeader(header);
    }

    /**
     * @dev See {IRelay-submitBlockHeader}.
     */
    function setCurrentHeight(
        uint32 height
    )
    external
    override
    {
        require(height > _currHeight && height.sub(_currHeight) == 1, ERR_CURRENT_HEIGHT);
        _currHeight = height;
    }

    /**
     * @dev See {IRelay-submitBlockHeaderBatch}.
     */
    function submitBlockHeaderBatch(
        bytes calldata headers
    )
    external
    override
    {
        require(headers.length % 80 == 0, ERR_INVALID_HEADER_BATCH);
        uint256 len = headers.length.div(80);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            bytes memory header = headers.slice(i.mul(80), 80);
            _submitBlockHeader(header);
        }
    }

    /**
     * @dev See {IRelay-getBlockHeight}.
     */
    function getBlockHeight(
        bytes32 digest
    )
    external
    view
    override
    returns (
        uint32
    )
    {
        return _headers[digest].height;
    }

    /**
     * @dev See {IRelay-getBlockHash}.
     */
    function getBlockHash(
        uint32 height
    )
    external
    view
    override
    returns (
        bytes32
    )
    {
        bytes32 digest = _chain[height];
        require(digest > 0, ERR_BLOCK_NOT_FOUND);
        return digest;
    }

    /**
     * @dev See {IRelay-getBestBlock}.
     */
    function getBestBlock()
    external
    view
    override
    returns (
        bytes32 digest,
        uint32 height
    )
    {
        return (_bestBlock, _bestHeight);
    }

    /**
     * @dev See {IRelay-getCurrentBlock}.
     */
    function getCurrentBlock()
    external
    view
    override
    returns (
        bytes32 digest,
        uint32 height
    )
    {
        return (_currBlock, _currHeight);
    }

    /**
     * @dev See {IRelay-verifyTx}.
     */
    function verifyTx(
        VerifyTxData calldata verifyTxData
    )
    external
    returns (
        bool
    )
    {
        require(verifyTxData.ethAddress != address(0), ERR_INVALID_ADDRESS);
        require(verifyTxData.relayData.length > 0, ERR_INVALID_RELAY_DATA);
        require(verifyTxData.txId.length > 0, ERR_INVALID_TX_ID);
        require(verifyTxData.txFees >= 0, ERR_TX_FEE_NEGATIVE);
        require(verifyTxData.requiredConfirmations >= 1, ERR_MINIMUM_CONFIRMATION);
        uint256 confirmations = 1;
        bytes32 root = verifyTxData.header.extractMerkleRootLE().toBytes32();
        validateProof(root, verifyTxData.index, verifyTxData.txId, verifyTxData.proof);
        parseRelayData(verifyTxData.relayData, verifyTxData.ethAddress, verifyTxData.requiredConfirmations, confirmations, verifyTxData.addressType);
        bytes memory relayDataToBeSent = prepareRelayData(verifyTxData.relayData, verifyTxData.txFees, verifyTxData.addressType);
        if (verifyTxData.addressType == ADDRESS_TYPE)
            emit Data(msg.sender, relayDataToBeSent);
        else {
            // btcpx.setData(relayDataToBeSent);
            emit DataMRC20(msg.sender, relayDataToBeSent);
            uint id = relaysMapped[verifyTxData.relayData];
            TxData memory txData = txsInformation[id];
            emit txProcessed(msg.sender, txData.toAddress, id);
        }
        return true;
    }

    /**
     * @dev See {IRelay-setMintCounter}.
     */
    function setMintCounter(
        uint id
    )
    external
    override
    returns (
        bool
    )
    {
        require(id > uuid, ERR_MINT_COUNTER_INVALID);
        uuid = id;
        emit MintCounter(uuid);
        return true;
    }

    /**
     * @dev See {IRelay-processTx}.
     */
    function processTx(
        bytes memory btcAddress,
        uint256 id
    )
    external
    override
    returns (
        bool
    )
    {
        require(txsInformation[id].txHex.length > 0, ERR_TX_NOT_FOUND);
        require(txsInformation[id].status, ERR_CONFIRMS);
        require(!txsInformation[id].transferred, ERR_TX_PROCESSED);
        (string memory toaddress) = abi.decode(btcAddress, (string));
        bytes memory btcAddressHex = fromHex(toaddress);
        txsInformation[id].transferred = true;
        emit txProcessed(msg.sender, btcAddressHex, id);
        removeByValue(id, txsInformation[id].ethAddress);
        completedMints[txsInformation[id].ethAddress].push(id);
        return true;
    }

    /**
     * @dev See {IRelay-getPendingMints}.
     */
    function getPendingMints(
        address ethAddress
    )
    external
    view
    override
    returns (
        uint[] memory
    )
    {
        uint count = 0;
        uint256 len = pendingMints[ethAddress].length;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (pendingMints[ethAddress][i] > 0)
                count = count.add(1);
        }
        uint[] memory pendingTxs = new uint[](count);
        uint index = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (pendingMints[ethAddress][i] > 0) {
                pendingTxs[index] = pendingMints[ethAddress][i];
                index = index.add(1);
            }
        }
        return pendingTxs;
    }

    /**
     * @dev See {IRelay-getCompletedMints}.
     */
    function getCompletedMints(
        address ethAddress
    )
    external
    view
    override
    returns (
        uint[] memory
    )
    {
        return completedMints[ethAddress];
    }

    function getPendingTransactions(
        address ethAddress
    )
    external
    view
    returns (
        TxData[] memory
    )
    {
        uint count = 0;
        uint256 len = pendingMints[ethAddress].length;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (pendingMints[ethAddress][i] > 0)
                count = count.add(1);
        }
        TxData[] memory pendingTxs = new TxData[](count);
        uint index = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (pendingMints[ethAddress][i] > 0) {
                pendingTxs[index] = txsInformation[pendingMints[ethAddress][i]];
                index = index.add(1);
            }
        }
        return pendingTxs;
    }

    function getCompletedTransactions(
        address ethAddress
    )
    external
    view
    returns (
        TxData[] memory
    )
    {
        uint256 len = completedMints[ethAddress].length;
        TxData[] memory completedTxs = new TxData[](len);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            completedTxs[i] = txsInformation[completedMints[ethAddress][i]];
        }
        return completedTxs;
    }

    function getTransactionById(
        uint id
    )
    external
    view
    returns (
        TxData memory
    )
    {
        require(id > 0, ERR_MINT_ID_INVALID);
        return txsInformation[id];
    }

    function initializeMRC20(
        IBTCpx _btcpx
    )
    external
    {
        btcpx = _btcpx;
    }

    /**
     * @notice Validates difficulty interval
     * @dev Reverts if previous period invalid
     * @param prevStartTarget Period starting target
     * @param prevStartTime Period starting timestamp
     * @param prevEndTarget Period ending target
     * @param prevEndTime Period ending timestamp
     * @param nextTarget Next period starting target
     * @return True if difficulty level is valid
     */
    function isCorrectDifficultyTarget(
        uint256 prevStartTarget,
        uint64 prevStartTime,
        uint256 prevEndTarget,
        uint64 prevEndTime,
        uint256 nextTarget
    )
    public
    pure
    returns (
        bool
    )
    {
        require(
            BTCUtils.calculateDifficulty(prevStartTarget) == BTCUtils.calculateDifficulty(prevEndTarget),
            ERR_DIFF_PERIOD
        );

        uint256 expectedTarget = BTCUtils.retargetAlgorithm(
            prevStartTarget,
            prevStartTime,
            prevEndTime
        );

        return (nextTarget & expectedTarget) == nextTarget;
    }

    /**
     * @dev Core logic for block header validation
     */
    function _submitBlockHeader(
        bytes memory header
    )
    internal
    virtual
    {
        require(header.length == 80, ERR_INVALID_HEADER_SIZE);

        // Fail if block already exists
        bytes32 hashCurrBlock = header.hash256();
        require(_headers[hashCurrBlock].height == 0, ERR_DUPLICATE_BLOCK);

        // Fail if previous block hash not in current state of main chain
        bytes32 hashPrevBlock = header.extractPrevBlockLE().toBytes32();
        require(_headers[hashPrevBlock].height > 0, ERR_PREVIOUS_BLOCK);

        uint256 target = header.extractTarget();

        // Check the PoW solution matches the target specified in the block header
        require(abi.encodePacked(hashCurrBlock).reverseEndianness().bytesToUint() <= target, ERR_LOW_DIFFICULTY);

        uint32 height = _headers[hashPrevBlock].height.add(1);

        _currHeight = height;
        _currBlock = hashCurrBlock;

        // Check the specified difficulty target is correct
        if (_isPeriodStart(height)) {
            require(isCorrectDifficultyTarget(
                    _epochStartTarget,
                    _epochStartTime,
                    _epochEndTarget,
                    _epochEndTime,
                    target
                ), ERR_DIFF_TARGET_HEADER);

            _epochStartTarget = target;
            _epochStartTime = header.extractTimestamp();

            delete _epochEndTarget;
            delete _epochEndTime;
        } else if (_isPeriodEnd(height)) {
            // only update if end to save gas
            _epochEndTarget = target;
            _epochEndTime = header.extractTimestamp();
        }

        uint256 chainId = _headers[hashPrevBlock].chainId;
        bool isNewFork = _forks[chainId].height != _headers[hashPrevBlock].height;

        if (isNewFork) {
            chainId = _incrementChainCounter();
            _initializeFork(hashCurrBlock, hashPrevBlock, chainId, height);

            _storeBlockHeader(
                hashCurrBlock,
                height,
                chainId
            );
        } else {
            _storeBlockHeader(
                hashCurrBlock,
                height,
                chainId
            );

            if (chainId == MAIN_CHAIN_ID) {
                _bestBlock = hashCurrBlock;
                _bestHeight = height;

                // extend height of main chain
                _forks[chainId].height = height;
                _chain[height] = hashCurrBlock;

            } else if (height >= _bestHeight.add(uint32(CONFIRMATIONS)))
            // with sufficient confirmations, reorg
                _reorgChain(chainId, height, hashCurrBlock);
            else {
                // extend fork
                _forks[chainId].height = height;
                _forks[chainId].descendants.push(hashCurrBlock);

            }
        }
    }

    function _storeBlockHeader(
        bytes32 digest,
        uint32 height,
        uint256 chainId
    )
    internal
    {
        _chain[height] = digest;
        _headers[digest].height = height;
        _headers[digest].chainId = uint64(chainId);
        emit StoreHeader(digest, height);
    }

    function _incrementChainCounter()
    internal
    returns (
        uint256
    )
    {
        _chainCounter = _chainCounter.add(1);
        return _chainCounter;
    }

    function _initializeFork(
        bytes32 hashCurrBlock,
        bytes32 hashPrevBlock,
        uint chainId,
        uint32 height
    )
    internal
    {
        bytes32[] memory descendants = new bytes32[](1);
        descendants[0] = hashCurrBlock;

        _forks[chainId].height = height;
        _forks[chainId].ancestor = hashPrevBlock;
        _forks[chainId].descendants = descendants;
    }

    function _reorgChain(
        uint chainId,
        uint32 height,
        bytes32 hashCurrBlock
    )
    internal
    {
        // reorg fork to main
        uint256 ancestorId = chainId;
        uint256 forkId = _incrementChainCounter();
        uint32 forkHeight = height.sub(1);

        // TODO: add new fork struct for old main

        while (ancestorId != MAIN_CHAIN_ID) {
            uint len = _forks[ancestorId].descendants.length;
            for (uint i = len; i > 0; i = i.sub(1)) {
                // get next descendant in fork
                bytes32 descendant = _forks[ancestorId].descendants[i.sub(1)];
                // promote header to main chain
                _headers[descendant].chainId = uint64(MAIN_CHAIN_ID);
                // demote old header to new fork
                _headers[_chain[height]].chainId = uint64(forkId);
                // swap header at height
                _chain[height] = descendant;
                forkHeight = forkHeight.sub(1);
            }

            bytes32 ancestor = _forks[ancestorId].ancestor;
            ancestorId = _headers[ancestor].chainId;
        }

        emit ChainReorg(_bestBlock, hashCurrBlock, chainId);

        _bestBlock = hashCurrBlock;
        _bestHeight = height;

        delete _forks[chainId];

        // extend to current head
        _chain[_bestHeight] = _bestBlock;
        _headers[_bestBlock].chainId = uint64(MAIN_CHAIN_ID);
    }

    /**
     * @notice Checks if the difficulty target should be adjusted at this block height
     * @param height Block height to be checked
     * @return True if block height is at difficulty adjustment interval, otherwise false
     */
    function _isPeriodStart(
        uint32 height
    )
    internal
    pure
    returns (
        bool
    )
    {
        return height % DIFFICULTY_ADJUSTMENT_INTERVAL == 0;
    }

    function _isPeriodEnd(
        uint32 height
    )
    internal
    pure
    returns (
        bool
    )
    {
        return height % DIFFICULTY_ADJUSTMENT_INTERVAL == 2015;
    }

    function validateProof(
        bytes32 root,
        uint256 index,
        bytes32 txId,
        bytes calldata proof
    )
    pure
    internal
    {
        require(
            ValidateSPV.prove(
                txId,
                root,
                proof,
                index
            ),
            ERR_VERIFY_TX
        );
    }

    function prepareRelayData(
        bytes memory relayData,
        uint256 txFees,
        uint256 addressType
    )
    internal
    returns (
        bytes memory relayDataToBeSent
    )
    {
        uint id = relaysMapped[relayData];
        require(id > 0, ERR_MINT_ID_NOT_FOUND);
        txsInformation[id].fees = txFees;
        TxData memory txData = txsInformation[id];
        require(txData.amount > txFees, ERR_INVALID_TX_FEE);
        relayDataToBeSent = abi.encode(txData.ethAddress, txData.amount, txFees, txData.uuid, txData.txHex, txData.toAddress);
        if (addressType != ADDRESS_TYPE) {
            txsInformation[id].transferred = true;
            removeByValue(id, txData.ethAddress);
            completedMints[txData.ethAddress].push(id);
        }
    }

    function parseRelayData(
        bytes memory relayData,
        address ethAddress,
        uint256 requiredConfirmations,
        uint256 confirmations,
        uint256 addressType
    )
    internal
    {
        if (relaysMapped[relayData] == 0) {
            (string memory txHex, string memory toAddress, string memory txId) = abi.decode(relayData, (string, string, string));
            bytes memory btcTxHex = fromHex(txHex);
            bytes memory btcAddress = fromHex(toAddress);
            bytes memory btcTxId = fromHex(txId);
            decryptData(btcTxHex);
            uint256 amount = getAmount(outs, btcAddress);
            require(amount > 0, ERR_INVALID_AMOUNT);
            txsInformation[uuid].txHex = btcTxHex;
            txsInformation[uuid].toAddress = btcAddress;
            txsInformation[uuid].txId = btcTxId;
            txsInformation[uuid].amount = amount;
            txsInformation[uuid].ethAddress = ethAddress;
            txsInformation[uuid].uuid = uuid;
            txsInformation[uuid].transferred = false;
            txsInformation[uuid].confirmations = confirmations;
            txsInformation[uuid].addressType = addressType;
            if (confirmations >= requiredConfirmations) {
                require(!txsInformation[uuid].status, ERR_TX_PROCESSED);
                txsInformation[uuid].status = true;
            } else {
                txsInformation[uuid].status = false;
            }
            pendingMints[ethAddress].push(uuid);
            relaysMapped[relayData] = uuid;
            uuid = uuid.add(1);
        } else {
            uint id = relaysMapped[relayData];
            require(id > 0, ERR_MINT_ID_NOT_FOUND);
            require(!txsInformation[id].status, ERR_TX_PROCESSED);
            txsInformation[id].confirmations = confirmations;
            if (confirmations >= requiredConfirmations)
                txsInformation[id].status = true;
        }
    }

    function find(
        uint value,
        address ethAddress
    )
    internal
    view
    returns (
        uint,
        bool
    )
    {
        require(ethAddress != address(0), ERR_INVALID_ADDRESS);
        uint256 index;
        bool found = false;
        uint256 len = pendingMints[ethAddress].length;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (pendingMints[ethAddress][i] == value) {
                index = i;
                found = true;
            }
        }
        return (index, found);
    }

    function getAmount(
        vout[] memory outs,
        bytes memory btcAddress
    )
    internal
    pure
    returns (
        uint256 amount
    )
    {
        uint256 len = outs.length;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (compareStringsByBytes(string(outs[i].script), string(btcAddress))) {
                amount = amount.add(outs[i].value);
                break;
            }
        }
    }

    function removeByValue(
        uint value,
        address ethAddress
    )
    internal
    {
        (uint pendingMintIndex, bool found) = find(value, ethAddress);
        require(found, ERR_MINT_ID_NOT_FOUND);
        delete pendingMints[ethAddress][pendingMintIndex];
    }
}