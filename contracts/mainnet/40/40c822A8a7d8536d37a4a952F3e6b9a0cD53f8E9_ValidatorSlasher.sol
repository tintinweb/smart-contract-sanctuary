/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

pragma solidity ^0.8.0;


// It is not actually an interface regarding solidity because interfaces can only have external functions
abstract contract DepositLockerInterface {
    function slash(address _depositorToBeSlashed) public virtual;
}

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "The function can only be called by the owner"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            revert("ECDSA: incorrect signature version");
        } else {
            // solium-disable-next-line arg-overflow
            address signer = ecrecover(hash, v, r, s);
            require(signer != address(0), "ECDSA: invalid signature");
            return signer;
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 *
 * Copyright 2018 Hamdi Allam
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/**
    Taken from https://github.com/hamdiallam/Solidity-RLP/blob/cd39a6a5d9ddc64eb3afedb3b4cda08396c5bfc5/contracts/RLPReader.sol
    with small modifications
 */

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item)
        internal
        pure
        returns (RLPItem memory)
    {
        require(item.length > 0);

        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item)
        internal
        pure
        returns (RLPItem[] memory result)
    {
        require(isList(item));

        uint items = numItems(item);
        result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 1;
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (
            byte0 < STRING_LONG_START ||
            (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
        ) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;

        uint result;
        uint memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shift to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint src,
        uint dest,
        uint len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

/**
 * Utilities to verify equivocating behavior of validators.
 */

library EquivocationInspector {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    uint constant STEP_DURATION = 5;

    /**
     * Get the signer address for a given signature and the related data.
     *
     * @dev Used as abstraction layer to the ECDSA library.
     *
     * @param _data       the data the signature is for
     * @param _signature  the signature the address should be recovered from
     */
    function getSignerAddress(bytes memory _data, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        bytes32 hash = keccak256(_data);
        return ECDSA.recover(hash, _signature);
    }

    /**
     * Verify malicious behavior of an authority.
     * Prove the presence of equivocation by two given blocks.
     * Equivocation is proven by:
     *    - two different blocks have been provided
     *    - both signatures have been issued by the same address
     *    - the step of both blocks is the same
     *
     * Block headers provided as arguments do not include their signature within.
     * By design this is expected to be the source that has been signed.
     *
     * The function fails if the proof can not be verified.
     * In case the proof can be verified, the function returns nothing.
     *
     * @dev Implement the rules of an equivocation.
     *
     * @param _rlpUnsignedHeaderOne   the RLP encoded header of the first block
     * @param _signatureOne           the signature related to the first block
     * @param _rlpUnsignedHeaderTwo   the RLP encoded header of the second block
     * @param _signatureTwo           the signature related to the second block
     */
    function verifyEquivocationProof(
        bytes memory _rlpUnsignedHeaderOne,
        bytes memory _signatureOne,
        bytes memory _rlpUnsignedHeaderTwo,
        bytes memory _signatureTwo
    ) internal pure {
        // Make sure two different blocks have been provided.
        bytes32 hashOne = keccak256(_rlpUnsignedHeaderOne);
        bytes32 hashTwo = keccak256(_rlpUnsignedHeaderTwo);

        // Different block rule.
        require(
            hashOne != hashTwo,
            "Equivocation can be proved for two different blocks only."
        );

        // Parse the RLP encoded block header list.
        // Note that this can fail here, if the block header has no list format.
        RLPReader.RLPItem[] memory blockOne =
            _rlpUnsignedHeaderOne.toRlpItem().toList();
        RLPReader.RLPItem[] memory blockTwo =
            _rlpUnsignedHeaderTwo.toRlpItem().toList();

        // Header length rule.
        // Keep it open ended, since they could contain a list of empty messages for finality.
        require(
            blockOne.length >= 12 && blockTwo.length >= 12,
            "The number of provided header entries are not enough."
        );

        // Equal signer rule.
        require(
            getSignerAddress(_rlpUnsignedHeaderOne, _signatureOne) ==
                getSignerAddress(_rlpUnsignedHeaderTwo, _signatureTwo),
            "The two blocks have been signed by different identities."
        );

        // Equal block step rule.
        uint stepOne = blockOne[11].toUint() / STEP_DURATION;
        uint stepTwo = blockTwo[11].toUint() / STEP_DURATION;

        require(stepOne == stepTwo, "The two blocks have different steps.");
    }
}

contract ValidatorSlasher is Ownable {
    bool public initialized = false;
    DepositLockerInterface public depositContract;

    fallback() external {}

    function init(address _depositContractAddress) external onlyOwner {
        require(!initialized, "The contract is already initialized.");

        depositContract = DepositLockerInterface(_depositContractAddress);

        initialized = true;
    }

    /**
     * Report a malicious validator for having equivocated.
     * The reporter must provide the both blocks with their related signature.
     * By the given blocks, the equivocation will be verified.
     * In case a equivocation could been proven, the issuer of the blocks get
     * removed from the set of validators, if his address is registered. Also
     * his deposit will be slashed afterwards.
     * In case any check before removing the malicious validator fails, the
     * whole report procedure fails due to that.
     *
     * @param _rlpUnsignedHeaderOne   the RLP encoded header of the first block
     * @param _signatureOne           the signature related to the first block
     * @param _rlpUnsignedHeaderTwo   the RLP encoded header of the second block
     * @param _signatureTwo           the signature related to the second block
     */
    function reportMaliciousValidator(
        bytes calldata _rlpUnsignedHeaderOne,
        bytes calldata _signatureOne,
        bytes calldata _rlpUnsignedHeaderTwo,
        bytes calldata _signatureTwo
    ) external {
        EquivocationInspector.verifyEquivocationProof(
            _rlpUnsignedHeaderOne,
            _signatureOne,
            _rlpUnsignedHeaderTwo,
            _signatureTwo
        );

        // Since the proof has already verified, that both blocks have been
        // issued by the same validator, it doesn't matter which one is used here
        // to recover the address.
        address validator =
            EquivocationInspector.getSignerAddress(
                _rlpUnsignedHeaderOne,
                _signatureOne
            );

        depositContract.slash(validator);
    }
}

// SPDX-License-Identifier: MIT