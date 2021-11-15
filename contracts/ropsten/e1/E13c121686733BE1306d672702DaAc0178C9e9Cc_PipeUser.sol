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

        RemoteMessage memory tmp = m_remoteMessages[key];

        delete m_remoteMessages[key];

        return tmp.value;
    }

    function pushLocalMessage(bytes32 contractReceiver, bytes memory msgBody)
        public
    {
        // TODO: pckgId
        emit NewLocalMessage(m_localMsgCounter++, msg.sender, contractReceiver, msgBody);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "./Pipe.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract PipeUser {
    using SafeERC20 for IERC20;
    address m_pipeAddress;
    address m_beamToken;
    bytes32 m_beamPipeUserCid;

    constructor(address pipeAddress, address beamToken, bytes32 beamPipeUserCid)
    {
        m_pipeAddress = pipeAddress;
        m_beamToken = beamToken;
        m_beamPipeUserCid = beamPipeUserCid;
    }

    function receiveFunds(uint msgId)
        public
    {
        bytes memory value = Pipe(m_pipeAddress).getRemoteMessage(msgId);

        // parse msg: [address][uint64 value]
        address receiver;
        bytes8 tmp;
        assembly {
            receiver := shr(96, mload(add(value, 32)))
            tmp := mload(add(value, 52))
        }
        uint64 amount = BeamUtils.reverse64(uint64(tmp));

        IERC20(m_beamToken).safeTransfer(receiver, amount);
    }

    function sendFunds(uint64 value, bytes memory receiverBeamPubkey)
        public
    {
        IERC20(m_beamToken).safeTransferFrom(msg.sender, address(this), value);

        Pipe(m_pipeAddress).pushLocalMessage(m_beamPipeUserCid, abi.encodePacked(receiverBeamPubkey, value));
    }

    function setRemote(bytes32 remoteContractId)
        public
    {
        m_beamPipeUserCid = remoteContractId;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

