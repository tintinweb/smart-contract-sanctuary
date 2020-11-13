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
// ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------
pragma solidity ^0.5.2;

import "MemoryMap.sol";
import "StarkParameters.sol";

contract CpuOods is MemoryMap, StarkParameters {
    // For each query point we want to invert (2 + N_ROWS_IN_MASK) items:
    //  The query point itself (x).
    //  The denominator for the constraint polynomial (x-z^constraintDegree)
    //  [(x-(g^rowNumber)z) for rowNumber in mask].
    uint256 constant internal BATCH_INVERSE_CHUNK = (2 + N_ROWS_IN_MASK);
    uint256 constant internal BATCH_INVERSE_SIZE = MAX_N_QUERIES * BATCH_INVERSE_CHUNK;

    /*
      Builds and sums boundary constraints that check that the prover provided the proper evaluations
      out of domain evaluations for the trace and composition columns.

      The inputs to this function are:
          The verifier context.

      The boundary constraints for the trace enforce claims of the form f(g^k*z) = c by
      requiring the quotient (f(x) - c)/(x-g^k*z) to be a low degree polynomial.

      The boundary constraints for the composition enforce claims of the form h(z^d) = c by
      requiring the quotient (h(x) - c)/(x-z^d) to be a low degree polynomial.
      Where:
            f is a trace column.
            h is a composition column.
            z is the out of domain sampling point.
            g is the trace generator
            k is the offset in the mask.
            d is the degree of the composition polynomial.
            c is the evaluation sent by the prover.
    */
    function() external {
        // This funciton assumes that the calldata contains the context as defined in MemoryMap.sol.
        // Note that ctx is a variable size array so the first uint256 cell contrains it's length.
        uint256[] memory ctx;
        assembly {
            let ctxSize := mul(add(calldataload(0), 1), 0x20)
            ctx := mload(0x40)
            mstore(0x40, add(ctx, ctxSize))
            calldatacopy(ctx, 0, ctxSize)
        }
        uint256[] memory batchInverseArray = new uint256[](2 * BATCH_INVERSE_SIZE);

        oodsPrepareInverses(ctx, batchInverseArray);

        uint256 kMontgomeryRInv_ = PrimeFieldElement0.K_MONTGOMERY_R_INV;

        assembly {
            let PRIME := 0x800000000000011000000000000000000000000000000000000000000000001
            let kMontgomeryRInv := kMontgomeryRInv_
            let context := ctx
            let friQueue := /*friQueue*/ add(context, 0xdc0)
            let friQueueEnd := add(friQueue,  mul(/*n_unique_queries*/ mload(add(context, 0x140)), 0x60))
            let traceQueryResponses := /*traceQueryQesponses*/ add(context, 0x8340)

            let compositionQueryResponses := /*composition_query_responses*/ add(context, 0x11940)

            // Set denominatorsPtr to point to the batchInverseOut array.
            // The content of batchInverseOut is described in oodsPrepareInverses.
            let denominatorsPtr := add(batchInverseArray, 0x20)

            for {} lt(friQueue, friQueueEnd) {friQueue := add(friQueue, 0x60)} {
                // res accumulates numbers modulo PRIME. Since 31*PRIME < 2**256, we may add up to
                // 31 numbers without fear of overflow, and use addmod modulo PRIME only every
                // 31 iterations, and once more at the very end.
                let res := 0

                // Trace constraints.

                // Mask items for column #0.
                {
                // Read the next element.
                let columnValue := mulmod(mload(traceQueryResponses), kMontgomeryRInv, PRIME)

                // res += c_0*(f_0(x) - f_0(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[0]*/ mload(add(context, 0x6d40)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[0]*/ mload(add(context, 0x5140)))),
                           PRIME))

                // res += c_1*(f_0(x) - f_0(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[1]*/ mload(add(context, 0x6d60)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[1]*/ mload(add(context, 0x5160)))),
                           PRIME))

                // res += c_2*(f_0(x) - f_0(g^4 * z)) / (x - g^4 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4 * z)^(-1)*/ mload(add(denominatorsPtr, 0x80)),
                                  /*oods_coefficients[2]*/ mload(add(context, 0x6d80)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[2]*/ mload(add(context, 0x5180)))),
                           PRIME))

                // res += c_3*(f_0(x) - f_0(g^8 * z)) / (x - g^8 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8 * z)^(-1)*/ mload(add(denominatorsPtr, 0x100)),
                                  /*oods_coefficients[3]*/ mload(add(context, 0x6da0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[3]*/ mload(add(context, 0x51a0)))),
                           PRIME))

                // res += c_4*(f_0(x) - f_0(g^12 * z)) / (x - g^12 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^12 * z)^(-1)*/ mload(add(denominatorsPtr, 0x180)),
                                  /*oods_coefficients[4]*/ mload(add(context, 0x6dc0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[4]*/ mload(add(context, 0x51c0)))),
                           PRIME))

                // res += c_5*(f_0(x) - f_0(g^28 * z)) / (x - g^28 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^28 * z)^(-1)*/ mload(add(denominatorsPtr, 0x2e0)),
                                  /*oods_coefficients[5]*/ mload(add(context, 0x6de0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[5]*/ mload(add(context, 0x51e0)))),
                           PRIME))

                // res += c_6*(f_0(x) - f_0(g^44 * z)) / (x - g^44 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^44 * z)^(-1)*/ mload(add(denominatorsPtr, 0x380)),
                                  /*oods_coefficients[6]*/ mload(add(context, 0x6e00)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[6]*/ mload(add(context, 0x5200)))),
                           PRIME))

                // res += c_7*(f_0(x) - f_0(g^60 * z)) / (x - g^60 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^60 * z)^(-1)*/ mload(add(denominatorsPtr, 0x3c0)),
                                  /*oods_coefficients[7]*/ mload(add(context, 0x6e20)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[7]*/ mload(add(context, 0x5220)))),
                           PRIME))

                // res += c_8*(f_0(x) - f_0(g^76 * z)) / (x - g^76 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^76 * z)^(-1)*/ mload(add(denominatorsPtr, 0x440)),
                                  /*oods_coefficients[8]*/ mload(add(context, 0x6e40)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[8]*/ mload(add(context, 0x5240)))),
                           PRIME))

                // res += c_9*(f_0(x) - f_0(g^92 * z)) / (x - g^92 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^92 * z)^(-1)*/ mload(add(denominatorsPtr, 0x4a0)),
                                  /*oods_coefficients[9]*/ mload(add(context, 0x6e60)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[9]*/ mload(add(context, 0x5260)))),
                           PRIME))

                // res += c_10*(f_0(x) - f_0(g^108 * z)) / (x - g^108 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^108 * z)^(-1)*/ mload(add(denominatorsPtr, 0x500)),
                                  /*oods_coefficients[10]*/ mload(add(context, 0x6e80)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[10]*/ mload(add(context, 0x5280)))),
                           PRIME))

                // res += c_11*(f_0(x) - f_0(g^124 * z)) / (x - g^124 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^124 * z)^(-1)*/ mload(add(denominatorsPtr, 0x520)),
                                  /*oods_coefficients[11]*/ mload(add(context, 0x6ea0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[11]*/ mload(add(context, 0x52a0)))),
                           PRIME))
                }

                // Mask items for column #1.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x20)), kMontgomeryRInv, PRIME)

                // res += c_12*(f_1(x) - f_1(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[12]*/ mload(add(context, 0x6ec0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[12]*/ mload(add(context, 0x52c0)))),
                           PRIME))

                // res += c_13*(f_1(x) - f_1(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[13]*/ mload(add(context, 0x6ee0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[13]*/ mload(add(context, 0x52e0)))),
                           PRIME))

                // res += c_14*(f_1(x) - f_1(g^2 * z)) / (x - g^2 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^2 * z)^(-1)*/ mload(add(denominatorsPtr, 0x40)),
                                  /*oods_coefficients[14]*/ mload(add(context, 0x6f00)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[14]*/ mload(add(context, 0x5300)))),
                           PRIME))

                // res += c_15*(f_1(x) - f_1(g^3 * z)) / (x - g^3 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^3 * z)^(-1)*/ mload(add(denominatorsPtr, 0x60)),
                                  /*oods_coefficients[15]*/ mload(add(context, 0x6f20)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[15]*/ mload(add(context, 0x5320)))),
                           PRIME))

                // res += c_16*(f_1(x) - f_1(g^4 * z)) / (x - g^4 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4 * z)^(-1)*/ mload(add(denominatorsPtr, 0x80)),
                                  /*oods_coefficients[16]*/ mload(add(context, 0x6f40)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[16]*/ mload(add(context, 0x5340)))),
                           PRIME))

                // res += c_17*(f_1(x) - f_1(g^5 * z)) / (x - g^5 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^5 * z)^(-1)*/ mload(add(denominatorsPtr, 0xa0)),
                                  /*oods_coefficients[17]*/ mload(add(context, 0x6f60)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[17]*/ mload(add(context, 0x5360)))),
                           PRIME))

                // res += c_18*(f_1(x) - f_1(g^6 * z)) / (x - g^6 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^6 * z)^(-1)*/ mload(add(denominatorsPtr, 0xc0)),
                                  /*oods_coefficients[18]*/ mload(add(context, 0x6f80)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[18]*/ mload(add(context, 0x5380)))),
                           PRIME))

                // res += c_19*(f_1(x) - f_1(g^7 * z)) / (x - g^7 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^7 * z)^(-1)*/ mload(add(denominatorsPtr, 0xe0)),
                                  /*oods_coefficients[19]*/ mload(add(context, 0x6fa0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[19]*/ mload(add(context, 0x53a0)))),
                           PRIME))

                // res += c_20*(f_1(x) - f_1(g^8 * z)) / (x - g^8 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8 * z)^(-1)*/ mload(add(denominatorsPtr, 0x100)),
                                  /*oods_coefficients[20]*/ mload(add(context, 0x6fc0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[20]*/ mload(add(context, 0x53c0)))),
                           PRIME))

                // res += c_21*(f_1(x) - f_1(g^9 * z)) / (x - g^9 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^9 * z)^(-1)*/ mload(add(denominatorsPtr, 0x120)),
                                  /*oods_coefficients[21]*/ mload(add(context, 0x6fe0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[21]*/ mload(add(context, 0x53e0)))),
                           PRIME))

                // res += c_22*(f_1(x) - f_1(g^10 * z)) / (x - g^10 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^10 * z)^(-1)*/ mload(add(denominatorsPtr, 0x140)),
                                  /*oods_coefficients[22]*/ mload(add(context, 0x7000)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[22]*/ mload(add(context, 0x5400)))),
                           PRIME))

                // res += c_23*(f_1(x) - f_1(g^11 * z)) / (x - g^11 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^11 * z)^(-1)*/ mload(add(denominatorsPtr, 0x160)),
                                  /*oods_coefficients[23]*/ mload(add(context, 0x7020)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[23]*/ mload(add(context, 0x5420)))),
                           PRIME))

                // res += c_24*(f_1(x) - f_1(g^12 * z)) / (x - g^12 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^12 * z)^(-1)*/ mload(add(denominatorsPtr, 0x180)),
                                  /*oods_coefficients[24]*/ mload(add(context, 0x7040)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[24]*/ mload(add(context, 0x5440)))),
                           PRIME))

                // res += c_25*(f_1(x) - f_1(g^13 * z)) / (x - g^13 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^13 * z)^(-1)*/ mload(add(denominatorsPtr, 0x1a0)),
                                  /*oods_coefficients[25]*/ mload(add(context, 0x7060)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[25]*/ mload(add(context, 0x5460)))),
                           PRIME))

                // res += c_26*(f_1(x) - f_1(g^14 * z)) / (x - g^14 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^14 * z)^(-1)*/ mload(add(denominatorsPtr, 0x1c0)),
                                  /*oods_coefficients[26]*/ mload(add(context, 0x7080)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[26]*/ mload(add(context, 0x5480)))),
                           PRIME))

                // res += c_27*(f_1(x) - f_1(g^15 * z)) / (x - g^15 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^15 * z)^(-1)*/ mload(add(denominatorsPtr, 0x1e0)),
                                  /*oods_coefficients[27]*/ mload(add(context, 0x70a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[27]*/ mload(add(context, 0x54a0)))),
                           PRIME))
                }

                // Mask items for column #2.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x40)), kMontgomeryRInv, PRIME)

                // res += c_28*(f_2(x) - f_2(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[28]*/ mload(add(context, 0x70c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[28]*/ mload(add(context, 0x54c0)))),
                           PRIME))

                // res += c_29*(f_2(x) - f_2(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[29]*/ mload(add(context, 0x70e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[29]*/ mload(add(context, 0x54e0)))),
                           PRIME))
                }

                // Mask items for column #3.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x60)), kMontgomeryRInv, PRIME)

                // res += c_30*(f_3(x) - f_3(z)) / (x - z).
                res := addmod(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[30]*/ mload(add(context, 0x7100)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[30]*/ mload(add(context, 0x5500)))),
                           PRIME),
                    PRIME)

                // res += c_31*(f_3(x) - f_3(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[31]*/ mload(add(context, 0x7120)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[31]*/ mload(add(context, 0x5520)))),
                           PRIME))

                // res += c_32*(f_3(x) - f_3(g^255 * z)) / (x - g^255 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^255 * z)^(-1)*/ mload(add(denominatorsPtr, 0x620)),
                                  /*oods_coefficients[32]*/ mload(add(context, 0x7140)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[32]*/ mload(add(context, 0x5540)))),
                           PRIME))

                // res += c_33*(f_3(x) - f_3(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[33]*/ mload(add(context, 0x7160)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[33]*/ mload(add(context, 0x5560)))),
                           PRIME))

                // res += c_34*(f_3(x) - f_3(g^511 * z)) / (x - g^511 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^511 * z)^(-1)*/ mload(add(denominatorsPtr, 0x740)),
                                  /*oods_coefficients[34]*/ mload(add(context, 0x7180)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[34]*/ mload(add(context, 0x5580)))),
                           PRIME))
                }

                // Mask items for column #4.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x80)), kMontgomeryRInv, PRIME)

                // res += c_35*(f_4(x) - f_4(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[35]*/ mload(add(context, 0x71a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[35]*/ mload(add(context, 0x55a0)))),
                           PRIME))

                // res += c_36*(f_4(x) - f_4(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[36]*/ mload(add(context, 0x71c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[36]*/ mload(add(context, 0x55c0)))),
                           PRIME))

                // res += c_37*(f_4(x) - f_4(g^255 * z)) / (x - g^255 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^255 * z)^(-1)*/ mload(add(denominatorsPtr, 0x620)),
                                  /*oods_coefficients[37]*/ mload(add(context, 0x71e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[37]*/ mload(add(context, 0x55e0)))),
                           PRIME))

                // res += c_38*(f_4(x) - f_4(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[38]*/ mload(add(context, 0x7200)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[38]*/ mload(add(context, 0x5600)))),
                           PRIME))
                }

                // Mask items for column #5.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0xa0)), kMontgomeryRInv, PRIME)

                // res += c_39*(f_5(x) - f_5(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[39]*/ mload(add(context, 0x7220)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[39]*/ mload(add(context, 0x5620)))),
                           PRIME))
                }

                // Mask items for column #6.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0xc0)), kMontgomeryRInv, PRIME)

                // res += c_40*(f_6(x) - f_6(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[40]*/ mload(add(context, 0x7240)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[40]*/ mload(add(context, 0x5640)))),
                           PRIME))

                // res += c_41*(f_6(x) - f_6(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[41]*/ mload(add(context, 0x7260)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[41]*/ mload(add(context, 0x5660)))),
                           PRIME))

                // res += c_42*(f_6(x) - f_6(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[42]*/ mload(add(context, 0x7280)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[42]*/ mload(add(context, 0x5680)))),
                           PRIME))
                }

                // Mask items for column #7.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0xe0)), kMontgomeryRInv, PRIME)

                // res += c_43*(f_7(x) - f_7(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[43]*/ mload(add(context, 0x72a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[43]*/ mload(add(context, 0x56a0)))),
                           PRIME))

                // res += c_44*(f_7(x) - f_7(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[44]*/ mload(add(context, 0x72c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[44]*/ mload(add(context, 0x56c0)))),
                           PRIME))

                // res += c_45*(f_7(x) - f_7(g^255 * z)) / (x - g^255 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^255 * z)^(-1)*/ mload(add(denominatorsPtr, 0x620)),
                                  /*oods_coefficients[45]*/ mload(add(context, 0x72e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[45]*/ mload(add(context, 0x56e0)))),
                           PRIME))

                // res += c_46*(f_7(x) - f_7(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[46]*/ mload(add(context, 0x7300)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[46]*/ mload(add(context, 0x5700)))),
                           PRIME))

                // res += c_47*(f_7(x) - f_7(g^511 * z)) / (x - g^511 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^511 * z)^(-1)*/ mload(add(denominatorsPtr, 0x740)),
                                  /*oods_coefficients[47]*/ mload(add(context, 0x7320)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[47]*/ mload(add(context, 0x5720)))),
                           PRIME))
                }

                // Mask items for column #8.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x100)), kMontgomeryRInv, PRIME)

                // res += c_48*(f_8(x) - f_8(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[48]*/ mload(add(context, 0x7340)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[48]*/ mload(add(context, 0x5740)))),
                           PRIME))

                // res += c_49*(f_8(x) - f_8(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[49]*/ mload(add(context, 0x7360)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[49]*/ mload(add(context, 0x5760)))),
                           PRIME))

                // res += c_50*(f_8(x) - f_8(g^255 * z)) / (x - g^255 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^255 * z)^(-1)*/ mload(add(denominatorsPtr, 0x620)),
                                  /*oods_coefficients[50]*/ mload(add(context, 0x7380)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[50]*/ mload(add(context, 0x5780)))),
                           PRIME))

                // res += c_51*(f_8(x) - f_8(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[51]*/ mload(add(context, 0x73a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[51]*/ mload(add(context, 0x57a0)))),
                           PRIME))
                }

                // Mask items for column #9.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x120)), kMontgomeryRInv, PRIME)

                // res += c_52*(f_9(x) - f_9(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[52]*/ mload(add(context, 0x73c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[52]*/ mload(add(context, 0x57c0)))),
                           PRIME))
                }

                // Mask items for column #10.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x140)), kMontgomeryRInv, PRIME)

                // res += c_53*(f_10(x) - f_10(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[53]*/ mload(add(context, 0x73e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[53]*/ mload(add(context, 0x57e0)))),
                           PRIME))

                // res += c_54*(f_10(x) - f_10(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[54]*/ mload(add(context, 0x7400)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[54]*/ mload(add(context, 0x5800)))),
                           PRIME))

                // res += c_55*(f_10(x) - f_10(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[55]*/ mload(add(context, 0x7420)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[55]*/ mload(add(context, 0x5820)))),
                           PRIME))
                }

                // Mask items for column #11.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x160)), kMontgomeryRInv, PRIME)

                // res += c_56*(f_11(x) - f_11(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[56]*/ mload(add(context, 0x7440)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[56]*/ mload(add(context, 0x5840)))),
                           PRIME))

                // res += c_57*(f_11(x) - f_11(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[57]*/ mload(add(context, 0x7460)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[57]*/ mload(add(context, 0x5860)))),
                           PRIME))

                // res += c_58*(f_11(x) - f_11(g^255 * z)) / (x - g^255 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^255 * z)^(-1)*/ mload(add(denominatorsPtr, 0x620)),
                                  /*oods_coefficients[58]*/ mload(add(context, 0x7480)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[58]*/ mload(add(context, 0x5880)))),
                           PRIME))

                // res += c_59*(f_11(x) - f_11(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[59]*/ mload(add(context, 0x74a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[59]*/ mload(add(context, 0x58a0)))),
                           PRIME))

                // res += c_60*(f_11(x) - f_11(g^511 * z)) / (x - g^511 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^511 * z)^(-1)*/ mload(add(denominatorsPtr, 0x740)),
                                  /*oods_coefficients[60]*/ mload(add(context, 0x74c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[60]*/ mload(add(context, 0x58c0)))),
                           PRIME))
                }

                // Mask items for column #12.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x180)), kMontgomeryRInv, PRIME)

                // res += c_61*(f_12(x) - f_12(z)) / (x - z).
                res := addmod(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[61]*/ mload(add(context, 0x74e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[61]*/ mload(add(context, 0x58e0)))),
                           PRIME),
                    PRIME)

                // res += c_62*(f_12(x) - f_12(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[62]*/ mload(add(context, 0x7500)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[62]*/ mload(add(context, 0x5900)))),
                           PRIME))

                // res += c_63*(f_12(x) - f_12(g^255 * z)) / (x - g^255 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^255 * z)^(-1)*/ mload(add(denominatorsPtr, 0x620)),
                                  /*oods_coefficients[63]*/ mload(add(context, 0x7520)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[63]*/ mload(add(context, 0x5920)))),
                           PRIME))

                // res += c_64*(f_12(x) - f_12(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[64]*/ mload(add(context, 0x7540)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[64]*/ mload(add(context, 0x5940)))),
                           PRIME))
                }

                // Mask items for column #13.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x1a0)), kMontgomeryRInv, PRIME)

                // res += c_65*(f_13(x) - f_13(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[65]*/ mload(add(context, 0x7560)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[65]*/ mload(add(context, 0x5960)))),
                           PRIME))
                }

                // Mask items for column #14.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x1c0)), kMontgomeryRInv, PRIME)

                // res += c_66*(f_14(x) - f_14(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[66]*/ mload(add(context, 0x7580)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[66]*/ mload(add(context, 0x5980)))),
                           PRIME))

                // res += c_67*(f_14(x) - f_14(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[67]*/ mload(add(context, 0x75a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[67]*/ mload(add(context, 0x59a0)))),
                           PRIME))

                // res += c_68*(f_14(x) - f_14(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[68]*/ mload(add(context, 0x75c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[68]*/ mload(add(context, 0x59c0)))),
                           PRIME))
                }

                // Mask items for column #15.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x1e0)), kMontgomeryRInv, PRIME)

                // res += c_69*(f_15(x) - f_15(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[69]*/ mload(add(context, 0x75e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[69]*/ mload(add(context, 0x59e0)))),
                           PRIME))

                // res += c_70*(f_15(x) - f_15(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[70]*/ mload(add(context, 0x7600)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[70]*/ mload(add(context, 0x5a00)))),
                           PRIME))

                // res += c_71*(f_15(x) - f_15(g^255 * z)) / (x - g^255 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^255 * z)^(-1)*/ mload(add(denominatorsPtr, 0x620)),
                                  /*oods_coefficients[71]*/ mload(add(context, 0x7620)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[71]*/ mload(add(context, 0x5a20)))),
                           PRIME))

                // res += c_72*(f_15(x) - f_15(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[72]*/ mload(add(context, 0x7640)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[72]*/ mload(add(context, 0x5a40)))),
                           PRIME))

                // res += c_73*(f_15(x) - f_15(g^511 * z)) / (x - g^511 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^511 * z)^(-1)*/ mload(add(denominatorsPtr, 0x740)),
                                  /*oods_coefficients[73]*/ mload(add(context, 0x7660)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[73]*/ mload(add(context, 0x5a60)))),
                           PRIME))
                }

                // Mask items for column #16.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x200)), kMontgomeryRInv, PRIME)

                // res += c_74*(f_16(x) - f_16(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[74]*/ mload(add(context, 0x7680)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[74]*/ mload(add(context, 0x5a80)))),
                           PRIME))

                // res += c_75*(f_16(x) - f_16(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[75]*/ mload(add(context, 0x76a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[75]*/ mload(add(context, 0x5aa0)))),
                           PRIME))

                // res += c_76*(f_16(x) - f_16(g^255 * z)) / (x - g^255 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^255 * z)^(-1)*/ mload(add(denominatorsPtr, 0x620)),
                                  /*oods_coefficients[76]*/ mload(add(context, 0x76c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[76]*/ mload(add(context, 0x5ac0)))),
                           PRIME))

                // res += c_77*(f_16(x) - f_16(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[77]*/ mload(add(context, 0x76e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[77]*/ mload(add(context, 0x5ae0)))),
                           PRIME))
                }

                // Mask items for column #17.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x220)), kMontgomeryRInv, PRIME)

                // res += c_78*(f_17(x) - f_17(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[78]*/ mload(add(context, 0x7700)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[78]*/ mload(add(context, 0x5b00)))),
                           PRIME))
                }

                // Mask items for column #18.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x240)), kMontgomeryRInv, PRIME)

                // res += c_79*(f_18(x) - f_18(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[79]*/ mload(add(context, 0x7720)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[79]*/ mload(add(context, 0x5b20)))),
                           PRIME))

                // res += c_80*(f_18(x) - f_18(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[80]*/ mload(add(context, 0x7740)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[80]*/ mload(add(context, 0x5b40)))),
                           PRIME))

                // res += c_81*(f_18(x) - f_18(g^256 * z)) / (x - g^256 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^256 * z)^(-1)*/ mload(add(denominatorsPtr, 0x640)),
                                  /*oods_coefficients[81]*/ mload(add(context, 0x7760)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[81]*/ mload(add(context, 0x5b60)))),
                           PRIME))
                }

                // Mask items for column #19.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x260)), kMontgomeryRInv, PRIME)

                // res += c_82*(f_19(x) - f_19(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[82]*/ mload(add(context, 0x7780)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[82]*/ mload(add(context, 0x5b80)))),
                           PRIME))

                // res += c_83*(f_19(x) - f_19(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[83]*/ mload(add(context, 0x77a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[83]*/ mload(add(context, 0x5ba0)))),
                           PRIME))

                // res += c_84*(f_19(x) - f_19(g^2 * z)) / (x - g^2 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^2 * z)^(-1)*/ mload(add(denominatorsPtr, 0x40)),
                                  /*oods_coefficients[84]*/ mload(add(context, 0x77c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[84]*/ mload(add(context, 0x5bc0)))),
                           PRIME))

                // res += c_85*(f_19(x) - f_19(g^3 * z)) / (x - g^3 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^3 * z)^(-1)*/ mload(add(denominatorsPtr, 0x60)),
                                  /*oods_coefficients[85]*/ mload(add(context, 0x77e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[85]*/ mload(add(context, 0x5be0)))),
                           PRIME))

                // res += c_86*(f_19(x) - f_19(g^4 * z)) / (x - g^4 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4 * z)^(-1)*/ mload(add(denominatorsPtr, 0x80)),
                                  /*oods_coefficients[86]*/ mload(add(context, 0x7800)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[86]*/ mload(add(context, 0x5c00)))),
                           PRIME))

                // res += c_87*(f_19(x) - f_19(g^5 * z)) / (x - g^5 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^5 * z)^(-1)*/ mload(add(denominatorsPtr, 0xa0)),
                                  /*oods_coefficients[87]*/ mload(add(context, 0x7820)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[87]*/ mload(add(context, 0x5c20)))),
                           PRIME))

                // res += c_88*(f_19(x) - f_19(g^6 * z)) / (x - g^6 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^6 * z)^(-1)*/ mload(add(denominatorsPtr, 0xc0)),
                                  /*oods_coefficients[88]*/ mload(add(context, 0x7840)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[88]*/ mload(add(context, 0x5c40)))),
                           PRIME))

                // res += c_89*(f_19(x) - f_19(g^7 * z)) / (x - g^7 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^7 * z)^(-1)*/ mload(add(denominatorsPtr, 0xe0)),
                                  /*oods_coefficients[89]*/ mload(add(context, 0x7860)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[89]*/ mload(add(context, 0x5c60)))),
                           PRIME))

                // res += c_90*(f_19(x) - f_19(g^8 * z)) / (x - g^8 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8 * z)^(-1)*/ mload(add(denominatorsPtr, 0x100)),
                                  /*oods_coefficients[90]*/ mload(add(context, 0x7880)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[90]*/ mload(add(context, 0x5c80)))),
                           PRIME))

                // res += c_91*(f_19(x) - f_19(g^9 * z)) / (x - g^9 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^9 * z)^(-1)*/ mload(add(denominatorsPtr, 0x120)),
                                  /*oods_coefficients[91]*/ mload(add(context, 0x78a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[91]*/ mload(add(context, 0x5ca0)))),
                           PRIME))

                // res += c_92*(f_19(x) - f_19(g^12 * z)) / (x - g^12 * z).
                res := addmod(
                    res,
                    mulmod(mulmod(/*(x - g^12 * z)^(-1)*/ mload(add(denominatorsPtr, 0x180)),
                                  /*oods_coefficients[92]*/ mload(add(context, 0x78c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[92]*/ mload(add(context, 0x5cc0)))),
                           PRIME),
                    PRIME)

                // res += c_93*(f_19(x) - f_19(g^13 * z)) / (x - g^13 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^13 * z)^(-1)*/ mload(add(denominatorsPtr, 0x1a0)),
                                  /*oods_coefficients[93]*/ mload(add(context, 0x78e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[93]*/ mload(add(context, 0x5ce0)))),
                           PRIME))

                // res += c_94*(f_19(x) - f_19(g^16 * z)) / (x - g^16 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^16 * z)^(-1)*/ mload(add(denominatorsPtr, 0x200)),
                                  /*oods_coefficients[94]*/ mload(add(context, 0x7900)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[94]*/ mload(add(context, 0x5d00)))),
                           PRIME))

                // res += c_95*(f_19(x) - f_19(g^22 * z)) / (x - g^22 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^22 * z)^(-1)*/ mload(add(denominatorsPtr, 0x260)),
                                  /*oods_coefficients[95]*/ mload(add(context, 0x7920)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[95]*/ mload(add(context, 0x5d20)))),
                           PRIME))

                // res += c_96*(f_19(x) - f_19(g^23 * z)) / (x - g^23 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^23 * z)^(-1)*/ mload(add(denominatorsPtr, 0x280)),
                                  /*oods_coefficients[96]*/ mload(add(context, 0x7940)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[96]*/ mload(add(context, 0x5d40)))),
                           PRIME))

                // res += c_97*(f_19(x) - f_19(g^38 * z)) / (x - g^38 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^38 * z)^(-1)*/ mload(add(denominatorsPtr, 0x340)),
                                  /*oods_coefficients[97]*/ mload(add(context, 0x7960)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[97]*/ mload(add(context, 0x5d60)))),
                           PRIME))

                // res += c_98*(f_19(x) - f_19(g^39 * z)) / (x - g^39 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^39 * z)^(-1)*/ mload(add(denominatorsPtr, 0x360)),
                                  /*oods_coefficients[98]*/ mload(add(context, 0x7980)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[98]*/ mload(add(context, 0x5d80)))),
                           PRIME))

                // res += c_99*(f_19(x) - f_19(g^70 * z)) / (x - g^70 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^70 * z)^(-1)*/ mload(add(denominatorsPtr, 0x400)),
                                  /*oods_coefficients[99]*/ mload(add(context, 0x79a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[99]*/ mload(add(context, 0x5da0)))),
                           PRIME))

                // res += c_100*(f_19(x) - f_19(g^71 * z)) / (x - g^71 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^71 * z)^(-1)*/ mload(add(denominatorsPtr, 0x420)),
                                  /*oods_coefficients[100]*/ mload(add(context, 0x79c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[100]*/ mload(add(context, 0x5dc0)))),
                           PRIME))

                // res += c_101*(f_19(x) - f_19(g^86 * z)) / (x - g^86 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^86 * z)^(-1)*/ mload(add(denominatorsPtr, 0x460)),
                                  /*oods_coefficients[101]*/ mload(add(context, 0x79e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[101]*/ mload(add(context, 0x5de0)))),
                           PRIME))

                // res += c_102*(f_19(x) - f_19(g^87 * z)) / (x - g^87 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^87 * z)^(-1)*/ mload(add(denominatorsPtr, 0x480)),
                                  /*oods_coefficients[102]*/ mload(add(context, 0x7a00)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[102]*/ mload(add(context, 0x5e00)))),
                           PRIME))

                // res += c_103*(f_19(x) - f_19(g^102 * z)) / (x - g^102 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^102 * z)^(-1)*/ mload(add(denominatorsPtr, 0x4c0)),
                                  /*oods_coefficients[103]*/ mload(add(context, 0x7a20)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[103]*/ mload(add(context, 0x5e20)))),
                           PRIME))

                // res += c_104*(f_19(x) - f_19(g^103 * z)) / (x - g^103 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^103 * z)^(-1)*/ mload(add(denominatorsPtr, 0x4e0)),
                                  /*oods_coefficients[104]*/ mload(add(context, 0x7a40)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[104]*/ mload(add(context, 0x5e40)))),
                           PRIME))

                // res += c_105*(f_19(x) - f_19(g^134 * z)) / (x - g^134 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^134 * z)^(-1)*/ mload(add(denominatorsPtr, 0x540)),
                                  /*oods_coefficients[105]*/ mload(add(context, 0x7a60)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[105]*/ mload(add(context, 0x5e60)))),
                           PRIME))

                // res += c_106*(f_19(x) - f_19(g^135 * z)) / (x - g^135 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^135 * z)^(-1)*/ mload(add(denominatorsPtr, 0x560)),
                                  /*oods_coefficients[106]*/ mload(add(context, 0x7a80)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[106]*/ mload(add(context, 0x5e80)))),
                           PRIME))

                // res += c_107*(f_19(x) - f_19(g^150 * z)) / (x - g^150 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^150 * z)^(-1)*/ mload(add(denominatorsPtr, 0x580)),
                                  /*oods_coefficients[107]*/ mload(add(context, 0x7aa0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[107]*/ mload(add(context, 0x5ea0)))),
                           PRIME))

                // res += c_108*(f_19(x) - f_19(g^151 * z)) / (x - g^151 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^151 * z)^(-1)*/ mload(add(denominatorsPtr, 0x5a0)),
                                  /*oods_coefficients[108]*/ mload(add(context, 0x7ac0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[108]*/ mload(add(context, 0x5ec0)))),
                           PRIME))

                // res += c_109*(f_19(x) - f_19(g^167 * z)) / (x - g^167 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^167 * z)^(-1)*/ mload(add(denominatorsPtr, 0x5c0)),
                                  /*oods_coefficients[109]*/ mload(add(context, 0x7ae0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[109]*/ mload(add(context, 0x5ee0)))),
                           PRIME))

                // res += c_110*(f_19(x) - f_19(g^199 * z)) / (x - g^199 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^199 * z)^(-1)*/ mload(add(denominatorsPtr, 0x5e0)),
                                  /*oods_coefficients[110]*/ mload(add(context, 0x7b00)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[110]*/ mload(add(context, 0x5f00)))),
                           PRIME))

                // res += c_111*(f_19(x) - f_19(g^230 * z)) / (x - g^230 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^230 * z)^(-1)*/ mload(add(denominatorsPtr, 0x600)),
                                  /*oods_coefficients[111]*/ mload(add(context, 0x7b20)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[111]*/ mload(add(context, 0x5f20)))),
                           PRIME))

                // res += c_112*(f_19(x) - f_19(g^263 * z)) / (x - g^263 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^263 * z)^(-1)*/ mload(add(denominatorsPtr, 0x660)),
                                  /*oods_coefficients[112]*/ mload(add(context, 0x7b40)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[112]*/ mload(add(context, 0x5f40)))),
                           PRIME))

                // res += c_113*(f_19(x) - f_19(g^295 * z)) / (x - g^295 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^295 * z)^(-1)*/ mload(add(denominatorsPtr, 0x680)),
                                  /*oods_coefficients[113]*/ mload(add(context, 0x7b60)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[113]*/ mload(add(context, 0x5f60)))),
                           PRIME))

                // res += c_114*(f_19(x) - f_19(g^327 * z)) / (x - g^327 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^327 * z)^(-1)*/ mload(add(denominatorsPtr, 0x6a0)),
                                  /*oods_coefficients[114]*/ mload(add(context, 0x7b80)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[114]*/ mload(add(context, 0x5f80)))),
                           PRIME))

                // res += c_115*(f_19(x) - f_19(g^391 * z)) / (x - g^391 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^391 * z)^(-1)*/ mload(add(denominatorsPtr, 0x6c0)),
                                  /*oods_coefficients[115]*/ mload(add(context, 0x7ba0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[115]*/ mload(add(context, 0x5fa0)))),
                           PRIME))

                // res += c_116*(f_19(x) - f_19(g^406 * z)) / (x - g^406 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^406 * z)^(-1)*/ mload(add(denominatorsPtr, 0x6e0)),
                                  /*oods_coefficients[116]*/ mload(add(context, 0x7bc0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[116]*/ mload(add(context, 0x5fc0)))),
                           PRIME))

                // res += c_117*(f_19(x) - f_19(g^423 * z)) / (x - g^423 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^423 * z)^(-1)*/ mload(add(denominatorsPtr, 0x700)),
                                  /*oods_coefficients[117]*/ mload(add(context, 0x7be0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[117]*/ mload(add(context, 0x5fe0)))),
                           PRIME))

                // res += c_118*(f_19(x) - f_19(g^455 * z)) / (x - g^455 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^455 * z)^(-1)*/ mload(add(denominatorsPtr, 0x720)),
                                  /*oods_coefficients[118]*/ mload(add(context, 0x7c00)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[118]*/ mload(add(context, 0x6000)))),
                           PRIME))

                // res += c_119*(f_19(x) - f_19(g^4118 * z)) / (x - g^4118 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4118 * z)^(-1)*/ mload(add(denominatorsPtr, 0x840)),
                                  /*oods_coefficients[119]*/ mload(add(context, 0x7c20)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[119]*/ mload(add(context, 0x6020)))),
                           PRIME))

                // res += c_120*(f_19(x) - f_19(g^4119 * z)) / (x - g^4119 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4119 * z)^(-1)*/ mload(add(denominatorsPtr, 0x860)),
                                  /*oods_coefficients[120]*/ mload(add(context, 0x7c40)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[120]*/ mload(add(context, 0x6040)))),
                           PRIME))

                // res += c_121*(f_19(x) - f_19(g^8214 * z)) / (x - g^8214 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8214 * z)^(-1)*/ mload(add(denominatorsPtr, 0x980)),
                                  /*oods_coefficients[121]*/ mload(add(context, 0x7c60)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[121]*/ mload(add(context, 0x6060)))),
                           PRIME))
                }

                // Mask items for column #20.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x280)), kMontgomeryRInv, PRIME)

                // res += c_122*(f_20(x) - f_20(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[122]*/ mload(add(context, 0x7c80)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[122]*/ mload(add(context, 0x6080)))),
                           PRIME))

                // res += c_123*(f_20(x) - f_20(g * z)) / (x - g * z).
                res := addmod(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[123]*/ mload(add(context, 0x7ca0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[123]*/ mload(add(context, 0x60a0)))),
                           PRIME),
                    PRIME)

                // res += c_124*(f_20(x) - f_20(g^2 * z)) / (x - g^2 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^2 * z)^(-1)*/ mload(add(denominatorsPtr, 0x40)),
                                  /*oods_coefficients[124]*/ mload(add(context, 0x7cc0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[124]*/ mload(add(context, 0x60c0)))),
                           PRIME))

                // res += c_125*(f_20(x) - f_20(g^3 * z)) / (x - g^3 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^3 * z)^(-1)*/ mload(add(denominatorsPtr, 0x60)),
                                  /*oods_coefficients[125]*/ mload(add(context, 0x7ce0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[125]*/ mload(add(context, 0x60e0)))),
                           PRIME))
                }

                // Mask items for column #21.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x2a0)), kMontgomeryRInv, PRIME)

                // res += c_126*(f_21(x) - f_21(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[126]*/ mload(add(context, 0x7d00)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[126]*/ mload(add(context, 0x6100)))),
                           PRIME))

                // res += c_127*(f_21(x) - f_21(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[127]*/ mload(add(context, 0x7d20)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[127]*/ mload(add(context, 0x6120)))),
                           PRIME))

                // res += c_128*(f_21(x) - f_21(g^2 * z)) / (x - g^2 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^2 * z)^(-1)*/ mload(add(denominatorsPtr, 0x40)),
                                  /*oods_coefficients[128]*/ mload(add(context, 0x7d40)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[128]*/ mload(add(context, 0x6140)))),
                           PRIME))

                // res += c_129*(f_21(x) - f_21(g^3 * z)) / (x - g^3 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^3 * z)^(-1)*/ mload(add(denominatorsPtr, 0x60)),
                                  /*oods_coefficients[129]*/ mload(add(context, 0x7d60)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[129]*/ mload(add(context, 0x6160)))),
                           PRIME))

                // res += c_130*(f_21(x) - f_21(g^4 * z)) / (x - g^4 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4 * z)^(-1)*/ mload(add(denominatorsPtr, 0x80)),
                                  /*oods_coefficients[130]*/ mload(add(context, 0x7d80)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[130]*/ mload(add(context, 0x6180)))),
                           PRIME))

                // res += c_131*(f_21(x) - f_21(g^5 * z)) / (x - g^5 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^5 * z)^(-1)*/ mload(add(denominatorsPtr, 0xa0)),
                                  /*oods_coefficients[131]*/ mload(add(context, 0x7da0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[131]*/ mload(add(context, 0x61a0)))),
                           PRIME))

                // res += c_132*(f_21(x) - f_21(g^6 * z)) / (x - g^6 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^6 * z)^(-1)*/ mload(add(denominatorsPtr, 0xc0)),
                                  /*oods_coefficients[132]*/ mload(add(context, 0x7dc0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[132]*/ mload(add(context, 0x61c0)))),
                           PRIME))

                // res += c_133*(f_21(x) - f_21(g^7 * z)) / (x - g^7 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^7 * z)^(-1)*/ mload(add(denominatorsPtr, 0xe0)),
                                  /*oods_coefficients[133]*/ mload(add(context, 0x7de0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[133]*/ mload(add(context, 0x61e0)))),
                           PRIME))

                // res += c_134*(f_21(x) - f_21(g^8 * z)) / (x - g^8 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8 * z)^(-1)*/ mload(add(denominatorsPtr, 0x100)),
                                  /*oods_coefficients[134]*/ mload(add(context, 0x7e00)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[134]*/ mload(add(context, 0x6200)))),
                           PRIME))

                // res += c_135*(f_21(x) - f_21(g^9 * z)) / (x - g^9 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^9 * z)^(-1)*/ mload(add(denominatorsPtr, 0x120)),
                                  /*oods_coefficients[135]*/ mload(add(context, 0x7e20)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[135]*/ mload(add(context, 0x6220)))),
                           PRIME))

                // res += c_136*(f_21(x) - f_21(g^10 * z)) / (x - g^10 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^10 * z)^(-1)*/ mload(add(denominatorsPtr, 0x140)),
                                  /*oods_coefficients[136]*/ mload(add(context, 0x7e40)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[136]*/ mload(add(context, 0x6240)))),
                           PRIME))

                // res += c_137*(f_21(x) - f_21(g^11 * z)) / (x - g^11 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^11 * z)^(-1)*/ mload(add(denominatorsPtr, 0x160)),
                                  /*oods_coefficients[137]*/ mload(add(context, 0x7e60)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[137]*/ mload(add(context, 0x6260)))),
                           PRIME))

                // res += c_138*(f_21(x) - f_21(g^12 * z)) / (x - g^12 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^12 * z)^(-1)*/ mload(add(denominatorsPtr, 0x180)),
                                  /*oods_coefficients[138]*/ mload(add(context, 0x7e80)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[138]*/ mload(add(context, 0x6280)))),
                           PRIME))

                // res += c_139*(f_21(x) - f_21(g^13 * z)) / (x - g^13 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^13 * z)^(-1)*/ mload(add(denominatorsPtr, 0x1a0)),
                                  /*oods_coefficients[139]*/ mload(add(context, 0x7ea0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[139]*/ mload(add(context, 0x62a0)))),
                           PRIME))

                // res += c_140*(f_21(x) - f_21(g^14 * z)) / (x - g^14 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^14 * z)^(-1)*/ mload(add(denominatorsPtr, 0x1c0)),
                                  /*oods_coefficients[140]*/ mload(add(context, 0x7ec0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[140]*/ mload(add(context, 0x62c0)))),
                           PRIME))

                // res += c_141*(f_21(x) - f_21(g^15 * z)) / (x - g^15 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^15 * z)^(-1)*/ mload(add(denominatorsPtr, 0x1e0)),
                                  /*oods_coefficients[141]*/ mload(add(context, 0x7ee0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[141]*/ mload(add(context, 0x62e0)))),
                           PRIME))

                // res += c_142*(f_21(x) - f_21(g^16 * z)) / (x - g^16 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^16 * z)^(-1)*/ mload(add(denominatorsPtr, 0x200)),
                                  /*oods_coefficients[142]*/ mload(add(context, 0x7f00)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[142]*/ mload(add(context, 0x6300)))),
                           PRIME))

                // res += c_143*(f_21(x) - f_21(g^19 * z)) / (x - g^19 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^19 * z)^(-1)*/ mload(add(denominatorsPtr, 0x220)),
                                  /*oods_coefficients[143]*/ mload(add(context, 0x7f20)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[143]*/ mload(add(context, 0x6320)))),
                           PRIME))

                // res += c_144*(f_21(x) - f_21(g^21 * z)) / (x - g^21 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^21 * z)^(-1)*/ mload(add(denominatorsPtr, 0x240)),
                                  /*oods_coefficients[144]*/ mload(add(context, 0x7f40)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[144]*/ mload(add(context, 0x6340)))),
                           PRIME))

                // res += c_145*(f_21(x) - f_21(g^22 * z)) / (x - g^22 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^22 * z)^(-1)*/ mload(add(denominatorsPtr, 0x260)),
                                  /*oods_coefficients[145]*/ mload(add(context, 0x7f60)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[145]*/ mload(add(context, 0x6360)))),
                           PRIME))

                // res += c_146*(f_21(x) - f_21(g^23 * z)) / (x - g^23 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^23 * z)^(-1)*/ mload(add(denominatorsPtr, 0x280)),
                                  /*oods_coefficients[146]*/ mload(add(context, 0x7f80)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[146]*/ mload(add(context, 0x6380)))),
                           PRIME))

                // res += c_147*(f_21(x) - f_21(g^24 * z)) / (x - g^24 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^24 * z)^(-1)*/ mload(add(denominatorsPtr, 0x2a0)),
                                  /*oods_coefficients[147]*/ mload(add(context, 0x7fa0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[147]*/ mload(add(context, 0x63a0)))),
                           PRIME))

                // res += c_148*(f_21(x) - f_21(g^25 * z)) / (x - g^25 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^25 * z)^(-1)*/ mload(add(denominatorsPtr, 0x2c0)),
                                  /*oods_coefficients[148]*/ mload(add(context, 0x7fc0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[148]*/ mload(add(context, 0x63c0)))),
                           PRIME))

                // res += c_149*(f_21(x) - f_21(g^30 * z)) / (x - g^30 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^30 * z)^(-1)*/ mload(add(denominatorsPtr, 0x300)),
                                  /*oods_coefficients[149]*/ mload(add(context, 0x7fe0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[149]*/ mload(add(context, 0x63e0)))),
                           PRIME))

                // res += c_150*(f_21(x) - f_21(g^31 * z)) / (x - g^31 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^31 * z)^(-1)*/ mload(add(denominatorsPtr, 0x320)),
                                  /*oods_coefficients[150]*/ mload(add(context, 0x8000)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[150]*/ mload(add(context, 0x6400)))),
                           PRIME))

                // res += c_151*(f_21(x) - f_21(g^39 * z)) / (x - g^39 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^39 * z)^(-1)*/ mload(add(denominatorsPtr, 0x360)),
                                  /*oods_coefficients[151]*/ mload(add(context, 0x8020)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[151]*/ mload(add(context, 0x6420)))),
                           PRIME))

                // res += c_152*(f_21(x) - f_21(g^55 * z)) / (x - g^55 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^55 * z)^(-1)*/ mload(add(denominatorsPtr, 0x3a0)),
                                  /*oods_coefficients[152]*/ mload(add(context, 0x8040)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[152]*/ mload(add(context, 0x6440)))),
                           PRIME))

                // res += c_153*(f_21(x) - f_21(g^63 * z)) / (x - g^63 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^63 * z)^(-1)*/ mload(add(denominatorsPtr, 0x3e0)),
                                  /*oods_coefficients[153]*/ mload(add(context, 0x8060)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[153]*/ mload(add(context, 0x6460)))),
                           PRIME))

                // res += c_154*(f_21(x) - f_21(g^4081 * z)) / (x - g^4081 * z).
                res := addmod(
                    res,
                    mulmod(mulmod(/*(x - g^4081 * z)^(-1)*/ mload(add(denominatorsPtr, 0x760)),
                                  /*oods_coefficients[154]*/ mload(add(context, 0x8080)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[154]*/ mload(add(context, 0x6480)))),
                           PRIME),
                    PRIME)

                // res += c_155*(f_21(x) - f_21(g^4085 * z)) / (x - g^4085 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4085 * z)^(-1)*/ mload(add(denominatorsPtr, 0x780)),
                                  /*oods_coefficients[155]*/ mload(add(context, 0x80a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[155]*/ mload(add(context, 0x64a0)))),
                           PRIME))

                // res += c_156*(f_21(x) - f_21(g^4089 * z)) / (x - g^4089 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4089 * z)^(-1)*/ mload(add(denominatorsPtr, 0x7a0)),
                                  /*oods_coefficients[156]*/ mload(add(context, 0x80c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[156]*/ mload(add(context, 0x64c0)))),
                           PRIME))

                // res += c_157*(f_21(x) - f_21(g^4091 * z)) / (x - g^4091 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4091 * z)^(-1)*/ mload(add(denominatorsPtr, 0x7c0)),
                                  /*oods_coefficients[157]*/ mload(add(context, 0x80e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[157]*/ mload(add(context, 0x64e0)))),
                           PRIME))

                // res += c_158*(f_21(x) - f_21(g^4093 * z)) / (x - g^4093 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4093 * z)^(-1)*/ mload(add(denominatorsPtr, 0x7e0)),
                                  /*oods_coefficients[158]*/ mload(add(context, 0x8100)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[158]*/ mload(add(context, 0x6500)))),
                           PRIME))

                // res += c_159*(f_21(x) - f_21(g^4102 * z)) / (x - g^4102 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4102 * z)^(-1)*/ mload(add(denominatorsPtr, 0x800)),
                                  /*oods_coefficients[159]*/ mload(add(context, 0x8120)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[159]*/ mload(add(context, 0x6520)))),
                           PRIME))

                // res += c_160*(f_21(x) - f_21(g^4110 * z)) / (x - g^4110 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^4110 * z)^(-1)*/ mload(add(denominatorsPtr, 0x820)),
                                  /*oods_coefficients[160]*/ mload(add(context, 0x8140)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[160]*/ mload(add(context, 0x6540)))),
                           PRIME))

                // res += c_161*(f_21(x) - f_21(g^8167 * z)) / (x - g^8167 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8167 * z)^(-1)*/ mload(add(denominatorsPtr, 0x8a0)),
                                  /*oods_coefficients[161]*/ mload(add(context, 0x8160)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[161]*/ mload(add(context, 0x6560)))),
                           PRIME))

                // res += c_162*(f_21(x) - f_21(g^8175 * z)) / (x - g^8175 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8175 * z)^(-1)*/ mload(add(denominatorsPtr, 0x8c0)),
                                  /*oods_coefficients[162]*/ mload(add(context, 0x8180)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[162]*/ mload(add(context, 0x6580)))),
                           PRIME))

                // res += c_163*(f_21(x) - f_21(g^8177 * z)) / (x - g^8177 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8177 * z)^(-1)*/ mload(add(denominatorsPtr, 0x8e0)),
                                  /*oods_coefficients[163]*/ mload(add(context, 0x81a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[163]*/ mload(add(context, 0x65a0)))),
                           PRIME))

                // res += c_164*(f_21(x) - f_21(g^8181 * z)) / (x - g^8181 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8181 * z)^(-1)*/ mload(add(denominatorsPtr, 0x900)),
                                  /*oods_coefficients[164]*/ mload(add(context, 0x81c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[164]*/ mload(add(context, 0x65c0)))),
                           PRIME))

                // res += c_165*(f_21(x) - f_21(g^8183 * z)) / (x - g^8183 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8183 * z)^(-1)*/ mload(add(denominatorsPtr, 0x920)),
                                  /*oods_coefficients[165]*/ mload(add(context, 0x81e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[165]*/ mload(add(context, 0x65e0)))),
                           PRIME))

                // res += c_166*(f_21(x) - f_21(g^8185 * z)) / (x - g^8185 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8185 * z)^(-1)*/ mload(add(denominatorsPtr, 0x940)),
                                  /*oods_coefficients[166]*/ mload(add(context, 0x8200)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[166]*/ mload(add(context, 0x6600)))),
                           PRIME))

                // res += c_167*(f_21(x) - f_21(g^8189 * z)) / (x - g^8189 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8189 * z)^(-1)*/ mload(add(denominatorsPtr, 0x960)),
                                  /*oods_coefficients[167]*/ mload(add(context, 0x8220)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[167]*/ mload(add(context, 0x6620)))),
                           PRIME))
                }

                // Mask items for column #22.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x2c0)), kMontgomeryRInv, PRIME)

                // res += c_168*(f_22(x) - f_22(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[168]*/ mload(add(context, 0x8240)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[168]*/ mload(add(context, 0x6640)))),
                           PRIME))

                // res += c_169*(f_22(x) - f_22(g^8160 * z)) / (x - g^8160 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^8160 * z)^(-1)*/ mload(add(denominatorsPtr, 0x880)),
                                  /*oods_coefficients[169]*/ mload(add(context, 0x8260)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[169]*/ mload(add(context, 0x6660)))),
                           PRIME))
                }

                // Mask items for column #23.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x2e0)), kMontgomeryRInv, PRIME)

                // res += c_170*(f_23(x) - f_23(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[170]*/ mload(add(context, 0x8280)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[170]*/ mload(add(context, 0x6680)))),
                           PRIME))

                // res += c_171*(f_23(x) - f_23(g * z)) / (x - g * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g * z)^(-1)*/ mload(add(denominatorsPtr, 0x20)),
                                  /*oods_coefficients[171]*/ mload(add(context, 0x82a0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[171]*/ mload(add(context, 0x66a0)))),
                           PRIME))
                }

                // Mask items for column #24.
                {
                // Read the next element.
                let columnValue := mulmod(mload(add(traceQueryResponses, 0x300)), kMontgomeryRInv, PRIME)

                // res += c_172*(f_24(x) - f_24(z)) / (x - z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z)^(-1)*/ mload(denominatorsPtr),
                                  /*oods_coefficients[172]*/ mload(add(context, 0x82c0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[172]*/ mload(add(context, 0x66c0)))),
                           PRIME))

                // res += c_173*(f_24(x) - f_24(g^2 * z)) / (x - g^2 * z).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - g^2 * z)^(-1)*/ mload(add(denominatorsPtr, 0x40)),
                                  /*oods_coefficients[173]*/ mload(add(context, 0x82e0)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*oods_values[173]*/ mload(add(context, 0x66e0)))),
                           PRIME))
                }

                // Advance traceQueryResponses by amount read (0x20 * nTraceColumns).
                traceQueryResponses := add(traceQueryResponses, 0x320)

                // Composition constraints.

                {
                // Read the next element.
                let columnValue := mulmod(mload(compositionQueryResponses), kMontgomeryRInv, PRIME)
                // res += c_174*(h_0(x) - C_0(z^2)) / (x - z^2).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z^2)^(-1)*/ mload(add(denominatorsPtr, 0x9a0)),
                                  /*oods_coefficients[174]*/ mload(add(context, 0x8300)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*composition_oods_values[0]*/ mload(add(context, 0x6700)))),
                           PRIME))
                }

                {
                // Read the next element.
                let columnValue := mulmod(mload(add(compositionQueryResponses, 0x20)), kMontgomeryRInv, PRIME)
                // res += c_175*(h_1(x) - C_1(z^2)) / (x - z^2).
                res := add(
                    res,
                    mulmod(mulmod(/*(x - z^2)^(-1)*/ mload(add(denominatorsPtr, 0x9a0)),
                                  /*oods_coefficients[175]*/ mload(add(context, 0x8320)),
                                  PRIME),
                           add(columnValue, sub(PRIME, /*composition_oods_values[1]*/ mload(add(context, 0x6720)))),
                           PRIME))
                }

                // Advance compositionQueryResponses by amount read (0x20 * constraintDegree).
                compositionQueryResponses := add(compositionQueryResponses, 0x40)

                // Append the friValue, which is the sum of the out-of-domain-sampling boundary
                // constraints for the trace and composition polynomials, to the friQueue array.
                mstore(add(friQueue, 0x20), mod(res, PRIME))

                // Append the friInvPoint of the current query to the friQueue array.
                mstore(add(friQueue, 0x40), /*friInvPoint*/ mload(add(denominatorsPtr,0x9c0)))

                // Advance denominatorsPtr by chunk size (0x20 * (2+N_ROWS_IN_MASK)).
                denominatorsPtr := add(denominatorsPtr, 0x9e0)
            }
            return(/*friQueue*/ add(context, 0xdc0), 0x1200)
        }
    }

    /*
      Computes and performs batch inverse on all the denominators required for the out of domain
      sampling boundary constraints.

      Since the friEvalPoints are calculated during the computation of the denominators
      this function also adds those to the batch inverse in prepartion for the fri that follows.

      After this function returns, the batch_inverse_out array holds #queries
      chunks of size (2 + N_ROWS_IN_MASK) with the following structure:
      0..(N_ROWS_IN_MASK-1):   [(x - g^i * z)^(-1) for i in rowsInMask]
      N_ROWS_IN_MASK:          (x - z^constraintDegree)^-1
      N_ROWS_IN_MASK+1:        friEvalPointInv.
    */
    function oodsPrepareInverses(
        uint256[] memory context, uint256[] memory batchInverseArray)
        internal view {
        uint256 evalCosetOffset_ = PrimeFieldElement0.GENERATOR_VAL;
        // The array expmodsAndPoints stores subexpressions that are needed
        // for the denominators computation.
        // The array is segmented as follows:
        //    expmodsAndPoints[0:19] (.expmods) expmods used during calculations of the points below.
        //    expmodsAndPoints[19:96] (.points) points used during the denominators calculation.
        uint256[96] memory expmodsAndPoints;
        assembly {
            function expmod(base, exponent, modulus) -> res {
              let p := mload(0x40)
              mstore(p, 0x20)                 // Length of Base.
              mstore(add(p, 0x20), 0x20)      // Length of Exponent.
              mstore(add(p, 0x40), 0x20)      // Length of Modulus.
              mstore(add(p, 0x60), base)      // Base.
              mstore(add(p, 0x80), exponent)  // Exponent.
              mstore(add(p, 0xa0), modulus)   // Modulus.
              // Call modexp precompile.
              if iszero(staticcall(not(0), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
              }
              res := mload(p)
            }

            let traceGenerator := /*trace_generator*/ mload(add(context, 0x2b60))
            let PRIME := 0x800000000000011000000000000000000000000000000000000000000000001

            // Prepare expmods for computations of trace generator powers.

            // expmodsAndPoints.expmods[0] = traceGenerator^2.
            mstore(expmodsAndPoints,
                   mulmod(traceGenerator, // traceGenerator^1
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[1] = traceGenerator^3.
            mstore(add(expmodsAndPoints, 0x20),
                   mulmod(mload(expmodsAndPoints), // traceGenerator^2
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[2] = traceGenerator^4.
            mstore(add(expmodsAndPoints, 0x40),
                   mulmod(mload(add(expmodsAndPoints, 0x20)), // traceGenerator^3
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[3] = traceGenerator^5.
            mstore(add(expmodsAndPoints, 0x60),
                   mulmod(mload(add(expmodsAndPoints, 0x40)), // traceGenerator^4
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[4] = traceGenerator^7.
            mstore(add(expmodsAndPoints, 0x80),
                   mulmod(mload(add(expmodsAndPoints, 0x60)), // traceGenerator^5
                          mload(expmodsAndPoints), // traceGenerator^2
                          PRIME))

            // expmodsAndPoints.expmods[5] = traceGenerator^8.
            mstore(add(expmodsAndPoints, 0xa0),
                   mulmod(mload(add(expmodsAndPoints, 0x80)), // traceGenerator^7
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[6] = traceGenerator^9.
            mstore(add(expmodsAndPoints, 0xc0),
                   mulmod(mload(add(expmodsAndPoints, 0xa0)), // traceGenerator^8
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[7] = traceGenerator^10.
            mstore(add(expmodsAndPoints, 0xe0),
                   mulmod(mload(add(expmodsAndPoints, 0xc0)), // traceGenerator^9
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[8] = traceGenerator^11.
            mstore(add(expmodsAndPoints, 0x100),
                   mulmod(mload(add(expmodsAndPoints, 0xe0)), // traceGenerator^10
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[9] = traceGenerator^15.
            mstore(add(expmodsAndPoints, 0x120),
                   mulmod(mload(add(expmodsAndPoints, 0x100)), // traceGenerator^11
                          mload(add(expmodsAndPoints, 0x40)), // traceGenerator^4
                          PRIME))

            // expmodsAndPoints.expmods[10] = traceGenerator^16.
            mstore(add(expmodsAndPoints, 0x140),
                   mulmod(mload(add(expmodsAndPoints, 0x120)), // traceGenerator^15
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[11] = traceGenerator^17.
            mstore(add(expmodsAndPoints, 0x160),
                   mulmod(mload(add(expmodsAndPoints, 0x140)), // traceGenerator^16
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[12] = traceGenerator^25.
            mstore(add(expmodsAndPoints, 0x180),
                   mulmod(mload(add(expmodsAndPoints, 0x160)), // traceGenerator^17
                          mload(add(expmodsAndPoints, 0xa0)), // traceGenerator^8
                          PRIME))

            // expmodsAndPoints.expmods[13] = traceGenerator^31.
            mstore(add(expmodsAndPoints, 0x1a0),
                   mulmod(mload(add(expmodsAndPoints, 0x140)), // traceGenerator^16
                          mload(add(expmodsAndPoints, 0x120)), // traceGenerator^15
                          PRIME))

            // expmodsAndPoints.expmods[14] = traceGenerator^32.
            mstore(add(expmodsAndPoints, 0x1c0),
                   mulmod(mload(add(expmodsAndPoints, 0x1a0)), // traceGenerator^31
                          traceGenerator, // traceGenerator^1
                          PRIME))

            // expmodsAndPoints.expmods[15] = traceGenerator^56.
            mstore(add(expmodsAndPoints, 0x1e0),
                   mulmod(mload(add(expmodsAndPoints, 0x1a0)), // traceGenerator^31
                          mload(add(expmodsAndPoints, 0x180)), // traceGenerator^25
                          PRIME))

            // expmodsAndPoints.expmods[16] = traceGenerator^64.
            mstore(add(expmodsAndPoints, 0x200),
                   mulmod(mload(add(expmodsAndPoints, 0x1e0)), // traceGenerator^56
                          mload(add(expmodsAndPoints, 0xa0)), // traceGenerator^8
                          PRIME))

            // expmodsAndPoints.expmods[17] = traceGenerator^3570.
            mstore(add(expmodsAndPoints, 0x220),
                   expmod(traceGenerator, 3570, PRIME))

            // expmodsAndPoints.expmods[18] = traceGenerator^4041.
            mstore(add(expmodsAndPoints, 0x240),
                   expmod(traceGenerator, 4041, PRIME))

            let oodsPoint := /*oods_point*/ mload(add(context, 0x2b80))
            {
              // point = -z.
              let point := sub(PRIME, oodsPoint)
              // Compute denominators for rows with nonconst mask expression.
              // We compute those first because for the const rows we modify the point variable.

              // Compute denominators for rows with const mask expression.

              // expmods_and_points.points[0] = -z.
              mstore(add(expmodsAndPoints, 0x260), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[1] = -(g * z).
              mstore(add(expmodsAndPoints, 0x280), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[2] = -(g^2 * z).
              mstore(add(expmodsAndPoints, 0x2a0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[3] = -(g^3 * z).
              mstore(add(expmodsAndPoints, 0x2c0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[4] = -(g^4 * z).
              mstore(add(expmodsAndPoints, 0x2e0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[5] = -(g^5 * z).
              mstore(add(expmodsAndPoints, 0x300), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[6] = -(g^6 * z).
              mstore(add(expmodsAndPoints, 0x320), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[7] = -(g^7 * z).
              mstore(add(expmodsAndPoints, 0x340), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[8] = -(g^8 * z).
              mstore(add(expmodsAndPoints, 0x360), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[9] = -(g^9 * z).
              mstore(add(expmodsAndPoints, 0x380), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[10] = -(g^10 * z).
              mstore(add(expmodsAndPoints, 0x3a0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[11] = -(g^11 * z).
              mstore(add(expmodsAndPoints, 0x3c0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[12] = -(g^12 * z).
              mstore(add(expmodsAndPoints, 0x3e0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[13] = -(g^13 * z).
              mstore(add(expmodsAndPoints, 0x400), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[14] = -(g^14 * z).
              mstore(add(expmodsAndPoints, 0x420), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[15] = -(g^15 * z).
              mstore(add(expmodsAndPoints, 0x440), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[16] = -(g^16 * z).
              mstore(add(expmodsAndPoints, 0x460), point)

              // point *= g^3.
              point := mulmod(point, /*traceGenerator^3*/ mload(add(expmodsAndPoints, 0x20)), PRIME)
              // expmods_and_points.points[17] = -(g^19 * z).
              mstore(add(expmodsAndPoints, 0x480), point)

              // point *= g^2.
              point := mulmod(point, /*traceGenerator^2*/ mload(expmodsAndPoints), PRIME)
              // expmods_and_points.points[18] = -(g^21 * z).
              mstore(add(expmodsAndPoints, 0x4a0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[19] = -(g^22 * z).
              mstore(add(expmodsAndPoints, 0x4c0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[20] = -(g^23 * z).
              mstore(add(expmodsAndPoints, 0x4e0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[21] = -(g^24 * z).
              mstore(add(expmodsAndPoints, 0x500), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[22] = -(g^25 * z).
              mstore(add(expmodsAndPoints, 0x520), point)

              // point *= g^3.
              point := mulmod(point, /*traceGenerator^3*/ mload(add(expmodsAndPoints, 0x20)), PRIME)
              // expmods_and_points.points[23] = -(g^28 * z).
              mstore(add(expmodsAndPoints, 0x540), point)

              // point *= g^2.
              point := mulmod(point, /*traceGenerator^2*/ mload(expmodsAndPoints), PRIME)
              // expmods_and_points.points[24] = -(g^30 * z).
              mstore(add(expmodsAndPoints, 0x560), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[25] = -(g^31 * z).
              mstore(add(expmodsAndPoints, 0x580), point)

              // point *= g^7.
              point := mulmod(point, /*traceGenerator^7*/ mload(add(expmodsAndPoints, 0x80)), PRIME)
              // expmods_and_points.points[26] = -(g^38 * z).
              mstore(add(expmodsAndPoints, 0x5a0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[27] = -(g^39 * z).
              mstore(add(expmodsAndPoints, 0x5c0), point)

              // point *= g^5.
              point := mulmod(point, /*traceGenerator^5*/ mload(add(expmodsAndPoints, 0x60)), PRIME)
              // expmods_and_points.points[28] = -(g^44 * z).
              mstore(add(expmodsAndPoints, 0x5e0), point)

              // point *= g^11.
              point := mulmod(point, /*traceGenerator^11*/ mload(add(expmodsAndPoints, 0x100)), PRIME)
              // expmods_and_points.points[29] = -(g^55 * z).
              mstore(add(expmodsAndPoints, 0x600), point)

              // point *= g^5.
              point := mulmod(point, /*traceGenerator^5*/ mload(add(expmodsAndPoints, 0x60)), PRIME)
              // expmods_and_points.points[30] = -(g^60 * z).
              mstore(add(expmodsAndPoints, 0x620), point)

              // point *= g^3.
              point := mulmod(point, /*traceGenerator^3*/ mload(add(expmodsAndPoints, 0x20)), PRIME)
              // expmods_and_points.points[31] = -(g^63 * z).
              mstore(add(expmodsAndPoints, 0x640), point)

              // point *= g^7.
              point := mulmod(point, /*traceGenerator^7*/ mload(add(expmodsAndPoints, 0x80)), PRIME)
              // expmods_and_points.points[32] = -(g^70 * z).
              mstore(add(expmodsAndPoints, 0x660), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[33] = -(g^71 * z).
              mstore(add(expmodsAndPoints, 0x680), point)

              // point *= g^5.
              point := mulmod(point, /*traceGenerator^5*/ mload(add(expmodsAndPoints, 0x60)), PRIME)
              // expmods_and_points.points[34] = -(g^76 * z).
              mstore(add(expmodsAndPoints, 0x6a0), point)

              // point *= g^10.
              point := mulmod(point, /*traceGenerator^10*/ mload(add(expmodsAndPoints, 0xe0)), PRIME)
              // expmods_and_points.points[35] = -(g^86 * z).
              mstore(add(expmodsAndPoints, 0x6c0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[36] = -(g^87 * z).
              mstore(add(expmodsAndPoints, 0x6e0), point)

              // point *= g^5.
              point := mulmod(point, /*traceGenerator^5*/ mload(add(expmodsAndPoints, 0x60)), PRIME)
              // expmods_and_points.points[37] = -(g^92 * z).
              mstore(add(expmodsAndPoints, 0x700), point)

              // point *= g^10.
              point := mulmod(point, /*traceGenerator^10*/ mload(add(expmodsAndPoints, 0xe0)), PRIME)
              // expmods_and_points.points[38] = -(g^102 * z).
              mstore(add(expmodsAndPoints, 0x720), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[39] = -(g^103 * z).
              mstore(add(expmodsAndPoints, 0x740), point)

              // point *= g^5.
              point := mulmod(point, /*traceGenerator^5*/ mload(add(expmodsAndPoints, 0x60)), PRIME)
              // expmods_and_points.points[40] = -(g^108 * z).
              mstore(add(expmodsAndPoints, 0x760), point)

              // point *= g^16.
              point := mulmod(point, /*traceGenerator^16*/ mload(add(expmodsAndPoints, 0x140)), PRIME)
              // expmods_and_points.points[41] = -(g^124 * z).
              mstore(add(expmodsAndPoints, 0x780), point)

              // point *= g^10.
              point := mulmod(point, /*traceGenerator^10*/ mload(add(expmodsAndPoints, 0xe0)), PRIME)
              // expmods_and_points.points[42] = -(g^134 * z).
              mstore(add(expmodsAndPoints, 0x7a0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[43] = -(g^135 * z).
              mstore(add(expmodsAndPoints, 0x7c0), point)

              // point *= g^15.
              point := mulmod(point, /*traceGenerator^15*/ mload(add(expmodsAndPoints, 0x120)), PRIME)
              // expmods_and_points.points[44] = -(g^150 * z).
              mstore(add(expmodsAndPoints, 0x7e0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[45] = -(g^151 * z).
              mstore(add(expmodsAndPoints, 0x800), point)

              // point *= g^16.
              point := mulmod(point, /*traceGenerator^16*/ mload(add(expmodsAndPoints, 0x140)), PRIME)
              // expmods_and_points.points[46] = -(g^167 * z).
              mstore(add(expmodsAndPoints, 0x820), point)

              // point *= g^32.
              point := mulmod(point, /*traceGenerator^32*/ mload(add(expmodsAndPoints, 0x1c0)), PRIME)
              // expmods_and_points.points[47] = -(g^199 * z).
              mstore(add(expmodsAndPoints, 0x840), point)

              // point *= g^31.
              point := mulmod(point, /*traceGenerator^31*/ mload(add(expmodsAndPoints, 0x1a0)), PRIME)
              // expmods_and_points.points[48] = -(g^230 * z).
              mstore(add(expmodsAndPoints, 0x860), point)

              // point *= g^25.
              point := mulmod(point, /*traceGenerator^25*/ mload(add(expmodsAndPoints, 0x180)), PRIME)
              // expmods_and_points.points[49] = -(g^255 * z).
              mstore(add(expmodsAndPoints, 0x880), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[50] = -(g^256 * z).
              mstore(add(expmodsAndPoints, 0x8a0), point)

              // point *= g^7.
              point := mulmod(point, /*traceGenerator^7*/ mload(add(expmodsAndPoints, 0x80)), PRIME)
              // expmods_and_points.points[51] = -(g^263 * z).
              mstore(add(expmodsAndPoints, 0x8c0), point)

              // point *= g^32.
              point := mulmod(point, /*traceGenerator^32*/ mload(add(expmodsAndPoints, 0x1c0)), PRIME)
              // expmods_and_points.points[52] = -(g^295 * z).
              mstore(add(expmodsAndPoints, 0x8e0), point)

              // point *= g^32.
              point := mulmod(point, /*traceGenerator^32*/ mload(add(expmodsAndPoints, 0x1c0)), PRIME)
              // expmods_and_points.points[53] = -(g^327 * z).
              mstore(add(expmodsAndPoints, 0x900), point)

              // point *= g^64.
              point := mulmod(point, /*traceGenerator^64*/ mload(add(expmodsAndPoints, 0x200)), PRIME)
              // expmods_and_points.points[54] = -(g^391 * z).
              mstore(add(expmodsAndPoints, 0x920), point)

              // point *= g^15.
              point := mulmod(point, /*traceGenerator^15*/ mload(add(expmodsAndPoints, 0x120)), PRIME)
              // expmods_and_points.points[55] = -(g^406 * z).
              mstore(add(expmodsAndPoints, 0x940), point)

              // point *= g^17.
              point := mulmod(point, /*traceGenerator^17*/ mload(add(expmodsAndPoints, 0x160)), PRIME)
              // expmods_and_points.points[56] = -(g^423 * z).
              mstore(add(expmodsAndPoints, 0x960), point)

              // point *= g^32.
              point := mulmod(point, /*traceGenerator^32*/ mload(add(expmodsAndPoints, 0x1c0)), PRIME)
              // expmods_and_points.points[57] = -(g^455 * z).
              mstore(add(expmodsAndPoints, 0x980), point)

              // point *= g^56.
              point := mulmod(point, /*traceGenerator^56*/ mload(add(expmodsAndPoints, 0x1e0)), PRIME)
              // expmods_and_points.points[58] = -(g^511 * z).
              mstore(add(expmodsAndPoints, 0x9a0), point)

              // point *= g^3570.
              point := mulmod(point, /*traceGenerator^3570*/ mload(add(expmodsAndPoints, 0x220)), PRIME)
              // expmods_and_points.points[59] = -(g^4081 * z).
              mstore(add(expmodsAndPoints, 0x9c0), point)

              // point *= g^4.
              point := mulmod(point, /*traceGenerator^4*/ mload(add(expmodsAndPoints, 0x40)), PRIME)
              // expmods_and_points.points[60] = -(g^4085 * z).
              mstore(add(expmodsAndPoints, 0x9e0), point)

              // point *= g^4.
              point := mulmod(point, /*traceGenerator^4*/ mload(add(expmodsAndPoints, 0x40)), PRIME)
              // expmods_and_points.points[61] = -(g^4089 * z).
              mstore(add(expmodsAndPoints, 0xa00), point)

              // point *= g^2.
              point := mulmod(point, /*traceGenerator^2*/ mload(expmodsAndPoints), PRIME)
              // expmods_and_points.points[62] = -(g^4091 * z).
              mstore(add(expmodsAndPoints, 0xa20), point)

              // point *= g^2.
              point := mulmod(point, /*traceGenerator^2*/ mload(expmodsAndPoints), PRIME)
              // expmods_and_points.points[63] = -(g^4093 * z).
              mstore(add(expmodsAndPoints, 0xa40), point)

              // point *= g^9.
              point := mulmod(point, /*traceGenerator^9*/ mload(add(expmodsAndPoints, 0xc0)), PRIME)
              // expmods_and_points.points[64] = -(g^4102 * z).
              mstore(add(expmodsAndPoints, 0xa60), point)

              // point *= g^8.
              point := mulmod(point, /*traceGenerator^8*/ mload(add(expmodsAndPoints, 0xa0)), PRIME)
              // expmods_and_points.points[65] = -(g^4110 * z).
              mstore(add(expmodsAndPoints, 0xa80), point)

              // point *= g^8.
              point := mulmod(point, /*traceGenerator^8*/ mload(add(expmodsAndPoints, 0xa0)), PRIME)
              // expmods_and_points.points[66] = -(g^4118 * z).
              mstore(add(expmodsAndPoints, 0xaa0), point)

              // point *= g.
              point := mulmod(point, traceGenerator, PRIME)
              // expmods_and_points.points[67] = -(g^4119 * z).
              mstore(add(expmodsAndPoints, 0xac0), point)

              // point *= g^4041.
              point := mulmod(point, /*traceGenerator^4041*/ mload(add(expmodsAndPoints, 0x240)), PRIME)
              // expmods_and_points.points[68] = -(g^8160 * z).
              mstore(add(expmodsAndPoints, 0xae0), point)

              // point *= g^7.
              point := mulmod(point, /*traceGenerator^7*/ mload(add(expmodsAndPoints, 0x80)), PRIME)
              // expmods_and_points.points[69] = -(g^8167 * z).
              mstore(add(expmodsAndPoints, 0xb00), point)

              // point *= g^8.
              point := mulmod(point, /*traceGenerator^8*/ mload(add(expmodsAndPoints, 0xa0)), PRIME)
              // expmods_and_points.points[70] = -(g^8175 * z).
              mstore(add(expmodsAndPoints, 0xb20), point)

              // point *= g^2.
              point := mulmod(point, /*traceGenerator^2*/ mload(expmodsAndPoints), PRIME)
              // expmods_and_points.points[71] = -(g^8177 * z).
              mstore(add(expmodsAndPoints, 0xb40), point)

              // point *= g^4.
              point := mulmod(point, /*traceGenerator^4*/ mload(add(expmodsAndPoints, 0x40)), PRIME)
              // expmods_and_points.points[72] = -(g^8181 * z).
              mstore(add(expmodsAndPoints, 0xb60), point)

              // point *= g^2.
              point := mulmod(point, /*traceGenerator^2*/ mload(expmodsAndPoints), PRIME)
              // expmods_and_points.points[73] = -(g^8183 * z).
              mstore(add(expmodsAndPoints, 0xb80), point)

              // point *= g^2.
              point := mulmod(point, /*traceGenerator^2*/ mload(expmodsAndPoints), PRIME)
              // expmods_and_points.points[74] = -(g^8185 * z).
              mstore(add(expmodsAndPoints, 0xba0), point)

              // point *= g^4.
              point := mulmod(point, /*traceGenerator^4*/ mload(add(expmodsAndPoints, 0x40)), PRIME)
              // expmods_and_points.points[75] = -(g^8189 * z).
              mstore(add(expmodsAndPoints, 0xbc0), point)

              // point *= g^25.
              point := mulmod(point, /*traceGenerator^25*/ mload(add(expmodsAndPoints, 0x180)), PRIME)
              // expmods_and_points.points[76] = -(g^8214 * z).
              mstore(add(expmodsAndPoints, 0xbe0), point)
            }


            let evalPointsPtr := /*oodsEvalPoints*/ add(context, 0x6740)
            let evalPointsEndPtr := add(evalPointsPtr,
                                           mul(/*n_unique_queries*/ mload(add(context, 0x140)), 0x20))
            let productsPtr := add(batchInverseArray, 0x20)
            let valuesPtr := add(add(batchInverseArray, 0x20), 0x1da00)
            let partialProduct := 1
            let minusPointPow := sub(PRIME, mulmod(oodsPoint, oodsPoint, PRIME))
            for {} lt(evalPointsPtr, evalPointsEndPtr)
                     {evalPointsPtr := add(evalPointsPtr, 0x20)} {
                let evalPoint := mload(evalPointsPtr)

                // Shift evalPoint to evaluation domain coset.
                let shiftedEvalPoint := mulmod(evalPoint, evalCosetOffset_, PRIME)

                {
                // Calculate denominator for row 0: x - z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x260)))
                mstore(productsPtr, partialProduct)
                mstore(valuesPtr, denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 1: x - g * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x280)))
                mstore(add(productsPtr, 0x20), partialProduct)
                mstore(add(valuesPtr, 0x20), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 2: x - g^2 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x2a0)))
                mstore(add(productsPtr, 0x40), partialProduct)
                mstore(add(valuesPtr, 0x40), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 3: x - g^3 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x2c0)))
                mstore(add(productsPtr, 0x60), partialProduct)
                mstore(add(valuesPtr, 0x60), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4: x - g^4 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x2e0)))
                mstore(add(productsPtr, 0x80), partialProduct)
                mstore(add(valuesPtr, 0x80), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 5: x - g^5 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x300)))
                mstore(add(productsPtr, 0xa0), partialProduct)
                mstore(add(valuesPtr, 0xa0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 6: x - g^6 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x320)))
                mstore(add(productsPtr, 0xc0), partialProduct)
                mstore(add(valuesPtr, 0xc0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 7: x - g^7 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x340)))
                mstore(add(productsPtr, 0xe0), partialProduct)
                mstore(add(valuesPtr, 0xe0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8: x - g^8 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x360)))
                mstore(add(productsPtr, 0x100), partialProduct)
                mstore(add(valuesPtr, 0x100), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 9: x - g^9 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x380)))
                mstore(add(productsPtr, 0x120), partialProduct)
                mstore(add(valuesPtr, 0x120), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 10: x - g^10 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x3a0)))
                mstore(add(productsPtr, 0x140), partialProduct)
                mstore(add(valuesPtr, 0x140), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 11: x - g^11 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x3c0)))
                mstore(add(productsPtr, 0x160), partialProduct)
                mstore(add(valuesPtr, 0x160), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 12: x - g^12 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x3e0)))
                mstore(add(productsPtr, 0x180), partialProduct)
                mstore(add(valuesPtr, 0x180), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 13: x - g^13 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x400)))
                mstore(add(productsPtr, 0x1a0), partialProduct)
                mstore(add(valuesPtr, 0x1a0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 14: x - g^14 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x420)))
                mstore(add(productsPtr, 0x1c0), partialProduct)
                mstore(add(valuesPtr, 0x1c0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 15: x - g^15 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x440)))
                mstore(add(productsPtr, 0x1e0), partialProduct)
                mstore(add(valuesPtr, 0x1e0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 16: x - g^16 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x460)))
                mstore(add(productsPtr, 0x200), partialProduct)
                mstore(add(valuesPtr, 0x200), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 19: x - g^19 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x480)))
                mstore(add(productsPtr, 0x220), partialProduct)
                mstore(add(valuesPtr, 0x220), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 21: x - g^21 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x4a0)))
                mstore(add(productsPtr, 0x240), partialProduct)
                mstore(add(valuesPtr, 0x240), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 22: x - g^22 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x4c0)))
                mstore(add(productsPtr, 0x260), partialProduct)
                mstore(add(valuesPtr, 0x260), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 23: x - g^23 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x4e0)))
                mstore(add(productsPtr, 0x280), partialProduct)
                mstore(add(valuesPtr, 0x280), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 24: x - g^24 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x500)))
                mstore(add(productsPtr, 0x2a0), partialProduct)
                mstore(add(valuesPtr, 0x2a0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 25: x - g^25 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x520)))
                mstore(add(productsPtr, 0x2c0), partialProduct)
                mstore(add(valuesPtr, 0x2c0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 28: x - g^28 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x540)))
                mstore(add(productsPtr, 0x2e0), partialProduct)
                mstore(add(valuesPtr, 0x2e0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 30: x - g^30 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x560)))
                mstore(add(productsPtr, 0x300), partialProduct)
                mstore(add(valuesPtr, 0x300), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 31: x - g^31 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x580)))
                mstore(add(productsPtr, 0x320), partialProduct)
                mstore(add(valuesPtr, 0x320), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 38: x - g^38 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x5a0)))
                mstore(add(productsPtr, 0x340), partialProduct)
                mstore(add(valuesPtr, 0x340), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 39: x - g^39 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x5c0)))
                mstore(add(productsPtr, 0x360), partialProduct)
                mstore(add(valuesPtr, 0x360), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 44: x - g^44 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x5e0)))
                mstore(add(productsPtr, 0x380), partialProduct)
                mstore(add(valuesPtr, 0x380), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 55: x - g^55 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x600)))
                mstore(add(productsPtr, 0x3a0), partialProduct)
                mstore(add(valuesPtr, 0x3a0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 60: x - g^60 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x620)))
                mstore(add(productsPtr, 0x3c0), partialProduct)
                mstore(add(valuesPtr, 0x3c0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 63: x - g^63 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x640)))
                mstore(add(productsPtr, 0x3e0), partialProduct)
                mstore(add(valuesPtr, 0x3e0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 70: x - g^70 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x660)))
                mstore(add(productsPtr, 0x400), partialProduct)
                mstore(add(valuesPtr, 0x400), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 71: x - g^71 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x680)))
                mstore(add(productsPtr, 0x420), partialProduct)
                mstore(add(valuesPtr, 0x420), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 76: x - g^76 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x6a0)))
                mstore(add(productsPtr, 0x440), partialProduct)
                mstore(add(valuesPtr, 0x440), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 86: x - g^86 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x6c0)))
                mstore(add(productsPtr, 0x460), partialProduct)
                mstore(add(valuesPtr, 0x460), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 87: x - g^87 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x6e0)))
                mstore(add(productsPtr, 0x480), partialProduct)
                mstore(add(valuesPtr, 0x480), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 92: x - g^92 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x700)))
                mstore(add(productsPtr, 0x4a0), partialProduct)
                mstore(add(valuesPtr, 0x4a0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 102: x - g^102 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x720)))
                mstore(add(productsPtr, 0x4c0), partialProduct)
                mstore(add(valuesPtr, 0x4c0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 103: x - g^103 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x740)))
                mstore(add(productsPtr, 0x4e0), partialProduct)
                mstore(add(valuesPtr, 0x4e0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 108: x - g^108 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x760)))
                mstore(add(productsPtr, 0x500), partialProduct)
                mstore(add(valuesPtr, 0x500), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 124: x - g^124 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x780)))
                mstore(add(productsPtr, 0x520), partialProduct)
                mstore(add(valuesPtr, 0x520), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 134: x - g^134 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x7a0)))
                mstore(add(productsPtr, 0x540), partialProduct)
                mstore(add(valuesPtr, 0x540), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 135: x - g^135 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x7c0)))
                mstore(add(productsPtr, 0x560), partialProduct)
                mstore(add(valuesPtr, 0x560), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 150: x - g^150 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x7e0)))
                mstore(add(productsPtr, 0x580), partialProduct)
                mstore(add(valuesPtr, 0x580), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 151: x - g^151 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x800)))
                mstore(add(productsPtr, 0x5a0), partialProduct)
                mstore(add(valuesPtr, 0x5a0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 167: x - g^167 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x820)))
                mstore(add(productsPtr, 0x5c0), partialProduct)
                mstore(add(valuesPtr, 0x5c0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 199: x - g^199 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x840)))
                mstore(add(productsPtr, 0x5e0), partialProduct)
                mstore(add(valuesPtr, 0x5e0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 230: x - g^230 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x860)))
                mstore(add(productsPtr, 0x600), partialProduct)
                mstore(add(valuesPtr, 0x600), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 255: x - g^255 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x880)))
                mstore(add(productsPtr, 0x620), partialProduct)
                mstore(add(valuesPtr, 0x620), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 256: x - g^256 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x8a0)))
                mstore(add(productsPtr, 0x640), partialProduct)
                mstore(add(valuesPtr, 0x640), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 263: x - g^263 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x8c0)))
                mstore(add(productsPtr, 0x660), partialProduct)
                mstore(add(valuesPtr, 0x660), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 295: x - g^295 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x8e0)))
                mstore(add(productsPtr, 0x680), partialProduct)
                mstore(add(valuesPtr, 0x680), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 327: x - g^327 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x900)))
                mstore(add(productsPtr, 0x6a0), partialProduct)
                mstore(add(valuesPtr, 0x6a0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 391: x - g^391 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x920)))
                mstore(add(productsPtr, 0x6c0), partialProduct)
                mstore(add(valuesPtr, 0x6c0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 406: x - g^406 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x940)))
                mstore(add(productsPtr, 0x6e0), partialProduct)
                mstore(add(valuesPtr, 0x6e0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 423: x - g^423 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x960)))
                mstore(add(productsPtr, 0x700), partialProduct)
                mstore(add(valuesPtr, 0x700), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 455: x - g^455 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x980)))
                mstore(add(productsPtr, 0x720), partialProduct)
                mstore(add(valuesPtr, 0x720), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 511: x - g^511 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x9a0)))
                mstore(add(productsPtr, 0x740), partialProduct)
                mstore(add(valuesPtr, 0x740), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4081: x - g^4081 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x9c0)))
                mstore(add(productsPtr, 0x760), partialProduct)
                mstore(add(valuesPtr, 0x760), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4085: x - g^4085 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0x9e0)))
                mstore(add(productsPtr, 0x780), partialProduct)
                mstore(add(valuesPtr, 0x780), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4089: x - g^4089 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xa00)))
                mstore(add(productsPtr, 0x7a0), partialProduct)
                mstore(add(valuesPtr, 0x7a0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4091: x - g^4091 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xa20)))
                mstore(add(productsPtr, 0x7c0), partialProduct)
                mstore(add(valuesPtr, 0x7c0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4093: x - g^4093 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xa40)))
                mstore(add(productsPtr, 0x7e0), partialProduct)
                mstore(add(valuesPtr, 0x7e0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4102: x - g^4102 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xa60)))
                mstore(add(productsPtr, 0x800), partialProduct)
                mstore(add(valuesPtr, 0x800), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4110: x - g^4110 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xa80)))
                mstore(add(productsPtr, 0x820), partialProduct)
                mstore(add(valuesPtr, 0x820), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4118: x - g^4118 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xaa0)))
                mstore(add(productsPtr, 0x840), partialProduct)
                mstore(add(valuesPtr, 0x840), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 4119: x - g^4119 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xac0)))
                mstore(add(productsPtr, 0x860), partialProduct)
                mstore(add(valuesPtr, 0x860), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8160: x - g^8160 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xae0)))
                mstore(add(productsPtr, 0x880), partialProduct)
                mstore(add(valuesPtr, 0x880), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8167: x - g^8167 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xb00)))
                mstore(add(productsPtr, 0x8a0), partialProduct)
                mstore(add(valuesPtr, 0x8a0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8175: x - g^8175 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xb20)))
                mstore(add(productsPtr, 0x8c0), partialProduct)
                mstore(add(valuesPtr, 0x8c0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8177: x - g^8177 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xb40)))
                mstore(add(productsPtr, 0x8e0), partialProduct)
                mstore(add(valuesPtr, 0x8e0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8181: x - g^8181 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xb60)))
                mstore(add(productsPtr, 0x900), partialProduct)
                mstore(add(valuesPtr, 0x900), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8183: x - g^8183 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xb80)))
                mstore(add(productsPtr, 0x920), partialProduct)
                mstore(add(valuesPtr, 0x920), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8185: x - g^8185 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xba0)))
                mstore(add(productsPtr, 0x940), partialProduct)
                mstore(add(valuesPtr, 0x940), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8189: x - g^8189 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xbc0)))
                mstore(add(productsPtr, 0x960), partialProduct)
                mstore(add(valuesPtr, 0x960), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate denominator for row 8214: x - g^8214 * z.
                let denominator := add(shiftedEvalPoint, mload(add(expmodsAndPoints, 0xbe0)))
                mstore(add(productsPtr, 0x980), partialProduct)
                mstore(add(valuesPtr, 0x980), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                {
                // Calculate the denominator for the composition polynomial columns: x - z^2.
                let denominator := add(shiftedEvalPoint, minusPointPow)
                mstore(add(productsPtr, 0x9a0), partialProduct)
                mstore(add(valuesPtr, 0x9a0), denominator)
                partialProduct := mulmod(partialProduct, denominator, PRIME)
                }

                // Add evalPoint to batch inverse inputs.
                // inverse(evalPoint) is going to be used by FRI.
                mstore(add(productsPtr, 0x9c0), partialProduct)
                mstore(add(valuesPtr, 0x9c0), evalPoint)
                partialProduct := mulmod(partialProduct, evalPoint, PRIME)

                // Advance pointers.
                productsPtr := add(productsPtr, 0x9e0)
                valuesPtr := add(valuesPtr, 0x9e0)
            }

            let productsToValuesOffset := 0x1da00
            let firstPartialProductPtr := add(batchInverseArray, 0x20)
            // Compute the inverse of the product.
            let prodInv := expmod(partialProduct, sub(PRIME, 2), PRIME)

            if eq(prodInv, 0) {
                // Solidity generates reverts with reason that look as follows:
                // 1. 4 bytes with the constant 0x08c379a0 (== Keccak256(b'Error(string)')[:4]).
                // 2. 32 bytes offset bytes (always 0x20 as far as i can tell).
                // 3. 32 bytes with the length of the revert reason.
                // 4. Revert reason string.

                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x4, 0x20)
                mstore(0x24, 0x1e)
                mstore(0x44, "Batch inverse product is zero.")
                revert(0, 0x62)
            }

            // Compute the inverses.
            // Loop over denominator_invs in reverse order.
            // currentPartialProductPtr is initialized to one past the end.
            let currentPartialProductPtr := productsPtr
            // Loop in blocks of size 8 as much as possible: we can loop over a full block as long as
            // currentPartialProductPtr >= firstPartialProductPtr + 8*0x20, or equivalently,
            // currentPartialProductPtr > firstPartialProductPtr + 7*0x20.
            // We use the latter comparison since there is no >= evm opcode.
            let midPartialProductPtr := add(firstPartialProductPtr, 0xe0)
            for { } gt(currentPartialProductPtr, midPartialProductPtr) { } {
                currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                mstore(currentPartialProductPtr,
                       mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                prodInv := mulmod(prodInv,
                                   mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                   PRIME)

                currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                mstore(currentPartialProductPtr,
                       mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                prodInv := mulmod(prodInv,
                                   mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                   PRIME)

                currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                mstore(currentPartialProductPtr,
                       mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                prodInv := mulmod(prodInv,
                                   mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                   PRIME)

                currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                mstore(currentPartialProductPtr,
                       mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                prodInv := mulmod(prodInv,
                                   mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                   PRIME)

                currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                mstore(currentPartialProductPtr,
                       mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                prodInv := mulmod(prodInv,
                                   mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                   PRIME)

                currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                mstore(currentPartialProductPtr,
                       mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                prodInv := mulmod(prodInv,
                                   mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                   PRIME)

                currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                mstore(currentPartialProductPtr,
                       mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                prodInv := mulmod(prodInv,
                                   mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                   PRIME)

                currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                mstore(currentPartialProductPtr,
                       mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                prodInv := mulmod(prodInv,
                                   mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                   PRIME)
            }

            // Loop over the remainder.
            for { } gt(currentPartialProductPtr, firstPartialProductPtr) { } {
                currentPartialProductPtr := sub(currentPartialProductPtr, 0x20)
                // Store 1/d_{i} = (d_0 * ... * d_{i-1}) * 1/(d_0 * ... * d_{i}).
                mstore(currentPartialProductPtr,
                       mulmod(mload(currentPartialProductPtr), prodInv, PRIME))
                // Update prodInv to be 1/(d_0 * ... * d_{i-1}) by multiplying by d_i.
                prodInv := mulmod(prodInv,
                                   mload(add(currentPartialProductPtr, productsToValuesOffset)),
                                   PRIME)
            }
        }
    }
}
// ---------- End of auto-generated code. ----------
