pragma solidity ^0.5.2;

import "./Prng.sol";

contract VerifierChannel is Prng {

    /*
      We store the state of the channel in uint256[3] as follows:
        [0] proof pointer.
        [1] prng digest.
        [2] prng counter.
    */
    uint256 constant internal CHANNEL_STATE_SIZE = 3;

    event LogValue(bytes32 val);

    event SendRandomnessEvent(uint256 val);

    event ReadFieldElementEvent(uint256 val);

    event ReadHashEvent(bytes32 val);

    function getPrngPtr(uint256 channelPtr)
        internal pure
        returns (uint256)
    {
        return channelPtr + 0x20;
    }

    function initChannel(uint256 channelPtr, uint256 proofPtr, bytes32 publicInputHash)
        internal pure
    {
        assembly {
            // Skip 0x20 bytes length at the beginning of the proof.
            mstore(channelPtr, add(proofPtr, 0x20))
        }

        initPrng(getPrngPtr(channelPtr), publicInputHash);
    }

    function sendFieldElements(uint256 channelPtr, uint256 nElements, uint256 targetPtr)
        internal pure
    {
        require(nElements < 0x1000000, "Overflow protection failed.");
        assembly {
            let PRIME := 0x30000003000000010000000000000001
            let PRIME_MON_R_INV := 0x9000001200000096000000600000001
            let PRIME_MASK := 0x3fffffffffffffffffffffffffffffff
            let digestPtr := add(channelPtr, 0x20)
            let counterPtr := add(channelPtr, 0x40)

            let endPtr := add(targetPtr, mul(nElements, 0x20))
            for { } lt(targetPtr, endPtr) { targetPtr := add(targetPtr, 0x20) } {
                // *targetPtr = getRandomFieldElement(getPrngPtr(channelPtr));

                let fieldElement := PRIME
                // while (fieldElement >= PRIME).
                for { } iszero(lt(fieldElement, PRIME)) { } {
                    // keccak256(abi.encodePacked(digest, counter));
                    fieldElement := and(keccak256(digestPtr, 0x40), PRIME_MASK)
                    // *counterPtr += 1;
                    mstore(counterPtr, add(mload(counterPtr), 1))
                }
                // *targetPtr = fromMontgomery(fieldElement);
                mstore(targetPtr, mulmod(fieldElement, PRIME_MON_R_INV, PRIME))
                // emit ReadFieldElementEvent(fieldElement);
                // log1(targetPtr, 0x20, 0x4bfcc54f35095697be2d635fb0706801e13637312eff0cedcdfc254b3b8c385e);
            }
        }
    }

    /*
      Sends random queries and returns an array of queries sorted in ascending order.
      Generates count queries in the range [0, mask] and returns the number of unique queries.
      Note that mask is of the form 2^k-1 (for some k).

      Note that queriesOutPtr may be (and is) inteleaved with other arrays. The stride parameter
      is passed to indicate the distance between every two entries to the queries array, i.e.
      stride = 0x20*(number of interleaved arrays).
    */
    function sendRandomQueries(
        uint256 channelPtr, uint256 count, uint256 mask, uint256 queriesOutPtr, uint256 stride)
        internal pure returns (uint256)
    {
        uint256 val;
        uint256 shift = 0;
        uint256 endPtr = queriesOutPtr;
        for (uint256 i = 0; i < count; i++) {
            if (shift == 0) {
                val = uint256(getRandomBytes(getPrngPtr(channelPtr)));
                shift = 0x100;
            }
            shift -= 0x40;
            uint256 queryIdx = (val >> shift) & mask;
            // emit sendRandomnessEvent(queryIdx);

            uint256 ptr = endPtr;
            uint256 curr;
            // Insert new queryIdx in the correct place like insertion sort.

            while (ptr > queriesOutPtr) {
                assembly {
                    curr := mload(sub(ptr, stride))
                }

                if (queryIdx >= curr) {
                    break;
                }

                assembly {
                    mstore(ptr, curr)
                }
                ptr -= stride;
            }

            if (queryIdx != curr) {
                assembly {
                    mstore(ptr, queryIdx)
                }
                endPtr += stride;
            } else {
                // Revert right shuffling.
                while (ptr < endPtr) {
                    assembly {
                        mstore(ptr, mload(add(ptr, stride)))
                        ptr := add(ptr, stride)
                    }
                }
            }
        }

        return (endPtr - queriesOutPtr) / stride;
    }

    function readBytes(uint256 channelPtr, bool mix)
        internal pure
        returns (bytes32)
    {
        uint256 proofPtr;
        bytes32 val;

        assembly {
            proofPtr := mload(channelPtr)
            val := mload(proofPtr)
            mstore(channelPtr, add(proofPtr, 0x20))
        }
        if (mix) {
            // inline: Prng.mixSeedWithBytes(getPrngPtr(channelPtr), abi.encodePacked(val));
            assembly {
                let digestPtr := add(channelPtr, 0x20)
                let counterPtr := add(digestPtr, 0x20)
                mstore(counterPtr, val)
                // prng.digest := keccak256(digest||val), nonce was written earlier.
                mstore(digestPtr, keccak256(digestPtr, 0x40))
                // prng.counter := 0.
                mstore(counterPtr, 0)
            }
        }

        return val;
    }

    function readHash(uint256 channelPtr, bool mix)
        internal pure
        returns (bytes32)
    {
        bytes32 val = readBytes(channelPtr, mix);
        // emit ReadHashEvent(val);

        return val;
    }

    function readFieldElement(uint256 channelPtr, bool mix)
        internal pure returns (uint256) {
        uint256 val = fromMontgomery(uint256(readBytes(channelPtr, mix)));
        // emit ReadFieldElementEvent(val);

        return val;
    }

    function verifyProofOfWork(uint256 channelPtr, uint256 proofOfWorkBits) internal pure {
        if (proofOfWorkBits == 0) {
            return;
        }

        uint256 proofOfWorkDigest;
        assembly {
            // [0:29] := 0123456789abcded || digest || workBits.
            mstore(0, 0x0123456789abcded000000000000000000000000000000000000000000000000)
            let digest := mload(add(channelPtr, 0x20))
            mstore(0x8, digest)
            mstore8(0x28, proofOfWorkBits)
            mstore(0, keccak256(0, 0x29))

            let proofPtr := mload(channelPtr)
            mstore(0x20, mload(proofPtr))
            // proofOfWorkDigest:= keccak256(keccak256(0123456789abcded || digest || workBits) || nonce).
            proofOfWorkDigest := keccak256(0, 0x28)

            mstore(0, digest)
            // prng.digest := keccak256(digest||nonce), nonce was written earlier.
            mstore(add(channelPtr, 0x20), keccak256(0, 0x28))
            // prng.counter := 0.
            mstore(add(channelPtr, 0x40), 0)

            mstore(channelPtr, add(proofPtr, 0x8))
        }

        uint256 proofOfWorkThreshold = uint256(1) << (256 - proofOfWorkBits);
        require(proofOfWorkDigest < proofOfWorkThreshold, "Proof of work check failed.");
    }
}
