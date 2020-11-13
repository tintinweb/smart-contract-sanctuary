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

import "MemoryMap.sol";
import "MemoryAccessUtils.sol";
import "FriStatementContract.sol";
import "HornerEvaluator.sol";
import "VerifierChannel.sol";

/*
  This contract verifies all the FRI layer, one by one, using the FriStatementContract.
  The first layer is computed from decommitments, the last layer is computed by evaluating the
  fully committed polynomial, and the mid-layers are provided in the proof only as hashed data.
*/
contract FriStatementVerifier is MemoryMap, MemoryAccessUtils, VerifierChannel, HornerEvaluator {
    event LogGas(string name, uint256 val);

    FriStatementContract friStatementContract;

    constructor(address friStatementContractAddress) internal {
        friStatementContract = FriStatementContract(friStatementContractAddress);
    }

    /*
      Fast-forwards the queries and invPoints of the friQueue from before the first layer to after
      the last layer, computes the last FRI layer using horner evalations, then returns the hash
      of the final FriQueue.
    */
    function computerLastLayerHash(uint256[] memory ctx, uint256 nPoints, uint256 numLayers)
        internal view returns (bytes32 lastLayerHash) {
        uint256 friLastLayerDegBound = ctx[MM_FRI_LAST_LAYER_DEG_BOUND];
        uint256 groupOrderMinusOne = friLastLayerDegBound * ctx[MM_BLOW_UP_FACTOR] - 1;
        uint256 exponent = 1 << numLayers;
        uint256 curPointIndex = 0;
        uint256 prevQuery = 0;
        uint256 coefsStart = ctx[MM_FRI_LAST_LAYER_PTR];

        for (uint256 i = 0; i < nPoints; i++) {
            uint256 query = ctx[MM_FRI_QUEUE + 3*i] >> numLayers;
            if (query == prevQuery) {
                continue;
            }
            ctx[MM_FRI_QUEUE + 3*curPointIndex] = query;
            prevQuery = query;

            uint256 point = fpow(ctx[MM_FRI_QUEUE + 3*i + 2], exponent);
            ctx[MM_FRI_QUEUE + 3*curPointIndex + 2] = point;
            // Invert point using inverse(point) == fpow(point, ord(point) - 1).

            point = fpow(point, groupOrderMinusOne);
            ctx[MM_FRI_QUEUE + 3*curPointIndex + 1] = hornerEval(
                coefsStart, point, friLastLayerDegBound);

            curPointIndex++;
        }

        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        assembly {
            lastLayerHash := keccak256(friQueue, mul(curPointIndex, 0x60))
        }
    }

    /*
      Verifies that FRI layers consistent with the computed first and last FRI layers
      have been registered in the FriStatementContract.
    */
    function friVerifyLayers(
        uint256[] memory ctx)
        internal view
    {
        uint256 channelPtr = getChannelPtr(ctx);
        uint256 nQueries = ctx[MM_N_UNIQUE_QUERIES];

        // Rather than converting all the values from Montgomery to standard form,
        // we can just pretend that the values are in standard form but all
        // the committed polynomials are multiplied by MontgomeryR.
        //
        // The values in the proof are already multiplied by MontgomeryR,
        // but the inputs from the OODS oracle need to be fixed.
        for (uint256 i = 0; i < nQueries; i++ ) {
            ctx[MM_FRI_QUEUE + 3*i + 1] = fmul(ctx[MM_FRI_QUEUE + 3*i + 1], K_MONTGOMERY_R);
        }

        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        uint256 inputLayerHash;
        assembly {
            inputLayerHash := keccak256(friQueue, mul(nQueries, 0x60))
        }


        uint256[] memory friSteps = getFriSteps(ctx);
        uint256 nFriStepsLessOne = friSteps.length - 1;
        uint256 friStep = 1;
        uint256 sumSteps = friSteps[1];
        uint256[5] memory dataToHash;
        while (friStep < nFriStepsLessOne) {
            uint256 outputLayerHash = uint256(readBytes(channelPtr, true));
            dataToHash[0] = ctx[MM_FRI_EVAL_POINTS + friStep];
            dataToHash[1] = friSteps[friStep];
            dataToHash[2] = inputLayerHash;
            dataToHash[3] = outputLayerHash;
            dataToHash[4] = ctx[MM_FRI_COMMITMENTS + friStep - 1];

            // Verify statement is registered.
            require( // NOLINT: calls-loop.
                friStatementContract.isValid(keccak256(abi.encodePacked(dataToHash))),
                "INVALIDATED_FRI_STATEMENT");

            inputLayerHash = outputLayerHash;

            friStep++;
            sumSteps += friSteps[friStep];
        }

        dataToHash[0] = ctx[MM_FRI_EVAL_POINTS + friStep];
        dataToHash[1] = friSteps[friStep];
        dataToHash[2] = inputLayerHash;
        dataToHash[3] = uint256(computerLastLayerHash(ctx, nQueries, sumSteps));
        dataToHash[4] = ctx[MM_FRI_COMMITMENTS + friStep - 1];

        require(
            friStatementContract.isValid(keccak256(abi.encodePacked(dataToHash))),
            "INVALIDATED_FRI_STATEMENT");
    }
}
