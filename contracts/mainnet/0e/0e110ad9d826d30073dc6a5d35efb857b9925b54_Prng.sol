pragma solidity ^0.5.2;

import "./PrimeFieldElement6.sol";

contract Prng is PrimeFieldElement6 {
    function storePrng(uint256 statePtr, bytes32 digest, uint256 counter)
        internal pure {
        assembly {
            mstore(statePtr, digest)
            mstore(add(statePtr, 0x20), counter)
        }
    }

    function loadPrng(uint256 statePtr)
        internal pure
        returns (bytes32, uint256) {
        bytes32 digest;
        uint256 counter;

        assembly {
            digest := mload(statePtr)
            counter := mload(add(statePtr, 0x20))
        }

        return (digest, counter);
    }

    function initPrng(uint256 prngPtr, bytes32 publicInputHash)
        internal pure
    {
        storePrng(prngPtr, /*keccak256(publicInput)*/ publicInputHash, 0);
    }

    /*
      Auxiliary function for getRandomBytes.
    */
    function getRandomBytesInner(bytes32 digest, uint256 counter)
        internal pure
        returns (bytes32, uint256, bytes32)
    {
        // returns 32 bytes (for random field elements or four queries at a time).
        bytes32 randomBytes = keccak256(abi.encodePacked(digest, counter));

        return (digest, counter + 1, randomBytes);
    }

    /*
      Returns 32 bytes. Used for a random field element, or for 4 query indices.
    */
    function getRandomBytes(uint256 prngPtr)
        internal pure
        returns (bytes32 randomBytes)
    {
        bytes32 digest;
        uint256 counter;
        (digest, counter) = loadPrng(prngPtr);

        // returns 32 bytes (for random field elements or four queries at a time).
        (digest, counter, randomBytes) = getRandomBytesInner(digest, counter);

        storePrng(prngPtr, digest, counter);
        return randomBytes;
    }

    function mixSeedWithBytes(uint256 prngPtr, bytes memory dataBytes)
        internal pure
    {
        bytes32 digest;

        assembly {
            digest := mload(prngPtr)
        }
        initPrng(prngPtr, keccak256(abi.encodePacked(digest, dataBytes)));
    }

    function getPrngDigest(uint256 prngPtr)
        internal pure
        returns (bytes32 digest)
    {
        assembly {
           digest := mload(prngPtr)
        }
    }
}
