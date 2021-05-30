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

import "./OneStepProofCommon.sol";

import "../libraries/Precompiles.sol";

// Originally forked from https://github.com/leapdao/solEVM-enforcer/tree/master

contract OneStepProofHash is OneStepProofCommon {
    function executeHashInsn(AssertionContext memory context) internal pure {
        Value.Data memory val = popVal(context.stack);
        pushVal(context.stack, Value.newInt(uint256(val.hash())));
    }

    function executeTypeInsn(AssertionContext memory context) internal pure {
        Value.Data memory val = popVal(context.stack);
        pushVal(context.stack, val.typeCodeVal());
    }

    function executeEthHash2Insn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        if (!val1.isInt() || !val2.isInt()) {
            handleOpcodeError(context);
            return;
        }
        uint256 a = val1.intVal;
        uint256 b = val2.intVal;
        uint256 c = uint256(keccak256(abi.encodePacked(a, b)));
        pushVal(context.stack, Value.newInt(c));
    }

    function executeKeccakFInsn(AssertionContext memory context) internal pure {
        Value.Data memory val = popVal(context.stack);
        if (!val.isTuple() || val.tupleVal.length != 7) {
            handleOpcodeError(context);
            return;
        }

        Value.Data[] memory values = val.tupleVal;
        for (uint256 i = 0; i < 7; i++) {
            if (!values[i].isInt()) {
                handleOpcodeError(context);
                return;
            }
        }
        uint256[25] memory data;
        for (uint256 i = 0; i < 25; i++) {
            data[5 * (i % 5) + i / 5] = uint256(uint64(values[i / 4].intVal >> ((i % 4) * 64)));
        }

        data = Precompiles.keccakF(data);

        Value.Data[] memory outValues = new Value.Data[](7);
        for (uint256 i = 0; i < 7; i++) {
            outValues[i] = Value.newInt(0);
        }

        for (uint256 i = 0; i < 25; i++) {
            outValues[i / 4].intVal |= data[5 * (i % 5) + i / 5] << ((i % 4) * 64);
        }

        pushVal(context.stack, Value.newTuple(outValues));
    }

    function executeSha256FInsn(AssertionContext memory context) internal pure {
        Value.Data memory val1 = popVal(context.stack);
        Value.Data memory val2 = popVal(context.stack);
        Value.Data memory val3 = popVal(context.stack);
        if (!val1.isInt() || !val2.isInt() || !val3.isInt()) {
            handleOpcodeError(context);
            return;
        }
        uint256 a = val1.intVal;
        uint256 b = val2.intVal;
        uint256 c = val3.intVal;

        pushVal(context.stack, Value.newInt(Precompiles.sha256Block([b, c], a)));
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
        if (opCode == OP_HASH) {
            return (1, 0, 7, executeHashInsn);
        } else if (opCode == OP_TYPE) {
            return (1, 0, 3, executeTypeInsn);
        } else if (opCode == OP_ETHHASH2) {
            return (2, 0, 8, executeEthHash2Insn);
        } else if (opCode == OP_KECCAK_F) {
            return (1, 0, 600, executeKeccakFInsn);
        } else if (opCode == OP_SHA256_F) {
            return (3, 0, 250, executeSha256FInsn);
        } else {
            revert("use another contract to handle other opcodes");
        }
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

///      This algorithm has been extracted from the implementation of smart pool (https://github.com/smartpool)
library Precompiles {
    function keccakF(uint256[25] memory a) internal pure returns (uint256[25] memory) {
        uint256[5] memory c;
        uint256[5] memory d;
        //uint D_0; uint D_1; uint D_2; uint D_3; uint D_4;
        uint256[25] memory b;

        uint256[24] memory rc =
            [
                uint256(0x0000000000000001),
                0x0000000000008082,
                0x800000000000808A,
                0x8000000080008000,
                0x000000000000808B,
                0x0000000080000001,
                0x8000000080008081,
                0x8000000000008009,
                0x000000000000008A,
                0x0000000000000088,
                0x0000000080008009,
                0x000000008000000A,
                0x000000008000808B,
                0x800000000000008B,
                0x8000000000008089,
                0x8000000000008003,
                0x8000000000008002,
                0x8000000000000080,
                0x000000000000800A,
                0x800000008000000A,
                0x8000000080008081,
                0x8000000000008080,
                0x0000000080000001,
                0x8000000080008008
            ];

        for (uint256 i = 0; i < 24; i++) {
            /*
            for( x = 0 ; x < 5 ; x++ ) {
                C[x] = A[5*x]^A[5*x+1]^A[5*x+2]^A[5*x+3]^A[5*x+4];
            }*/

            c[0] = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4];
            c[1] = a[5] ^ a[6] ^ a[7] ^ a[8] ^ a[9];
            c[2] = a[10] ^ a[11] ^ a[12] ^ a[13] ^ a[14];
            c[3] = a[15] ^ a[16] ^ a[17] ^ a[18] ^ a[19];
            c[4] = a[20] ^ a[21] ^ a[22] ^ a[23] ^ a[24];

            /*
            for( x = 0 ; x < 5 ; x++ ) {
                D[x] = C[(x+4)%5]^((C[(x+1)%5] * 2)&0xffffffffffffffff | (C[(x+1)%5]/(2**63)));
            }*/

            d[0] = c[4] ^ (((c[1] * 2) & 0xffffffffffffffff) | (c[1] / (2**63)));
            d[1] = c[0] ^ (((c[2] * 2) & 0xffffffffffffffff) | (c[2] / (2**63)));
            d[2] = c[1] ^ (((c[3] * 2) & 0xffffffffffffffff) | (c[3] / (2**63)));
            d[3] = c[2] ^ (((c[4] * 2) & 0xffffffffffffffff) | (c[4] / (2**63)));
            d[4] = c[3] ^ (((c[0] * 2) & 0xffffffffffffffff) | (c[0] / (2**63)));

            /*
            for( x = 0 ; x < 5 ; x++ ) {
                for( y = 0 ; y < 5 ; y++ ) {
                    A[5*x+y] = A[5*x+y] ^ D[x];
                }
            }*/

            a[0] = a[0] ^ d[0];
            a[1] = a[1] ^ d[0];
            a[2] = a[2] ^ d[0];
            a[3] = a[3] ^ d[0];
            a[4] = a[4] ^ d[0];
            a[5] = a[5] ^ d[1];
            a[6] = a[6] ^ d[1];
            a[7] = a[7] ^ d[1];
            a[8] = a[8] ^ d[1];
            a[9] = a[9] ^ d[1];
            a[10] = a[10] ^ d[2];
            a[11] = a[11] ^ d[2];
            a[12] = a[12] ^ d[2];
            a[13] = a[13] ^ d[2];
            a[14] = a[14] ^ d[2];
            a[15] = a[15] ^ d[3];
            a[16] = a[16] ^ d[3];
            a[17] = a[17] ^ d[3];
            a[18] = a[18] ^ d[3];
            a[19] = a[19] ^ d[3];
            a[20] = a[20] ^ d[4];
            a[21] = a[21] ^ d[4];
            a[22] = a[22] ^ d[4];
            a[23] = a[23] ^ d[4];
            a[24] = a[24] ^ d[4];

            /*Rho and pi steps*/
            b[0] = a[0];
            b[8] = (((a[1] * (2**36)) & 0xffffffffffffffff) | (a[1] / (2**28)));
            b[11] = (((a[2] * (2**3)) & 0xffffffffffffffff) | (a[2] / (2**61)));
            b[19] = (((a[3] * (2**41)) & 0xffffffffffffffff) | (a[3] / (2**23)));
            b[22] = (((a[4] * (2**18)) & 0xffffffffffffffff) | (a[4] / (2**46)));
            b[2] = (((a[5] * (2**1)) & 0xffffffffffffffff) | (a[5] / (2**63)));
            b[5] = (((a[6] * (2**44)) & 0xffffffffffffffff) | (a[6] / (2**20)));
            b[13] = (((a[7] * (2**10)) & 0xffffffffffffffff) | (a[7] / (2**54)));
            b[16] = (((a[8] * (2**45)) & 0xffffffffffffffff) | (a[8] / (2**19)));
            b[24] = (((a[9] * (2**2)) & 0xffffffffffffffff) | (a[9] / (2**62)));
            b[4] = (((a[10] * (2**62)) & 0xffffffffffffffff) | (a[10] / (2**2)));
            b[7] = (((a[11] * (2**6)) & 0xffffffffffffffff) | (a[11] / (2**58)));
            b[10] = (((a[12] * (2**43)) & 0xffffffffffffffff) | (a[12] / (2**21)));
            b[18] = (((a[13] * (2**15)) & 0xffffffffffffffff) | (a[13] / (2**49)));
            b[21] = (((a[14] * (2**61)) & 0xffffffffffffffff) | (a[14] / (2**3)));
            b[1] = (((a[15] * (2**28)) & 0xffffffffffffffff) | (a[15] / (2**36)));
            b[9] = (((a[16] * (2**55)) & 0xffffffffffffffff) | (a[16] / (2**9)));
            b[12] = (((a[17] * (2**25)) & 0xffffffffffffffff) | (a[17] / (2**39)));
            b[15] = (((a[18] * (2**21)) & 0xffffffffffffffff) | (a[18] / (2**43)));
            b[23] = (((a[19] * (2**56)) & 0xffffffffffffffff) | (a[19] / (2**8)));
            b[3] = (((a[20] * (2**27)) & 0xffffffffffffffff) | (a[20] / (2**37)));
            b[6] = (((a[21] * (2**20)) & 0xffffffffffffffff) | (a[21] / (2**44)));
            b[14] = (((a[22] * (2**39)) & 0xffffffffffffffff) | (a[22] / (2**25)));
            b[17] = (((a[23] * (2**8)) & 0xffffffffffffffff) | (a[23] / (2**56)));
            b[20] = (((a[24] * (2**14)) & 0xffffffffffffffff) | (a[24] / (2**50)));

            /*Xi state*/
            /*
            for( x = 0 ; x < 5 ; x++ ) {
                for( y = 0 ; y < 5 ; y++ ) {
                    A[5*x+y] = B[5*x+y]^((~B[5*((x+1)%5)+y]) & B[5*((x+2)%5)+y]);
                }
            }*/

            a[0] = b[0] ^ ((~b[5]) & b[10]);
            a[1] = b[1] ^ ((~b[6]) & b[11]);
            a[2] = b[2] ^ ((~b[7]) & b[12]);
            a[3] = b[3] ^ ((~b[8]) & b[13]);
            a[4] = b[4] ^ ((~b[9]) & b[14]);
            a[5] = b[5] ^ ((~b[10]) & b[15]);
            a[6] = b[6] ^ ((~b[11]) & b[16]);
            a[7] = b[7] ^ ((~b[12]) & b[17]);
            a[8] = b[8] ^ ((~b[13]) & b[18]);
            a[9] = b[9] ^ ((~b[14]) & b[19]);
            a[10] = b[10] ^ ((~b[15]) & b[20]);
            a[11] = b[11] ^ ((~b[16]) & b[21]);
            a[12] = b[12] ^ ((~b[17]) & b[22]);
            a[13] = b[13] ^ ((~b[18]) & b[23]);
            a[14] = b[14] ^ ((~b[19]) & b[24]);
            a[15] = b[15] ^ ((~b[20]) & b[0]);
            a[16] = b[16] ^ ((~b[21]) & b[1]);
            a[17] = b[17] ^ ((~b[22]) & b[2]);
            a[18] = b[18] ^ ((~b[23]) & b[3]);
            a[19] = b[19] ^ ((~b[24]) & b[4]);
            a[20] = b[20] ^ ((~b[0]) & b[5]);
            a[21] = b[21] ^ ((~b[1]) & b[6]);
            a[22] = b[22] ^ ((~b[2]) & b[7]);
            a[23] = b[23] ^ ((~b[3]) & b[8]);
            a[24] = b[24] ^ ((~b[4]) & b[9]);

            /*Last step*/
            a[0] = a[0] ^ rc[i];
        }

        return a;
    }

    function rightRotate(uint32 x, uint32 n) internal pure returns (uint32) {
        return ((x) >> (n)) | ((x) << (32 - (n)));
    }

    function ch(
        uint32 e,
        uint32 f,
        uint32 g
    ) internal pure returns (uint32) {
        return ((e & f) ^ ((~e) & g));
    }

    // SHA256 compression function that operates on a 512 bit chunk
    // Note that the input must be padded by the caller
    // For the initial chunk, the initial values from the SHA256 spec should be passed in as hashState
    // For subsequent rounds, hashState is the output from the previous round
    function sha256Block(uint256[2] memory inputChunk, uint256 hashState)
        internal
        pure
        returns (uint256)
    {
        uint32[64] memory k =
            [
                0x428a2f98,
                0x71374491,
                0xb5c0fbcf,
                0xe9b5dba5,
                0x3956c25b,
                0x59f111f1,
                0x923f82a4,
                0xab1c5ed5,
                0xd807aa98,
                0x12835b01,
                0x243185be,
                0x550c7dc3,
                0x72be5d74,
                0x80deb1fe,
                0x9bdc06a7,
                0xc19bf174,
                0xe49b69c1,
                0xefbe4786,
                0x0fc19dc6,
                0x240ca1cc,
                0x2de92c6f,
                0x4a7484aa,
                0x5cb0a9dc,
                0x76f988da,
                0x983e5152,
                0xa831c66d,
                0xb00327c8,
                0xbf597fc7,
                0xc6e00bf3,
                0xd5a79147,
                0x06ca6351,
                0x14292967,
                0x27b70a85,
                0x2e1b2138,
                0x4d2c6dfc,
                0x53380d13,
                0x650a7354,
                0x766a0abb,
                0x81c2c92e,
                0x92722c85,
                0xa2bfe8a1,
                0xa81a664b,
                0xc24b8b70,
                0xc76c51a3,
                0xd192e819,
                0xd6990624,
                0xf40e3585,
                0x106aa070,
                0x19a4c116,
                0x1e376c08,
                0x2748774c,
                0x34b0bcb5,
                0x391c0cb3,
                0x4ed8aa4a,
                0x5b9cca4f,
                0x682e6ff3,
                0x748f82ee,
                0x78a5636f,
                0x84c87814,
                0x8cc70208,
                0x90befffa,
                0xa4506ceb,
                0xbef9a3f7,
                0xc67178f2
            ];

        uint32[64] memory w;
        uint32 i;
        for (i = 0; i < 8; i++) {
            w[i] = uint32(inputChunk[0] >> (224 - (32 * i)));
            w[i + 8] = uint32(inputChunk[1] >> (224 - (32 * i)));
        }

        uint32 s0;
        uint32 s1;
        for (i = 16; i < 64; i++) {
            s0 = rightRotate(w[i - 15], 7) ^ rightRotate(w[i - 15], 18) ^ (w[i - 15] >> 3);

            s1 = rightRotate(w[i - 2], 17) ^ rightRotate(w[i - 2], 19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16] + s0 + w[i - 7] + s1;
        }

        uint32[8] memory state;

        for (i = 0; i < 8; i++) {
            state[i] = uint32(hashState >> (224 - (32 * i)));
        }

        uint32 temp1;
        uint32 temp2;
        uint32 maj;

        for (i = 0; i < 64; i++) {
            s1 = rightRotate(state[4], 6) ^ rightRotate(state[4], 11) ^ rightRotate(state[4], 25);
            temp1 = state[7] + s1 + ch(state[4], state[5], state[6]) + k[i] + w[i];
            s0 = rightRotate(state[0], 2) ^ rightRotate(state[0], 13) ^ rightRotate(state[0], 22);

            maj = (state[0] & (state[1] ^ state[2])) ^ (state[1] & state[2]);
            temp2 = s0 + maj;

            state[7] = state[6];
            state[6] = state[5];
            state[5] = state[4];
            state[4] = state[3] + temp1;
            state[3] = state[2];
            state[2] = state[1];
            state[1] = state[0];
            state[0] = temp1 + temp2;
        }

        for (i = 0; i < 8; i++) {
            state[i] += uint32(hashState >> (224 - (32 * i)));
        }

        uint256 result;

        for (i = 0; i < 8; i++) {
            result |= (uint256(state[i]) << (224 - (32 * i)));
        }

        return result;
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