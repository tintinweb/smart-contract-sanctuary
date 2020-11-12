pragma solidity ^0.5.2;

import "./MerkleVerifier.sol";
import "./PrimeFieldElement6.sol";

/*
  The main component of FRI is the FRI step which takes
  the i-th layer evaluations on a coset c*<g> and produces a single evaluation in layer i+1.

  To this end we have a friCtx that holds the following data:
  evaluations:    holds the evaluations on the coset we are currently working on.
  group:          holds the group <g> in bit reversed order.
  halfInvGroup:   holds the group <g^-1>/<-1> in bit reversed order.
                  (We only need half of the inverse group)

  Note that due to the bit reversed order, a prefix of size 2^k of either group
  or halfInvGroup has the same structure (but for a smaller group).
*/
contract FriLayer is MerkleVerifier, PrimeFieldElement6 {
    event LogGas(string name, uint256 val);

    uint256 constant internal FRI_MAX_FRI_STEP = 4;
    uint256 constant internal MAX_COSET_SIZE = 2**FRI_MAX_FRI_STEP;
    // Generator of the group of size MAX_COSET_SIZE: GENERATOR_VAL**((PRIME - 1)/MAX_COSET_SIZE).
    uint256 constant internal FRI_GROUP_GEN =
    0x1388a7fd3b4b9599dc4b0691d6a5fcba;

    uint256 constant internal FRI_GROUP_SIZE = 0x20 * MAX_COSET_SIZE;
    uint256 constant internal FRI_CTX_TO_COSET_EVALUATIONS_OFFSET = 0;
    uint256 constant internal FRI_CTX_TO_FRI_GROUP_OFFSET = FRI_GROUP_SIZE;
    uint256 constant internal FRI_CTX_TO_FRI_HALF_INV_GROUP_OFFSET =
    FRI_CTX_TO_FRI_GROUP_OFFSET + FRI_GROUP_SIZE;

    uint256 constant internal FRI_CTX_SIZE =
    FRI_CTX_TO_FRI_HALF_INV_GROUP_OFFSET + (FRI_GROUP_SIZE / 2);

    function nextLayerElementFromTwoPreviousLayerElements(
        uint256 fX, uint256 fMinusX, uint256 evalPoint, uint256 xInv)
        internal pure
        returns (uint256 res)
    {
        // Folding formula:
        // f(x)  = g(x^2) + xh(x^2)
        // f(-x) = g((-x)^2) - xh((-x)^2) = g(x^2) - xh(x^2)
        // =>
        // 2g(x^2) = f(x) + f(-x)
        // 2h(x^2) = (f(x) - f(-x))/x
        // => The 2*interpolation at evalPoint is:
        // 2*(g(x^2) + evalPoint*h(x^2)) = f(x) + f(-x) + evalPoint*(f(x) - f(-x))*xInv.
        //
        // Note that multiplying by 2 doesn't affect the degree,
        // so we can just agree to do that on both the prover and verifier.
        assembly {
            // PRIME is PrimeFieldElement6.K_MODULUS.
            let PRIME := 0x30000003000000010000000000000001
            // Note that whenever we call add(), the result is always less than 2*PRIME,
            // so there are no overflows.
            res := addmod(add(fX, fMinusX),
                   mulmod(mulmod(evalPoint, xInv, PRIME),
                   add(fX, /*-fMinusX*/sub(PRIME, fMinusX)), PRIME), PRIME)
        }
    }

    /*
      Reads 4 elements, and applies 2 + 1 FRI transformations to obtain a single element.

      FRI layer n:                              f0 f1  f2 f3
      -----------------------------------------  \ / -- \ / -----------
      FRI layer n+1:                              f0    f2
      -------------------------------------------- \ ---/ -------------
      FRI layer n+2:                                 f0

      The basic FRI transformation is described in nextLayerElementFromTwoPreviousLayerElements().
    */
    function do2FriSteps(
        uint256 friHalfInvGroupPtr, uint256 evaluationsOnCosetPtr, uint256 cosetOffset_,
        uint256 friEvalPoint)
    internal pure returns (uint256 nextLayerValue, uint256 nextXInv) {
        assembly {
            let PRIME := 0x30000003000000010000000000000001
            let friEvalPointDivByX := mulmod(friEvalPoint, cosetOffset_, PRIME)

            let f0 := mload(evaluationsOnCosetPtr)
            {
                let f1 := mload(add(evaluationsOnCosetPtr, 0x20))

                // f0 < 3P ( = 1 + 1 + 1).
                f0 := add(add(f0, f1),
                             mulmod(friEvalPointDivByX,
                                    add(f0, /*-fMinusX*/sub(PRIME, f1)),
                                    PRIME))
            }

            let f2 := mload(add(evaluationsOnCosetPtr, 0x40))
            {
                let f3 := mload(add(evaluationsOnCosetPtr, 0x60))
                f2 := addmod(add(f2, f3),
                             mulmod(add(f2, /*-fMinusX*/sub(PRIME, f3)),
                                    mulmod(mload(add(friHalfInvGroupPtr, 0x20)),
                                           friEvalPointDivByX,
                                           PRIME),
                                    PRIME),
                             PRIME)
            }

            {
                let newXInv := mulmod(cosetOffset_, cosetOffset_, PRIME)
                nextXInv := mulmod(newXInv, newXInv, PRIME)
            }

            // f0 + f2 < 4P ( = 3 + 1).
            nextLayerValue := addmod(add(f0, f2),
                          mulmod(mulmod(friEvalPointDivByX, friEvalPointDivByX, PRIME),
                                 add(f0, /*-fMinusX*/sub(PRIME, f2)),
                                 PRIME),
                          PRIME)
        }
    }

    /*
      Reads 8 elements, and applies 4 + 2 + 1 FRI transformation to obtain a single element.

      See do2FriSteps for more detailed explanation.
    */
    function do3FriSteps(
        uint256 friHalfInvGroupPtr, uint256 evaluationsOnCosetPtr, uint256 cosetOffset_,
        uint256 friEvalPoint)
    internal pure returns (uint256 nextLayerValue, uint256 nextXInv) {
        assembly {
            let PRIME := 0x30000003000000010000000000000001
            let MPRIME := 0x300000030000000100000000000000010
            let f0 := mload(evaluationsOnCosetPtr)

            let friEvalPointDivByX := mulmod(friEvalPoint, cosetOffset_, PRIME)
            let friEvalPointDivByXSquared := mulmod(friEvalPointDivByX, friEvalPointDivByX, PRIME)
            let imaginaryUnit := mload(add(friHalfInvGroupPtr, 0x20))

            {
                let f1 := mload(add(evaluationsOnCosetPtr, 0x20))

                // f0 < 3P ( = 1 + 1 + 1).
                f0 := add(add(f0, f1),
                          mulmod(friEvalPointDivByX,
                                 add(f0, /*-fMinusX*/sub(PRIME, f1)),
                                 PRIME))
            }
            {
                let f2 := mload(add(evaluationsOnCosetPtr, 0x40))
                {
                    let f3 := mload(add(evaluationsOnCosetPtr, 0x60))

                    // f2 < 3P ( = 1 + 1 + 1).
                    f2 := add(add(f2, f3),
                              mulmod(add(f2, /*-fMinusX*/sub(PRIME, f3)),
                                     mulmod(friEvalPointDivByX, imaginaryUnit, PRIME),
                                     PRIME))
                }

                // f0 < 7P ( = 3 + 3 + 1).
                f0 := add(add(f0, f2),
                          mulmod(friEvalPointDivByXSquared,
                                 add(f0, /*-fMinusX*/sub(MPRIME, f2)),
                                 PRIME))
            }
            {
                let f4 := mload(add(evaluationsOnCosetPtr, 0x80))
                {
                    let friEvalPointDivByX2 := mulmod(friEvalPointDivByX,
                                                    mload(add(friHalfInvGroupPtr, 0x40)), PRIME)
                    {
                        let f5 := mload(add(evaluationsOnCosetPtr, 0xa0))

                        // f4 < 3P ( = 1 + 1 + 1).
                        f4 := add(add(f4, f5),
                                  mulmod(friEvalPointDivByX2,
                                         add(f4, /*-fMinusX*/sub(PRIME, f5)),
                                         PRIME))
                    }

                    let f6 := mload(add(evaluationsOnCosetPtr, 0xc0))
                    {
                        let f7 := mload(add(evaluationsOnCosetPtr, 0xe0))

                        // f6 < 3P ( = 1 + 1 + 1).
                        f6 := add(add(f6, f7),
                                  mulmod(add(f6, /*-fMinusX*/sub(PRIME, f7)),
                                         // friEvalPointDivByX2 * imaginaryUnit ==
                                         // friEvalPointDivByX * mload(add(friHalfInvGroupPtr, 0x60)).
                                         mulmod(friEvalPointDivByX2, imaginaryUnit, PRIME),
                                         PRIME))
                    }

                    // f4 < 7P ( = 3 + 3 + 1).
                    f4 := add(add(f4, f6),
                              mulmod(mulmod(friEvalPointDivByX2, friEvalPointDivByX2, PRIME),
                                     add(f4, /*-fMinusX*/sub(MPRIME, f6)),
                                     PRIME))
                }

                // f0, f4 < 7P -> f0 + f4 < 14P && 9P < f0 + (MPRIME - f4) < 23P.
                nextLayerValue :=
                   addmod(add(f0, f4),
                          mulmod(mulmod(friEvalPointDivByXSquared, friEvalPointDivByXSquared, PRIME),
                                 add(f0, /*-fMinusX*/sub(MPRIME, f4)),
                                 PRIME),
                          PRIME)
            }

            {
                let xInv2 := mulmod(cosetOffset_, cosetOffset_, PRIME)
                let xInv4 := mulmod(xInv2, xInv2, PRIME)
                nextXInv := mulmod(xInv4, xInv4, PRIME)
            }


        }
    }

    /*
      This function reads 16 elements, and applies 8 + 4 + 2 + 1 fri transformation
      to obtain a single element.

      See do2FriSteps for more detailed explanation.
    */
    function do4FriSteps(
        uint256 friHalfInvGroupPtr, uint256 evaluationsOnCosetPtr, uint256 cosetOffset_,
        uint256 friEvalPoint)
    internal pure returns (uint256 nextLayerValue, uint256 nextXInv) {
        assembly {
            let friEvalPointDivByXTessed
            let PRIME := 0x30000003000000010000000000000001
            let MPRIME := 0x300000030000000100000000000000010
            let f0 := mload(evaluationsOnCosetPtr)

            let friEvalPointDivByX := mulmod(friEvalPoint, cosetOffset_, PRIME)
            let imaginaryUnit := mload(add(friHalfInvGroupPtr, 0x20))

            {
                let f1 := mload(add(evaluationsOnCosetPtr, 0x20))

                // f0 < 3P ( = 1 + 1 + 1).
                f0 := add(add(f0, f1),
                          mulmod(friEvalPointDivByX,
                                 add(f0, /*-fMinusX*/sub(PRIME, f1)),
                                 PRIME))
            }
            {
                let f2 := mload(add(evaluationsOnCosetPtr, 0x40))
                {
                    let f3 := mload(add(evaluationsOnCosetPtr, 0x60))

                    // f2 < 3P ( = 1 + 1 + 1).
                    f2 := add(add(f2, f3),
                                mulmod(add(f2, /*-fMinusX*/sub(PRIME, f3)),
                                       mulmod(friEvalPointDivByX, imaginaryUnit, PRIME),
                                       PRIME))
                }
                {
                    let friEvalPointDivByXSquared := mulmod(friEvalPointDivByX, friEvalPointDivByX, PRIME)
                    friEvalPointDivByXTessed := mulmod(friEvalPointDivByXSquared, friEvalPointDivByXSquared, PRIME)

                    // f0 < 7P ( = 3 + 3 + 1).
                    f0 := add(add(f0, f2),
                              mulmod(friEvalPointDivByXSquared,
                                     add(f0, /*-fMinusX*/sub(MPRIME, f2)),
                                     PRIME))
                }
            }
            {
                let f4 := mload(add(evaluationsOnCosetPtr, 0x80))
                {
                    let friEvalPointDivByX2 := mulmod(friEvalPointDivByX,
                                                      mload(add(friHalfInvGroupPtr, 0x40)), PRIME)
                    {
                        let f5 := mload(add(evaluationsOnCosetPtr, 0xa0))

                        // f4 < 3P ( = 1 + 1 + 1).
                        f4 := add(add(f4, f5),
                                  mulmod(friEvalPointDivByX2,
                                         add(f4, /*-fMinusX*/sub(PRIME, f5)),
                                         PRIME))
                    }

                    let f6 := mload(add(evaluationsOnCosetPtr, 0xc0))
                    {
                        let f7 := mload(add(evaluationsOnCosetPtr, 0xe0))

                        // f6 < 3P ( = 1 + 1 + 1).
                        f6 := add(add(f6, f7),
                                  mulmod(add(f6, /*-fMinusX*/sub(PRIME, f7)),
                                         // friEvalPointDivByX2 * imaginaryUnit ==
                                         // friEvalPointDivByX * mload(add(friHalfInvGroupPtr, 0x60)).
                                         mulmod(friEvalPointDivByX2, imaginaryUnit, PRIME),
                                         PRIME))
                    }

                    // f4 < 7P ( = 3 + 3 + 1).
                    f4 := add(add(f4, f6),
                              mulmod(mulmod(friEvalPointDivByX2, friEvalPointDivByX2, PRIME),
                                     add(f4, /*-fMinusX*/sub(MPRIME, f6)),
                                     PRIME))
                }

                // f0 < 15P ( = 7 + 7 + 1).
                f0 := add(add(f0, f4),
                          mulmod(friEvalPointDivByXTessed,
                                 add(f0, /*-fMinusX*/sub(MPRIME, f4)),
                                 PRIME))
            }
            {
                let f8 := mload(add(evaluationsOnCosetPtr, 0x100))
                {
                    let friEvalPointDivByX4 := mulmod(friEvalPointDivByX,
                                                      mload(add(friHalfInvGroupPtr, 0x80)), PRIME)
                    {
                        let f9 := mload(add(evaluationsOnCosetPtr, 0x120))

                        // f8 < 3P ( = 1 + 1 + 1).
                        f8 := add(add(f8, f9),
                                  mulmod(friEvalPointDivByX4,
                                         add(f8, /*-fMinusX*/sub(PRIME, f9)),
                                         PRIME))
                    }

                    let f10 := mload(add(evaluationsOnCosetPtr, 0x140))
                    {
                        let f11 := mload(add(evaluationsOnCosetPtr, 0x160))
                        // f10 < 3P ( = 1 + 1 + 1).
                        f10 := add(add(f10, f11),
                                   mulmod(add(f10, /*-fMinusX*/sub(PRIME, f11)),
                                          // friEvalPointDivByX4 * imaginaryUnit ==
                                          // friEvalPointDivByX * mload(add(friHalfInvGroupPtr, 0xa0)).
                                          mulmod(friEvalPointDivByX4, imaginaryUnit, PRIME),
                                          PRIME))
                    }

                    // f8 < 7P ( = 3 + 3 + 1).
                    f8 := add(add(f8, f10),
                              mulmod(mulmod(friEvalPointDivByX4, friEvalPointDivByX4, PRIME),
                                     add(f8, /*-fMinusX*/sub(MPRIME, f10)),
                                     PRIME))
                }
                {
                    let f12 := mload(add(evaluationsOnCosetPtr, 0x180))
                    {
                        let friEvalPointDivByX6 := mulmod(friEvalPointDivByX,
                                                          mload(add(friHalfInvGroupPtr, 0xc0)), PRIME)
                        {
                            let f13 := mload(add(evaluationsOnCosetPtr, 0x1a0))

                            // f12 < 3P ( = 1 + 1 + 1).
                            f12 := add(add(f12, f13),
                                       mulmod(friEvalPointDivByX6,
                                              add(f12, /*-fMinusX*/sub(PRIME, f13)),
                                              PRIME))
                        }

                        let f14 := mload(add(evaluationsOnCosetPtr, 0x1c0))
                        {
                            let f15 := mload(add(evaluationsOnCosetPtr, 0x1e0))

                            // f14 < 3P ( = 1 + 1 + 1).
                            f14 := add(add(f14, f15),
                                       mulmod(add(f14, /*-fMinusX*/sub(PRIME, f15)),
                                              // friEvalPointDivByX6 * imaginaryUnit ==
                                              // friEvalPointDivByX * mload(add(friHalfInvGroupPtr, 0xe0)).
                                              mulmod(friEvalPointDivByX6, imaginaryUnit, PRIME),
                                              PRIME))
                        }

                        // f12 < 7P ( = 3 + 3 + 1).
                        f12 := add(add(f12, f14),
                                   mulmod(mulmod(friEvalPointDivByX6, friEvalPointDivByX6, PRIME),
                                          add(f12, /*-fMinusX*/sub(MPRIME, f14)),
                                          PRIME))
                    }

                    // f8 < 15P ( = 7 + 7 + 1).
                    f8 := add(add(f8, f12),
                              mulmod(mulmod(friEvalPointDivByXTessed, imaginaryUnit, PRIME),
                                     add(f8, /*-fMinusX*/sub(MPRIME, f12)),
                                     PRIME))
                }

                // f0, f8 < 15P -> f0 + f8 < 30P && 16P < f0 + (MPRIME - f8) < 31P.
                nextLayerValue :=
                    addmod(add(f0, f8),
                           mulmod(mulmod(friEvalPointDivByXTessed, friEvalPointDivByXTessed, PRIME),
                                  add(f0, /*-fMinusX*/sub(MPRIME, f8)),
                                  PRIME),
                           PRIME)
            }

            {
                let xInv2 := mulmod(cosetOffset_, cosetOffset_, PRIME)
                let xInv4 := mulmod(xInv2, xInv2, PRIME)
                let xInv8 := mulmod(xInv4, xInv4, PRIME)
                nextXInv := mulmod(xInv8, xInv8, PRIME)
            }
        }
    }

    /*
      Gathers the "cosetSize" elements that belong to the same coset
      as the item at the top of the FRI queue and stores them in ctx[MM_FRI_STEP_VALUES:].

      Returns
        friQueueHead - friQueueHead_ + 0x60  * (# elements that were taken from the queue).
        cosetIdx - the start index of the coset that was gathered.
        cosetOffset_ - the xInv field element that corresponds to cosetIdx.
    */
    function gatherCosetInputs(
        uint256 channelPtr, uint256 friCtx, uint256 friQueueHead_, uint256 cosetSize)
        internal pure returns (uint256 friQueueHead, uint256 cosetIdx, uint256 cosetOffset_) {

        uint256 evaluationsOnCosetPtr = friCtx + FRI_CTX_TO_COSET_EVALUATIONS_OFFSET;
        uint256 friGroupPtr = friCtx + FRI_CTX_TO_FRI_GROUP_OFFSET;

        friQueueHead = friQueueHead_;
        assembly {
            let queueItemIdx := mload(friQueueHead)
            // The coset index is represented by the most significant bits of the queue item index.
            cosetIdx := and(queueItemIdx, not(sub(cosetSize, 1)))
            let nextCosetIdx := add(cosetIdx, cosetSize)
            let PRIME := 0x30000003000000010000000000000001

            // Get the algebraic coset offset:
            // I.e. given c*g^(-k) compute c, where
            //      g is the generator of the coset group.
            //      k is bitReverse(offsetWithinCoset, log2(cosetSize)).
            //
            // To do this we multiply the algebraic coset offset at the top of the queue (c*g^(-k))
            // by the group element that corresponds to the index inside the coset (g^k).
            cosetOffset_ := mulmod(
                /*(c*g^(-k)*/ mload(add(friQueueHead, 0x40)),
                /*(g^k)*/     mload(add(friGroupPtr,
                                        mul(/*offsetWithinCoset*/sub(queueItemIdx, cosetIdx),
                                            0x20))),
                PRIME)

            let proofPtr := mload(channelPtr)

            for { let index := cosetIdx } lt(index, nextCosetIdx) { index := add(index, 1) } {
                // Inline channel operation:
                // Assume we are going to read the next element from the proof.
                // If this is not the case add(proofPtr, 0x20) will be reverted.
                let fieldElementPtr := proofPtr
                proofPtr := add(proofPtr, 0x20)

                // Load the next index from the queue and check if it is our sibling.
                if eq(index, queueItemIdx) {
                    // Take element from the queue rather than from the proof
                    // and convert it back to Montgomery form for Merkle verification.
                    fieldElementPtr := add(friQueueHead, 0x20)

                    // Revert the read from proof.
                    proofPtr := sub(proofPtr, 0x20)

                    // Reading the next index here is safe due to the
                    // delimiter after the queries.
                    friQueueHead := add(friQueueHead, 0x60)
                    queueItemIdx := mload(friQueueHead)
                }

                // Note that we apply the modulo operation to convert the field elements we read
                // from the proof to canonical representation (in the range [0, PRIME - 1]).
                mstore(evaluationsOnCosetPtr, mod(mload(fieldElementPtr), PRIME))
                evaluationsOnCosetPtr := add(evaluationsOnCosetPtr, 0x20)
            }

            mstore(channelPtr, proofPtr)
        }
    }

    /*
      Returns the bit reversal of num assuming it has the given number of bits.
      For example, if we have numberOfBits = 6 and num = (0b)1101 == (0b)001101,
      the function will return (0b)101100.
    */
    function bitReverse(uint256 num, uint256 numberOfBits)
    internal pure
        returns(uint256 numReversed)
    {
        assert((numberOfBits == 256) || (num < 2 ** numberOfBits));
        uint256 n = num;
        uint256 r = 0;
        for (uint256 k = 0; k < numberOfBits; k++) {
            r = (r * 2) | (n % 2);
            n = n / 2;
        }
        return r;
    }

    /*
      Initializes the FRI group and half inv group in the FRI context.
    */
    function initFriGroups(uint256 friCtx) internal {
        uint256 friGroupPtr = friCtx + FRI_CTX_TO_FRI_GROUP_OFFSET;
        uint256 friHalfInvGroupPtr = friCtx + FRI_CTX_TO_FRI_HALF_INV_GROUP_OFFSET;

        // FRI_GROUP_GEN is the coset generator.
        // Raising it to the (MAX_COSET_SIZE - 1) power gives us the inverse.
        uint256 genFriGroup = FRI_GROUP_GEN;

        uint256 genFriGroupInv = fpow(genFriGroup, (MAX_COSET_SIZE - 1));

        uint256 lastVal = ONE_VAL;
        uint256 lastValInv = ONE_VAL;
        uint256 prime = PrimeFieldElement6.K_MODULUS;
        assembly {
            // ctx[mmHalfFriInvGroup + 0] = ONE_VAL;
            mstore(friHalfInvGroupPtr, lastValInv)
            // ctx[mmFriGroup + 0] = ONE_VAL;
            mstore(friGroupPtr, lastVal)
            // ctx[mmFriGroup + 1] = fsub(0, ONE_VAL);
            mstore(add(friGroupPtr, 0x20), sub(prime, lastVal))
        }

        // To compute [1, -1 (== g^n/2), g^n/4, -g^n/4, ...]
        // we compute half the elements and derive the rest using negation.
        uint256 halfCosetSize = MAX_COSET_SIZE / 2;
        for (uint256 i = 1; i < halfCosetSize; i++) {
            lastVal = fmul(lastVal, genFriGroup);
            lastValInv = fmul(lastValInv, genFriGroupInv);
            uint256 idx = bitReverse(i, FRI_MAX_FRI_STEP-1);

            assembly {
                // ctx[mmHalfFriInvGroup + idx] = lastValInv;
                mstore(add(friHalfInvGroupPtr, mul(idx, 0x20)), lastValInv)
                // ctx[mmFriGroup + 2*idx] = lastVal;
                mstore(add(friGroupPtr, mul(idx, 0x40)), lastVal)
                // ctx[mmFriGroup + 2*idx + 1] = fsub(0, lastVal);
                mstore(add(friGroupPtr, add(mul(idx, 0x40), 0x20)), sub(prime, lastVal))
            }
        }
    }

    /*
      Operates on the coset of size friFoldedCosetSize that start at index.

      It produces 3 outputs:
        1. The field elements that result from doing FRI reductions on the coset.
        2. The pointInv elements for the location that corresponds to the first output.
        3. The root of a Merkle tree for the input layer.

      The input is read either from the queue or from the proof depending on data availability.
      Since the function reads from the queue it returns an updated head pointer.
    */
    function doFriSteps(
        uint256 friCtx, uint256 friQueueTail, uint256 cosetOffset_, uint256 friEvalPoint,
        uint256 friCosetSize, uint256 index, uint256 merkleQueuePtr)
        internal pure {
        uint256 friValue;

        uint256 evaluationsOnCosetPtr = friCtx + FRI_CTX_TO_COSET_EVALUATIONS_OFFSET;
        uint256 friHalfInvGroupPtr = friCtx + FRI_CTX_TO_FRI_HALF_INV_GROUP_OFFSET;

        // Compare to expected FRI step sizes in order of likelihood, step size 3 being most common.
        if (friCosetSize == 8) {
            (friValue, cosetOffset_) = do3FriSteps(
                friHalfInvGroupPtr, evaluationsOnCosetPtr, cosetOffset_, friEvalPoint);
        } else if (friCosetSize == 4) {
            (friValue, cosetOffset_) = do2FriSteps(
                friHalfInvGroupPtr, evaluationsOnCosetPtr, cosetOffset_, friEvalPoint);
        } else if (friCosetSize == 16) {
            (friValue, cosetOffset_) = do4FriSteps(
                friHalfInvGroupPtr, evaluationsOnCosetPtr, cosetOffset_, friEvalPoint);
        } else {
            require(false, "Only step sizes of 2, 3 or 4 are supported.");
        }

        uint256 lhashMask = getHashMask();
        assembly {
            let indexInNextStep := div(index, friCosetSize)
            mstore(merkleQueuePtr, indexInNextStep)
            mstore(add(merkleQueuePtr, 0x20), and(lhashMask, keccak256(evaluationsOnCosetPtr,
                                                                          mul(0x20,friCosetSize))))

            mstore(friQueueTail, indexInNextStep)
            mstore(add(friQueueTail, 0x20), friValue)
            mstore(add(friQueueTail, 0x40), cosetOffset_)
        }
    }

    /*
      Computes the FRI step with eta = log2(friCosetSize) for all the live queries.
      The input and output data is given in array of triplets:
          (query index, FRI value, FRI inversed point)
      in the address friQueuePtr (which is &ctx[mmFriQueue:]).

      The function returns the number of live queries remaining after computing the FRI step.

      The number of live queries decreases whenever multiple query points in the same
      coset are reduced to a single query in the next FRI layer.

      As the function computes the next layer it also collects that data from
      the previous layer for Merkle verification.
    */
    function computeNextLayer(
        uint256 channelPtr, uint256 friQueuePtr, uint256 merkleQueuePtr, uint256 nQueries,
        uint256 friEvalPoint, uint256 friCosetSize, uint256 friCtx)
        internal pure returns (uint256 nLiveQueries) {
        uint256 merkleQueueTail = merkleQueuePtr;
        uint256 friQueueHead = friQueuePtr;
        uint256 friQueueTail = friQueuePtr;
        uint256 friQueueEnd = friQueueHead + (0x60 * nQueries);

        do {
            uint256 cosetOffset;
            uint256 index;
            (friQueueHead, index, cosetOffset) = gatherCosetInputs(
                channelPtr, friCtx, friQueueHead, friCosetSize);

            doFriSteps(
                friCtx, friQueueTail, cosetOffset, friEvalPoint, friCosetSize, index,
                merkleQueueTail);

            merkleQueueTail += 0x40;
            friQueueTail += 0x60;
        } while (friQueueHead < friQueueEnd);
        return (friQueueTail - friQueuePtr) / 0x60;
    }

}
