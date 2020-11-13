pragma solidity ^0.5.2;

import "./Fri.sol";
import "./MemoryMap.sol";
import "./MemoryAccessUtils.sol";
import "./IStarkVerifier.sol";
import "./VerifierChannel.sol";


contract StarkVerifier is MemoryMap, MemoryAccessUtils, VerifierChannel, IStarkVerifier, Fri {
    /*
      The work required to generate an invalid proof is 2^numSecurityBits.
      Typical values: 80-128.
    */
    uint256 numSecurityBits;

    /*
      The secuirty of a proof is a composition of bits obtained by PoW and bits obtained by FRI
      queries. The verifier requires at least minProofOfWorkBits to be obtained by PoW.
      Typical values: 20-30.
    */
    uint256 minProofOfWorkBits;

    constructor(uint256 numSecurityBits_, uint256 minProofOfWorkBits_) public {
        numSecurityBits = numSecurityBits_;
        minProofOfWorkBits = minProofOfWorkBits_;
    }

    /*
      To print LogDebug messages from assembly use code like the following:

      assembly {
            let val := 0x1234
            mstore(0, val) // uint256 val
            // log to the LogDebug(uint256) topic
            log1(0, 0x20, 0x2feb477e5c8c82cfb95c787ed434e820b1a28fa84d68bbf5aba5367382f5581c)
      }

      Note that you can't use log in a contract that was called with staticcall
      (ContraintPoly, Oods,...)

      If logging is needed replace the staticcall to call and add a third argument of 0.
    */
    event LogBool(bool val);
    event LogDebug(uint256 val);
    address oodsContractAddress;

    function airSpecificInit(uint256[] memory publicInput)
        internal returns (uint256[] memory ctx, uint256 logTraceLength);

    uint256 constant internal PROOF_PARAMS_N_QUERIES_OFFSET = 0;
    uint256 constant internal PROOF_PARAMS_LOG_BLOWUP_FACTOR_OFFSET = 1;
    uint256 constant internal PROOF_PARAMS_PROOF_OF_WORK_BITS_OFFSET = 2;
    uint256 constant internal PROOF_PARAMS_FRI_LAST_LAYER_DEG_BOUND_OFFSET = 3;
    uint256 constant internal PROOF_PARAMS_N_FRI_STEPS_OFFSET = 4;
    uint256 constant internal PROOF_PARAMS_FRI_STEPS_OFFSET = 5;

    function validateFriParams(
        uint256[] memory friSteps, uint256 logTraceLength, uint256 logFriLastLayerDegBound)
        internal pure {
        require (friSteps[0] == 0, "Only eta0 == 0 is currently supported");

        uint256 expectedLogDegBound = logFriLastLayerDegBound;
        uint256 nFriSteps = friSteps.length;
        for (uint256 i = 1; i < nFriSteps; i++) {
            uint256 friStep = friSteps[i];
            require(friStep > 0, "Only the first fri step can be 0");
            require(friStep <= 4, "Max supported fri step is 4.");
            expectedLogDegBound += friStep;
        }

        // FRI starts with a polynomial of degree 'traceLength'.
        // After applying all the FRI steps we expect to get a polynomial of degree less
        // than friLastLayerDegBound.
        require (
            expectedLogDegBound == logTraceLength, "Fri params do not match trace length");
    }

    function initVerifierParams(uint256[] memory publicInput, uint256[] memory proofParams)
        internal returns (uint256[] memory ctx) {
        require (proofParams.length > PROOF_PARAMS_FRI_STEPS_OFFSET, "Invalid proofParams.");
        require (
            proofParams.length == (
                PROOF_PARAMS_FRI_STEPS_OFFSET + proofParams[PROOF_PARAMS_N_FRI_STEPS_OFFSET]),
            "Invalid proofParams.");
        uint256 logBlowupFactor = proofParams[PROOF_PARAMS_LOG_BLOWUP_FACTOR_OFFSET];
        require (logBlowupFactor <= 16, "logBlowupFactor must be at most 16");
        require (logBlowupFactor >= 1, "logBlowupFactor must be at least 1");

        uint256 proofOfWorkBits = proofParams[PROOF_PARAMS_PROOF_OF_WORK_BITS_OFFSET];
        require (proofOfWorkBits <= 50, "proofOfWorkBits must be at most 50");
        require (proofOfWorkBits >= minProofOfWorkBits, "minimum proofOfWorkBits not satisfied");
        require (proofOfWorkBits < numSecurityBits, "Proofs may not be purely based on PoW.");

        uint256 logFriLastLayerDegBound = (
            proofParams[PROOF_PARAMS_FRI_LAST_LAYER_DEG_BOUND_OFFSET]
        );
        require (
            logFriLastLayerDegBound <= 10, "logFriLastLayerDegBound must be at most 10.");

        uint256 nFriSteps = proofParams[PROOF_PARAMS_N_FRI_STEPS_OFFSET];
        require (nFriSteps <= 10, "Too many fri steps.");
        require (nFriSteps > 1, "Not enough fri steps.");

        uint256[] memory friSteps = new uint256[](nFriSteps);
        for (uint256 i = 0; i < nFriSteps; i++) {
            friSteps[i] = proofParams[PROOF_PARAMS_FRI_STEPS_OFFSET + i];
        }

        uint256 logTraceLength;
        (ctx, logTraceLength) = airSpecificInit(publicInput);

        validateFriParams(friSteps, logTraceLength, logFriLastLayerDegBound);

        uint256 friStepsPtr = getPtr(ctx, MM_FRI_STEPS_PTR);
        assembly {
            mstore(friStepsPtr, friSteps)
        }
        ctx[MM_FRI_LAST_LAYER_DEG_BOUND] = 2**logFriLastLayerDegBound;
        ctx[MM_TRACE_LENGTH] = 2 ** logTraceLength;

        ctx[MM_BLOW_UP_FACTOR] = 2**logBlowupFactor;
        ctx[MM_PROOF_OF_WORK_BITS] = proofOfWorkBits;

        uint256 nQueries = proofParams[PROOF_PARAMS_N_QUERIES_OFFSET];
        require (nQueries > 0, "Number of queries must be at least one");
        require (nQueries <= MAX_N_QUERIES, "Too many queries.");
        require (
            nQueries * logBlowupFactor + proofOfWorkBits >= numSecurityBits,
            "Proof params do not satisfy security requirements.");

        ctx[MM_N_UNIQUE_QUERIES] = nQueries;

        // We start with log_evalDomainSize = logTraceSize and update it here.
        ctx[MM_LOG_EVAL_DOMAIN_SIZE] = logTraceLength + logBlowupFactor;
        ctx[MM_EVAL_DOMAIN_SIZE] = 2**ctx[MM_LOG_EVAL_DOMAIN_SIZE];

        uint256 gen_evalDomain = fpow(GENERATOR_VAL, (K_MODULUS - 1) / ctx[MM_EVAL_DOMAIN_SIZE]);
        ctx[MM_EVAL_DOMAIN_GENERATOR] = gen_evalDomain;
        uint256 genTraceDomain = fpow(gen_evalDomain, ctx[MM_BLOW_UP_FACTOR]);
        ctx[MM_TRACE_GENERATOR] = genTraceDomain;
    }

    function getPublicInputHash(uint256[] memory publicInput) internal pure returns (bytes32);

    function oodsConsistencyCheck(uint256[] memory ctx) internal;

    function getNColumnsInTrace() internal pure returns(uint256);

    function getNColumnsInComposition() internal pure returns(uint256);

    function getMmCoefficients() internal pure returns(uint256);

    function getMmOodsValues() internal pure returns(uint256);

    function getMmOodsCoefficients() internal pure returns(uint256);

    function getNCoefficients() internal pure returns(uint256);

    function getNOodsValues() internal pure returns(uint256);

    function getNOodsCoefficients() internal pure returns(uint256);

    function hashRow(uint256[] memory ctx, uint256 offset, uint256 length)
    internal pure returns (uint256 res) {
        assembly {
            res := keccak256(add(add(ctx, 0x20), offset), length)
        }
        res &= getHashMask();
    }

    /*
      Adjusts the query indices and generates evaluation points for each query index.
      The operations above are independent but we can save gas by combining them as both
      operations require us to iterate the queries array.

      Indices adjustment:
          The query indices adjustment is needed because both the Merkle verification and FRI
          expect queries "full binary tree in array" indices.
          The adjustment is simply adding evalDomainSize to each query.
          Note that evalDomainSize == 2^(#FRI layers) == 2^(Merkle tree hight).

      evalPoints generation:
          for each query index "idx" we compute the corresponding evaluation point:
              g^(bitReverse(idx, log_evalDomainSize).
    */
    function adjustQueryIndicesAndPrepareEvalPoints(uint256[] memory ctx) internal {
        uint256 nUniqueQueries = ctx[MM_N_UNIQUE_QUERIES];
        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        uint256 friQueueEnd = friQueue + nUniqueQueries * 0x60;
        uint256 evalPointsPtr = getPtr(ctx, MM_OODS_EVAL_POINTS);
        uint256 log_evalDomainSize = ctx[MM_LOG_EVAL_DOMAIN_SIZE];
        uint256 evalDomainSize = ctx[MM_EVAL_DOMAIN_SIZE];
        uint256 evalDomainGenerator = ctx[MM_EVAL_DOMAIN_GENERATOR];

        assembly {
            /*
              Returns the bit reversal of value assuming it has the given number of bits.
              numberOfBits must be <= 64.
            */
            function bitReverse(value, numberOfBits) -> res {
                // Bit reverse value by swapping 1 bit chunks then 2 bit chunks and so forth.
                // Each swap is done by masking out and shifting one of the chunks by twice its size.
                // Finally, we use div to align the result to the right.
                res := value
                // Swap 1 bit chunks.
                res := or(mul(and(res, 0x5555555555555555), 0x4),
                        and(res, 0xaaaaaaaaaaaaaaaa))
                // Swap 2 bit chunks.
                res := or(mul(and(res, 0x6666666666666666), 0x10),
                        and(res, 0x19999999999999998))
                // Swap 4 bit chunks.
                res := or(mul(and(res, 0x7878787878787878), 0x100),
                        and(res, 0x78787878787878780))
                // Swap 8 bit chunks.
                res := or(mul(and(res, 0x7f807f807f807f80), 0x10000),
                        and(res, 0x7f807f807f807f8000))
                // Swap 16 bit chunks.
                res := or(mul(and(res, 0x7fff80007fff8000), 0x100000000),
                        and(res, 0x7fff80007fff80000000))
                // Swap 32 bit chunks.
                res := or(mul(and(res, 0x7fffffff80000000), 0x10000000000000000),
                        and(res, 0x7fffffff8000000000000000))
                // Right align the result.
                res := div(res, exp(2, sub(127, numberOfBits)))
            }

            function expmod(base, exponent, modulus) -> res {
                let p := mload(0x40)
                mstore(p, 0x20)                 // Length of Base.
                mstore(add(p, 0x20), 0x20)      // Length of Exponent.
                mstore(add(p, 0x40), 0x20)      // Length of Modulus.
                mstore(add(p, 0x60), base)      // Base.
                mstore(add(p, 0x80), exponent)  // Exponent.
                mstore(add(p, 0xa0), modulus)   // Modulus.
                // Call modexp precompile.
                if iszero(call(not(0), 0x05, 0, p, 0xc0, p, 0x20)) {
                    revert(0, 0)
                }
                res := mload(p)
            }

            let PRIME := 0x30000003000000010000000000000001

            for {} lt(friQueue, friQueueEnd) {friQueue := add(friQueue, 0x60)} {
                let queryIdx := mload(friQueue)
                // Adjust queryIdx, see comment in function description.
                let adjustedQueryIdx := add(queryIdx, evalDomainSize)
                mstore(friQueue, adjustedQueryIdx)

                // Compute the evaluation point corresponding to the current queryIdx.
                mstore(evalPointsPtr, expmod(evalDomainGenerator,
                                             bitReverse(queryIdx, log_evalDomainSize),
                                             PRIME))
                evalPointsPtr := add(evalPointsPtr, 0x20)
            }
        }
    }

    function readQueryResponsesAndDecommit(
        uint256[] memory ctx, uint256 nColumns, uint256 proofDataPtr, bytes32 merkleRoot)
         internal view {
        require(nColumns <= getNColumnsInTrace() + getNColumnsInComposition(), "Too many columns.");

        uint256 nUniqueQueries = ctx[MM_N_UNIQUE_QUERIES];
        uint256 channelPtr = getPtr(ctx, MM_CHANNEL);
        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        uint256 friQueueEnd = friQueue + nUniqueQueries * 0x60;
        uint256 merkleQueuePtr = getPtr(ctx, MM_MERKLE_QUEUE);
        uint256 rowSize = 0x20 * nColumns;
        uint256 lhashMask = getHashMask();

        assembly {
            let proofPtr := mload(channelPtr)
            let merklePtr := merkleQueuePtr

            for {} lt(friQueue, friQueueEnd) {friQueue := add(friQueue, 0x60)} {
                let merkleLeaf := and(keccak256(proofPtr, rowSize), lhashMask)
                if eq(rowSize, 0x20) {
                    // If a leaf contains only 1 field element we don't hash it.
                    merkleLeaf := mload(proofPtr)
                }

                // push(queryIdx, hash(row)) to merkleQueue.
                mstore(merklePtr, mload(friQueue))
                mstore(add(merklePtr, 0x20), merkleLeaf)
                merklePtr := add(merklePtr, 0x40)

                // Copy query responses to proofData array.
                // This array will be sent to the OODS contract.
                for {let proofDataChunk_end := add(proofPtr, rowSize)}
                        lt(proofPtr, proofDataChunk_end)
                        {proofPtr := add(proofPtr, 0x20)} {
                    mstore(proofDataPtr, mload(proofPtr))
                    proofDataPtr := add(proofDataPtr, 0x20)
                }
            }

            mstore(channelPtr, proofPtr)
        }

        verify(channelPtr, merkleQueuePtr, merkleRoot, nUniqueQueries);
    }

    /*
      Computes the first FRI layer by reading the query responses and calling
      the OODS contract.

      The OODS contract will build and sum boundary constraints that check that
      the prover provided the proper evaluations for the Out of Domain Sampling.

      I.e. if the prover said that f(z) = c, the first FRI layer will include
      the term (f(x) - c)/(x-z).
    */
    function computeFirstFriLayer(uint256[] memory ctx) internal {
        adjustQueryIndicesAndPrepareEvalPoints(ctx);
        // emit LogGas("Prepare evaluation points", gasleft());
        readQueryResponsesAndDecommit(
            ctx, getNColumnsInTrace(), getPtr(ctx, MM_TRACE_QUERY_RESPONSES),
            bytes32(ctx[MM_TRACE_COMMITMENT]));
        // emit LogGas("Read and decommit trace", gasleft());

        readQueryResponsesAndDecommit(
            ctx, getNColumnsInComposition(), getPtr(ctx, MM_COMPOSITION_QUERY_RESPONSES),
            bytes32(ctx[MM_OODS_COMMITMENT]));

        // emit LogGas("Read and decommit composition", gasleft());

        address oodsAddress = oodsContractAddress;
        uint256 friQueue = getPtr(ctx, MM_FRI_QUEUE);
        uint256 returnDataSize = MAX_N_QUERIES * 0x60;
        assembly {
            // Call the OODS contract.
            if iszero(staticcall(not(0), oodsAddress, ctx,
                                 /*sizeof(ctx)*/ mul(add(mload(ctx), 1), 0x20),
                                 friQueue, returnDataSize)) {
              returndatacopy(0, 0, returndatasize)
              revert(0, returndatasize)
            }
        }
        // emit LogGas("OODS virtual oracle", gasleft());
    }

    /*
      Reads the last FRI layer (i.e. the polynomial's coefficients) from the channel.
      This differs from standard reading of channel field elements in several ways:
      -- The digest is updated by hashing it once with all coefficients simultaneously, rather than
         iteratively one by one.
      -- The coefficients are kept in Montgomery form, as is the case throughout the FRI
         computation.
      -- The coefficients are not actually read and copied elsewhere, but rather only a pointer to
         their location in the channel is stored.
    */
    function readLastFriLayer(uint256[] memory ctx)
        internal pure
    {
        uint256 lmmChannel = MM_CHANNEL;
        uint256 friLastLayerDegBound = ctx[MM_FRI_LAST_LAYER_DEG_BOUND];
        uint256 lastLayerPtr;
        uint256 badInput = 0;

        assembly {
            let primeMinusOne := 0x30000003000000010000000000000000
            let channelPtr := add(add(ctx, 0x20), mul(lmmChannel, 0x20))
            lastLayerPtr := mload(channelPtr)

            // Make sure all the values are valid field elements.
            let length := mul(friLastLayerDegBound, 0x20)
            let lastLayerEnd := add(lastLayerPtr, length)
            for { let coefsPtr := lastLayerPtr } lt(coefsPtr, lastLayerEnd)
                { coefsPtr := add(coefsPtr, 0x20) } {
                badInput := or(badInput, gt(mload(coefsPtr), primeMinusOne))
            }

            // Copy the digest to the proof area
            // (store it before the coefficients - this is done because
            // keccak256 needs all data to be consecutive),
            // then hash and place back in digestPtr.
            let newDigestPtr := sub(lastLayerPtr, 0x20)
            let digestPtr := add(channelPtr, 0x20)
            // Overwriting the proof to minimize copying of data.
            mstore(newDigestPtr, mload(digestPtr))

            // prng.digest := keccak256(digest||lastLayerCoefs).
            mstore(digestPtr, keccak256(newDigestPtr, add(length, 0x20)))
            // prng.counter := 0.
            mstore(add(channelPtr, 0x40), 0)

            // Note: proof pointer is not incremented until this point.
            mstore(channelPtr, lastLayerEnd)
        }

        require(badInput == 0, "Invalid field element.");
        ctx[MM_FRI_LAST_LAYER_PTR] = lastLayerPtr;
    }

    function verifyProof(
        uint256[] memory proofParams, uint256[] memory proof, uint256[] memory publicInput)
        internal {
        // emit LogGas("Transmission", gasleft());
        uint256[] memory ctx = initVerifierParams(publicInput, proofParams);
        uint256 channelPtr = getChannelPtr(ctx);

        initChannel(channelPtr,  getProofPtr(proof), getPublicInputHash(publicInput));
        // emit LogGas("Initializations", gasleft());

        // Read trace commitment.
        ctx[MM_TRACE_COMMITMENT] = uint256(readHash(channelPtr, true));
        VerifierChannel.sendFieldElements(
            channelPtr, getNCoefficients(), getPtr(ctx, getMmCoefficients()));
        // emit LogGas("Generate coefficients", gasleft());

        ctx[MM_OODS_COMMITMENT] = uint256(readHash(channelPtr, true));

        // Send Out of Domain Sampling point.
        VerifierChannel.sendFieldElements(channelPtr, 1, getPtr(ctx, MM_OODS_POINT));

        // Read the answers to the Out of Domain Sampling.
        uint256 lmmOodsValues = getMmOodsValues();
        for (uint256 i = lmmOodsValues; i < lmmOodsValues+getNOodsValues(); i++) {
            ctx[i] = VerifierChannel.readFieldElement(channelPtr, true);
        }
        // emit LogGas("Read OODS commitments", gasleft());
        oodsConsistencyCheck(ctx);
        // emit LogGas("OODS consistency check", gasleft());
        VerifierChannel.sendFieldElements(
            channelPtr, getNOodsCoefficients(), getPtr(ctx, getMmOodsCoefficients()));
        // emit LogGas("Generate OODS coefficients", gasleft());
        ctx[MM_FRI_COMMITMENTS] = uint256(VerifierChannel.readHash(channelPtr, true));

        uint256 nFriSteps = getFriSteps(ctx).length;
        uint256 fri_evalPointPtr = getPtr(ctx, MM_FRI_EVAL_POINTS);
        for (uint256 i = 1; i < nFriSteps - 1; i++) {
            VerifierChannel.sendFieldElements(channelPtr, 1, fri_evalPointPtr + i * 0x20);
            ctx[MM_FRI_COMMITMENTS + i] = uint256(VerifierChannel.readHash(channelPtr, true));
        }

        // Send last random FRI evaluation point.
        VerifierChannel.sendFieldElements(
            channelPtr, 1, getPtr(ctx, MM_FRI_EVAL_POINTS + nFriSteps - 1));

        // Read FRI last layer commitment.
        readLastFriLayer(ctx);

        // Generate queries.
        // emit LogGas("Read FRI commitments", gasleft());
        VerifierChannel.verifyProofOfWork(channelPtr, ctx[MM_PROOF_OF_WORK_BITS]);
        ctx[MM_N_UNIQUE_QUERIES] = VerifierChannel.sendRandomQueries(
            channelPtr, ctx[MM_N_UNIQUE_QUERIES], ctx[MM_EVAL_DOMAIN_SIZE] - 1,
            getPtr(ctx, MM_FRI_QUEUE), 0x60);
        // emit LogGas("Send queries", gasleft());

        computeFirstFriLayer(ctx);

        friVerifyLayers(ctx);
    }
}
