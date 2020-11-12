// ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------
pragma solidity ^0.5.2;

contract MimcConstraintPoly {
    // The Memory map during the execution of this contract is as follows:
    // [0x0, 0x20) - periodic_column/consts0_a.
    // [0x20, 0x40) - periodic_column/consts1_a.
    // [0x40, 0x60) - periodic_column/consts2_a.
    // [0x60, 0x80) - periodic_column/consts3_a.
    // [0x80, 0xa0) - periodic_column/consts4_a.
    // [0xa0, 0xc0) - periodic_column/consts5_a.
    // [0xc0, 0xe0) - periodic_column/consts6_a.
    // [0xe0, 0x100) - periodic_column/consts7_a.
    // [0x100, 0x120) - periodic_column/consts8_a.
    // [0x120, 0x140) - periodic_column/consts9_a.
    // [0x140, 0x160) - periodic_column/consts0_b.
    // [0x160, 0x180) - periodic_column/consts1_b.
    // [0x180, 0x1a0) - periodic_column/consts2_b.
    // [0x1a0, 0x1c0) - periodic_column/consts3_b.
    // [0x1c0, 0x1e0) - periodic_column/consts4_b.
    // [0x1e0, 0x200) - periodic_column/consts5_b.
    // [0x200, 0x220) - periodic_column/consts6_b.
    // [0x220, 0x240) - periodic_column/consts7_b.
    // [0x240, 0x260) - periodic_column/consts8_b.
    // [0x260, 0x280) - periodic_column/consts9_b.
    // [0x280, 0x2a0) - mat00.
    // [0x2a0, 0x2c0) - mat01.
    // [0x2c0, 0x2e0) - trace_length.
    // [0x2e0, 0x300) - mat10.
    // [0x300, 0x320) - mat11.
    // [0x320, 0x340) - input_value_a.
    // [0x340, 0x360) - output_value_a.
    // [0x360, 0x380) - input_value_b.
    // [0x380, 0x3a0) - output_value_b.
    // [0x3a0, 0x3c0) - trace_generator.
    // [0x3c0, 0x3e0) - oods_point.
    // [0x3e0, 0x9e0) - coefficients.
    // [0x9e0, 0xca0) - oods_values.
    // ----------------------- end of input data - -------------------------
    // [0xca0, 0xcc0) - composition_degree_bound.
    // [0xcc0, 0xce0) - intermediate_value/after_lin_transform0_a_0.
    // [0xce0, 0xd00) - intermediate_value/after_lin_transform0_b_0.
    // [0xd00, 0xd20) - intermediate_value/after_lin_transform1_a_0.
    // [0xd20, 0xd40) - intermediate_value/after_lin_transform1_b_0.
    // [0xd40, 0xd60) - intermediate_value/after_lin_transform2_a_0.
    // [0xd60, 0xd80) - intermediate_value/after_lin_transform2_b_0.
    // [0xd80, 0xda0) - intermediate_value/after_lin_transform3_a_0.
    // [0xda0, 0xdc0) - intermediate_value/after_lin_transform3_b_0.
    // [0xdc0, 0xde0) - intermediate_value/after_lin_transform4_a_0.
    // [0xde0, 0xe00) - intermediate_value/after_lin_transform4_b_0.
    // [0xe00, 0xe20) - intermediate_value/after_lin_transform5_a_0.
    // [0xe20, 0xe40) - intermediate_value/after_lin_transform5_b_0.
    // [0xe40, 0xe60) - intermediate_value/after_lin_transform6_a_0.
    // [0xe60, 0xe80) - intermediate_value/after_lin_transform6_b_0.
    // [0xe80, 0xea0) - intermediate_value/after_lin_transform7_a_0.
    // [0xea0, 0xec0) - intermediate_value/after_lin_transform7_b_0.
    // [0xec0, 0xee0) - intermediate_value/after_lin_transform8_a_0.
    // [0xee0, 0xf00) - intermediate_value/after_lin_transform8_b_0.
    // [0xf00, 0xf20) - intermediate_value/after_lin_transform9_a_0.
    // [0xf20, 0xf40) - intermediate_value/after_lin_transform9_b_0.
    // [0xf40, 0xf80) - expmods.
    // [0xf80, 0xfe0) - denominator_invs.
    // [0xfe0, 0x1040) - denominators.
    // [0x1040, 0x1060) - numerators.
    // [0x1060, 0x10c0) - adjustments.
    // [0x10c0, 0x1180) - expmod_context.

    function() external {
        uint256 res;
        assembly {
            let PRIME := 0x30000003000000010000000000000001
            // Copy input from calldata to memory.
            calldatacopy(0x0, 0x0, /*Input data size*/ 0xca0)
            let point := /*oods_point*/ mload(0x3c0)
            // Initialize composition_degree_bound to 2 * trace_length.
            mstore(0xca0, mul(2, /*trace_length*/ mload(0x2c0)))
            function expmod(base, exponent, modulus) -> res {
              let p := /*expmod_context*/ 0x10c0
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

            function degreeAdjustment(compositionPolynomialDegreeBound, constraintDegree, numeratorDegree,
                                       denominatorDegree) -> res {
              res := sub(sub(compositionPolynomialDegreeBound, 1),
                         sub(add(constraintDegree, numeratorDegree), denominatorDegree))
            }

            {
              // Prepare expmods for denominators and numerators.

              // expmods[0] = point^trace_length.
              mstore(0xf40, expmod(point, /*trace_length*/ mload(0x2c0), PRIME))

              // expmods[1] = trace_generator^(trace_length - 1).
              mstore(0xf60, expmod(/*trace_generator*/ mload(0x3a0), sub(/*trace_length*/ mload(0x2c0), 1), PRIME))

            }

            {
              // Prepare denominators for batch inverse.

              // Denominator for constraints: 'step0_a', 'step0_b', 'step1_a', 'step1_b', 'step2_a', 'step2_b', 'step3_a', 'step3_b', 'step4_a', 'step4_b', 'step5_a', 'step5_b', 'step6_a', 'step6_b', 'step7_a', 'step7_b', 'step8_a', 'step8_b', 'step9_a', 'step9_b'.
              // denominators[0] = point^trace_length - 1.
              mstore(0xfe0,
                     addmod(/*point^trace_length*/ mload(0xf40), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'input_a', 'input_b'.
              // denominators[1] = point - 1.
              mstore(0x1000,
                     addmod(point, sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'output_a', 'output_b'.
              // denominators[2] = point - trace_generator^(trace_length - 1).
              mstore(0x1020,
                     addmod(point, sub(PRIME, /*trace_generator^(trace_length - 1)*/ mload(0xf60)), PRIME))

            }

            {
              // Compute the inverses of the denominators into denominatorInvs using batch inverse.

              // Start by computing the cumulative product.
              // Let (d_0, d_1, d_2, ..., d_{n-1}) be the values in denominators. After this loop
              // denominatorInvs will be (1, d_0, d_0 * d_1, ...) and prod will contain the value of
              // d_0 * ... * d_{n-1}.
              // Compute the offset between the partialProducts array and the input values array.
              let productsToValuesOffset := 0x60
              let prod := 1
              let partialProductEndPtr := 0xfe0
              for { let partialProductPtr := 0xf80 }
                  lt(partialProductPtr, partialProductEndPtr)
                  { partialProductPtr := add(partialProductPtr, 0x20) } {
                  mstore(partialProductPtr, prod)
                  // prod *= d_{i}.
                  prod := mulmod(prod,
                                 mload(add(partialProductPtr, productsToValuesOffset)),
                                 PRIME)
              }

              let firstPartialProductPtr := 0xf80
              // Compute the inverse of the product.
              let prodInv := expmod(prod, sub(PRIME, 2), PRIME)

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
              let currentPartialProductPtr := 0xfe0
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

            {
              // Compute numerators and adjustment polynomials.

              // Numerator for constraints 'step9_a', 'step9_b'.
              // numerators[0] = point - trace_generator^(trace_length - 1).
              mstore(0x1040,
                     addmod(point, sub(PRIME, /*trace_generator^(trace_length - 1)*/ mload(0xf60)), PRIME))

              // Adjustment polynomial for constraints 'step0_a', 'step0_b', 'step1_a', 'step1_b', 'step2_a', 'step2_b', 'step3_a', 'step3_b', 'step4_a', 'step4_b', 'step5_a', 'step5_b', 'step6_a', 'step6_b', 'step7_a', 'step7_b', 'step8_a', 'step8_b'.
              // adjustments[0] = point^degreeAdjustment(composition_degree_bound, 3 * (trace_length - 1), 0, trace_length).
              mstore(0x1060,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0xca0), mul(3, sub(/*trace_length*/ mload(0x2c0), 1)), 0, /*trace_length*/ mload(0x2c0)), PRIME))

              // Adjustment polynomial for constraints 'step9_a', 'step9_b'.
              // adjustments[1] = point^degreeAdjustment(composition_degree_bound, 3 * (trace_length - 1), 1, trace_length).
              mstore(0x1080,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0xca0), mul(3, sub(/*trace_length*/ mload(0x2c0), 1)), 1, /*trace_length*/ mload(0x2c0)), PRIME))

              // Adjustment polynomial for constraints 'input_a', 'output_a', 'input_b', 'output_b'.
              // adjustments[2] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, 1).
              mstore(0x10a0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0xca0), sub(/*trace_length*/ mload(0x2c0), 1), 0, 1), PRIME))

            }

            {
              // Compute the result of the composition polynomial.

              {
              // after_lin_transform0_a_0 = mat00 * (column0_row0 - consts0_a) + mat01 * (column10_row0 - consts0_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column0_row0*/ mload(0x9e0),
                    sub(PRIME, /*periodic_column/consts0_a*/ mload(0x0)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column10_row0*/ mload(0xb40),
                    sub(PRIME, /*periodic_column/consts0_b*/ mload(0x140)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xcc0, val)
              }


              {
              // after_lin_transform0_b_0 = mat10 * (column0_row0 - consts0_a) + mat11 * (column10_row0 - consts0_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column0_row0*/ mload(0x9e0),
                    sub(PRIME, /*periodic_column/consts0_a*/ mload(0x0)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column10_row0*/ mload(0xb40),
                    sub(PRIME, /*periodic_column/consts0_b*/ mload(0x140)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xce0, val)
              }


              {
              // after_lin_transform1_a_0 = mat00 * (column1_row0 - consts1_a) + mat01 * (column11_row0 - consts1_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column1_row0*/ mload(0xa20),
                    sub(PRIME, /*periodic_column/consts1_a*/ mload(0x20)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column11_row0*/ mload(0xb80),
                    sub(PRIME, /*periodic_column/consts1_b*/ mload(0x160)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xd00, val)
              }


              {
              // after_lin_transform1_b_0 = mat10 * (column1_row0 - consts1_a) + mat11 * (column11_row0 - consts1_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column1_row0*/ mload(0xa20),
                    sub(PRIME, /*periodic_column/consts1_a*/ mload(0x20)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column11_row0*/ mload(0xb80),
                    sub(PRIME, /*periodic_column/consts1_b*/ mload(0x160)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xd20, val)
              }


              {
              // after_lin_transform2_a_0 = mat00 * (column2_row0 - consts2_a) + mat01 * (column12_row0 - consts2_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column2_row0*/ mload(0xa40),
                    sub(PRIME, /*periodic_column/consts2_a*/ mload(0x40)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column12_row0*/ mload(0xba0),
                    sub(PRIME, /*periodic_column/consts2_b*/ mload(0x180)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xd40, val)
              }


              {
              // after_lin_transform2_b_0 = mat10 * (column2_row0 - consts2_a) + mat11 * (column12_row0 - consts2_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column2_row0*/ mload(0xa40),
                    sub(PRIME, /*periodic_column/consts2_a*/ mload(0x40)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column12_row0*/ mload(0xba0),
                    sub(PRIME, /*periodic_column/consts2_b*/ mload(0x180)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xd60, val)
              }


              {
              // after_lin_transform3_a_0 = mat00 * (column3_row0 - consts3_a) + mat01 * (column13_row0 - consts3_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column3_row0*/ mload(0xa60),
                    sub(PRIME, /*periodic_column/consts3_a*/ mload(0x60)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column13_row0*/ mload(0xbc0),
                    sub(PRIME, /*periodic_column/consts3_b*/ mload(0x1a0)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xd80, val)
              }


              {
              // after_lin_transform3_b_0 = mat10 * (column3_row0 - consts3_a) + mat11 * (column13_row0 - consts3_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column3_row0*/ mload(0xa60),
                    sub(PRIME, /*periodic_column/consts3_a*/ mload(0x60)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column13_row0*/ mload(0xbc0),
                    sub(PRIME, /*periodic_column/consts3_b*/ mload(0x1a0)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xda0, val)
              }


              {
              // after_lin_transform4_a_0 = mat00 * (column4_row0 - consts4_a) + mat01 * (column14_row0 - consts4_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column4_row0*/ mload(0xa80),
                    sub(PRIME, /*periodic_column/consts4_a*/ mload(0x80)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column14_row0*/ mload(0xbe0),
                    sub(PRIME, /*periodic_column/consts4_b*/ mload(0x1c0)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xdc0, val)
              }


              {
              // after_lin_transform4_b_0 = mat10 * (column4_row0 - consts4_a) + mat11 * (column14_row0 - consts4_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column4_row0*/ mload(0xa80),
                    sub(PRIME, /*periodic_column/consts4_a*/ mload(0x80)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column14_row0*/ mload(0xbe0),
                    sub(PRIME, /*periodic_column/consts4_b*/ mload(0x1c0)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xde0, val)
              }


              {
              // after_lin_transform5_a_0 = mat00 * (column5_row0 - consts5_a) + mat01 * (column15_row0 - consts5_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column5_row0*/ mload(0xaa0),
                    sub(PRIME, /*periodic_column/consts5_a*/ mload(0xa0)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column15_row0*/ mload(0xc00),
                    sub(PRIME, /*periodic_column/consts5_b*/ mload(0x1e0)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xe00, val)
              }


              {
              // after_lin_transform5_b_0 = mat10 * (column5_row0 - consts5_a) + mat11 * (column15_row0 - consts5_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column5_row0*/ mload(0xaa0),
                    sub(PRIME, /*periodic_column/consts5_a*/ mload(0xa0)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column15_row0*/ mload(0xc00),
                    sub(PRIME, /*periodic_column/consts5_b*/ mload(0x1e0)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xe20, val)
              }


              {
              // after_lin_transform6_a_0 = mat00 * (column6_row0 - consts6_a) + mat01 * (column16_row0 - consts6_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column6_row0*/ mload(0xac0),
                    sub(PRIME, /*periodic_column/consts6_a*/ mload(0xc0)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column16_row0*/ mload(0xc20),
                    sub(PRIME, /*periodic_column/consts6_b*/ mload(0x200)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xe40, val)
              }


              {
              // after_lin_transform6_b_0 = mat10 * (column6_row0 - consts6_a) + mat11 * (column16_row0 - consts6_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column6_row0*/ mload(0xac0),
                    sub(PRIME, /*periodic_column/consts6_a*/ mload(0xc0)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column16_row0*/ mload(0xc20),
                    sub(PRIME, /*periodic_column/consts6_b*/ mload(0x200)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xe60, val)
              }


              {
              // after_lin_transform7_a_0 = mat00 * (column7_row0 - consts7_a) + mat01 * (column17_row0 - consts7_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column7_row0*/ mload(0xae0),
                    sub(PRIME, /*periodic_column/consts7_a*/ mload(0xe0)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column17_row0*/ mload(0xc40),
                    sub(PRIME, /*periodic_column/consts7_b*/ mload(0x220)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xe80, val)
              }


              {
              // after_lin_transform7_b_0 = mat10 * (column7_row0 - consts7_a) + mat11 * (column17_row0 - consts7_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column7_row0*/ mload(0xae0),
                    sub(PRIME, /*periodic_column/consts7_a*/ mload(0xe0)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column17_row0*/ mload(0xc40),
                    sub(PRIME, /*periodic_column/consts7_b*/ mload(0x220)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xea0, val)
              }


              {
              // after_lin_transform8_a_0 = mat00 * (column8_row0 - consts8_a) + mat01 * (column18_row0 - consts8_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column8_row0*/ mload(0xb00),
                    sub(PRIME, /*periodic_column/consts8_a*/ mload(0x100)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column18_row0*/ mload(0xc60),
                    sub(PRIME, /*periodic_column/consts8_b*/ mload(0x240)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xec0, val)
              }


              {
              // after_lin_transform8_b_0 = mat10 * (column8_row0 - consts8_a) + mat11 * (column18_row0 - consts8_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column8_row0*/ mload(0xb00),
                    sub(PRIME, /*periodic_column/consts8_a*/ mload(0x100)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column18_row0*/ mload(0xc60),
                    sub(PRIME, /*periodic_column/consts8_b*/ mload(0x240)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xee0, val)
              }


              {
              // after_lin_transform9_a_0 = mat00 * (column9_row0 - consts9_a) + mat01 * (column19_row0 - consts9_b).
              let val := addmod(
                mulmod(
                  /*mat00*/ mload(0x280),
                  addmod(
                    /*column9_row0*/ mload(0xb20),
                    sub(PRIME, /*periodic_column/consts9_a*/ mload(0x120)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat01*/ mload(0x2a0),
                  addmod(
                    /*column19_row0*/ mload(0xc80),
                    sub(PRIME, /*periodic_column/consts9_b*/ mload(0x260)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xf00, val)
              }


              {
              // after_lin_transform9_b_0 = mat10 * (column9_row0 - consts9_a) + mat11 * (column19_row0 - consts9_b).
              let val := addmod(
                mulmod(
                  /*mat10*/ mload(0x2e0),
                  addmod(
                    /*column9_row0*/ mload(0xb20),
                    sub(PRIME, /*periodic_column/consts9_a*/ mload(0x120)),
                    PRIME),
                  PRIME),
                mulmod(
                  /*mat11*/ mload(0x300),
                  addmod(
                    /*column19_row0*/ mload(0xc80),
                    sub(PRIME, /*periodic_column/consts9_b*/ mload(0x260)),
                    PRIME),
                  PRIME),
                PRIME)
              mstore(0xf20, val)
              }


              {
              // Constraint expression for step0_a: column1_row0 - after_lin_transform0_a_0 * after_lin_transform0_a_0 * after_lin_transform0_a_0.
              let val := addmod(
                /*column1_row0*/ mload(0xa20),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform0_a_0*/ mload(0xcc0),
                      /*intermediate_value/after_lin_transform0_a_0*/ mload(0xcc0),
                      PRIME),
                    /*intermediate_value/after_lin_transform0_a_0*/ mload(0xcc0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[0] + coefficients[1] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[0]*/ mload(0x3e0),
                                       mulmod(/*coefficients[1]*/ mload(0x400),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step0_b: column11_row0 - after_lin_transform0_b_0 * after_lin_transform0_b_0 * after_lin_transform0_b_0.
              let val := addmod(
                /*column11_row0*/ mload(0xb80),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform0_b_0*/ mload(0xce0),
                      /*intermediate_value/after_lin_transform0_b_0*/ mload(0xce0),
                      PRIME),
                    /*intermediate_value/after_lin_transform0_b_0*/ mload(0xce0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[2] + coefficients[3] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[2]*/ mload(0x420),
                                       mulmod(/*coefficients[3]*/ mload(0x440),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step1_a: column2_row0 - after_lin_transform1_a_0 * after_lin_transform1_a_0 * after_lin_transform1_a_0.
              let val := addmod(
                /*column2_row0*/ mload(0xa40),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform1_a_0*/ mload(0xd00),
                      /*intermediate_value/after_lin_transform1_a_0*/ mload(0xd00),
                      PRIME),
                    /*intermediate_value/after_lin_transform1_a_0*/ mload(0xd00),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[4] + coefficients[5] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[4]*/ mload(0x460),
                                       mulmod(/*coefficients[5]*/ mload(0x480),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step1_b: column12_row0 - after_lin_transform1_b_0 * after_lin_transform1_b_0 * after_lin_transform1_b_0.
              let val := addmod(
                /*column12_row0*/ mload(0xba0),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform1_b_0*/ mload(0xd20),
                      /*intermediate_value/after_lin_transform1_b_0*/ mload(0xd20),
                      PRIME),
                    /*intermediate_value/after_lin_transform1_b_0*/ mload(0xd20),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[6] + coefficients[7] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[6]*/ mload(0x4a0),
                                       mulmod(/*coefficients[7]*/ mload(0x4c0),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step2_a: column3_row0 - after_lin_transform2_a_0 * after_lin_transform2_a_0 * after_lin_transform2_a_0.
              let val := addmod(
                /*column3_row0*/ mload(0xa60),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform2_a_0*/ mload(0xd40),
                      /*intermediate_value/after_lin_transform2_a_0*/ mload(0xd40),
                      PRIME),
                    /*intermediate_value/after_lin_transform2_a_0*/ mload(0xd40),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[8] + coefficients[9] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[8]*/ mload(0x4e0),
                                       mulmod(/*coefficients[9]*/ mload(0x500),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step2_b: column13_row0 - after_lin_transform2_b_0 * after_lin_transform2_b_0 * after_lin_transform2_b_0.
              let val := addmod(
                /*column13_row0*/ mload(0xbc0),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform2_b_0*/ mload(0xd60),
                      /*intermediate_value/after_lin_transform2_b_0*/ mload(0xd60),
                      PRIME),
                    /*intermediate_value/after_lin_transform2_b_0*/ mload(0xd60),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[10] + coefficients[11] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[10]*/ mload(0x520),
                                       mulmod(/*coefficients[11]*/ mload(0x540),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step3_a: column4_row0 - after_lin_transform3_a_0 * after_lin_transform3_a_0 * after_lin_transform3_a_0.
              let val := addmod(
                /*column4_row0*/ mload(0xa80),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform3_a_0*/ mload(0xd80),
                      /*intermediate_value/after_lin_transform3_a_0*/ mload(0xd80),
                      PRIME),
                    /*intermediate_value/after_lin_transform3_a_0*/ mload(0xd80),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[12] + coefficients[13] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[12]*/ mload(0x560),
                                       mulmod(/*coefficients[13]*/ mload(0x580),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step3_b: column14_row0 - after_lin_transform3_b_0 * after_lin_transform3_b_0 * after_lin_transform3_b_0.
              let val := addmod(
                /*column14_row0*/ mload(0xbe0),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform3_b_0*/ mload(0xda0),
                      /*intermediate_value/after_lin_transform3_b_0*/ mload(0xda0),
                      PRIME),
                    /*intermediate_value/after_lin_transform3_b_0*/ mload(0xda0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[14] + coefficients[15] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[14]*/ mload(0x5a0),
                                       mulmod(/*coefficients[15]*/ mload(0x5c0),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step4_a: column5_row0 - after_lin_transform4_a_0 * after_lin_transform4_a_0 * after_lin_transform4_a_0.
              let val := addmod(
                /*column5_row0*/ mload(0xaa0),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform4_a_0*/ mload(0xdc0),
                      /*intermediate_value/after_lin_transform4_a_0*/ mload(0xdc0),
                      PRIME),
                    /*intermediate_value/after_lin_transform4_a_0*/ mload(0xdc0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[16] + coefficients[17] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[16]*/ mload(0x5e0),
                                       mulmod(/*coefficients[17]*/ mload(0x600),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step4_b: column15_row0 - after_lin_transform4_b_0 * after_lin_transform4_b_0 * after_lin_transform4_b_0.
              let val := addmod(
                /*column15_row0*/ mload(0xc00),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform4_b_0*/ mload(0xde0),
                      /*intermediate_value/after_lin_transform4_b_0*/ mload(0xde0),
                      PRIME),
                    /*intermediate_value/after_lin_transform4_b_0*/ mload(0xde0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[18] + coefficients[19] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[18]*/ mload(0x620),
                                       mulmod(/*coefficients[19]*/ mload(0x640),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step5_a: column6_row0 - after_lin_transform5_a_0 * after_lin_transform5_a_0 * after_lin_transform5_a_0.
              let val := addmod(
                /*column6_row0*/ mload(0xac0),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform5_a_0*/ mload(0xe00),
                      /*intermediate_value/after_lin_transform5_a_0*/ mload(0xe00),
                      PRIME),
                    /*intermediate_value/after_lin_transform5_a_0*/ mload(0xe00),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[20] + coefficients[21] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[20]*/ mload(0x660),
                                       mulmod(/*coefficients[21]*/ mload(0x680),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step5_b: column16_row0 - after_lin_transform5_b_0 * after_lin_transform5_b_0 * after_lin_transform5_b_0.
              let val := addmod(
                /*column16_row0*/ mload(0xc20),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform5_b_0*/ mload(0xe20),
                      /*intermediate_value/after_lin_transform5_b_0*/ mload(0xe20),
                      PRIME),
                    /*intermediate_value/after_lin_transform5_b_0*/ mload(0xe20),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[22] + coefficients[23] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[22]*/ mload(0x6a0),
                                       mulmod(/*coefficients[23]*/ mload(0x6c0),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step6_a: column7_row0 - after_lin_transform6_a_0 * after_lin_transform6_a_0 * after_lin_transform6_a_0.
              let val := addmod(
                /*column7_row0*/ mload(0xae0),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform6_a_0*/ mload(0xe40),
                      /*intermediate_value/after_lin_transform6_a_0*/ mload(0xe40),
                      PRIME),
                    /*intermediate_value/after_lin_transform6_a_0*/ mload(0xe40),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[24] + coefficients[25] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[24]*/ mload(0x6e0),
                                       mulmod(/*coefficients[25]*/ mload(0x700),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step6_b: column17_row0 - after_lin_transform6_b_0 * after_lin_transform6_b_0 * after_lin_transform6_b_0.
              let val := addmod(
                /*column17_row0*/ mload(0xc40),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform6_b_0*/ mload(0xe60),
                      /*intermediate_value/after_lin_transform6_b_0*/ mload(0xe60),
                      PRIME),
                    /*intermediate_value/after_lin_transform6_b_0*/ mload(0xe60),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[26] + coefficients[27] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[26]*/ mload(0x720),
                                       mulmod(/*coefficients[27]*/ mload(0x740),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step7_a: column8_row0 - after_lin_transform7_a_0 * after_lin_transform7_a_0 * after_lin_transform7_a_0.
              let val := addmod(
                /*column8_row0*/ mload(0xb00),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform7_a_0*/ mload(0xe80),
                      /*intermediate_value/after_lin_transform7_a_0*/ mload(0xe80),
                      PRIME),
                    /*intermediate_value/after_lin_transform7_a_0*/ mload(0xe80),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[28] + coefficients[29] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[28]*/ mload(0x760),
                                       mulmod(/*coefficients[29]*/ mload(0x780),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step7_b: column18_row0 - after_lin_transform7_b_0 * after_lin_transform7_b_0 * after_lin_transform7_b_0.
              let val := addmod(
                /*column18_row0*/ mload(0xc60),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform7_b_0*/ mload(0xea0),
                      /*intermediate_value/after_lin_transform7_b_0*/ mload(0xea0),
                      PRIME),
                    /*intermediate_value/after_lin_transform7_b_0*/ mload(0xea0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[30] + coefficients[31] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[30]*/ mload(0x7a0),
                                       mulmod(/*coefficients[31]*/ mload(0x7c0),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step8_a: column9_row0 - after_lin_transform8_a_0 * after_lin_transform8_a_0 * after_lin_transform8_a_0.
              let val := addmod(
                /*column9_row0*/ mload(0xb20),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform8_a_0*/ mload(0xec0),
                      /*intermediate_value/after_lin_transform8_a_0*/ mload(0xec0),
                      PRIME),
                    /*intermediate_value/after_lin_transform8_a_0*/ mload(0xec0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[32] + coefficients[33] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[32]*/ mload(0x7e0),
                                       mulmod(/*coefficients[33]*/ mload(0x800),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step8_b: column19_row0 - after_lin_transform8_b_0 * after_lin_transform8_b_0 * after_lin_transform8_b_0.
              let val := addmod(
                /*column19_row0*/ mload(0xc80),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform8_b_0*/ mload(0xee0),
                      /*intermediate_value/after_lin_transform8_b_0*/ mload(0xee0),
                      PRIME),
                    /*intermediate_value/after_lin_transform8_b_0*/ mload(0xee0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[34] + coefficients[35] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[34]*/ mload(0x820),
                                       mulmod(/*coefficients[35]*/ mload(0x840),
                                              /*adjustments[0]*/mload(0x1060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step9_a: column0_row1 - after_lin_transform9_a_0 * after_lin_transform9_a_0 * after_lin_transform9_a_0.
              let val := addmod(
                /*column0_row1*/ mload(0xa00),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform9_a_0*/ mload(0xf00),
                      /*intermediate_value/after_lin_transform9_a_0*/ mload(0xf00),
                      PRIME),
                    /*intermediate_value/after_lin_transform9_a_0*/ mload(0xf00),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= numerators[0].
              val := mulmod(val, mload(0x1040), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[36] + coefficients[37] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[36]*/ mload(0x860),
                                       mulmod(/*coefficients[37]*/ mload(0x880),
                                              /*adjustments[1]*/mload(0x1080),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for step9_b: column10_row1 - after_lin_transform9_b_0 * after_lin_transform9_b_0 * after_lin_transform9_b_0.
              let val := addmod(
                /*column10_row1*/ mload(0xb60),
                sub(
                  PRIME,
                  mulmod(
                    mulmod(
                      /*intermediate_value/after_lin_transform9_b_0*/ mload(0xf20),
                      /*intermediate_value/after_lin_transform9_b_0*/ mload(0xf20),
                      PRIME),
                    /*intermediate_value/after_lin_transform9_b_0*/ mload(0xf20),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= numerators[0].
              val := mulmod(val, mload(0x1040), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0xf80), PRIME)

              // res += val * (coefficients[38] + coefficients[39] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[38]*/ mload(0x8a0),
                                       mulmod(/*coefficients[39]*/ mload(0x8c0),
                                              /*adjustments[1]*/mload(0x1080),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for input_a: column0_row0 - input_value_a.
              let val := addmod(/*column0_row0*/ mload(0x9e0), sub(PRIME, /*input_value_a*/ mload(0x320)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[1].
              val := mulmod(val, mload(0xfa0), PRIME)

              // res += val * (coefficients[40] + coefficients[41] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[40]*/ mload(0x8e0),
                                       mulmod(/*coefficients[41]*/ mload(0x900),
                                              /*adjustments[2]*/mload(0x10a0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for output_a: column9_row0 - output_value_a.
              let val := addmod(/*column9_row0*/ mload(0xb20), sub(PRIME, /*output_value_a*/ mload(0x340)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0xfc0), PRIME)

              // res += val * (coefficients[42] + coefficients[43] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[42]*/ mload(0x920),
                                       mulmod(/*coefficients[43]*/ mload(0x940),
                                              /*adjustments[2]*/mload(0x10a0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for input_b: column10_row0 - input_value_b.
              let val := addmod(/*column10_row0*/ mload(0xb40), sub(PRIME, /*input_value_b*/ mload(0x360)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[1].
              val := mulmod(val, mload(0xfa0), PRIME)

              // res += val * (coefficients[44] + coefficients[45] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[44]*/ mload(0x960),
                                       mulmod(/*coefficients[45]*/ mload(0x980),
                                              /*adjustments[2]*/mload(0x10a0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for output_b: column19_row0 - output_value_b.
              let val := addmod(/*column19_row0*/ mload(0xc80), sub(PRIME, /*output_value_b*/ mload(0x380)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0xfc0), PRIME)

              // res += val * (coefficients[46] + coefficients[47] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[46]*/ mload(0x9a0),
                                       mulmod(/*coefficients[47]*/ mload(0x9c0),
                                              /*adjustments[2]*/mload(0x10a0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

            mstore(0, res)
            return(0, 0x20)
            }
        }
    }
}
// ---------- End of auto-generated code. ----------
