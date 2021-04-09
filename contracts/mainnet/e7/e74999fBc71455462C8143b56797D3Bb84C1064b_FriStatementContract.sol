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

import "FactRegistry.sol";
import "FriLayer.sol";

contract FriStatementContract is FriLayer, FactRegistry {
    /*
      Compute a single FRI layer of size friStepSize at evaluationPoint starting from input
      friQueue, and the extra witnesses in the "proof" channel. Also check that the input and
      witnesses belong to a Merkle tree with root expectedRoot, again using witnesses from "proof".
      After verification, register the FRI fact hash, which is:
      keccak256(
          evaluationPoint,
          friStepSize,
          keccak256(friQueue_input),
          keccak256(friQueue_output),  // The FRI queue after proccessing the FRI layer
          expectedRoot
      )

      Note that this function is used as external, but declared public to avoid copying the arrays.
    */
    function verifyFRI(
        uint256[] memory proof,
        uint256[] memory friQueue,
        uint256 evaluationPoint,
        uint256 friStepSize,
        uint256 expectedRoot) public {

        require (friStepSize <= FRI_MAX_FRI_STEP, "FRI step size too large");
        /*
          The friQueue should have of 3*nQueries + 1 elements, beginning with nQueries triplets
          of the form (query_index, FRI_value, FRI_inverse_point), and ending with a single buffer
          cell set to 0, which is accessed and read during the computation of the FRI layer.
        */
        require (
            friQueue.length % 3 == 1,
            "FRI Queue must be composed of triplets plus one delimiter cell");
        require (friQueue.length >= 4, "No query to process");

        uint256 mmFriCtxSize = FRI_CTX_SIZE;
        uint256 nQueries = friQueue.length / 3;
        friQueue[3*nQueries] = 0;  // NOLINT: divide-before-multiply.
        uint256 merkleQueuePtr;
        uint256 friQueuePtr;
        uint256 channelPtr;
        uint256 friCtx;
        uint256 dataToHash;

        // Verify evaluation point within valid range.
        require(evaluationPoint < K_MODULUS, "INVALID_EVAL_POINT");

        // Queries need to be in the range [2**height .. 2**(height+1)-1] strictly incrementing.
        // i.e. we need to check that Qi+1 > Qi for each i,
        // but regarding the height range - it's sufficient to check that
        // (Q1 ^ Qn) < Q1 Which affirms that all queries are within the same logarithmic step.

        // Verify FRI values and inverses are within valid range.
        // and verify that queries are strictly incrementing.
        uint256 prevQuery = 0; // If we pass height, change to: prevQuery = 1 << height - 1;
        for (uint256 i = 0; i < nQueries; i++) {
            require(friQueue[3*i] > prevQuery, "INVALID_QUERY_VALUE");
            require(friQueue[3*i+1] < K_MODULUS, "INVALID_FRI_VALUE");
            require(friQueue[3*i+2] < K_MODULUS, "INVALID_FRI_INVERSE_POINT");
            prevQuery = friQueue[3*i];
        }

        // Verify all queries are on the same logarithmic step.
        // NOLINTNEXTLINE: divide-before-multiply.
        require((friQueue[0] ^ friQueue[3*nQueries-3]) < friQueue[0], "INVALID_QUERIES_RANGE");

        // Allocate memory queues: channelPtr, merkleQueue, friCtx, dataToHash.
        assembly {
            friQueuePtr := add(friQueue, 0x20)
            channelPtr := mload(0x40) // Free pointer location.
            mstore(channelPtr, add(proof, 0x20))
            merkleQueuePtr := add(channelPtr, 0x20)
            friCtx := add(merkleQueuePtr, mul(0x40, nQueries))
            dataToHash := add(friCtx, mmFriCtxSize)
            mstore(0x40, add(dataToHash, 0xa0)) // Advance free pointer.

            mstore(dataToHash, evaluationPoint)
            mstore(add(dataToHash, 0x20), friStepSize)
            mstore(add(dataToHash, 0x80), expectedRoot)

            // Hash FRI inputs and add to dataToHash.
            mstore(add(dataToHash, 0x40), keccak256(friQueuePtr, mul(0x60, nQueries)))
        }

        initFriGroups(friCtx);

        nQueries = computeNextLayer(
            channelPtr, friQueuePtr, merkleQueuePtr, nQueries, evaluationPoint,
            2**friStepSize, /* friCosetSize = 2**friStepSize */
            friCtx);

        verify(channelPtr, merkleQueuePtr, bytes32(expectedRoot), nQueries);

        bytes32 factHash;
        assembly {
            // Hash FRI outputs and add to dataToHash.
            mstore(add(dataToHash, 0x60), keccak256(friQueuePtr, mul(0x60, nQueries)))
            factHash := keccak256(dataToHash, 0xa0)
        }

        registerFact(factHash);
    }
}