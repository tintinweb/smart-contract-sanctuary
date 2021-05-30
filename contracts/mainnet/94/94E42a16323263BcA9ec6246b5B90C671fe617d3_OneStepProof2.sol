// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./Value.sol";

library Hashing {
    using Hashing for Value.Data;
    using Value for Value.CodePoint;

    function keccak1(bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(b));
    }

    function keccak2(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }

    function bytes32FromArray(
        bytes memory arr,
        uint256 offset,
        uint256 arrLength
    ) internal pure returns (uint256) {
        uint256 res = 0;
        for (uint256 i = 0; i < 32; i++) {
            res = res << 8;
            bytes1 b = arrLength > offset + i ? arr[offset + i] : bytes1(0);
            res = res | uint256(uint8(b));
        }
        return res;
    }

    /*
     * !! Note that dataLength must be a power of two !!
     *
     * If you have an arbitrary data length, you can round it up with roundUpToPow2.
     * The boolean return value tells if the data segment data[startOffset..startOffset+dataLength] only included zeroes.
     * If pack is true, the returned value is the merkle hash where trailing zeroes are ignored, that is,
     *   if h is the smallest height for which all data[startOffset+2**h..] are zero, merkle hash of data[startOffset..startOffset+2**h] is returned.
     * If all elements in the data segment are zero (and pack is true), keccak1(bytes32(0)) is returned.
     */
    function merkleRoot(
        bytes memory data,
        uint256 rawDataLength,
        uint256 startOffset,
        uint256 dataLength,
        bool pack
    ) internal pure returns (bytes32, bool) {
        if (dataLength <= 32) {
            if (startOffset >= rawDataLength) {
                return (keccak1(bytes32(0)), true);
            }
            bytes32 res = keccak1(bytes32(bytes32FromArray(data, startOffset, rawDataLength)));
            return (res, res == keccak1(bytes32(0)));
        }
        (bytes32 h2, bool zero2) =
            merkleRoot(data, rawDataLength, startOffset + dataLength / 2, dataLength / 2, false);
        if (zero2 && pack) {
            return merkleRoot(data, rawDataLength, startOffset, dataLength / 2, pack);
        }
        (bytes32 h1, bool zero1) =
            merkleRoot(data, rawDataLength, startOffset, dataLength / 2, false);
        return (keccak2(h1, h2), zero1 && zero2);
    }

    function roundUpToPow2(uint256 len) internal pure returns (uint256) {
        if (len <= 1) return 1;
        else return 2 * roundUpToPow2((len + 1) / 2);
    }

    function bytesToBufferHash(
        bytes memory buf,
        uint256 startOffset,
        uint256 length
    ) internal pure returns (bytes32) {
        (bytes32 mhash, ) =
            merkleRoot(buf, startOffset + length, startOffset, roundUpToPow2(length), true);
        return keccak2(bytes32(uint256(123)), mhash);
    }

    function hashInt(uint256 val) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(val));
    }

    function hashCodePoint(Value.CodePoint memory cp) internal pure returns (bytes32) {
        assert(cp.immediate.length < 2);
        if (cp.immediate.length == 0) {
            return
                keccak256(abi.encodePacked(Value.codePointTypeCode(), cp.opcode, cp.nextCodePoint));
        }
        return
            keccak256(
                abi.encodePacked(
                    Value.codePointTypeCode(),
                    cp.opcode,
                    cp.immediate[0].hash(),
                    cp.nextCodePoint
                )
            );
    }

    function hashTuplePreImage(bytes32 innerHash, uint256 valueSize)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(uint8(Value.tupleTypeCode()), innerHash, valueSize));
    }

    function hash(Value.Data memory val) internal pure returns (bytes32) {
        if (val.typeCode == Value.intTypeCode()) {
            return hashInt(val.intVal);
        } else if (val.typeCode == Value.codePointTypeCode()) {
            return hashCodePoint(val.cpVal);
        } else if (val.typeCode == Value.tuplePreImageTypeCode()) {
            return hashTuplePreImage(bytes32(val.intVal), val.size);
        } else if (val.typeCode == Value.tupleTypeCode()) {
            Value.Data memory preImage = getTuplePreImage(val.tupleVal);
            return preImage.hash();
        } else if (val.typeCode == Value.hashOnlyTypeCode()) {
            return bytes32(val.intVal);
        } else if (val.typeCode == Value.bufferTypeCode()) {
            return keccak256(abi.encodePacked(uint256(123), val.bufferHash));
        } else {
            require(false, "Invalid type code");
        }
    }

    function getTuplePreImage(Value.Data[] memory vals) internal pure returns (Value.Data memory) {
        require(vals.length <= 8, "Invalid tuple length");
        bytes32[] memory hashes = new bytes32[](vals.length);
        uint256 hashCount = hashes.length;
        uint256 size = 1;
        for (uint256 i = 0; i < hashCount; i++) {
            hashes[i] = vals[i].hash();
            size += vals[i].size;
        }
        bytes32 firstHash = keccak256(abi.encodePacked(uint8(hashes.length), hashes));
        return Value.newTuplePreImage(firstHash, size);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";

interface IOneStepProof {
    // Bridges is sequencer bridge then delayed bridge
    function executeStep(
        address[2] calldata bridges,
        uint256 initialMessagesRead,
        bytes32[2] calldata accs,
        bytes calldata proof,
        bytes calldata bproof
    )
        external
        view
        returns (
            uint64 gas,
            uint256 afterMessagesRead,
            bytes32[4] memory fields
        );

    function executeStepDebug(
        address[2] calldata bridges,
        uint256 initialMessagesRead,
        bytes32[2] calldata accs,
        bytes calldata proof,
        bytes calldata bproof
    ) external view returns (string memory startMachine, string memory afterMachine);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./Marshaling.sol";

import "../libraries/DebugPrint.sol";

library Machine {
    using Hashing for Value.Data;

    // Make sure these don't conflict with Challenge.MACHINE_UNREACHABLE (currently 100)
    uint256 internal constant MACHINE_EXTENSIVE = 0;
    uint256 internal constant MACHINE_ERRORSTOP = 1;
    uint256 internal constant MACHINE_HALT = 2;

    function addStackVal(Value.Data memory stackValHash, Value.Data memory valHash)
        internal
        pure
        returns (Value.Data memory)
    {
        Value.Data[] memory vals = new Value.Data[](2);
        vals[0] = valHash;
        vals[1] = stackValHash;

        return Hashing.getTuplePreImage(vals);
    }

    struct Data {
        bytes32 instructionStackHash;
        Value.Data dataStack;
        Value.Data auxStack;
        Value.Data registerVal;
        Value.Data staticVal;
        uint256 arbGasRemaining;
        bytes32 errHandlerHash;
        uint256 status;
    }

    function toString(Data memory machine) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Machine(",
                    DebugPrint.bytes32string(machine.instructionStackHash),
                    ", \n",
                    DebugPrint.bytes32string(machine.dataStack.hash()),
                    ", \n",
                    DebugPrint.bytes32string(machine.auxStack.hash()),
                    ", \n",
                    DebugPrint.bytes32string(machine.registerVal.hash()),
                    ", \n",
                    DebugPrint.bytes32string(machine.staticVal.hash()),
                    ", \n",
                    DebugPrint.uint2str(machine.arbGasRemaining),
                    ", \n",
                    DebugPrint.bytes32string(machine.errHandlerHash),
                    ")\n"
                )
            );
    }

    function setErrorStop(Data memory machine) internal pure {
        machine.status = MACHINE_ERRORSTOP;
    }

    function setHalt(Data memory machine) internal pure {
        machine.status = MACHINE_HALT;
    }

    function addDataStackValue(Data memory machine, Value.Data memory val) internal pure {
        machine.dataStack = addStackVal(machine.dataStack, val);
    }

    function addAuxStackValue(Data memory machine, Value.Data memory val) internal pure {
        machine.auxStack = addStackVal(machine.auxStack, val);
    }

    function addDataStackInt(Data memory machine, uint256 val) internal pure {
        machine.dataStack = addStackVal(machine.dataStack, Value.newInt(val));
    }

    function hash(Data memory machine) internal pure returns (bytes32) {
        if (machine.status == MACHINE_HALT) {
            return bytes32(uint256(0));
        } else if (machine.status == MACHINE_ERRORSTOP) {
            return bytes32(uint256(1));
        } else {
            return
                keccak256(
                    abi.encodePacked(
                        machine.instructionStackHash,
                        machine.dataStack.hash(),
                        machine.auxStack.hash(),
                        machine.registerVal.hash(),
                        machine.staticVal.hash(),
                        machine.arbGasRemaining,
                        machine.errHandlerHash
                    )
                );
        }
    }

    function clone(Data memory machine) internal pure returns (Data memory) {
        return
            Data(
                machine.instructionStackHash,
                machine.dataStack,
                machine.auxStack,
                machine.registerVal,
                machine.staticVal,
                machine.arbGasRemaining,
                machine.errHandlerHash,
                machine.status
            );
    }

    function deserializeMachine(bytes memory data, uint256 offset)
        internal
        pure
        returns (
            uint256, // offset
            Data memory // machine
        )
    {
        Data memory m;
        m.status = MACHINE_EXTENSIVE;
        uint256 instructionStack;
        uint256 errHandler;
        (offset, instructionStack) = Marshaling.deserializeInt(data, offset);

        (offset, m.dataStack) = Marshaling.deserializeHashPreImage(data, offset);
        (offset, m.auxStack) = Marshaling.deserializeHashPreImage(data, offset);
        (offset, m.registerVal) = Marshaling.deserialize(data, offset);
        (offset, m.staticVal) = Marshaling.deserialize(data, offset);
        (offset, m.arbGasRemaining) = Marshaling.deserializeInt(data, offset);
        (offset, errHandler) = Marshaling.deserializeInt(data, offset);

        m.instructionStackHash = bytes32(instructionStack);
        m.errHandlerHash = bytes32(errHandler);
        return (offset, m);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./Value.sol";
import "./Hashing.sol";

import "../libraries/BytesLib.sol";

library Marshaling {
    using BytesLib for bytes;
    using Value for Value.Data;

    // This depends on how it's implemented in arb-os
    function deserializeMessage(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            bool,
            uint256,
            address,
            uint8,
            bytes memory
        )
    {
        require(data.length >= startOffset && data.length - startOffset >= 8, "too short");
        uint256 size = 0;
        for (uint256 i = 0; i < 8; i++) {
            size *= 256;
            size += uint8(data[startOffset + 7 - i]);
        }
        (, uint256 sender) = deserializeInt(data, startOffset + 8);
        (, uint256 kind) = deserializeInt(data, startOffset + 8 + 32);
        bytes memory res = new bytes(size - 64);
        for (uint256 i = 0; i < size - 64; i++) {
            res[i] = data[startOffset + 8 + 64 + i];
        }
        return (true, startOffset + 8 + size, address(uint160(sender)), uint8(kind), res);
    }

    function deserializeRawMessage(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            bool,
            uint256,
            bytes memory
        )
    {
        require(data.length >= startOffset && data.length - startOffset >= 8, "too short");
        uint256 size = 0;
        for (uint256 i = 0; i < 8; i++) {
            size *= 256;
            size += uint8(data[startOffset + 7 - i]);
        }
        bytes memory res = new bytes(size);
        for (uint256 i = 0; i < size; i++) {
            res[i] = data[startOffset + 8 + i];
        }
        return (true, startOffset + 8 + size, res);
    }

    function deserializeHashPreImage(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (uint256 offset, Value.Data memory value)
    {
        require(data.length >= startOffset && data.length - startOffset >= 64, "too short");
        bytes32 hashData;
        uint256 size;
        (offset, hashData) = extractBytes32(data, startOffset);
        (offset, size) = deserializeInt(data, offset);
        return (offset, Value.newTuplePreImage(hashData, size));
    }

    function deserializeInt(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            uint256 // val
        )
    {
        require(data.length >= startOffset && data.length - startOffset >= 32, "too short");
        return (startOffset + 32, data.toUint(startOffset));
    }

    function deserializeBytes32(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            bytes32 // val
        )
    {
        require(data.length >= startOffset && data.length - startOffset >= 32, "too short");
        return (startOffset + 32, data.toBytes32(startOffset));
    }

    function deserializeCodePoint(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            Value.Data memory // val
        )
    {
        uint256 offset = startOffset;
        uint8 immediateType;
        uint8 opCode;
        Value.Data memory immediate;
        bytes32 nextHash;

        (offset, immediateType) = extractUint8(data, offset);
        (offset, opCode) = extractUint8(data, offset);
        if (immediateType == 1) {
            (offset, immediate) = deserialize(data, offset);
        }
        (offset, nextHash) = extractBytes32(data, offset);
        if (immediateType == 1) {
            return (offset, Value.newCodePoint(opCode, nextHash, immediate));
        }
        return (offset, Value.newCodePoint(opCode, nextHash));
    }

    function deserializeTuple(
        uint8 memberCount,
        bytes memory data,
        uint256 startOffset
    )
        internal
        pure
        returns (
            uint256, // offset
            Value.Data[] memory // val
        )
    {
        uint256 offset = startOffset;
        Value.Data[] memory members = new Value.Data[](memberCount);
        for (uint8 i = 0; i < memberCount; i++) {
            (offset, members[i]) = deserialize(data, offset);
        }
        return (offset, members);
    }

    function deserialize(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            Value.Data memory // val
        )
    {
        require(startOffset < data.length, "invalid offset");
        (uint256 offset, uint8 valType) = extractUint8(data, startOffset);
        if (valType == Value.intTypeCode()) {
            uint256 intVal;
            (offset, intVal) = deserializeInt(data, offset);
            return (offset, Value.newInt(intVal));
        } else if (valType == Value.codePointTypeCode()) {
            return deserializeCodePoint(data, offset);
        } else if (valType == Value.bufferTypeCode()) {
            bytes32 hashVal;
            (offset, hashVal) = deserializeBytes32(data, offset);
            return (offset, Value.newBuffer(hashVal));
        } else if (valType == Value.tuplePreImageTypeCode()) {
            return deserializeHashPreImage(data, offset);
        } else if (valType >= Value.tupleTypeCode() && valType < Value.valueTypeCode()) {
            uint8 tupLength = uint8(valType - Value.tupleTypeCode());
            Value.Data[] memory tupleVal;
            (offset, tupleVal) = deserializeTuple(tupLength, data, offset);
            return (offset, Value.newTuple(tupleVal));
        }
        require(false, "invalid typecode");
    }

    function extractUint8(bytes memory data, uint256 startOffset)
        private
        pure
        returns (
            uint256, // offset
            uint8 // val
        )
    {
        return (startOffset + 1, uint8(data[startOffset]));
    }

    function extractBytes32(bytes memory data, uint256 startOffset)
        private
        pure
        returns (
            uint256, // offset
            bytes32 // val
        )
    {
        return (startOffset + 32, data.toBytes32(startOffset));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*

Structure of the extra proofs passed to operations accessing buffers (d, array of words):
 * d_0: 32 bytes header, includes the locations of other proofs as the first 5 bytes b_0 ... b_1
 * The words d[b_0..b_1]: merkle proof for first access, first element is the leaf that is accessed
 * The words d[b_1..b_2]: normalization proof for the case the buffer shrinks
 * The words d[b_2..b_3]: merkle proof for second access
 * The words d[b_4..b_5]: normalization proof for second access

Structure of merkle proofs:
 * first element is the leaf
 * other elements are the adjacent subtrees
 * the location in the tree is known from the argument passed to opcodes
 * if the access is outside the tree, the merkle proof is needed to confirm the size of the tree, and is the accessed location mod the original size of the tree

Structure of normalization proof:
 * needed if the tree shrinks
 * has three words
 * height of the tree (minus one)
 * left subtree hash
 * right subtree hash
 * if the height of the tree is 0, the left subtree hash is the single leaf of the tree instead
 * right subtree hash is checked that it's not zero, this ensures that the resulting tree is of minimal height

*/

pragma solidity ^0.6.11;

import "./IOneStepProof.sol";
import "./OneStepProofCommon.sol";
import "./Value.sol";
import "./Machine.sol";

// Originally forked from https://github.com/leapdao/solEVM-enforcer/tree/master

contract OneStepProof2 is OneStepProofCommon {
    /* solhint-disable no-inline-assembly */

    function makeZeros() internal pure returns (bytes32[] memory) {
        bytes32[] memory zeros = new bytes32[](64);
        zeros[0] = keccak1(0);
        for (uint256 i = 1; i < 64; i++) {
            zeros[i] = keccak2(zeros[i - 1], zeros[i - 1]);
        }
        return zeros;
    }

    function keccak1(bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(b));
    }

    function keccak2(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }

    // hashes are normalized
    function get(
        bytes32 buf,
        uint256 loc,
        bytes32[] memory proof
    ) internal pure returns (bytes32) {
        // empty tree is full of zeros
        if (proof.length == 0) {
            require(buf == keccak1(bytes32(0)), "expected empty buffer");
            return 0;
        }
        bytes32 acc = keccak1(proof[0]);
        for (uint256 i = 1; i < proof.length; i++) {
            if (loc & 1 == 1) acc = keccak2(proof[i], acc);
            else acc = keccak2(acc, proof[i]);
            loc = loc >> 1;
        }
        require(acc == buf, "expected correct root");
        // maybe it is a zero outside the actual tree
        if (loc > 0) return 0;
        return proof[0];
    }

    function checkSize(
        bytes32 buf,
        uint256 loc,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        // empty tree is full of zeros
        if (proof.length == 0) {
            require(buf == keccak1(bytes32(0)), "expected empty buffer");
            return true;
        }
        bytes32 acc = keccak1(proof[0]);
        bool check = true;
        bytes32[] memory zeros = makeZeros();
        for (uint256 i = 1; i < proof.length; i++) {
            if (loc & 1 == 1) acc = keccak2(proof[i], acc);
            else {
                acc = keccak2(acc, proof[i]);
                check = check && proof[i] == zeros[i - 1];
            }
            loc = loc >> 1;
        }
        require(acc == buf, "expected correct root");
        // maybe it is a zero outside the actual tree
        if (loc > 0) return true;
        return check;
    }

    function calcHeight(uint256 loc) internal pure returns (uint256) {
        if (loc == 0) return 1;
        else return 1 + calcHeight(loc >> 1);
    }

    function set(
        bytes32 buf,
        uint256 loc,
        bytes32 v,
        bytes32[] memory proof,
        uint256 nh,
        bytes32 normal1,
        bytes32 normal2
    ) internal pure returns (bytes32) {
        // three possibilities, the tree depth stays same, it becomes lower or it's extended
        bytes32 acc = keccak1(v);
        // check that the proof matches original
        get(buf, loc, proof);
        bytes32[] memory zeros = makeZeros();
        // extended
        if (loc >= (1 << (proof.length - 1))) {
            if (v == 0) return buf;
            uint256 height = calcHeight(loc);
            // build the left branch
            for (uint256 i = proof.length; i < height - 1; i++) {
                buf = keccak2(buf, zeros[i - 1]);
            }
            for (uint256 i = 1; i < height - 1; i++) {
                if (loc & 1 == 1) acc = keccak2(zeros[i - 1], acc);
                else acc = keccak2(acc, zeros[i - 1]);
                loc = loc >> 1;
            }
            return keccak2(buf, acc);
        }
        for (uint256 i = 1; i < proof.length; i++) {
            bytes32 a = loc & 1 == 1 ? proof[i] : acc;
            bytes32 b = loc & 1 == 1 ? acc : proof[i];
            acc = keccak2(a, b);
            loc = loc >> 1;
        }
        if (v != bytes32(0)) return acc;
        bytes32 res;
        if (nh == 0) {
            // Here we specify the leaf hash directly, since we're at height 0
            // There's no need for the leaf to be non-zero
            res = normal1;
        } else {
            // Since this is a branch, prove that its right side isn't 0,
            // as that wouldn't be normalized
            require(normal2 != zeros[nh], "right subtree cannot be zero");
            res = keccak2(normal1, normal2);
        }
        bytes32 acc2 = res;
        for (uint256 i = nh; i < proof.length - 1; i++) {
            acc2 = keccak2(acc2, zeros[i]);
        }
        require(acc2 == acc, "expected match");
        return res;
    }

    function getByte(bytes32 word, uint256 num) internal pure returns (uint256) {
        return (uint256(word) >> ((31 - num) * 8)) & 0xff;
    }

    function setByte(
        bytes32 word,
        uint256 num,
        uint256 b
    ) internal pure returns (bytes32) {
        bytes memory arr = bytes32ToArray(word);
        arr[num] = bytes1(uint8(b));
        return bytes32(bytes32FromArray(arr));
    }

    function setByte(
        bytes32 word,
        uint256 num,
        bytes1 b
    ) internal pure returns (bytes32) {
        bytes memory arr = bytes32ToArray(word);
        arr[num] = b;
        return bytes32(bytes32FromArray(arr));
    }

    function decode(
        bytes memory arr,
        bytes1 _start,
        bytes1 _end
    ) internal pure returns (bytes32[] memory) {
        uint256 len = uint256(uint8(_end) - uint8(_start));
        uint256 start = uint256(uint8(_start));
        bytes32[] memory res = new bytes32[](len);
        for (uint256 i = 0; i < len; i++) {
            res[i] = bytes32(bytes32FromArray(arr, (start + i) * 32));
        }
        return res;
    }

    struct BufferProof {
        bytes32[] proof1;
        bytes32[] nproof1;
        bytes32[] proof2;
        bytes32[] nproof2;
    }

    function decodeProof(bytes memory proof) internal pure returns (BufferProof memory) {
        bytes32[] memory proof1 = decode(proof, proof[0], proof[1]);
        bytes32[] memory nproof1 = decode(proof, proof[1], proof[2]);
        bytes32[] memory proof2 = decode(proof, proof[2], proof[3]);
        bytes32[] memory nproof2 = decode(proof, proof[3], proof[4]);
        return BufferProof(proof1, nproof1, proof2, nproof2);
    }

    function bytes32FromArray(bytes memory arr) internal pure returns (uint256) {
        uint256 res = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            res = res << 8;
            res = res | uint256(uint8(arr[i]));
        }
        return res;
    }

    function bytes32FromArray(bytes memory arr, uint256 offset) internal pure returns (uint256) {
        uint256 res = 0;
        for (uint256 i = 0; i < 32; i++) {
            res = res << 8;
            res = res | uint256(uint8(arr[offset + i]));
        }
        return res;
    }

    function bytes32ToArray(bytes32 b) internal pure returns (bytes memory) {
        uint256 acc = uint256(b);
        bytes memory res = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            res[31 - i] = bytes1(uint8(acc));
            acc = acc >> 8;
        }
        return res;
    }

    function getBuffer8(
        bytes32 buf,
        uint256 offset,
        BufferProof memory proof
    ) internal pure returns (uint256) {
        return getByte(get(buf, offset / 32, proof.proof1), offset % 32);
    }

    function checkBufferSize(
        bytes32 buf,
        uint256 offset,
        BufferProof memory proof
    ) internal pure returns (bool) {
        bytes32 w = get(buf, offset / 32, proof.proof1);
        for (uint256 i = offset % 32; i < 32; i++) {
            if (getByte(w, i) != 0) return false;
        }
        return checkSize(buf, offset / 32, proof.proof1);
    }

    function getBuffer64(
        bytes32 buf,
        uint256 offset,
        BufferProof memory proof
    ) internal pure returns (uint256) {
        bytes memory res = new bytes(8);
        bytes32 word = get(buf, offset / 32, proof.proof1);
        if ((offset % 32) + 8 >= 32) {
            bytes32 word2 = get(buf, offset / 32 + 1, proof.proof2);
            for (uint256 i = 0; i < 8 - ((offset % 32) + 8 - 32); i++) {
                res[i] = bytes1(uint8(getByte(word, (offset % 32) + i)));
            }
            for (uint256 i = 8 - ((offset % 32) + 8 - 32); i < 8; i++) {
                res[i] = bytes1(uint8(getByte(word2, (offset + i) % 32)));
            }
        } else {
            for (uint256 i = 0; i < 8; i++) {
                res[i] = bytes1(uint8(getByte(word, (offset % 32) + i)));
            }
        }
        return bytes32FromArray(res);
    }

    function getBuffer256(
        bytes32 buf,
        uint256 offset,
        BufferProof memory proof
    ) internal pure returns (uint256) {
        bytes memory res = new bytes(32);
        bytes32 word = get(buf, offset / 32, proof.proof1);
        if ((offset % 32) + 32 >= 32) {
            bytes32 word2 = get(buf, offset / 32 + 1, proof.proof2);
            for (uint256 i = 0; i < 32 - ((offset % 32) + 32 - 32); i++) {
                res[i] = bytes1(uint8(getByte(word, (offset % 32) + i)));
            }
            for (uint256 i = 8 - ((offset % 32) + 32 - 32); i < 32; i++) {
                res[i] = bytes1(uint8(getByte(word2, (offset + i) % 32)));
            }
        } else {
            for (uint256 i = 0; i < 32; i++) {
                res[i] = bytes1(uint8(getByte(word, (offset % 32) + i)));
            }
        }
        return bytes32FromArray(res);
    }

    function set(
        bytes32 buf,
        uint256 loc,
        bytes32 v,
        bytes32[] memory proof,
        bytes32[] memory nproof
    ) internal pure returns (bytes32) {
        require(nproof.length == 3, "BAD_NORMALIZATION_PROOF");
        return set(buf, loc, v, proof, uint256(nproof[0]), nproof[1], nproof[2]);
    }

    function setBuffer8(
        bytes32 buf,
        uint256 offset,
        uint256 b,
        BufferProof memory proof
    ) internal pure returns (bytes32) {
        bytes32 word = get(buf, offset / 32, proof.proof1);
        bytes32 nword = setByte(word, offset % 32, b);
        bytes32 res = set(buf, offset / 32, nword, proof.proof1, proof.nproof1);
        return res;
    }

    function setBuffer64(
        bytes32 buf,
        uint256 offset,
        uint256 val,
        BufferProof memory proof
    ) internal pure returns (bytes32) {
        bytes memory arr = bytes32ToArray(bytes32(val));
        bytes32 nword = get(buf, offset / 32, proof.proof1);
        if ((offset % 32) + 8 > 32) {
            for (uint256 i = 0; i < 8 - ((offset % 32) + 8 - 32); i++) {
                nword = setByte(nword, (offset + i) % 32, arr[i + 24]);
            }
            buf = set(buf, offset / 32, nword, proof.proof1, proof.nproof1);
            bytes32 nword2 = get(buf, offset / 32 + 1, proof.proof2);
            for (uint256 i = 8 - ((offset % 32) + 8 - 32); i < 8; i++) {
                nword2 = setByte(nword2, (offset + i) % 32, arr[i + 24]);
            }
            buf = set(buf, offset / 32 + 1, nword2, proof.proof2, proof.nproof2);
        } else {
            for (uint256 i = 0; i < 8; i++) {
                nword = setByte(nword, (offset % 32) + i, arr[i + 24]);
            }
            buf = set(buf, offset / 32, nword, proof.proof1, proof.nproof1);
        }
        return buf;
    }

    function parseProof(bytes memory proof)
        public
        pure
        returns (
            bytes32[] memory,
            bytes32[] memory,
            bytes32[] memory,
            bytes32[] memory
        )
    {
        BufferProof memory p = decodeProof(proof);
        return (p.proof1, p.nproof1, p.proof2, p.nproof2);
    }

    function setBuffer256(
        bytes32 buf,
        uint256 offset,
        uint256 val,
        BufferProof memory proof
    ) internal pure returns (bytes32) {
        bytes memory arr = bytes32ToArray(bytes32(val));
        bytes32 nword = get(buf, offset / 32, proof.proof1);
        if ((offset % 32) + 32 > 32) {
            for (uint256 i = 0; i < 32 - ((offset % 32) + 32 - 32); i++) {
                nword = setByte(nword, (offset % 32) + i, arr[i]);
            }
            buf = set(buf, offset / 32, nword, proof.proof1, proof.nproof1);
            bytes32 nword2 = get(buf, offset / 32 + 1, proof.proof2);
            for (uint256 i = 32 - ((offset % 32) + 32 - 32); i < 32; i++) {
                nword2 = setByte(nword2, (offset + i) % 32, arr[i]);
            }
            buf = set(buf, offset / 32 + 1, nword2, proof.proof2, proof.nproof2);
        } else {
            for (uint256 i = 0; i < 32; i++) {
                nword = setByte(nword, (offset % 32) + i, arr[i]);
            }
            buf = set(buf, offset / 32, nword, proof.proof1, proof.nproof1);
        }
        return buf;
    }

    function executeSendInsn(AssertionContext memory context) internal pure {
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val1 = popVal(context.stack);
        if (!val2.isInt64() || !val1.isBuffer()) {
            handleOpcodeError(context);
            return;
        }
        if (val2.intVal > SEND_SIZE_LIMIT || val2.intVal == 0) {
            handleOpcodeError(context);
            return;
        }

        if (context.offset == context.proof.length) {
            // If we didn't pass the message data, the buffer must have been longer than the length param passed
            require(
                !checkBufferSize(val1.bufferHash, val2.intVal, decodeProof(context.bufProof)),
                "BUF_LENGTH"
            );
            handleOpcodeError(context);
            return;
        }

        // We've passed more data in the proof which is the data of the send because it isn't too long
        uint256 dataStart = context.offset;
        uint256 dataLength = val2.intVal;
        bytes memory proof = context.proof;
        bytes32 bufferHash = Hashing.bytesToBufferHash(proof, dataStart, dataLength);
        require(val1.hash() == bufferHash, "WRONG_SEND");

        bytes32 dataHash;
        assembly {
            dataHash := keccak256(add(add(proof, 32), dataStart), dataLength)
        }

        context.sendAcc = keccak256(abi.encodePacked(context.sendAcc, dataHash));
    }

    function executeGetBuffer8(AssertionContext memory context) internal pure {
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val1 = popVal(context.stack);
        if (!val2.isInt64() || !val1.isBuffer()) {
            handleOpcodeError(context);
            return;
        }
        if (val2.intVal >= 1 << 64) {
            handleOpcodeError(context);
            return;
        }
        uint256 res = getBuffer8(val1.bufferHash, val2.intVal, decodeProof(context.bufProof));
        pushVal(context.stack, Value.newInt(res));
    }

    function executeGetBuffer64(AssertionContext memory context) internal pure {
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val1 = popVal(context.stack);
        if (!val2.isInt64() || !val1.isBuffer()) {
            handleOpcodeError(context);
            return;
        }
        if (val2.intVal >= (1 << 64) - 7) {
            handleOpcodeError(context);
            return;
        }
        uint256 res = getBuffer64(val1.bufferHash, val2.intVal, decodeProof(context.bufProof));
        pushVal(context.stack, Value.newInt(res));
    }

    function executeGetBuffer256(AssertionContext memory context) internal pure {
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val1 = popVal(context.stack);
        if (!val2.isInt64() || !val1.isBuffer()) {
            handleOpcodeError(context);
            return;
        }
        if (val2.intVal >= (1 << 64) - 31) {
            handleOpcodeError(context);
            return;
        }
        uint256 res = getBuffer256(val1.bufferHash, val2.intVal, decodeProof(context.bufProof));
        pushVal(context.stack, Value.newInt(res));
    }

    function executeSetBuffer8(AssertionContext memory context) internal pure {
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        Value.Data memory val1 = popVal(context.stack);
        if (!val2.isInt64() || !val3.isInt() || !val1.isBuffer()) {
            handleOpcodeError(context);
            return;
        }
        if (val2.intVal >= 1 << 64 || val3.intVal >= 1 << 8) {
            handleOpcodeError(context);
            return;
        }
        bytes32 res =
            setBuffer8(val1.bufferHash, val2.intVal, val3.intVal, decodeProof(context.bufProof));
        pushVal(context.stack, Value.newBuffer(res));
    }

    function executeSetBuffer64(AssertionContext memory context) internal pure {
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        Value.Data memory val1 = popVal(context.stack);
        if (!val2.isInt64() || !val3.isInt() || !val1.isBuffer()) {
            handleOpcodeError(context);
            return;
        }
        if (val2.intVal >= (1 << 64) - 7 || val3.intVal >= 1 << 64) {
            handleOpcodeError(context);
            return;
        }
        bytes32 res =
            setBuffer64(val1.bufferHash, val2.intVal, val3.intVal, decodeProof(context.bufProof));
        pushVal(context.stack, Value.newBuffer(res));
    }

    function executeSetBuffer256(AssertionContext memory context) internal pure {
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        Value.Data memory val1 = popVal(context.stack);
        if (!val2.isInt64() || !val3.isInt() || !val1.isBuffer()) {
            handleOpcodeError(context);
            return;
        }
        if (val2.intVal >= (1 << 64) - 31) {
            handleOpcodeError(context);
            return;
        }
        bytes32 res =
            setBuffer256(val1.bufferHash, val2.intVal, val3.intVal, decodeProof(context.bufProof));
        pushVal(context.stack, Value.newBuffer(res));
    }

    function opInfo(uint256 opCode)
        internal
        pure
        override
        returns (
            uint256, // stack pops
            uint256, // auxstack pops
            uint64, // gas used
            function(AssertionContext memory) internal view // impl
        )
    {
        if (opCode == OP_GETBUFFER8) {
            return (2, 0, 10, executeGetBuffer8);
        } else if (opCode == OP_GETBUFFER64) {
            return (2, 0, 10, executeGetBuffer64);
        } else if (opCode == OP_GETBUFFER256) {
            return (2, 0, 10, executeGetBuffer256);
        } else if (opCode == OP_SETBUFFER8) {
            return (3, 0, 100, executeSetBuffer8);
        } else if (opCode == OP_SETBUFFER64) {
            return (3, 0, 100, executeSetBuffer64);
        } else if (opCode == OP_SETBUFFER256) {
            return (3, 0, 100, executeSetBuffer256);
        } else if (opCode == OP_SEND) {
            return (2, 0, 100, executeSendInsn);
        } else {
            revert("use another contract to handle other opcodes");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./IOneStepProof.sol";
import "./Value.sol";
import "./Machine.sol";
import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";

abstract contract OneStepProofCommon is IOneStepProof {
    using Machine for Machine.Data;
    using Hashing for Value.Data;
    using Value for Value.Data;

    uint256 internal constant MAX_UINT256 = ((1 << 128) + 1) * ((1 << 128) - 1);

    uint64 internal constant ERROR_GAS_COST = 5;

    string internal constant BAD_IMM_TYP = "BAD_IMM_TYP";
    string internal constant NO_IMM = "NO_IMM";
    string internal constant STACK_MISSING = "STACK_MISSING";
    string internal constant AUX_MISSING = "AUX_MISSING";
    string internal constant STACK_MANY = "STACK_MANY";
    string internal constant AUX_MANY = "AUX_MANY";
    string internal constant INBOX_VAL = "INBOX_VAL";

    // Stop and arithmetic ops
    uint8 internal constant OP_ADD = 0x01;
    uint8 internal constant OP_MUL = 0x02;
    uint8 internal constant OP_SUB = 0x03;
    uint8 internal constant OP_DIV = 0x04;
    uint8 internal constant OP_SDIV = 0x05;
    uint8 internal constant OP_MOD = 0x06;
    uint8 internal constant OP_SMOD = 0x07;
    uint8 internal constant OP_ADDMOD = 0x08;
    uint8 internal constant OP_MULMOD = 0x09;
    uint8 internal constant OP_EXP = 0x0a;
    uint8 internal constant OP_SIGNEXTEND = 0x0b;

    // Comparison & bitwise logic
    uint8 internal constant OP_LT = 0x10;
    uint8 internal constant OP_GT = 0x11;
    uint8 internal constant OP_SLT = 0x12;
    uint8 internal constant OP_SGT = 0x13;
    uint8 internal constant OP_EQ = 0x14;
    uint8 internal constant OP_ISZERO = 0x15;
    uint8 internal constant OP_AND = 0x16;
    uint8 internal constant OP_OR = 0x17;
    uint8 internal constant OP_XOR = 0x18;
    uint8 internal constant OP_NOT = 0x19;
    uint8 internal constant OP_BYTE = 0x1a;
    uint8 internal constant OP_SHL = 0x1b;
    uint8 internal constant OP_SHR = 0x1c;
    uint8 internal constant OP_SAR = 0x1d;

    // SHA3
    uint8 internal constant OP_HASH = 0x20;
    uint8 internal constant OP_TYPE = 0x21;
    uint8 internal constant OP_ETHHASH2 = 0x22;
    uint8 internal constant OP_KECCAK_F = 0x23;
    uint8 internal constant OP_SHA256_F = 0x24;

    // Stack, Memory, Storage and Flow Operations
    uint8 internal constant OP_POP = 0x30;
    uint8 internal constant OP_SPUSH = 0x31;
    uint8 internal constant OP_RPUSH = 0x32;
    uint8 internal constant OP_RSET = 0x33;
    uint8 internal constant OP_JUMP = 0x34;
    uint8 internal constant OP_CJUMP = 0x35;
    uint8 internal constant OP_STACKEMPTY = 0x36;
    uint8 internal constant OP_PCPUSH = 0x37;
    uint8 internal constant OP_AUXPUSH = 0x38;
    uint8 internal constant OP_AUXPOP = 0x39;
    uint8 internal constant OP_AUXSTACKEMPTY = 0x3a;
    uint8 internal constant OP_NOP = 0x3b;
    uint8 internal constant OP_ERRPUSH = 0x3c;
    uint8 internal constant OP_ERRSET = 0x3d;

    // Duplication and Exchange operations
    uint8 internal constant OP_DUP0 = 0x40;
    uint8 internal constant OP_DUP1 = 0x41;
    uint8 internal constant OP_DUP2 = 0x42;
    uint8 internal constant OP_SWAP1 = 0x43;
    uint8 internal constant OP_SWAP2 = 0x44;

    // Tuple operations
    uint8 internal constant OP_TGET = 0x50;
    uint8 internal constant OP_TSET = 0x51;
    uint8 internal constant OP_TLEN = 0x52;
    uint8 internal constant OP_XGET = 0x53;
    uint8 internal constant OP_XSET = 0x54;

    // Logging operations
    uint8 internal constant OP_BREAKPOINT = 0x60;
    uint8 internal constant OP_LOG = 0x61;

    // System operations
    uint8 internal constant OP_SEND = 0x70;
    // OP_INBOX_PEEK has been removed
    uint8 internal constant OP_INBOX = 0x72;
    uint8 internal constant OP_ERROR = 0x73;
    uint8 internal constant OP_STOP = 0x74;
    uint8 internal constant OP_SETGAS = 0x75;
    uint8 internal constant OP_PUSHGAS = 0x76;
    uint8 internal constant OP_ERR_CODE_POINT = 0x77;
    uint8 internal constant OP_PUSH_INSN = 0x78;
    uint8 internal constant OP_PUSH_INSN_IMM = 0x79;
    // uint8 private constant OP_OPEN_INSN = 0x7a;
    uint8 internal constant OP_SIDELOAD = 0x7b;

    uint8 internal constant OP_ECRECOVER = 0x80;
    uint8 internal constant OP_ECADD = 0x81;
    uint8 internal constant OP_ECMUL = 0x82;
    uint8 internal constant OP_ECPAIRING = 0x83;

    uint8 internal constant OP_DEBUGPRINT = 0x90;

    // Buffer operations
    uint8 internal constant OP_NEWBUFFER = 0xa0;
    uint8 internal constant OP_GETBUFFER8 = 0xa1;
    uint8 internal constant OP_GETBUFFER64 = 0xa2;
    uint8 internal constant OP_GETBUFFER256 = 0xa3;
    uint8 internal constant OP_SETBUFFER8 = 0xa4;
    uint8 internal constant OP_SETBUFFER64 = 0xa5;
    uint8 internal constant OP_SETBUFFER256 = 0xa6;

    uint8 internal constant CODE_POINT_TYPECODE = 1;
    bytes32 internal constant CODE_POINT_ERROR =
        keccak256(abi.encodePacked(CODE_POINT_TYPECODE, uint8(0), bytes32(0)));

    uint256 internal constant SEND_SIZE_LIMIT = 10000;

    // accs is [sendAcc, logAcc]
    function executeStep(
        address[2] calldata bridges,
        uint256 initialMessagesRead,
        bytes32[2] calldata accs,
        bytes calldata proof,
        bytes calldata bproof
    )
        external
        view
        override
        returns (
            uint64 gas,
            uint256 afterMessagesRead,
            bytes32[4] memory fields
        )
    {
        AssertionContext memory context =
            initializeExecutionContext(initialMessagesRead, accs, proof, bproof, bridges);

        executeOp(context);

        return returnContext(context);
    }

    function executeStepDebug(
        address[2] calldata bridges,
        uint256 initialMessagesRead,
        bytes32[2] calldata accs,
        bytes calldata proof,
        bytes calldata bproof
    ) external view override returns (string memory startMachine, string memory afterMachine) {
        AssertionContext memory context =
            initializeExecutionContext(initialMessagesRead, accs, proof, bproof, bridges);

        executeOp(context);
        startMachine = Machine.toString(context.startMachine);
        afterMachine = Machine.toString(context.afterMachine);
    }

    // fields
    // startMachineHash,
    // endMachineHash,
    // afterInboxAcc,
    // afterMessagesHash,
    // afterLogsHash

    function returnContext(AssertionContext memory context)
        internal
        pure
        returns (
            uint64 gas,
            uint256 afterMessagesRead,
            bytes32[4] memory fields
        )
    {
        return (
            context.gas,
            context.totalMessagesRead,
            [
                Machine.hash(context.startMachine),
                Machine.hash(context.afterMachine),
                context.sendAcc,
                context.logAcc
            ]
        );
    }

    struct ValueStack {
        uint256 length;
        Value.Data[] values;
    }

    function popVal(ValueStack memory stack) internal pure returns (Value.Data memory) {
        Value.Data memory val = stack.values[stack.length - 1];
        stack.length--;
        return val;
    }

    function pushVal(ValueStack memory stack, Value.Data memory val) internal pure {
        stack.values[stack.length] = val;
        stack.length++;
    }

    struct AssertionContext {
        ISequencerInbox sequencerBridge;
        IBridge delayedBridge;
        Machine.Data startMachine;
        Machine.Data afterMachine;
        uint256 totalMessagesRead;
        bytes32 sendAcc;
        bytes32 logAcc;
        uint64 gas;
        ValueStack stack;
        ValueStack auxstack;
        bool hadImmediate;
        uint8 opcode;
        bytes proof;
        uint256 offset;
        // merkle proofs for buffer
        bytes bufProof;
        bool errorOccurred;
    }

    function handleError(AssertionContext memory context) internal pure {
        context.errorOccurred = true;
    }

    function deductGas(AssertionContext memory context, uint64 amount)
        internal
        pure
        returns (bool)
    {
        if (context.afterMachine.arbGasRemaining < amount) {
            // ERROR + GAS_SET
            context.gas += ERROR_GAS_COST;
            context.afterMachine.arbGasRemaining = MAX_UINT256;
            return true;
        } else {
            context.gas += amount;
            context.afterMachine.arbGasRemaining -= amount;
            return false;
        }
    }

    function handleOpcodeError(AssertionContext memory context) internal pure {
        handleError(context);
    }

    function initializeExecutionContext(
        uint256 initialMessagesRead,
        bytes32[2] calldata accs,
        bytes memory proof,
        bytes memory bproof,
        address[2] calldata bridges
    ) internal pure returns (AssertionContext memory) {
        uint8 opCode = uint8(proof[0]);
        uint8 stackCount = uint8(proof[1]);
        uint8 auxstackCount = uint8(proof[2]);
        uint256 offset = 3;

        // Leave some extra space for values pushed on the stack in the proofs
        Value.Data[] memory stackVals = new Value.Data[](stackCount + 4);
        Value.Data[] memory auxstackVals = new Value.Data[](auxstackCount + 4);
        for (uint256 i = 0; i < stackCount; i++) {
            (offset, stackVals[i]) = Marshaling.deserialize(proof, offset);
        }
        for (uint256 i = 0; i < auxstackCount; i++) {
            (offset, auxstackVals[i]) = Marshaling.deserialize(proof, offset);
        }
        Machine.Data memory mach;
        (offset, mach) = Machine.deserializeMachine(proof, offset);

        uint8 immediate = uint8(proof[offset]);
        offset += 1;

        AssertionContext memory context;
        context.sequencerBridge = ISequencerInbox(bridges[0]);
        context.delayedBridge = IBridge(bridges[1]);
        context.startMachine = mach;
        context.afterMachine = mach.clone();
        context.totalMessagesRead = initialMessagesRead;
        context.sendAcc = accs[0];
        context.logAcc = accs[1];
        context.gas = 0;
        context.stack = ValueStack(stackCount, stackVals);
        context.auxstack = ValueStack(auxstackCount, auxstackVals);
        context.hadImmediate = immediate == 1;
        context.opcode = opCode;
        context.proof = proof;
        context.bufProof = bproof;
        context.errorOccurred = false;
        context.offset = offset;

        require(immediate == 0 || immediate == 1, BAD_IMM_TYP);
        Value.Data memory cp;
        if (immediate == 0) {
            cp = Value.newCodePoint(uint8(opCode), context.startMachine.instructionStackHash);
        } else {
            // If we have an immediate, there must be at least one stack value
            require(stackVals.length > 0, NO_IMM);
            cp = Value.newCodePoint(
                uint8(opCode),
                context.startMachine.instructionStackHash,
                stackVals[stackCount - 1]
            );
        }
        context.startMachine.instructionStackHash = cp.hash();

        // Add the stack and auxstack values to the start machine
        uint256 i = 0;
        for (i = 0; i < stackCount - immediate; i++) {
            context.startMachine.addDataStackValue(stackVals[i]);
        }
        for (i = 0; i < auxstackCount; i++) {
            context.startMachine.addAuxStackValue(auxstackVals[i]);
        }

        return context;
    }

    function executeOp(AssertionContext memory context) internal view {
        (
            uint256 dataPopCount,
            uint256 auxPopCount,
            uint64 gasCost,
            function(AssertionContext memory) internal view impl
        ) = opInfo(context.opcode);

        // Require the prover to submit the minimal number of stack items
        require(
            ((dataPopCount > 0 || !context.hadImmediate) && context.stack.length <= dataPopCount) ||
                (context.hadImmediate && dataPopCount == 0 && context.stack.length == 1),
            STACK_MANY
        );
        require(context.auxstack.length <= auxPopCount, AUX_MANY);

        // Update end machine gas remaining before running opcode
        if (context.stack.length < dataPopCount) {
            // If we have insufficient values, reject the proof unless the stack has been fully exhausted
            require(
                context.afterMachine.dataStack.hash() == Value.newEmptyTuple().hash(),
                STACK_MISSING
            );
            deductGas(context, ERROR_GAS_COST);
            // If the stack is empty, the instruction underflowed so we have hit an error
            handleError(context);
        } else if (context.auxstack.length < auxPopCount) {
            // If we have insufficient values, reject the proof unless the auxstack has been fully exhausted
            require(
                context.afterMachine.auxStack.hash() == Value.newEmptyTuple().hash(),
                AUX_MISSING
            );
            deductGas(context, ERROR_GAS_COST);
            // If the auxstack is empty, the instruction underflowed so we have hit an error
            handleError(context);
        } else if (deductGas(context, gasCost)) {
            handleError(context);
        } else {
            impl(context);
        }

        if (context.errorOccurred) {
            if (context.afterMachine.errHandlerHash == CODE_POINT_ERROR) {
                context.afterMachine.setErrorStop();
            } else {
                // Clear error
                context.errorOccurred = false;
                context.afterMachine.instructionStackHash = context.afterMachine.errHandlerHash;

                if (!(context.hadImmediate && dataPopCount == 0)) {
                    context.stack.length = 0;
                }
                context.auxstack.length = 0;
            }
        }

        // Add the stack and auxstack values to the start machine
        uint256 i = 0;

        for (i = 0; i < context.stack.length; i++) {
            context.afterMachine.addDataStackValue(context.stack.values[i]);
        }

        for (i = 0; i < context.auxstack.length; i++) {
            context.afterMachine.addAuxStackValue(context.auxstack.values[i]);
        }
    }

    function opInfo(uint256 opCode)
        internal
        pure
        virtual
        returns (
            uint256, // stack pops
            uint256, // auxstack pops
            uint64, // gas used
            function(AssertionContext memory) internal view // impl
        );
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

library Value {
    uint8 internal constant INT_TYPECODE = 0;
    uint8 internal constant CODE_POINT_TYPECODE = 1;
    uint8 internal constant HASH_PRE_IMAGE_TYPECODE = 2;
    uint8 internal constant TUPLE_TYPECODE = 3;
    uint8 internal constant BUFFER_TYPECODE = TUPLE_TYPECODE + 9;
    // All values received from clients will have type codes less than the VALUE_TYPE_COUNT
    uint8 internal constant VALUE_TYPE_COUNT = TUPLE_TYPECODE + 10;

    // The following types do not show up in the marshalled format and is
    // only used for internal tracking purposes
    uint8 internal constant HASH_ONLY = 100;

    struct CodePoint {
        uint8 opcode;
        bytes32 nextCodePoint;
        Data[] immediate;
    }

    struct Data {
        uint256 intVal;
        CodePoint cpVal;
        Data[] tupleVal;
        bytes32 bufferHash;
        uint8 typeCode;
        uint256 size;
    }

    function tupleTypeCode() internal pure returns (uint8) {
        return TUPLE_TYPECODE;
    }

    function tuplePreImageTypeCode() internal pure returns (uint8) {
        return HASH_PRE_IMAGE_TYPECODE;
    }

    function intTypeCode() internal pure returns (uint8) {
        return INT_TYPECODE;
    }

    function bufferTypeCode() internal pure returns (uint8) {
        return BUFFER_TYPECODE;
    }

    function codePointTypeCode() internal pure returns (uint8) {
        return CODE_POINT_TYPECODE;
    }

    function valueTypeCode() internal pure returns (uint8) {
        return VALUE_TYPE_COUNT;
    }

    function hashOnlyTypeCode() internal pure returns (uint8) {
        return HASH_ONLY;
    }

    function isValidTupleSize(uint256 size) internal pure returns (bool) {
        return size <= 8;
    }

    function typeCodeVal(Data memory val) internal pure returns (Data memory) {
        if (val.typeCode == 2) {
            // Map HashPreImage to Tuple
            return newInt(TUPLE_TYPECODE);
        }
        return newInt(val.typeCode);
    }

    function valLength(Data memory val) internal pure returns (uint8) {
        if (val.typeCode == TUPLE_TYPECODE) {
            return uint8(val.tupleVal.length);
        } else {
            return 1;
        }
    }

    function isInt(Data memory val) internal pure returns (bool) {
        return val.typeCode == INT_TYPECODE;
    }

    function isInt64(Data memory val) internal pure returns (bool) {
        return val.typeCode == INT_TYPECODE && val.intVal < (1 << 64);
    }

    function isCodePoint(Data memory val) internal pure returns (bool) {
        return val.typeCode == CODE_POINT_TYPECODE;
    }

    function isTuple(Data memory val) internal pure returns (bool) {
        return val.typeCode == TUPLE_TYPECODE;
    }

    function isBuffer(Data memory val) internal pure returns (bool) {
        return val.typeCode == BUFFER_TYPECODE;
    }

    function newEmptyTuple() internal pure returns (Data memory) {
        return newTuple(new Data[](0));
    }

    function newBoolean(bool val) internal pure returns (Data memory) {
        if (val) {
            return newInt(1);
        } else {
            return newInt(0);
        }
    }

    function newInt(uint256 _val) internal pure returns (Data memory) {
        return
            Data(_val, CodePoint(0, 0, new Data[](0)), new Data[](0), 0, INT_TYPECODE, uint256(1));
    }

    function newHashedValue(bytes32 valueHash, uint256 valueSize)
        internal
        pure
        returns (Data memory)
    {
        return
            Data(
                uint256(valueHash),
                CodePoint(0, 0, new Data[](0)),
                new Data[](0),
                0,
                HASH_ONLY,
                valueSize
            );
    }

    function newTuple(Data[] memory _val) internal pure returns (Data memory) {
        require(isValidTupleSize(_val.length), "Tuple must have valid size");
        uint256 size = 1;

        for (uint256 i = 0; i < _val.length; i++) {
            size += _val[i].size;
        }

        return Data(0, CodePoint(0, 0, new Data[](0)), _val, 0, TUPLE_TYPECODE, size);
    }

    function newTuplePreImage(bytes32 preImageHash, uint256 size)
        internal
        pure
        returns (Data memory)
    {
        return
            Data(
                uint256(preImageHash),
                CodePoint(0, 0, new Data[](0)),
                new Data[](0),
                0,
                HASH_PRE_IMAGE_TYPECODE,
                size
            );
    }

    function newCodePoint(uint8 opCode, bytes32 nextHash) internal pure returns (Data memory) {
        return newCodePoint(CodePoint(opCode, nextHash, new Data[](0)));
    }

    function newCodePoint(
        uint8 opCode,
        bytes32 nextHash,
        Data memory immediate
    ) internal pure returns (Data memory) {
        Data[] memory imm = new Data[](1);
        imm[0] = immediate;
        return newCodePoint(CodePoint(opCode, nextHash, imm));
    }

    function newCodePoint(CodePoint memory _val) private pure returns (Data memory) {
        return Data(0, _val, new Data[](0), 0, CODE_POINT_TYPECODE, uint256(1));
    }

    function newBuffer(bytes32 bufHash) internal pure returns (Data memory) {
        return
            Data(
                uint256(0),
                CodePoint(0, 0, new Data[](0)),
                new Data[](0),
                bufHash,
                BUFFER_TYPECODE,
                uint256(1)
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

interface ISequencerInbox {
    event SequencerBatchDelivered(
        uint256 indexed firstMessageNum,
        bytes32 indexed beforeAcc,
        uint256 newMessageCount,
        bytes32 afterAcc,
        bytes transactions,
        uint256[] lengths,
        uint256[] sectionsMetadata,
        uint256 seqBatchIndex,
        address sequencer
    );

    event SequencerBatchDeliveredFromOrigin(
        uint256 indexed firstMessageNum,
        bytes32 indexed beforeAcc,
        uint256 newMessageCount,
        bytes32 afterAcc,
        uint256 seqBatchIndex
    );

    event DelayedInboxForced(
        uint256 indexed firstMessageNum,
        bytes32 indexed beforeAcc,
        uint256 newMessageCount,
        uint256 totalDelayedMessagesRead,
        bytes32[2] afterAccAndDelayed,
        uint256 seqBatchIndex
    );

    event SequencerAddressUpdated(address newAddress);

    function setSequencer(address newSequencer) external;

    function messageCount() external view returns (uint256);

    function maxDelayBlocks() external view returns (uint256);

    function maxDelaySeconds() external view returns (uint256);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function proveBatchContainsSequenceNumber(bytes calldata proof, uint256 inboxCount)
        external
        view
        returns (uint256, bytes32);
}

// SPDX-License-Identifier: MIT

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

pragma solidity ^0.6.11;

/* solhint-disable no-inline-assembly */
library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= (_start + 20), "Read out of bounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= (_start + 1), "Read out of bounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }
}
/* solhint-enable no-inline-assembly */

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

library DebugPrint {
    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) {
            return bytes1(uint8(b) + 0x30);
        } else {
            return bytes1(uint8(b) + 0x57);
        }
    }

    function bytes32string(bytes32 b32) internal pure returns (string memory out) {
        bytes memory s = new bytes(64);

        for (uint256 i = 0; i < 32; i++) {
            bytes1 b = bytes1(b32[i]);
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[i * 2] = char(hi);
            s[i * 2 + 1] = char(lo);
        }

        out = string(s);
    }

    // Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function uint2str(uint256 _iParam) internal pure returns (string memory _uintAsString) {
        uint256 _i = _iParam;
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
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
    "runs": 100
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