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

pragma solidity ^0.6.11;

import "./IOneStepProof.sol";
import "./OneStepProofCommon.sol";

import "../bridge/Messages.sol";

import "../libraries/BytesLib.sol";

// Originally forked from https://github.com/leapdao/solEVM-enforcer/tree/master

contract OneStepProof is OneStepProofCommon {
    using Machine for Machine.Data;
    using Hashing for Value.Data;
    using Value for Value.Data;
    using BytesLib for bytes;

    uint256 private constant MAX_PAIRING_COUNT = 30;
    uint64 internal constant EC_PAIRING_BASE_GAS_COST = 1000;
    uint64 internal constant EC_PAIRING_POINT_GAS_COST = 500000;

    /* solhint-disable no-inline-assembly */

    // Arithmetic

    function binaryMathOp(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        if (!val1.isInt() || !val2.isInt()) {
            handleOpcodeError(context);
            return;
        }
        uint256 a = val1.intVal;
        uint256 b = val2.intVal;

        uint256 c;
        if (context.opcode == OP_ADD) {
            assembly {
                c := add(a, b)
            }
        } else if (context.opcode == OP_MUL) {
            assembly {
                c := mul(a, b)
            }
        } else if (context.opcode == OP_SUB) {
            assembly {
                c := sub(a, b)
            }
        } else if (context.opcode == OP_EXP) {
            assembly {
                c := exp(a, b)
            }
        } else if (context.opcode == OP_SIGNEXTEND) {
            assembly {
                c := signextend(a, b)
            }
        } else if (context.opcode == OP_LT) {
            assembly {
                c := lt(a, b)
            }
        } else if (context.opcode == OP_GT) {
            assembly {
                c := gt(a, b)
            }
        } else if (context.opcode == OP_SLT) {
            assembly {
                c := slt(a, b)
            }
        } else if (context.opcode == OP_SGT) {
            assembly {
                c := sgt(a, b)
            }
        } else if (context.opcode == OP_AND) {
            assembly {
                c := and(a, b)
            }
        } else if (context.opcode == OP_OR) {
            assembly {
                c := or(a, b)
            }
        } else if (context.opcode == OP_XOR) {
            assembly {
                c := xor(a, b)
            }
        } else if (context.opcode == OP_BYTE) {
            assembly {
                c := byte(a, b)
            }
        } else if (context.opcode == OP_SHL) {
            assembly {
                c := shl(a, b)
            }
        } else if (context.opcode == OP_SHR) {
            assembly {
                c := shr(a, b)
            }
        } else if (context.opcode == OP_SAR) {
            assembly {
                c := sar(a, b)
            }
        } else if (context.opcode == OP_ETHHASH2) {
            c = uint256(keccak256(abi.encodePacked(a, b)));
        } else {
            assert(false);
        }

        pushVal(context.stack, Value.newInt(c));
    }

    function binaryMathOpZero(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        if (!val1.isInt() || !val2.isInt() || val2.intVal == 0) {
            handleOpcodeError(context);
            return;
        }
        uint256 a = val1.intVal;
        uint256 b = val2.intVal;

        uint256 c;
        if (context.opcode == OP_DIV) {
            assembly {
                c := div(a, b)
            }
        } else if (context.opcode == OP_SDIV) {
            assembly {
                c := sdiv(a, b)
            }
        } else if (context.opcode == OP_MOD) {
            assembly {
                c := mod(a, b)
            }
        } else if (context.opcode == OP_SMOD) {
            assembly {
                c := smod(a, b)
            }
        } else {
            assert(false);
        }

        pushVal(context.stack, Value.newInt(c));
    }

    function executeMathModInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        if (!val1.isInt() || !val2.isInt() || !val3.isInt() || val3.intVal == 0) {
            handleOpcodeError(context);
            return;
        }
        uint256 a = val1.intVal;
        uint256 b = val2.intVal;
        uint256 m = val3.intVal;

        uint256 c;

        if (context.opcode == OP_ADDMOD) {
            assembly {
                c := addmod(a, b, m)
            }
        } else if (context.opcode == OP_MULMOD) {
            assembly {
                c := mulmod(a, b, m)
            }
        } else {
            assert(false);
        }

        pushVal(context.stack, Value.newInt(c));
    }

    function executeEqInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        pushVal(context.stack, Value.newBoolean(val1.hash() == val2.hash()));
    }

    function executeIszeroInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        if (!val1.isInt()) {
            handleOpcodeError(context);
            return;
        }
        uint256 a = val1.intVal;
        uint256 c;
        assembly {
            c := iszero(a)
        }
        pushVal(context.stack, Value.newInt(c));
    }

    function executeNotInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        if (!val1.isInt()) {
            handleOpcodeError(context);
            return;
        }
        uint256 a = val1.intVal;
        uint256 c;
        assembly {
            c := not(a)
        }
        pushVal(context.stack, Value.newInt(c));
    }

    /* solhint-enable no-inline-assembly */

    // Stack ops

    function executePopInsn(AssertionContext memory context) internal pure {
        popVal(context.stack);
    }

    function executeSpushInsn(AssertionContext memory context) internal pure {
        pushVal(context.stack, context.afterMachine.staticVal);
    }

    function executeRpushInsn(AssertionContext memory context) internal pure {
        pushVal(context.stack, context.afterMachine.registerVal);
    }

    function executeRsetInsn(AssertionContext memory context) internal pure {
        context.afterMachine.registerVal = popVal(context.stack);
    }

    function executeJumpInsn(AssertionContext memory context) internal pure {
        Value.Data memory val = popVal(context.stack);
        if (!val.isCodePoint()) {
            handleOpcodeError(context);
            return;
        }
        context.afterMachine.instructionStackHash = val.hash();
    }

    function executeCjumpInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        if (!val1.isCodePoint() || !val2.isInt()) {
            handleOpcodeError(context);
            return;
        }
        if (val2.intVal != 0) {
            context.afterMachine.instructionStackHash = val1.hash();
        }
    }

    function executeStackemptyInsn(AssertionContext memory context) internal pure {
        bool empty =
            context.stack.length == 0 &&
                context.afterMachine.dataStack.hash() == Value.newEmptyTuple().hash();
        pushVal(context.stack, Value.newBoolean(empty));
    }

    function executePcpushInsn(AssertionContext memory context) internal pure {
        pushVal(context.stack, Value.newHashedValue(context.startMachine.instructionStackHash, 1));
    }

    function executeAuxpushInsn(AssertionContext memory context) internal pure {
        pushVal(context.auxstack, popVal(context.stack));
    }

    function executeAuxpopInsn(AssertionContext memory context) internal pure {
        pushVal(context.stack, popVal(context.auxstack));
    }

    function executeAuxstackemptyInsn(AssertionContext memory context) internal pure {
        bool empty =
            context.auxstack.length == 0 &&
                context.afterMachine.auxStack.hash() == Value.newEmptyTuple().hash();
        pushVal(context.stack, Value.newBoolean(empty));
    }

    /* solhint-disable-next-line no-empty-blocks */
    function executeNopInsn(AssertionContext memory) internal pure {}

    function executeErrpushInsn(AssertionContext memory context) internal pure {
        pushVal(context.stack, Value.newHashedValue(context.afterMachine.errHandlerHash, 1));
    }

    function executeErrsetInsn(AssertionContext memory context) internal pure {
        Value.Data memory val = popVal(context.stack);
        if (!val.isCodePoint()) {
            handleOpcodeError(context);
            return;
        }
        context.afterMachine.errHandlerHash = val.hash();
    }

    // Dup ops

    function executeDup0Insn(AssertionContext memory context) internal pure {
        Value.Data memory val = popVal(context.stack);
        pushVal(context.stack, val);
        pushVal(context.stack, val);
    }

    function executeDup1Insn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        pushVal(context.stack, val2);
        pushVal(context.stack, val1);
        pushVal(context.stack, val2);
    }

    function executeDup2Insn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        pushVal(context.stack, val3);
        pushVal(context.stack, val2);
        pushVal(context.stack, val1);
        pushVal(context.stack, val3);
    }

    // Swap ops

    function executeSwap1Insn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        pushVal(context.stack, val1);
        pushVal(context.stack, val2);
    }

    function executeSwap2Insn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        pushVal(context.stack, val1);
        pushVal(context.stack, val2);
        pushVal(context.stack, val3);
    }

    // Tuple ops

    function executeTgetInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        if (!val1.isInt() || !val2.isTuple() || val1.intVal >= val2.valLength()) {
            handleOpcodeError(context);
            return;
        }
        pushVal(context.stack, val2.tupleVal[val1.intVal]);
    }

    function executeTsetInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        if (!val1.isInt() || !val2.isTuple() || val1.intVal >= val2.valLength()) {
            handleOpcodeError(context);
            return;
        }
        Value.Data[] memory tupleVals = val2.tupleVal;
        tupleVals[val1.intVal] = val3;
        pushVal(context.stack, Value.newTuple(tupleVals));
    }

    function executeTlenInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        if (!val1.isTuple()) {
            handleOpcodeError(context);
            return;
        }
        pushVal(context.stack, Value.newInt(val1.valLength()));
    }

    function executeXgetInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory auxVal = popVal(context.auxstack);
        if (!val1.isInt() || !auxVal.isTuple() || val1.intVal >= auxVal.valLength()) {
            handleOpcodeError(context);
            return;
        }
        pushVal(context.auxstack, auxVal);
        pushVal(context.stack, auxVal.tupleVal[val1.intVal]);
    }

    function executeXsetInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory auxVal = popVal(context.auxstack);
        if (!auxVal.isTuple() || !val1.isInt() || val1.intVal >= auxVal.valLength()) {
            handleOpcodeError(context);
            return;
        }
        Value.Data[] memory tupleVals = auxVal.tupleVal;
        tupleVals[val1.intVal] = val2;
        pushVal(context.auxstack, Value.newTuple(tupleVals));
    }

    // Logging

    function executeLogInsn(AssertionContext memory context) internal pure {
        context.logAcc = keccak256(abi.encodePacked(context.logAcc, popVal(context.stack).hash()));
    }

    // System operations

    function incrementInbox(AssertionContext memory context)
        private
        view
        returns (Value.Data memory message)
    {
        bytes memory proof = context.proof;

        // [messageHash, prefixHash, messageDataHash]
        bytes32[3] memory messageHashes;
        uint256 inboxSeqNum;
        Value.Data[] memory tupData = new Value.Data[](8);

        {
            // Get message out of proof
            uint8 kind = uint8(proof[context.offset]);
            context.offset++;
            uint256 l1BlockNumber;
            uint256 l1Timestamp;
            uint256 gasPriceL1;
            address sender = proof.toAddress(context.offset);
            context.offset += 20;
            (context.offset, l1BlockNumber) = Marshaling.deserializeInt(proof, context.offset);
            (context.offset, l1Timestamp) = Marshaling.deserializeInt(proof, context.offset);
            (context.offset, inboxSeqNum) = Marshaling.deserializeInt(proof, context.offset);
            (context.offset, gasPriceL1) = Marshaling.deserializeInt(proof, context.offset);
            uint256 messageDataLength;
            (context.offset, messageDataLength) = Marshaling.deserializeInt(proof, context.offset);
            bytes32 messageBufHash =
                Hashing.bytesToBufferHash(proof, context.offset, messageDataLength);

            uint256 offset = context.offset;
            bytes32 messageDataHash;
            assembly {
                messageDataHash := keccak256(add(add(proof, 32), offset), messageDataLength)
            }
            context.offset += messageDataLength;

            messageHashes[0] = Messages.messageHash(
                kind,
                sender,
                l1BlockNumber,
                l1Timestamp,
                inboxSeqNum,
                gasPriceL1,
                messageDataHash
            );

            uint8 expectedSeqKind;
            if (messageDataLength > 0) {
                // L2_MSG
                expectedSeqKind = 3;
            } else {
                // END_OF_BLOCK_MESSAGE
                expectedSeqKind = 6;
            }
            if (kind == expectedSeqKind && gasPriceL1 == 0) {
                // Between the checks in the if statement, inboxSeqNum, and messageHashes[1:],
                // this constrains all fields without the full message hash.
                messageHashes[1] = keccak256(abi.encodePacked(sender, l1BlockNumber, l1Timestamp));
                messageHashes[2] = messageDataHash;
            }

            tupData[0] = Value.newInt(uint256(kind));
            tupData[1] = Value.newInt(l1BlockNumber);
            tupData[2] = Value.newInt(l1Timestamp);
            tupData[3] = Value.newInt(uint256(sender));
            tupData[4] = Value.newInt(inboxSeqNum);
            tupData[5] = Value.newInt(gasPriceL1);
            tupData[6] = Value.newInt(messageDataLength);
            tupData[7] = Value.newHashedValue(messageBufHash, 1);
        }

        uint256 seqBatchNum;
        (context.offset, seqBatchNum) = Marshaling.deserializeInt(proof, context.offset);
        uint8 isDelayed = uint8(proof[context.offset]);
        context.offset++;
        require(isDelayed == 0 || isDelayed == 1, "IS_DELAYED_VAL");

        bytes32 acc;
        (context.offset, acc) = Marshaling.deserializeBytes32(proof, context.offset);
        if (isDelayed == 0) {
            // Start the proof at an arbitrary previous accumulator, as we validate the end accumulator.
            acc = keccak256(abi.encodePacked(acc, inboxSeqNum, messageHashes[1], messageHashes[2]));

            require(inboxSeqNum == context.totalMessagesRead, "WRONG_SEQUENCER_MSG_SEQ_NUM");
            inboxSeqNum++;
        } else {
            // Read in delayed batch info from the proof. These fields are all part of the accumulator hash.
            uint256 firstSequencerSeqNum;
            uint256 delayedStart;
            uint256 delayedEnd;
            (context.offset, firstSequencerSeqNum) = Marshaling.deserializeInt(
                proof,
                context.offset
            );
            (context.offset, delayedStart) = Marshaling.deserializeInt(proof, context.offset);
            (context.offset, delayedEnd) = Marshaling.deserializeInt(proof, context.offset);
            bytes32 delayedEndAcc = context.delayedBridge.inboxAccs(delayedEnd - 1);

            // Validate the delayed message is included in this sequencer batch.
            require(inboxSeqNum >= delayedStart, "DELAYED_START");
            require(inboxSeqNum < delayedEnd, "DELAYED_END");

            // Validate the delayed message is in the delayed inbox.
            bytes32 prevDelayedAcc = 0;
            if (inboxSeqNum > 0) {
                prevDelayedAcc = context.delayedBridge.inboxAccs(inboxSeqNum - 1);
            }
            require(
                Messages.addMessageToInbox(prevDelayedAcc, messageHashes[0]) ==
                    context.delayedBridge.inboxAccs(inboxSeqNum),
                "DELAYED_ACC"
            );

            // Delayed messages are sequenced into a separate sequence number space with the upper bit set.
            // Note that messageHash is no longer accurate after this point, as this modifies the message.
            tupData[4] = Value.newInt(inboxSeqNum | (1 << 255));
            // Confirm that this fits into the correct position of the sequencer sequence.
            require(
                inboxSeqNum - delayedStart + firstSequencerSeqNum == context.totalMessagesRead,
                "WRONG_DELAYED_MSG_SEQ_NUM"
            );

            acc = keccak256(
                abi.encodePacked(
                    "Delayed messages:",
                    acc,
                    firstSequencerSeqNum,
                    delayedStart,
                    delayedEnd,
                    delayedEndAcc
                )
            );
            inboxSeqNum = firstSequencerSeqNum + (delayedEnd - delayedStart);
        }

        // Get to the end of the batch by hashing in arbitrary future sequencer messages.
        while (true) {
            // 0 = sequencer message
            // 1 = delayed message batch
            // 2 = end of batch
            isDelayed = uint8(proof[context.offset]);
            if (isDelayed == 2) {
                break;
            }
            require(isDelayed == 0 || isDelayed == 1, "REM_IS_DELAYED_VAL");
            context.offset++;
            if (isDelayed == 0) {
                bytes32 newerMessagePrefixHash;
                bytes32 newerMessageDataHash;
                (context.offset, newerMessagePrefixHash) = Marshaling.deserializeBytes32(
                    proof,
                    context.offset
                );
                (context.offset, newerMessageDataHash) = Marshaling.deserializeBytes32(
                    proof,
                    context.offset
                );
                acc = keccak256(
                    abi.encodePacked(acc, inboxSeqNum, newerMessagePrefixHash, newerMessageDataHash)
                );
                inboxSeqNum++;
            } else {
                uint256 delayedStart;
                uint256 delayedEnd;
                (context.offset, delayedStart) = Marshaling.deserializeInt(proof, context.offset);
                (context.offset, delayedEnd) = Marshaling.deserializeInt(proof, context.offset);
                acc = keccak256(
                    abi.encodePacked(
                        "Delayed messages:",
                        acc,
                        inboxSeqNum,
                        delayedStart,
                        delayedEnd,
                        context.delayedBridge.inboxAccs(delayedEnd - 1)
                    )
                );
                inboxSeqNum += delayedEnd - delayedStart;
            }
        }

        require(acc == context.sequencerBridge.inboxAccs(seqBatchNum), "WRONG_BATCH_ACC");

        context.totalMessagesRead++;

        return Value.newTuple(tupData);
    }

    function executeInboxInsn(AssertionContext memory context) internal view {
        pushVal(context.stack, incrementInbox(context));
    }

    function executeSetGasInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        if (!val1.isInt()) {
            handleOpcodeError(context);
            return;
        }
        context.afterMachine.arbGasRemaining = val1.intVal;
    }

    function executePushGasInsn(AssertionContext memory context) internal pure {
        pushVal(context.stack, Value.newInt(context.afterMachine.arbGasRemaining));
    }

    function executeErrCodePointInsn(AssertionContext memory context) internal pure {
        pushVal(context.stack, Value.newHashedValue(CODE_POINT_ERROR, 1));
    }

    function executePushInsnInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        if (!val1.isInt() || !val2.isCodePoint()) {
            handleOpcodeError(context);
            return;
        }
        pushVal(context.stack, Value.newCodePoint(uint8(val1.intVal), val2.hash()));
    }

    function executePushInsnImmInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        if (!val1.isInt() || !val3.isCodePoint()) {
            handleOpcodeError(context);
            return;
        }
        pushVal(context.stack, Value.newCodePoint(uint8(val1.intVal), val3.hash(), val2));
    }

    function executeSideloadInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        if (!val1.isInt()) {
            handleOpcodeError(context);
            return;
        }
        Value.Data[] memory values = new Value.Data[](0);
        pushVal(context.stack, Value.newTuple(values));
    }

    function executeECRecoverInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        Value.Data memory val4 = popVal(context.stack);
        if (!val1.isInt() || !val2.isInt() || !val3.isInt() || !val4.isInt()) {
            handleOpcodeError(context);
            return;
        }
        bytes32 r = bytes32(val1.intVal);
        bytes32 s = bytes32(val2.intVal);
        if (val3.intVal != 0 && val3.intVal != 1) {
            pushVal(context.stack, Value.newInt(0));
            return;
        }
        uint8 v = uint8(val3.intVal) + 27;
        bytes32 message = bytes32(val4.intVal);
        address ret = ecrecover(message, v, r, s);
        pushVal(context.stack, Value.newInt(uint256(ret)));
    }

    /* solhint-disable no-inline-assembly */

    function executeECAddInsn(AssertionContext memory context) internal view {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        Value.Data memory val4 = popVal(context.stack);
        if (!val1.isInt() || !val2.isInt() || !val3.isInt() || !val4.isInt()) {
            handleOpcodeError(context);
            return;
        }
        uint256[4] memory bnAddInput = [val1.intVal, val2.intVal, val3.intVal, val4.intVal];
        uint256[2] memory ret;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, bnAddInput, 0x80, ret, 0x40)
        }
        if (!success) {
            // Must end on empty tuple
            handleOpcodeError(context);
            return;
        }
        pushVal(context.stack, Value.newInt(uint256(ret[1])));
        pushVal(context.stack, Value.newInt(uint256(ret[0])));
    }

    function executeECMulInsn(AssertionContext memory context) internal view {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        if (!val1.isInt() || !val2.isInt() || !val3.isInt()) {
            handleOpcodeError(context);
            return;
        }
        uint256[3] memory bnAddInput = [val1.intVal, val2.intVal, val3.intVal];
        uint256[2] memory ret;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, bnAddInput, 0x80, ret, 0x40)
        }
        if (!success) {
            // Must end on empty tuple
            handleOpcodeError(context);
            return;
        }
        pushVal(context.stack, Value.newInt(uint256(ret[1])));
        pushVal(context.stack, Value.newInt(uint256(ret[0])));
    }

    function executeECPairingInsn(AssertionContext memory context) internal view {
        Value.Data memory val = popVal(context.stack);

        Value.Data[MAX_PAIRING_COUNT] memory items;
        bool postGasError = false;
        uint256 count;
        for (count = 0; count < MAX_PAIRING_COUNT; count++) {
            if (!val.isTuple()) {
                postGasError = true;
                break;
            }
            Value.Data[] memory stackTupleVals = val.tupleVal;
            if (stackTupleVals.length == 0) {
                // We reached the bottom of the stack
                break;
            }
            if (stackTupleVals.length != 2) {
                postGasError = true;
                break;
            }
            items[count] = stackTupleVals[0];
            val = stackTupleVals[1];
        }

        if (deductGas(context, uint64(EC_PAIRING_POINT_GAS_COST * count))) {
            // When we run out of gas, we only charge for an error + gas_set
            // That means we need to deduct the previously charged base cost here
            context.gas -= EC_PAIRING_BASE_GAS_COST;
            handleError(context);
            return;
        }

        if (postGasError || !val.isTuple() || val.tupleVal.length != 0) {
            // Must end on empty tuple
            handleOpcodeError(context);
            return;
        }

        // Allocate the maximum amount of space we might need
        uint256[MAX_PAIRING_COUNT * 6] memory input;
        for (uint256 i = 0; i < count; i++) {
            Value.Data memory pointVal = items[i];
            if (!pointVal.isTuple()) {
                handleOpcodeError(context);
                return;
            }

            Value.Data[] memory pointTupleVals = pointVal.tupleVal;
            if (pointTupleVals.length != 6) {
                handleOpcodeError(context);
                return;
            }

            for (uint256 j = 0; j < 6; j++) {
                if (!pointTupleVals[j].isInt()) {
                    handleOpcodeError(context);
                    return;
                }
            }
            input[i * 6] = pointTupleVals[0].intVal;
            input[i * 6 + 1] = pointTupleVals[1].intVal;
            input[i * 6 + 2] = pointTupleVals[3].intVal;
            input[i * 6 + 3] = pointTupleVals[2].intVal;
            input[i * 6 + 4] = pointTupleVals[5].intVal;
            input[i * 6 + 5] = pointTupleVals[4].intVal;
        }

        uint256 inputSize = count * 6 * 0x20;
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, inputSize, out, 0x20)
        }

        if (!success) {
            handleOpcodeError(context);
            return;
        }

        pushVal(context.stack, Value.newBoolean(out[0] != 0));
    }

    /* solhint-enable no-inline-assembly */

    function executeErrorInsn(AssertionContext memory context) internal pure {
        handleOpcodeError(context);
    }

    function executeStopInsn(AssertionContext memory context) internal pure {
        context.afterMachine.setHalt();
    }

    function executeNewBuffer(AssertionContext memory context) internal pure {
        pushVal(context.stack, Value.newBuffer(keccak256(abi.encodePacked(bytes32(0)))));
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
        if (opCode == OP_ADD || opCode == OP_MUL || opCode == OP_SUB) {
            return (2, 0, 3, binaryMathOp);
        } else if (opCode == OP_DIV || opCode == OP_MOD) {
            return (2, 0, 4, binaryMathOpZero);
        } else if (opCode == OP_SDIV || opCode == OP_SMOD) {
            return (2, 0, 7, binaryMathOpZero);
        } else if (opCode == OP_ADDMOD || opCode == OP_MULMOD) {
            return (3, 0, 4, executeMathModInsn);
        } else if (opCode == OP_EXP) {
            return (2, 0, 25, binaryMathOp);
        } else if (opCode == OP_SIGNEXTEND) {
            return (2, 0, 7, binaryMathOp);
        } else if (
            opCode == OP_LT ||
            opCode == OP_GT ||
            opCode == OP_SLT ||
            opCode == OP_SGT ||
            opCode == OP_AND ||
            opCode == OP_OR ||
            opCode == OP_XOR
        ) {
            return (2, 0, 2, binaryMathOp);
        } else if (opCode == OP_EQ) {
            return (2, 0, 2, executeEqInsn);
        } else if (opCode == OP_ISZERO) {
            return (1, 0, 1, executeIszeroInsn);
        } else if (opCode == OP_NOT) {
            return (1, 0, 1, executeNotInsn);
        } else if (opCode == OP_BYTE || opCode == OP_SHL || opCode == OP_SHR || opCode == OP_SAR) {
            return (2, 0, 4, binaryMathOp);
        } else if (opCode == OP_POP) {
            return (1, 0, 1, executePopInsn);
        } else if (opCode == OP_SPUSH) {
            return (0, 0, 1, executeSpushInsn);
        } else if (opCode == OP_RPUSH) {
            return (0, 0, 1, executeRpushInsn);
        } else if (opCode == OP_RSET) {
            return (1, 0, 2, executeRsetInsn);
        } else if (opCode == OP_JUMP) {
            return (1, 0, 4, executeJumpInsn);
        } else if (opCode == OP_CJUMP) {
            return (2, 0, 4, executeCjumpInsn);
        } else if (opCode == OP_STACKEMPTY) {
            return (0, 0, 2, executeStackemptyInsn);
        } else if (opCode == OP_PCPUSH) {
            return (0, 0, 1, executePcpushInsn);
        } else if (opCode == OP_AUXPUSH) {
            return (1, 0, 1, executeAuxpushInsn);
        } else if (opCode == OP_AUXPOP) {
            return (0, 1, 1, executeAuxpopInsn);
        } else if (opCode == OP_AUXSTACKEMPTY) {
            return (0, 0, 2, executeAuxstackemptyInsn);
        } else if (opCode == OP_NOP) {
            return (0, 0, 1, executeNopInsn);
        } else if (opCode == OP_ERRPUSH) {
            return (0, 0, 1, executeErrpushInsn);
        } else if (opCode == OP_ERRSET) {
            return (1, 0, 1, executeErrsetInsn);
        } else if (opCode == OP_DUP0) {
            return (1, 0, 1, executeDup0Insn);
        } else if (opCode == OP_DUP1) {
            return (2, 0, 1, executeDup1Insn);
        } else if (opCode == OP_DUP2) {
            return (3, 0, 1, executeDup2Insn);
        } else if (opCode == OP_SWAP1) {
            return (2, 0, 1, executeSwap1Insn);
        } else if (opCode == OP_SWAP2) {
            return (3, 0, 1, executeSwap2Insn);
        } else if (opCode == OP_TGET) {
            return (2, 0, 2, executeTgetInsn);
        } else if (opCode == OP_TSET) {
            return (3, 0, 40, executeTsetInsn);
        } else if (opCode == OP_TLEN) {
            return (1, 0, 2, executeTlenInsn);
        } else if (opCode == OP_XGET) {
            return (1, 1, 3, executeXgetInsn);
        } else if (opCode == OP_XSET) {
            return (2, 1, 41, executeXsetInsn);
        } else if (opCode == OP_BREAKPOINT) {
            return (0, 0, 100, executeNopInsn);
        } else if (opCode == OP_LOG) {
            return (1, 0, 100, executeLogInsn);
        } else if (opCode == OP_INBOX) {
            return (0, 0, 40, executeInboxInsn);
        } else if (opCode == OP_ERROR) {
            return (0, 0, ERROR_GAS_COST, executeErrorInsn);
        } else if (opCode == OP_STOP) {
            return (0, 0, 10, executeStopInsn);
        } else if (opCode == OP_SETGAS) {
            return (1, 0, 1, executeSetGasInsn);
        } else if (opCode == OP_PUSHGAS) {
            return (0, 0, 1, executePushGasInsn);
        } else if (opCode == OP_ERR_CODE_POINT) {
            return (0, 0, 25, executeErrCodePointInsn);
        } else if (opCode == OP_PUSH_INSN) {
            return (2, 0, 25, executePushInsnInsn);
        } else if (opCode == OP_PUSH_INSN_IMM) {
            return (3, 0, 25, executePushInsnImmInsn);
        } else if (opCode == OP_SIDELOAD) {
            return (1, 0, 10, executeSideloadInsn);
        } else if (opCode == OP_ECRECOVER) {
            return (4, 0, 20000, executeECRecoverInsn);
        } else if (opCode == OP_ECADD) {
            return (4, 0, 3500, executeECAddInsn);
        } else if (opCode == OP_ECMUL) {
            return (3, 0, 82000, executeECMulInsn);
        } else if (opCode == OP_ECPAIRING) {
            return (1, 0, EC_PAIRING_BASE_GAS_COST, executeECPairingInsn);
        } else if (opCode == OP_DEBUGPRINT) {
            return (1, 0, 1, executePopInsn);
        } else if (opCode == OP_NEWBUFFER) {
            return (0, 0, 1, executeNewBuffer);
        } else if (opCode >= OP_HASH && opCode <= OP_SHA256_F) {
            revert("use another contract to handle hashing opcodes");
        } else if ((opCode >= OP_GETBUFFER8 && opCode <= OP_SETBUFFER256) || opCode == OP_SEND) {
            revert("use another contract to handle buffer opcodes");
        } else {
            return (0, 0, ERROR_GAS_COST, executeErrorInsn);
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

library Messages {
    function messageHash(
        uint8 kind,
        address sender,
        uint256 blockNumber,
        uint256 timestamp,
        uint256 inboxSeqNum,
        uint256 gasPriceL1,
        bytes32 messageDataHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    kind,
                    sender,
                    blockNumber,
                    timestamp,
                    inboxSeqNum,
                    gasPriceL1,
                    messageDataHash
                )
            );
    }

    function addMessageToInbox(bytes32 inbox, bytes32 message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(inbox, message));
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