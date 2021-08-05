// SPDX-License-Identifier: Apache 2.0
/*
 * Blake2b library in Solidity using EIP-152
 *
 * Copyright (C) 2019 Alex Beregszaszi
 *
 * License: Apache 2.0
 */
pragma solidity ^0.7.0;

library Blake2b {
    struct Instance {
        // This is a bit misleadingly called state as it not only includes the Blake2 state,
        // but every field needed for the "blake2 f function precompile".
        //
        // This is a tightly packed buffer of:
        // - rounds: 32-bit BE
        // - h: 8 x 64-bit LE
        // - m: 16 x 64-bit LE
        // - t: 2 x 64-bit LE
        // - f: 8-bit
        bytes state;
        // Expected output hash length. (Used in `finalize`.)
        uint out_len;
        // Data passed to "function F".
        // NOTE: this is limited to 24 bits.
        uint input_counter;
    }

    // Initialise the state with a given `key` and required `out_len` hash length.
    function init(bytes memory key, uint out_len, bytes memory personalization)
        internal
        view
        returns (Instance memory instance)
    {
        // Safety check that the precompile exists.
        // TODO: remove this?
        // assembly {
        //    if eq(extcodehash(0x09), 0) { revert(0, 0) }
        //}

        reset(instance, key, out_len, personalization);
    }

    // Initialise the state with a given `key` and required `out_len` hash length.
    function reset(Instance memory instance, bytes memory key, uint out_len, bytes memory personalization)
        internal
        view
    {
        instance.out_len = out_len;
        instance.input_counter = 0;

        // This is entire state transmitted to the precompile.
        // It is byteswapped for the encoding requirements, additionally
        // the IV has the initial parameter block 0 XOR constant applied, but
        // not the key and output length.
        instance.state = hex"0000000c08c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        bytes memory state = instance.state;

        // Update parameter block 0 with key length and output length.
        uint key_len = key.length;
        assembly {
            let ptr := add(state, 36)
            let tmp := mload(ptr)
            let p0 := or(shl(240, key_len), shl(248, out_len))
            tmp := xor(tmp, p0)
            mstore(ptr, tmp)
        }

        // TODO: support salt and personalization
        if (personalization.length > 0) {
            require(personalization.length == 32);

            assembly {
                let ptr := add(state, 84) // 32+4+48
                let tmp := mload(ptr)
                let personalization_ptr := add(personalization, 32)
                let tmp_personalization := mload(personalization_ptr)
                tmp := xor(tmp, tmp_personalization)
                mstore(ptr, tmp)
            }
        }

        if (key_len > 0) {
            require(key_len == 64);
            // FIXME: the key must be zero padded
            assert(key.length == 128);
            update(instance, key, key_len);
        }
    }

    // This calls the blake2 precompile ("function F of the spec").
    // It expects the state was updated with the next block. Upon returning the state will be updated,
    // but the supplied block data will not be cleared.
    function call_function_f(Instance memory instance)
        private
        view
    {
        bytes memory state = instance.state;
        assembly {
            let state_ptr := add(state, 32)
            if iszero(staticcall(not(0), 0x09, state_ptr, 0xd5, add(state_ptr, 4), 0x40)) {
                revert(0, 0)
            }
        }
    }

    // This function will split blocks correctly and repeatedly call the precompile.
    // NOTE: this is dumb right now and expects `data` to be 128 bytes long and padded with zeroes,
    //       hence the real length is indicated with `data_len`
    function update_loop(Instance memory instance, bytes memory data, uint data_len, bool last_block)
        private
        view
    {
        bytes memory state = instance.state;
        uint input_counter = instance.input_counter;

        // This is the memory location where the "data block" starts for the precompile.
        uint state_ptr;
        assembly {
            // The `rounds` field is 4 bytes long and the `h` field is 64-bytes long.
            // Also adjust for the size of the bytes type.
            state_ptr := add(state, 100)
        }

        // This is the memory location where the input data resides.
        uint data_ptr;
        assembly {
            data_ptr := add(data, 32)
        }

        uint len = data.length;
        while (len > 0) {
            if (len >= 128) {
                assembly {
                    mstore(state_ptr, mload(data_ptr))
                    data_ptr := add(data_ptr, 32)

                    mstore(add(state_ptr, 32), mload(data_ptr))
                    data_ptr := add(data_ptr, 32)

                    mstore(add(state_ptr, 64), mload(data_ptr))
                    data_ptr := add(data_ptr, 32)

                    mstore(add(state_ptr, 96), mload(data_ptr))
                    data_ptr := add(data_ptr, 32)
                }

                len -= 128;
                // FIXME: remove this once implemented proper padding
                if (data_len < 128) {
                    input_counter += data_len;
                } else {
                    data_len -= 128;
                    input_counter += 128;
                }
            } else {
                // FIXME: implement support for smaller than 128 byte blocks
                revert();
            }

            // Set length field (little-endian) for maximum of 24-bits.
            assembly {
                mstore8(add(state, 228), and(input_counter, 0xff))
                mstore8(add(state, 229), and(shr(8, input_counter), 0xff))
                mstore8(add(state, 230), and(shr(16, input_counter), 0xff))
            }

            // Set the last block indicator.
            // Only if we've processed all input.
            if (len == 0) {
                assembly {
                    // Writing byte 212 here.
                    mstore8(add(state, 244), last_block)
                }
            }

            // Call the precompile
            call_function_f(instance);
        }

        instance.input_counter = input_counter;
    }

    // Update the state with a non-final block.
    // NOTE: the input must be complete blocks.
    function update(Instance memory instance, bytes memory data, uint data_len)
        internal
        view
    {
        require((data.length % 128) == 0);
        update_loop(instance, data, data_len, false);
    }

    // Update the state with a final block and return the hash.
    function finalize(Instance memory instance, bytes memory data, uint data_len)
        internal
        view
        returns (bytes memory output)
    {
        // FIXME: support incomplete blocks (zero pad them)
        assert((data.length % 128) == 0);
        update_loop(instance, data, data_len, true);

        // FIXME: support other lengths
        // assert(instance.out_len == 64);

        bytes memory state = instance.state;
        output = new bytes(instance.out_len);
        assembly {
            mstore(add(output, 32), mload(add(state, 36)))
            mstore(add(output, 64), mload(add(state, 68)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library BeamDifficulty {
    uint32 constant kMantissaBits = 24;

    function mul512(uint256 a, uint256 b)
        internal
        pure
        returns (bytes32 r0, bytes32 r1)
    {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a,b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    function isTargetReached(uint256 rawDifficulty, uint256 target)
        internal
        pure
        returns (bool)
    {
        (, bytes32 hightHalf) = mul512(rawDifficulty, target);

        // difficulty.length - (kMantissaBits >> 3) = 32 - (24 >> 3) = 29
        uint8 n = 29;
        for (uint16 i = 0; i < n; i++) {
            if (hightHalf[i] != 0) {
                return false;
            }
        }
        return true;
    }

    function unpack(uint32 packed)
        internal
        pure
        returns (uint256 rawDifficulty)
    {
        uint32 order = packed >> kMantissaBits;
        uint32 leadingBit = uint32(1 << kMantissaBits);
        uint32 mantissa = leadingBit | (packed & (leadingBit - 1));

        rawDifficulty = uint256(mantissa) << order;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./../3rdparty/blake2-solidity/contracts/Blake2b.sol";
import "./StepElem.sol";

library BeamHashIII {
    using Blake2b for Blake2b.Instance;
    using StepElem for StepElem.Instance;

    function indexDecoder(bytes memory soln)
        public
        pure
        returns (uint32[32] memory result)
    {
        uint maskSize = 25;
        uint mask = 1;
        mask = ((mask << maskSize) - 1);

        uint currentSize = 0;
        uint buffer = 0;
        uint index = 0;

        // check size of soln
        for (uint i = 0; i < 100; i++)
        {
            buffer |= uint(uint8(soln[i])) << currentSize;
            currentSize += 8;

            if (currentSize >= maskSize)
            {
                result[index] = uint32(buffer & mask);
                index++;
                buffer >>= maskSize;
                currentSize -= maskSize;
            }
        }
    }

    uint32 constant kColisionBitSize = 24;
    uint32 constant kWorkBitSize = 448;
    // Beam blake2b personalization!
    // zero padded to 32 bytes
    bytes constant personalization = hex"4265616d2d506f57c00100000500000000000000000000000000000000000000";

    function Verify(bytes32 dataHash, bytes8 nonce, bytes memory indicesRaw)
        internal
        view
        returns (bool)
    {
        require(indicesRaw.length == 104, "BeamHashIII: unexpected size of soln.");
        bytes memory buffer = new bytes(128);
        {
            bytes4 temp;
            assembly {
                // save hash to buffer
                mstore(add(buffer, 32), dataHash)
                // save nonce to buffer
                mstore(add(buffer, 64), nonce)

                // load additional 4 bytes from indicesRaw:
                // get last 32 bytes and shift left 28 bytes
                temp := shl(224, mload(add(indicesRaw, 104)))
                // save to buffer, offset: 32 + 32 + 8 = 72
                mstore(add(buffer, 72), temp)
            }
        }

        Blake2b.Instance memory instance = Blake2b.init(hex"", 32, personalization);
        bytes memory tmp = instance.finalize(buffer, dataHash.length + nonce.length + 4);
        uint64 state0 = StepElem.toUint64(tmp, 0);
        uint64 state1 = StepElem.toUint64(tmp, 8);
        uint64 state2 = StepElem.toUint64(tmp, 16);
        uint64 state3 = StepElem.toUint64(tmp, 24);
        uint32[32] memory indices = indexDecoder(indicesRaw);

        StepElem.Instance[32] memory elemLite;
        for (uint i = 0; i < elemLite.length; i++)
        {
            elemLite[i] = StepElem.init(state0, state1, state2, state3, indices[i]);
        }
 
        uint round = 1;
        uint i1;
        for (uint step = 1; step < indices.length; step <<= 1) {
            for (uint i0 = 0; i0 < indices.length;) {
                uint remLen = kWorkBitSize - (round - 1) * kColisionBitSize;

                if (round == 5) remLen -= 64;

                elemLite[i0].applyMix(remLen, indices, i0, step);
                i1 = i0 + step;
                elemLite[i1].applyMix(remLen, indices, i1, step);

                if (!elemLite[i0].hasColision(elemLite[i1]))
                    return false;

                if (indices[i0] >= indices[i1])
                    return false;

                remLen = kWorkBitSize - round * kColisionBitSize;
                if (round == 4) remLen -= 64;
                if (round == 5) remLen = kColisionBitSize;

                elemLite[i0].mergeWith(elemLite[i1], remLen);

                i0 = i1 + step;
            }
            round++;
        }

        if (!elemLite[0].isZero())
            return false;

        // ensure all the indices are distinct
        for (uint i = 0; i < indices.length - 1; i++) {
            for (uint j = i + 1; j < indices.length; j++) {
                if (indices[i] == indices[j])
                    return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./BeamHashIII.sol";
import "./BeamUtils.sol";
import "./BeamDifficulty.sol";

library BeamHeader {
    struct PoW {
        bytes indicies;
        bytes8 nonce;
        uint32 difficulty;
    }

    struct SystemState {
        uint64 height;
        bytes32 prev;
        bytes32 chainWork;
        bytes32 kernels;
        bytes32 definition;
        uint64 timestamp;
        PoW pow;
    }

    function exactPoW(bytes memory raw)
        private
        pure
        returns (PoW memory pow)
    {
        uint32 nSolutionBytes = 104;
        require(raw.length >= nSolutionBytes + 8 + 4, "unexpected rawPoW length!");
        bytes memory indicies = new bytes(nSolutionBytes);

        assembly {
            mstore(add(indicies, 32), mload(add(raw, 32)))
            mstore(add(indicies, 64), mload(add(raw, 64)))
            mstore(add(indicies, 96), mload(add(raw, 96)))
            mstore(add(indicies, 128), mload(add(raw, 128)))

            // load last 8 bytes
            mstore(add(indicies, 104), mload(add(raw, 104)))
        }
        pow.indicies = indicies;

        bytes8 nonce;
        assembly {
            nonce := shl(192, mload(add(raw, 112)))
        }
        pow.nonce = nonce;

        bytes4 diff;
        assembly {
            diff := shl(224, mload(add(raw, 116)))
        }
        pow.difficulty = BeamUtils.reverse32(uint32(diff));
    }

    function compileState(
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 height,
        uint64 timestamp,
        bytes memory pow
    ) private pure returns (SystemState memory state) {
        state.height = height;
        state.prev = prev;
        state.chainWork = chainWork;

        state.kernels = kernels;
        state.definition = definition;
        state.timestamp = timestamp;

        state.pow = exactPoW(pow);
    }

    function findFork(uint64 height)
        private
        pure
        returns (uint8)
    {
        if (height >= 777777) return 2;
        if (height >= 321321) return 1;
        return 0;
    }

    function getForkHash(uint8 fork)
        private
        pure
        returns (uint256)
    {
        if (fork == 2) {
            return 0x1ce8f721bf0c9fa7473795a97e365ad38bbc539aab821d6912d86f24e67720fc;
        }
        if (fork == 1) {
            return 0x6d622e615cfd29d0f8cdd9bdd73ca0b769c8661b29d7ba9c45856c96bc2ec5bc;
        }
        return 0xed91a717313c6eb0e3f082411584d0da8f0c8af2a4ac01e5af1959e0ec4338bc;
    }

    function encodeState(SystemState memory state, bool total, bytes32 rulesHash)
        private
        pure
        returns (bytes memory)
    {
        bytes memory prefix = abi.encodePacked(
            BeamUtils.encodeUint(state.height),
            state.prev,
            state.chainWork
        );
        bytes memory element = abi.encodePacked(
            state.kernels,
            state.definition,
            BeamUtils.encodeUint(state.timestamp),
            BeamUtils.encodeUint(state.pow.difficulty)
        );
        bytes memory encoded = abi.encodePacked(prefix, element);
        // support only fork2 and higher
        encoded = abi.encodePacked(encoded, rulesHash);

        if (total) {
            encoded = abi.encodePacked(
                encoded,
                state.pow.indicies,
                state.pow.nonce
            );
        }

        return encoded;
    }

    function getHashInternal(SystemState memory state, bool total, bytes32 rulesHash)
        private
        pure
        returns (bytes32)
    {
        bytes memory encodedState = encodeState(state, total, rulesHash);
        return sha256(encodedState);
    }

    function isValid(
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 height,
        uint64 timestamp,
        bytes memory pow,
        bytes32 rulesHash
    ) internal view returns (bool) {
        SystemState memory state = compileState(
            prev,
            chainWork,
            kernels,
            definition,
            height,
            timestamp,
            pow
        );

        // checking difficulty
        uint256 rawDifficulty = BeamDifficulty.unpack(state.pow.difficulty);
        uint256 target = uint256(sha256(abi.encodePacked(state.pow.indicies)));
        if (!BeamDifficulty.isTargetReached(rawDifficulty, target))
            return false;

        // get pre-pow
        bytes32 prepowHash = getHashInternal(state, false, rulesHash);

        return BeamHashIII.Verify(prepowHash, state.pow.nonce, state.pow.indicies);
    }

    function getHeaderHashInternal(
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 height,
        uint64 timestamp,
        bytes memory pow,
        bool total,
        bytes32 rulesHash
    ) internal pure returns (bytes32) {
        SystemState memory state = compileState(
            prev,
            chainWork,
            kernels,
            definition,
            height,
            timestamp,
            pow
        );

        return getHashInternal(state, total, rulesHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library BeamUtils {
    function encodeUint(uint value)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encoded;
        for (; value >= 0x80; value >>= 7) {
            encoded = abi.encodePacked(encoded, uint8(uint8(value) | 0x80));
        }
        return abi.encodePacked(encoded, uint8(value));
    }

    function getContractVariableHash(bytes memory key, bytes memory value)
        internal
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encodePacked(
            "beam.contract.val\x00",
            BeamUtils.encodeUint(key.length),
            key,
            BeamUtils.encodeUint(value.length),
            value
        );

        return sha256(encoded);
    }

    function interpretMerkleProof(bytes32 variableHash, bytes memory proof)
        internal
        pure
        returns (bytes32 rootHash)
    {
        // 33 - 1 byte for flag onRight and 32 byte for leaf hash
        require(proof.length % 33 == 0, "unexpected lenght of the proof.");
        // TODO: check proof max size
        require(proof.length < 255 * 33, "the length of the proof is too long.");

        rootHash = variableHash;
        bytes32 secondHash;
        for (uint16 index = 0; index < proof.length; index += 33) {
            assembly {
                secondHash := mload(add(add(proof, 33), index))
            }

            if (proof[index] != 0x01) {
                rootHash = sha256(abi.encodePacked(secondHash, rootHash));
            }
            else {
                rootHash = sha256(abi.encodePacked(rootHash, secondHash));
            }
        }
    }

    function reverse32(uint32 value)
        internal
        pure
        returns (uint32)
    {
        // swap bytes
        value = ((value & 0xFF00FF00) >> 8) |
                ((value & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        value = (value >> 16) | (value << 16);

        return value;
    }

    function reverse64(uint64 value)
        internal
        pure
        returns (uint64)
    {
        // swap bytes
        value = ((value & 0xFF00FF00FF00FF00) >> 8) |
                ((value & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        value = ((value & 0xFFFF0000FFFF0000) >> 16) |
                ((value & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        value = (value >> 32) | (value << 32);
        return value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "./BeamHeader.sol";
import "./BeamUtils.sol";

contract Pipe {
    // config:
    // remote cfg:
    // uint32 packageMaxMsgs;
    // uint64 packageMaxDiffHeightToClose;
    // local cfg:
    // bytes32 rulesRemote; // ?
    // uint256 comissionPerMsg;
    // uint256 stakeForRemoteMsg;
    // uint64  disputePeriod;
    // uint64  contenderWaitPeriod;

    // incoming messages
    struct RemoteMessage {
        // index in array m_remoteMsgsKeys
        uint32 index;
        // header:
        uint32 msgId;
        // eth contract address 
        address msgContractReceiver;
        // beam contract id
        bytes32 msgContractSender;

        // body
        bytes value;
        bool validated;
    }

    bytes32 m_remotePipeId;
    mapping (bytes32 => RemoteMessage) m_remoteMessages;
    bytes32[] m_remoteMsgsKeys;
    uint32 m_localMsgCounter;

    // LocalMessage {
    //     // header:
    //     uint32 msgId;
    //     address msgContractSender; // eth contract address
    //     bytes32 msgContractReceiver; // beam contract id

    //     // msg body
    //     uint64 value;
    //     bytes receiver; // beam pubKey - 33 bytes
    // }
    event NewLocalMessage(uint32 msgId, address msgContractSender, bytes32 msgContractReceiver, bytes msgBody);

    function setRemote(bytes32 remoteContractId)
        public
    {
        m_remotePipeId = remoteContractId;
    }

    function getMsgKey(uint msgId)
        private
        pure
        returns (bytes32 key)
    {
        key = keccak256(abi.encodePacked(uint32(msgId)));
    }

    // TODO: add support multiple msgs
    function pushRemoteMessage(uint msgId,
                               bytes32 msgContractSender,       // beam contract id
                               address msgContractReceiver,     // eth contract address
                               bytes memory messageBody)
        public
    {
        bytes32 key = getMsgKey(msgId);

        require(m_remoteMessages[key].value.length == 0, "message is exist");

        m_remoteMsgsKeys.push(key);

        m_remoteMessages[key].index = uint32(m_remoteMsgsKeys.length - 1);
        m_remoteMessages[key].msgId = uint32(msgId);
        m_remoteMessages[key].msgContractReceiver = msgContractReceiver;
        m_remoteMessages[key].msgContractSender = msgContractSender;
        m_remoteMessages[key].value = messageBody;
        m_remoteMessages[key].validated = false;
    }

    function getBeamVariableKey(uint msgId)
        private
        view
        returns (bytes memory)
    {
        // [contract_id,KeyTag::Internal(uint8 0),KeyType::OutCheckpoint(uint8 2),index_BE(uint32 'packageId')]
        return abi.encodePacked(m_remotePipeId, uint8(0), uint8(2), uint32(msgId));
    }

    function getMsgHash(bytes32 previousHash, RemoteMessage memory message)
        private
        pure
        returns (bytes32)
    {
        return sha256(abi.encodePacked("b.msg\x00",
                      previousHash,
                      // full msg size
                      BeamUtils.encodeUint(20 + message.msgContractSender.length + message.value.length),
                      // msgHdr: sender/receiver
                      message.msgContractSender,
                      message.msgContractReceiver,
                      // msg body
                      message.value));
    }

    function validateRemoteMessage(uint msgId, 
                                   // params of block
                                   bytes32 prev,
                                   bytes32 chainWork,
                                   bytes32 kernels,
                                   bytes32 definition,
                                   uint64 height,
                                   uint64 timestamp,
                                   bytes memory pow,
                                   bytes32 rulesHash,
                                   bytes memory proof)
        public
    {
        bytes32 key = getMsgKey(msgId);
        require(!m_remoteMessages[key].validated, "already verified.");
        
        // validate block header & proof of msg
        // TODO: uncomment when stop using FakePow
        // require(BeamHeader.isValid(prev, chainWork, kernels, definition, height, timestamp, pow, rulesHash), 'invalid header.');

        bytes memory variableKey = getBeamVariableKey(msgId);
        bytes memory ecodedMsg = abi.encodePacked(m_remoteMessages[key].msgContractSender, m_remoteMessages[key].msgContractReceiver, m_remoteMessages[key].value);
        bytes32 variableHash = BeamUtils.getContractVariableHash(variableKey, ecodedMsg);
        bytes32 rootHash = BeamUtils.interpretMerkleProof(variableHash, proof);

        require(rootHash == definition, "invalid proof");
        m_remoteMessages[key].validated = true;
    }

    function getRemoteMessage(uint msgId)
        public
        returns (bytes memory)
    {
        bytes32 key = getMsgKey(msgId);
        require(m_remoteMessages[key].validated, "message should be validated");
        // TODO: uncomment after testing
        // require(msg.sender == m_remoteMessages[key].msgContractReceiver, "invalid msg receiver");

        RemoteMessage memory tmp = m_remoteMessages[key];

        // delete from keys
        if (tmp.index != m_remoteMsgsKeys.length - 1) {
            bytes32 lastKey = m_remoteMsgsKeys[m_remoteMsgsKeys.length - 1];
            m_remoteMsgsKeys[tmp.index] = lastKey;
            m_remoteMessages[lastKey].index = tmp.index;
        }
        delete m_remoteMessages[key];
        m_remoteMsgsKeys.pop();

        return tmp.value;
    }

    function pushLocalMessage(bytes32 contractReceiver, bytes memory msgBody)
        public
    {
        // TODO: pckgId
        emit NewLocalMessage(m_localMsgCounter++, msg.sender, contractReceiver, msgBody);
    }

    function getRemoteMsgByKey(bytes32 key)
        public
        view
        returns (uint32, bytes32, bytes memory)
    {
        if (m_remoteMessages[key].value.length == 0  ||
            m_remoteMessages[key].msgContractReceiver != msg.sender 
            // TODO: uncomment after testing
            /* ||
            !m_remoteMessages[key].validated*/)
        {
            return (0, bytes32(0), new bytes(0));
        }
        return (m_remoteMessages[key].msgId, m_remoteMessages[key].msgContractSender, m_remoteMessages[key].value);
    }

    function getRemoteMsgKeys()
        public
        view
        returns (bytes32[] memory)
    {
        return m_remoteMsgsKeys;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library SipHash {
    function rotl(uint x, uint b)
        internal
        pure
        returns (uint64)
    {
        return uint64((x << b)) | uint64(x >> (64 - b));
    }

    function sipRound(uint64 v0, uint64 v1, uint64 v2, uint64 v3)
        private
        pure
        returns (uint64, uint64, uint64, uint64)
    {
        v0 += v1;
        v2 += v3;
        v1 = rotl(v1, 13);
        v3 = rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = rotl(v1, 17);
        v3 = rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = rotl(v2, 32);

        return (v0, v1, v2, v3);
    }

    function siphash24(uint64 v0, uint64 v1, uint64 v2, uint64 v3, uint64 nonce)
        internal
        pure
        returns (uint64)
    {
        v3 ^= nonce;

        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);
        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);

        v0 ^= nonce;
        v2 ^= 0xff;

        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);
        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);
        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);
        // sipRound    
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);

        return v0 ^ v1 ^ v2 ^ v3;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {SipHash} from "./SipHash.sol";
import "./BeamUtils.sol";

library StepElem {
    struct Instance {
        uint64 workWord0;
        uint64 workWord1;
        uint64 workWord2;
        uint64 workWord3;
        uint64 workWord4;
        uint64 workWord5;
        uint64 workWord6;
    }

    uint32 constant kColisionBitSize = 24;
    uint32 constant kWorkBitSize = 448;
    uint32 constant kWordSize = 8;
    uint32 constant kColisionBytes = 3;

    function init(uint64 state0, uint64 state1, uint64 state2, uint64 state3, uint64 index)
        internal
        pure
        returns (Instance memory result)
    {
        index = index << 3;
        result.workWord0 = SipHash.siphash24(state0, state1, state2, state3, index + 0);
        result.workWord1 = SipHash.siphash24(state0, state1, state2, state3, index + 1);
        result.workWord2 = SipHash.siphash24(state0, state1, state2, state3, index + 2);
        result.workWord3 = SipHash.siphash24(state0, state1, state2, state3, index + 3);
        result.workWord4 = SipHash.siphash24(state0, state1, state2, state3, index + 4);
        result.workWord5 = SipHash.siphash24(state0, state1, state2, state3, index + 5);
        result.workWord6 = SipHash.siphash24(state0, state1, state2, state3, index + 6);
    }

    function toUint64(bytes memory buffer, uint256 start)
        internal
        pure
        returns (uint64)
    {
        uint64 v = 0;
        start += 8;
        assembly {
            v := mload(add(buffer, start))
        }

        // reverse uint64:
        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);

        return v;
    }

    function mergeWith(Instance memory self, Instance memory other, uint remLen)
        internal
        pure
    {
        uint remBytes = remLen / 8;
        bytes memory buffer = new bytes(7 * 8);

        // copy to buffer
        {
            // revert bytes and add to buffer
            bytes8 value = bytes8(BeamUtils.reverse64(self.workWord0 ^ other.workWord0));
            assembly {
                mstore(add(buffer, 32), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord1 ^ other.workWord1));
            assembly {
                mstore(add(buffer, 40), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord2 ^ other.workWord2));
            assembly {
                mstore(add(buffer, 48), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord3 ^ other.workWord3));
            assembly {
                mstore(add(buffer, 56), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord4 ^ other.workWord4));
            assembly {
                mstore(add(buffer, 64), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord5 ^ other.workWord5));
            assembly {
                mstore(add(buffer, 72), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord6 ^ other.workWord6));
            assembly {
                mstore(add(buffer, 80), value)
            }
        }

        // shift to left
        for (uint i = 0; i < remBytes; i++) {
            buffer[i] = buffer[i + kColisionBytes];
        }

        for (uint i = remBytes; i < buffer.length; i++) {
            buffer[i] = 0;
        }

        // copy from buffer
        self.workWord0 = toUint64(buffer, 0);
        self.workWord1 = toUint64(buffer, 8);
        self.workWord2 = toUint64(buffer, 16);
        self.workWord3 = toUint64(buffer, 24);
        self.workWord4 = toUint64(buffer, 32);
        self.workWord5 = toUint64(buffer, 40);
        self.workWord6 = toUint64(buffer, 48);
    }

    function applyMix(Instance memory self, uint remLen, uint32[32] memory indices, uint startIndex, uint step)
        internal
        pure
    {
        uint64[9] memory temp;
     
        temp[0] = self.workWord0;
        temp[1] = self.workWord1;
        temp[2] = self.workWord2;
        temp[3] = self.workWord3;
        temp[4] = self.workWord4;
        temp[5] = self.workWord5;
        temp[6] = self.workWord6;

        // Add in the bits of the index tree to the end of work bits
        uint padNum = ((512 - remLen) + kColisionBitSize) / (kColisionBitSize + 1);

        if (padNum > step)
            padNum = step;

        uint shift = 0;
        uint n0 = 0;
        uint64 idx = 0;
        for (uint i = 0; i < padNum; i++) {
            shift = remLen + i * (kColisionBitSize + 1);
            n0 = shift / (kWordSize * 8);
            shift %= (kWordSize * 8);

            idx = indices[startIndex + i];

            temp[n0] |= idx << uint64(shift);

            if (shift + kColisionBitSize + 1 > kWordSize * 8)
                temp[n0 + 1] |= idx >> (kWordSize * 8 - shift);
        }

        // Applyin the mix from the lined up bits
        uint64 result = 0;
        result = SipHash.rotl(temp[0], (29 * 1) & 0x3F) +
                 SipHash.rotl(temp[1], (29 * 2) & 0x3F) +
                 SipHash.rotl(temp[2], (29 * 3) & 0x3F) +
                 SipHash.rotl(temp[3], (29 * 4) & 0x3F) +
                 SipHash.rotl(temp[4], (29 * 5) & 0x3F) +
                 SipHash.rotl(temp[5], (29 * 6) & 0x3F) +
                 SipHash.rotl(temp[6], (29 * 7) & 0x3F) +
                 SipHash.rotl(temp[7], (29 * 8) & 0x3F);

        result = SipHash.rotl(result, 24);

        // Wipe out lowest 64 bits in favor of the mixed bits
        self.workWord0 = result;
    }

    function hasColision(Instance memory self, Instance memory other)
        internal
        pure
        returns (bool)
    {
        uint64 val = self.workWord0 ^ other.workWord0;
        uint64 mask = (1 << 24) - 1;

        return (val & mask) == 0;
    }

    function isZero(Instance memory self)
        internal
        pure
        returns (bool)
    {
        return self.workWord0 == 0 || self.workWord1 == 0 ||
               self.workWord2 == 0 || self.workWord3 == 0 ||
               self.workWord4 == 0 || self.workWord5 == 0 ||
               self.workWord6 == 0;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "evmVersion": "petersburg",
  "libraries": {},
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