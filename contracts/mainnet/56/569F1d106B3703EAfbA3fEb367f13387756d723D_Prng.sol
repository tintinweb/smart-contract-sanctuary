/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.5.2;

import "PrimeFieldElement0.sol";

contract Prng is PrimeFieldElement0 {
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
