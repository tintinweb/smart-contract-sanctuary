pragma solidity ^0.5.2;

import "./MemoryMap.sol";
import "./MemoryAccessUtils.sol";
import "./FriLayer.sol";
import "./HornerEvaluator.sol";

/*
  This contract computes and verifies all the FRI layer, one by one. The final layer is verified
  by evaluating the fully committed polynomial, and requires specific handling.
*/
contract Fri is MemoryMap, MemoryAccessUtils, HornerEvaluator, FriLayer {
    event LogGas(string name, uint256 val);

    function verifyLastLayer(uint256[] memory ctx, uint256 nPoints)
        internal {
        uint256 friLastLayerDegBound = ctx[MM_FRI_LAST_LAYER_DEG_BOUND];
        uint256 groupOrderMinusOne = friLastLayerDegBound * ctx[MM_BLOW_UP_FACTOR] - 1;
        uint256 coefsStart = ctx[MM_FRI_LAST_LAYER_PTR];

        for (uint256 i = 0; i < nPoints; i++) {
            uint256 point = ctx[MM_FRI_QUEUE + 3*i + 2];
            // Invert point using inverse(point) == fpow(point, ord(point) - 1).

            point = fpow(point, groupOrderMinusOne);
            require(
                hornerEval(coefsStart, point, friLastLayerDegBound) == ctx[MM_FRI_QUEUE + 3*i + 1],
                "Bad Last layer value.");
        }
    }

    /*
      Verifies FRI layers.

      Upon entry and every time we pass through the "if (index < layerSize)" condition,
      ctx[mmFriQueue:] holds an array of triplets (query index, FRI value, FRI inversed point), i.e.
          ctx[mmFriQueue::3] holds query indices.
          ctx[mmFriQueue + 1::3] holds the input for the next layer.
          ctx[mmFriQueue + 2::3] holds the inverses of the evaluation points:
            ctx[mmFriQueue + 3*i + 2] = inverse(
                fpow(layerGenerator,  bitReverse(ctx[mmFriQueue + 3*i], logLayerSize)).
    */
    function friVerifyLayers(
        uint256[] memory ctx)
        internal
    {

        uint256 friCtx = getPtr(ctx, MM_FRI_CTX);
        require(
            MAX_SUPPORTED_MAX_FRI_STEP == FRI_MAX_FRI_STEP,
            "Incosistent MAX_FRI_STEP between MemoryMap.sol and FriLayer.sol");
        initFriGroups(friCtx);
        // emit LogGas("FRI offset precomputation", gasleft());
        uint256 channelPtr = getChannelPtr(ctx);
        uint256 merkleQueuePtr = getMerkleQueuePtr(ctx);

        uint256 friStep = 1;
        uint256 nLiveQueries = ctx[MM_N_UNIQUE_QUERIES];

        // Add 0 at the end of the queries array to avoid empty array check in readNextElment.
        ctx[MM_FRI_QUERIES_DELIMITER] = 0;

        // Rather than converting all the values from Montgomery to standard form,
        // we can just pretend that the values are in standard form but all
        // the committed polynomials are multiplied by MontgomeryR.
        //
        // The values in the proof are already multiplied by MontgomeryR,
        // but the inputs from the OODS oracle need to be fixed.
        for (uint256 i = 0; i < nLiveQueries; i++ ) {
            ctx[MM_FRI_QUEUE + 3*i + 1] = fmul(ctx[MM_FRI_QUEUE + 3*i + 1], K_MONTGOMERY_R);
        }

        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);

        uint256[] memory friSteps = getFriSteps(ctx);
        uint256 nFriSteps = friSteps.length;
        while (friStep < nFriSteps) {
            uint256 friCosetSize = 2**friSteps[friStep];

            nLiveQueries = computeNextLayer(
                channelPtr, friQueue, merkleQueuePtr, nLiveQueries,
                ctx[MM_FRI_EVAL_POINTS + friStep], friCosetSize, friCtx);

            // emit LogGas(
            //     string(abi.encodePacked("FRI layer ", bytes1(uint8(48 + friStep)))), gasleft());

            // Layer is done, verify the current layer and move to next layer.
            // ctx[mmMerkleQueue: merkleQueueIdx) holds the indices
            // and values of the merkle leaves that need verification.
            verify(
                channelPtr, merkleQueuePtr, bytes32(ctx[MM_FRI_COMMITMENTS + friStep - 1]),
                nLiveQueries);

            // emit LogGas(
            //     string(abi.encodePacked("Merkle of FRI layer ", bytes1(uint8(48 + friStep)))),
            //     gasleft());
            friStep++;
        }

        verifyLastLayer(ctx, nLiveQueries);
        // emit LogGas("last FRI layer", gasleft());
    }
}
