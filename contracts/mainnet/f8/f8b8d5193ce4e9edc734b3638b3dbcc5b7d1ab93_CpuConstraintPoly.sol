/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

/*
  Copyright 2019-2021 StarkWare Industries Ltd.

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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

contract CpuConstraintPoly {
    // The Memory map during the execution of this contract is as follows:
    // [0x0, 0x20) - periodic_column/pedersen/points/x.
    // [0x20, 0x40) - periodic_column/pedersen/points/y.
    // [0x40, 0x60) - periodic_column/ecdsa/generator_points/x.
    // [0x60, 0x80) - periodic_column/ecdsa/generator_points/y.
    // [0x80, 0xa0) - trace_length.
    // [0xa0, 0xc0) - offset_size.
    // [0xc0, 0xe0) - half_offset_size.
    // [0xe0, 0x100) - initial_ap.
    // [0x100, 0x120) - initial_pc.
    // [0x120, 0x140) - final_ap.
    // [0x140, 0x160) - final_pc.
    // [0x160, 0x180) - memory/multi_column_perm/perm/interaction_elm.
    // [0x180, 0x1a0) - memory/multi_column_perm/hash_interaction_elm0.
    // [0x1a0, 0x1c0) - memory/multi_column_perm/perm/public_memory_prod.
    // [0x1c0, 0x1e0) - rc16/perm/interaction_elm.
    // [0x1e0, 0x200) - rc16/perm/public_memory_prod.
    // [0x200, 0x220) - rc_min.
    // [0x220, 0x240) - rc_max.
    // [0x240, 0x260) - pedersen/shift_point.x.
    // [0x260, 0x280) - pedersen/shift_point.y.
    // [0x280, 0x2a0) - initial_pedersen_addr.
    // [0x2a0, 0x2c0) - initial_rc_addr.
    // [0x2c0, 0x2e0) - ecdsa/sig_config.alpha.
    // [0x2e0, 0x300) - ecdsa/sig_config.shift_point.x.
    // [0x300, 0x320) - ecdsa/sig_config.shift_point.y.
    // [0x320, 0x340) - ecdsa/sig_config.beta.
    // [0x340, 0x360) - initial_ecdsa_addr.
    // [0x360, 0x380) - initial_checkpoints_addr.
    // [0x380, 0x3a0) - final_checkpoints_addr.
    // [0x3a0, 0x3c0) - trace_generator.
    // [0x3c0, 0x3e0) - oods_point.
    // [0x3e0, 0x440) - interaction_elements.
    // [0x440, 0x2000) - coefficients.
    // [0x2000, 0x30a0) - oods_values.
    // ----------------------- end of input data - -------------------------
    // [0x30a0, 0x30c0) - composition_degree_bound.
    // [0x30c0, 0x30e0) - intermediate_value/cpu/decode/opcode_rc/bit_0.
    // [0x30e0, 0x3100) - intermediate_value/cpu/decode/opcode_rc/bit_1.
    // [0x3100, 0x3120) - intermediate_value/cpu/decode/opcode_rc/bit_2.
    // [0x3120, 0x3140) - intermediate_value/cpu/decode/opcode_rc/bit_4.
    // [0x3140, 0x3160) - intermediate_value/cpu/decode/opcode_rc/bit_3.
    // [0x3160, 0x3180) - intermediate_value/cpu/decode/opcode_rc/bit_9.
    // [0x3180, 0x31a0) - intermediate_value/cpu/decode/opcode_rc/bit_5.
    // [0x31a0, 0x31c0) - intermediate_value/cpu/decode/opcode_rc/bit_6.
    // [0x31c0, 0x31e0) - intermediate_value/cpu/decode/opcode_rc/bit_7.
    // [0x31e0, 0x3200) - intermediate_value/cpu/decode/opcode_rc/bit_8.
    // [0x3200, 0x3220) - intermediate_value/npc_reg_0.
    // [0x3220, 0x3240) - intermediate_value/cpu/decode/opcode_rc/bit_10.
    // [0x3240, 0x3260) - intermediate_value/cpu/decode/opcode_rc/bit_11.
    // [0x3260, 0x3280) - intermediate_value/cpu/decode/opcode_rc/bit_12.
    // [0x3280, 0x32a0) - intermediate_value/cpu/decode/opcode_rc/bit_13.
    // [0x32a0, 0x32c0) - intermediate_value/cpu/decode/opcode_rc/bit_14.
    // [0x32c0, 0x32e0) - intermediate_value/memory/address_diff_0.
    // [0x32e0, 0x3300) - intermediate_value/rc16/diff_0.
    // [0x3300, 0x3320) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_0.
    // [0x3320, 0x3340) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0.
    // [0x3340, 0x3360) - intermediate_value/rc_builtin/value0_0.
    // [0x3360, 0x3380) - intermediate_value/rc_builtin/value1_0.
    // [0x3380, 0x33a0) - intermediate_value/rc_builtin/value2_0.
    // [0x33a0, 0x33c0) - intermediate_value/rc_builtin/value3_0.
    // [0x33c0, 0x33e0) - intermediate_value/rc_builtin/value4_0.
    // [0x33e0, 0x3400) - intermediate_value/rc_builtin/value5_0.
    // [0x3400, 0x3420) - intermediate_value/rc_builtin/value6_0.
    // [0x3420, 0x3440) - intermediate_value/rc_builtin/value7_0.
    // [0x3440, 0x3460) - intermediate_value/ecdsa/signature0/doubling_key/x_squared.
    // [0x3460, 0x3480) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0.
    // [0x3480, 0x34a0) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0.
    // [0x34a0, 0x34c0) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_0.
    // [0x34c0, 0x34e0) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0.
    // [0x34e0, 0x37a0) - expmods.
    // [0x37a0, 0x3a80) - denominator_invs.
    // [0x3a80, 0x3d60) - denominators.
    // [0x3d60, 0x3ec0) - numerators.
    // [0x3ec0, 0x41c0) - adjustments.
    // [0x41c0, 0x4280) - expmod_context.

    fallback() external {
        uint256 res;
        assembly {
            let PRIME := 0x800000000000011000000000000000000000000000000000000000000000001
            // Copy input from calldata to memory.
            calldatacopy(0x0, 0x0, /*Input data size*/ 0x30a0)
            let point := /*oods_point*/ mload(0x3c0)
            // Initialize composition_degree_bound to 2 * trace_length.
            mstore(0x30a0, mul(2, /*trace_length*/ mload(0x80)))
            function expmod(base, exponent, modulus) -> result {
              let p := /*expmod_context*/ 0x41c0
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
              result := mload(p)
            }

            function degreeAdjustment(compositionPolynomialDegreeBound, constraintDegree, numeratorDegree,
                                       denominatorDegree) -> result {
              result := sub(sub(compositionPolynomialDegreeBound, 1),
                         sub(add(constraintDegree, numeratorDegree), denominatorDegree))
            }

            {
              // Prepare expmods for denominators and numerators.

              // expmods[0] = point^trace_length.
              mstore(0x34e0, expmod(point, /*trace_length*/ mload(0x80), PRIME))

              // expmods[1] = point^(trace_length / 16).
              mstore(0x3500, expmod(point, div(/*trace_length*/ mload(0x80), 16), PRIME))

              // expmods[2] = point^(trace_length / 2).
              mstore(0x3520, expmod(point, div(/*trace_length*/ mload(0x80), 2), PRIME))

              // expmods[3] = point^(trace_length / 8).
              mstore(0x3540, expmod(point, div(/*trace_length*/ mload(0x80), 8), PRIME))

              // expmods[4] = point^(trace_length / 4).
              mstore(0x3560, expmod(point, div(/*trace_length*/ mload(0x80), 4), PRIME))

              // expmods[5] = point^(trace_length / 256).
              mstore(0x3580, expmod(point, div(/*trace_length*/ mload(0x80), 256), PRIME))

              // expmods[6] = point^(trace_length / 512).
              mstore(0x35a0, expmod(point, div(/*trace_length*/ mload(0x80), 512), PRIME))

              // expmods[7] = point^(trace_length / 64).
              mstore(0x35c0, expmod(point, div(/*trace_length*/ mload(0x80), 64), PRIME))

              // expmods[8] = point^(trace_length / 16384).
              mstore(0x35e0, expmod(point, div(/*trace_length*/ mload(0x80), 16384), PRIME))

              // expmods[9] = point^(trace_length / 128).
              mstore(0x3600, expmod(point, div(/*trace_length*/ mload(0x80), 128), PRIME))

              // expmods[10] = point^(trace_length / 32768).
              mstore(0x3620, expmod(point, div(/*trace_length*/ mload(0x80), 32768), PRIME))

              // expmods[11] = trace_generator^(15 * trace_length / 16).
              mstore(0x3640, expmod(/*trace_generator*/ mload(0x3a0), div(mul(15, /*trace_length*/ mload(0x80)), 16), PRIME))

              // expmods[12] = trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x3660, expmod(/*trace_generator*/ mload(0x3a0), mul(16, sub(div(/*trace_length*/ mload(0x80), 16), 1)), PRIME))

              // expmods[13] = trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x3680, expmod(/*trace_generator*/ mload(0x3a0), mul(2, sub(div(/*trace_length*/ mload(0x80), 2), 1)), PRIME))

              // expmods[14] = trace_generator^(4 * (trace_length / 4 - 1)).
              mstore(0x36a0, expmod(/*trace_generator*/ mload(0x3a0), mul(4, sub(div(/*trace_length*/ mload(0x80), 4), 1)), PRIME))

              // expmods[15] = trace_generator^(255 * trace_length / 256).
              mstore(0x36c0, expmod(/*trace_generator*/ mload(0x3a0), div(mul(255, /*trace_length*/ mload(0x80)), 256), PRIME))

              // expmods[16] = trace_generator^(63 * trace_length / 64).
              mstore(0x36e0, expmod(/*trace_generator*/ mload(0x3a0), div(mul(63, /*trace_length*/ mload(0x80)), 64), PRIME))

              // expmods[17] = trace_generator^(trace_length / 2).
              mstore(0x3700, expmod(/*trace_generator*/ mload(0x3a0), div(/*trace_length*/ mload(0x80), 2), PRIME))

              // expmods[18] = trace_generator^(512 * (trace_length / 512 - 1)).
              mstore(0x3720, expmod(/*trace_generator*/ mload(0x3a0), mul(512, sub(div(/*trace_length*/ mload(0x80), 512), 1)), PRIME))

              // expmods[19] = trace_generator^(256 * (trace_length / 256 - 1)).
              mstore(0x3740, expmod(/*trace_generator*/ mload(0x3a0), mul(256, sub(div(/*trace_length*/ mload(0x80), 256), 1)), PRIME))

              // expmods[20] = trace_generator^(251 * trace_length / 256).
              mstore(0x3760, expmod(/*trace_generator*/ mload(0x3a0), div(mul(251, /*trace_length*/ mload(0x80)), 256), PRIME))

              // expmods[21] = trace_generator^(32768 * (trace_length / 32768 - 1)).
              mstore(0x3780, expmod(/*trace_generator*/ mload(0x3a0), mul(32768, sub(div(/*trace_length*/ mload(0x80), 32768), 1)), PRIME))

            }

            {
              // Prepare denominators for batch inverse.

              // Denominator for constraints: 'cpu/decode/opcode_rc/bit', 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y'.
              // denominators[0] = point^trace_length - 1.
              mstore(0x3a80,
                     addmod(/*point^trace_length*/ mload(0x34e0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc/zero'.
              // denominators[1] = point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              mstore(0x3aa0,
                     addmod(
                       /*point^(trace_length / 16)*/ mload(0x3500),
                       sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x3640)),
                       PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc_input', 'cpu/operands/mem_dst_addr', 'cpu/operands/mem0_addr', 'cpu/operands/mem1_addr', 'cpu/operands/ops_mul', 'cpu/operands/res', 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update', 'cpu/opcodes/call/push_fp', 'cpu/opcodes/call/push_pc', 'cpu/opcodes/assert_eq/assert_eq'.
              // denominators[2] = point^(trace_length / 16) - 1.
              mstore(0x3ac0,
                     addmod(/*point^(trace_length / 16)*/ mload(0x3500), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'initial_ap', 'initial_fp', 'initial_pc', 'memory/multi_column_perm/perm/init0', 'memory/initial_addr', 'rc16/perm/init0', 'rc16/minimum', 'pedersen/init_addr', 'rc_builtin/init_addr', 'ecdsa/init_addr', 'checkpoints/req_pc_init_addr'.
              // denominators[3] = point - 1.
              mstore(0x3ae0,
                     addmod(point, sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'final_ap', 'final_pc'.
              // denominators[4] = point - trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x3b00,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16 * (trace_length / 16 - 1))*/ mload(0x3660)),
                       PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // denominators[5] = point^(trace_length / 2) - 1.
              mstore(0x3b20,
                     addmod(/*point^(trace_length / 2)*/ mload(0x3520), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/last'.
              // denominators[6] = point - trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x3b40,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2 * (trace_length / 2 - 1))*/ mload(0x3680)),
                       PRIME))

              // Denominator for constraints: 'public_memory_addr_zero', 'public_memory_value_zero'.
              // denominators[7] = point^(trace_length / 8) - 1.
              mstore(0x3b60,
                     addmod(/*point^(trace_length / 8)*/ mload(0x3540), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // denominators[8] = point^(trace_length / 4) - 1.
              mstore(0x3b80,
                     addmod(/*point^(trace_length / 4)*/ mload(0x3560), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'rc16/perm/last', 'rc16/maximum'.
              // denominators[9] = point - trace_generator^(4 * (trace_length / 4 - 1)).
              mstore(0x3ba0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(4 * (trace_length / 4 - 1))*/ mload(0x36a0)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y', 'rc_builtin/value', 'rc_builtin/addr_step', 'checkpoints/required_fp_addr', 'checkpoints/required_pc_next_addr', 'checkpoints/req_pc', 'checkpoints/req_fp'.
              // denominators[10] = point^(trace_length / 256) - 1.
              mstore(0x3bc0,
                     addmod(/*point^(trace_length / 256)*/ mload(0x3580), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_extraction_end'.
              // denominators[11] = point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              mstore(0x3be0,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x3580),
                       sub(PRIME, /*trace_generator^(63 * trace_length / 64)*/ mload(0x36e0)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/zeros_tail'.
              // denominators[12] = point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              mstore(0x3c00,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x3580),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x36c0)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/init/x', 'pedersen/hash0/init/y', 'pedersen/input0_value0', 'pedersen/input0_addr', 'pedersen/input1_value0', 'pedersen/input1_addr', 'pedersen/output_value0', 'pedersen/output_addr'.
              // denominators[13] = point^(trace_length / 512) - 1.
              mstore(0x3c20,
                     addmod(/*point^(trace_length / 512)*/ mload(0x35a0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y'.
              // denominators[14] = point^(trace_length / 64) - 1.
              mstore(0x3c40,
                     addmod(/*point^(trace_length / 64)*/ mload(0x35c0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // denominators[15] = point^(trace_length / 128) - 1.
              mstore(0x3c60,
                     addmod(/*point^(trace_length / 128)*/ mload(0x3600), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/bit_extraction_end'.
              // denominators[16] = point^(trace_length / 32768) - trace_generator^(251 * trace_length / 256).
              mstore(0x3c80,
                     addmod(
                       /*point^(trace_length / 32768)*/ mload(0x3620),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x3760)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/zeros_tail'.
              // denominators[17] = point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              mstore(0x3ca0,
                     addmod(
                       /*point^(trace_length / 32768)*/ mload(0x3620),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x36c0)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/bit_extraction_end'.
              // denominators[18] = point^(trace_length / 16384) - trace_generator^(251 * trace_length / 256).
              mstore(0x3cc0,
                     addmod(
                       /*point^(trace_length / 16384)*/ mload(0x35e0),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x3760)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/zeros_tail'.
              // denominators[19] = point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              mstore(0x3ce0,
                     addmod(
                       /*point^(trace_length / 16384)*/ mload(0x35e0),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x36c0)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_gen/x', 'ecdsa/signature0/init_gen/y', 'ecdsa/signature0/add_results/slope', 'ecdsa/signature0/add_results/x', 'ecdsa/signature0/add_results/y', 'ecdsa/signature0/add_results/x_diff_inv', 'ecdsa/signature0/extract_r/slope', 'ecdsa/signature0/extract_r/x', 'ecdsa/signature0/extract_r/x_diff_inv', 'ecdsa/signature0/z_nonzero', 'ecdsa/signature0/q_on_curve/x_squared', 'ecdsa/signature0/q_on_curve/on_curve', 'ecdsa/message_addr', 'ecdsa/pubkey_addr', 'ecdsa/message_value0', 'ecdsa/pubkey_value0'.
              // denominators[20] = point^(trace_length / 32768) - 1.
              mstore(0x3d00,
                     addmod(/*point^(trace_length / 32768)*/ mload(0x3620), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_key/x', 'ecdsa/signature0/init_key/y', 'ecdsa/signature0/r_and_w_nonzero'.
              // denominators[21] = point^(trace_length / 16384) - 1.
              mstore(0x3d20,
                     addmod(/*point^(trace_length / 16384)*/ mload(0x35e0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'checkpoints/req_pc_final_addr'.
              // denominators[22] = point - trace_generator^(256 * (trace_length / 256 - 1)).
              mstore(0x3d40,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(256 * (trace_length / 256 - 1))*/ mload(0x3740)),
                       PRIME))

            }

            {
              // Compute the inverses of the denominators into denominatorInvs using batch inverse.

              // Start by computing the cumulative product.
              // Let (d_0, d_1, d_2, ..., d_{n-1}) be the values in denominators. After this loop
              // denominatorInvs will be (1, d_0, d_0 * d_1, ...) and prod will contain the value of
              // d_0 * ... * d_{n-1}.
              // Compute the offset between the partialProducts array and the input values array.
              let productsToValuesOffset := 0x2e0
              let prod := 1
              let partialProductEndPtr := 0x3a80
              for { let partialProductPtr := 0x37a0 }
                  lt(partialProductPtr, partialProductEndPtr)
                  { partialProductPtr := add(partialProductPtr, 0x20) } {
                  mstore(partialProductPtr, prod)
                  // prod *= d_{i}.
                  prod := mulmod(prod,
                                 mload(add(partialProductPtr, productsToValuesOffset)),
                                 PRIME)
              }

              let firstPartialProductPtr := 0x37a0
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
              let currentPartialProductPtr := 0x3a80
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

              // Numerator for constraints 'cpu/decode/opcode_rc/bit'.
              // numerators[0] = point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              mstore(0x3d60,
                     addmod(
                       /*point^(trace_length / 16)*/ mload(0x3500),
                       sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x3640)),
                       PRIME))

              // Numerator for constraints 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update'.
              // numerators[1] = point - trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x3d80,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16 * (trace_length / 16 - 1))*/ mload(0x3660)),
                       PRIME))

              // Numerator for constraints 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // numerators[2] = point - trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x3da0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2 * (trace_length / 2 - 1))*/ mload(0x3680)),
                       PRIME))

              // Numerator for constraints 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // numerators[3] = point - trace_generator^(4 * (trace_length / 4 - 1)).
              mstore(0x3dc0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(4 * (trace_length / 4 - 1))*/ mload(0x36a0)),
                       PRIME))

              // Numerator for constraints 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y'.
              // numerators[4] = point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              mstore(0x3de0,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x3580),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x36c0)),
                       PRIME))

              // Numerator for constraints 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y'.
              // numerators[5] = point^(trace_length / 512) - trace_generator^(trace_length / 2).
              mstore(0x3e00,
                     addmod(
                       /*point^(trace_length / 512)*/ mload(0x35a0),
                       sub(PRIME, /*trace_generator^(trace_length / 2)*/ mload(0x3700)),
                       PRIME))

              // Numerator for constraints 'pedersen/input0_addr'.
              // numerators[6] = point - trace_generator^(512 * (trace_length / 512 - 1)).
              mstore(0x3e20,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(512 * (trace_length / 512 - 1))*/ mload(0x3720)),
                       PRIME))

              // Numerator for constraints 'rc_builtin/addr_step', 'checkpoints/required_pc_next_addr', 'checkpoints/req_pc', 'checkpoints/req_fp'.
              // numerators[7] = point - trace_generator^(256 * (trace_length / 256 - 1)).
              mstore(0x3e40,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(256 * (trace_length / 256 - 1))*/ mload(0x3740)),
                       PRIME))

              // Numerator for constraints 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y'.
              // numerators[8] = point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              mstore(0x3e60,
                     addmod(
                       /*point^(trace_length / 16384)*/ mload(0x35e0),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x36c0)),
                       PRIME))

              // Numerator for constraints 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // numerators[9] = point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              mstore(0x3e80,
                     addmod(
                       /*point^(trace_length / 32768)*/ mload(0x3620),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x36c0)),
                       PRIME))

              // Numerator for constraints 'ecdsa/pubkey_addr'.
              // numerators[10] = point - trace_generator^(32768 * (trace_length / 32768 - 1)).
              mstore(0x3ea0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(32768 * (trace_length / 32768 - 1))*/ mload(0x3780)),
                       PRIME))

              // Adjustment polynomial for constraints 'cpu/decode/opcode_rc/bit'.
              // adjustments[0] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), trace_length / 16, trace_length).
              mstore(0x3ec0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), div(/*trace_length*/ mload(0x80), 16), /*trace_length*/ mload(0x80)), PRIME))

              // Adjustment polynomial for constraints 'cpu/decode/opcode_rc/zero', 'cpu/decode/opcode_rc_input'.
              // adjustments[1] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 16).
              mstore(0x3ee0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 16)), PRIME))

              // Adjustment polynomial for constraints 'cpu/operands/mem_dst_addr', 'cpu/operands/mem0_addr', 'cpu/operands/mem1_addr', 'cpu/operands/ops_mul', 'cpu/operands/res', 'cpu/opcodes/call/push_fp', 'cpu/opcodes/call/push_pc', 'cpu/opcodes/assert_eq/assert_eq'.
              // adjustments[2] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 0, trace_length / 16).
              mstore(0x3f00,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 0, div(/*trace_length*/ mload(0x80), 16)), PRIME))

              // Adjustment polynomial for constraints 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update'.
              // adjustments[3] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 1, trace_length / 16).
              mstore(0x3f20,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 1, div(/*trace_length*/ mload(0x80), 16)), PRIME))

              // Adjustment polynomial for constraints 'initial_ap', 'initial_fp', 'initial_pc', 'final_ap', 'final_pc', 'memory/multi_column_perm/perm/last', 'memory/initial_addr', 'rc16/perm/last', 'rc16/minimum', 'rc16/maximum', 'pedersen/init_addr', 'rc_builtin/init_addr', 'ecdsa/init_addr', 'checkpoints/req_pc_init_addr', 'checkpoints/req_pc_final_addr'.
              // adjustments[4] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, 1).
              mstore(0x3f40,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 0, 1), PRIME))

              // Adjustment polynomial for constraints 'memory/multi_column_perm/perm/init0', 'rc16/perm/init0'.
              // adjustments[5] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 0, 1).
              mstore(0x3f60,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 0, 1), PRIME))

              // Adjustment polynomial for constraints 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // adjustments[6] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 1, trace_length / 2).
              mstore(0x3f80,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 1, div(/*trace_length*/ mload(0x80), 2)), PRIME))

              // Adjustment polynomial for constraints 'public_memory_addr_zero', 'public_memory_value_zero'.
              // adjustments[7] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 8).
              mstore(0x3fa0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 8)), PRIME))

              // Adjustment polynomial for constraints 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // adjustments[8] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 1, trace_length / 4).
              mstore(0x3fc0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 1, div(/*trace_length*/ mload(0x80), 4)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196'.
              // adjustments[9] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 0, trace_length / 256).
              mstore(0x3fe0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 0, div(/*trace_length*/ mload(0x80), 256)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y'.
              // adjustments[10] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), trace_length / 256, trace_length).
              mstore(0x4000,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), div(/*trace_length*/ mload(0x80), 256), /*trace_length*/ mload(0x80)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/hash0/ec_subset_sum/bit_extraction_end', 'pedersen/hash0/ec_subset_sum/zeros_tail', 'rc_builtin/value', 'checkpoints/required_fp_addr'.
              // adjustments[11] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 256).
              mstore(0x4020,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 256)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y'.
              // adjustments[12] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, trace_length / 512, trace_length / 256).
              mstore(0x4040,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), div(/*trace_length*/ mload(0x80), 512), div(/*trace_length*/ mload(0x80), 256)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/hash0/init/x', 'pedersen/hash0/init/y', 'pedersen/input0_value0', 'pedersen/input1_value0', 'pedersen/input1_addr', 'pedersen/output_value0', 'pedersen/output_addr'.
              // adjustments[13] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 512).
              mstore(0x4060,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 512)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/input0_addr'.
              // adjustments[14] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 1, trace_length / 512).
              mstore(0x4080,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 1, div(/*trace_length*/ mload(0x80), 512)), PRIME))

              // Adjustment polynomial for constraints 'rc_builtin/addr_step'.
              // adjustments[15] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 1, trace_length / 256).
              mstore(0x40a0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 1, div(/*trace_length*/ mload(0x80), 256)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y'.
              // adjustments[16] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), trace_length / 16384, trace_length / 64).
              mstore(0x40c0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), div(/*trace_length*/ mload(0x80), 16384), div(/*trace_length*/ mload(0x80), 64)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // adjustments[17] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), trace_length / 32768, trace_length / 128).
              mstore(0x40e0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), div(/*trace_length*/ mload(0x80), 32768), div(/*trace_length*/ mload(0x80), 128)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/exponentiate_generator/bit_extraction_end', 'ecdsa/signature0/exponentiate_generator/zeros_tail', 'ecdsa/signature0/init_gen/x', 'ecdsa/signature0/init_gen/y', 'ecdsa/message_addr', 'ecdsa/message_value0', 'ecdsa/pubkey_value0'.
              // adjustments[18] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 32768).
              mstore(0x4100,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 32768)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/exponentiate_key/bit_extraction_end', 'ecdsa/signature0/exponentiate_key/zeros_tail', 'ecdsa/signature0/init_key/x', 'ecdsa/signature0/init_key/y'.
              // adjustments[19] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 16384).
              mstore(0x4120,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 16384)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/add_results/slope', 'ecdsa/signature0/add_results/x', 'ecdsa/signature0/add_results/y', 'ecdsa/signature0/add_results/x_diff_inv', 'ecdsa/signature0/extract_r/slope', 'ecdsa/signature0/extract_r/x', 'ecdsa/signature0/extract_r/x_diff_inv', 'ecdsa/signature0/z_nonzero', 'ecdsa/signature0/q_on_curve/x_squared', 'ecdsa/signature0/q_on_curve/on_curve'.
              // adjustments[20] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 0, trace_length / 32768).
              mstore(0x4140,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 0, div(/*trace_length*/ mload(0x80), 32768)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/r_and_w_nonzero'.
              // adjustments[21] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 0, trace_length / 16384).
              mstore(0x4160,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 0, div(/*trace_length*/ mload(0x80), 16384)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/pubkey_addr'.
              // adjustments[22] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 1, trace_length / 32768).
              mstore(0x4180,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), sub(/*trace_length*/ mload(0x80), 1), 1, div(/*trace_length*/ mload(0x80), 32768)), PRIME))

              // Adjustment polynomial for constraints 'checkpoints/required_pc_next_addr', 'checkpoints/req_pc', 'checkpoints/req_fp'.
              // adjustments[23] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 1, trace_length / 256).
              mstore(0x41a0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x30a0), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 1, div(/*trace_length*/ mload(0x80), 256)), PRIME))

            }

            {
              // Compute the result of the composition polynomial.

              {
              // cpu/decode/opcode_rc/bit_0 = column0_row0 - (column0_row1 + column0_row1).
              let val := addmod(
                /*column0_row0*/ mload(0x2000),
                sub(
                  PRIME,
                  addmod(/*column0_row1*/ mload(0x2020), /*column0_row1*/ mload(0x2020), PRIME)),
                PRIME)
              mstore(0x30c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_1 = column0_row1 - (column0_row2 + column0_row2).
              let val := addmod(
                /*column0_row1*/ mload(0x2020),
                sub(
                  PRIME,
                  addmod(/*column0_row2*/ mload(0x2040), /*column0_row2*/ mload(0x2040), PRIME)),
                PRIME)
              mstore(0x30e0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_2 = column0_row2 - (column0_row3 + column0_row3).
              let val := addmod(
                /*column0_row2*/ mload(0x2040),
                sub(
                  PRIME,
                  addmod(/*column0_row3*/ mload(0x2060), /*column0_row3*/ mload(0x2060), PRIME)),
                PRIME)
              mstore(0x3100, val)
              }


              {
              // cpu/decode/opcode_rc/bit_4 = column0_row4 - (column0_row5 + column0_row5).
              let val := addmod(
                /*column0_row4*/ mload(0x2080),
                sub(
                  PRIME,
                  addmod(/*column0_row5*/ mload(0x20a0), /*column0_row5*/ mload(0x20a0), PRIME)),
                PRIME)
              mstore(0x3120, val)
              }


              {
              // cpu/decode/opcode_rc/bit_3 = column0_row3 - (column0_row4 + column0_row4).
              let val := addmod(
                /*column0_row3*/ mload(0x2060),
                sub(
                  PRIME,
                  addmod(/*column0_row4*/ mload(0x2080), /*column0_row4*/ mload(0x2080), PRIME)),
                PRIME)
              mstore(0x3140, val)
              }


              {
              // cpu/decode/opcode_rc/bit_9 = column0_row9 - (column0_row10 + column0_row10).
              let val := addmod(
                /*column0_row9*/ mload(0x2120),
                sub(
                  PRIME,
                  addmod(/*column0_row10*/ mload(0x2140), /*column0_row10*/ mload(0x2140), PRIME)),
                PRIME)
              mstore(0x3160, val)
              }


              {
              // cpu/decode/opcode_rc/bit_5 = column0_row5 - (column0_row6 + column0_row6).
              let val := addmod(
                /*column0_row5*/ mload(0x20a0),
                sub(
                  PRIME,
                  addmod(/*column0_row6*/ mload(0x20c0), /*column0_row6*/ mload(0x20c0), PRIME)),
                PRIME)
              mstore(0x3180, val)
              }


              {
              // cpu/decode/opcode_rc/bit_6 = column0_row6 - (column0_row7 + column0_row7).
              let val := addmod(
                /*column0_row6*/ mload(0x20c0),
                sub(
                  PRIME,
                  addmod(/*column0_row7*/ mload(0x20e0), /*column0_row7*/ mload(0x20e0), PRIME)),
                PRIME)
              mstore(0x31a0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_7 = column0_row7 - (column0_row8 + column0_row8).
              let val := addmod(
                /*column0_row7*/ mload(0x20e0),
                sub(
                  PRIME,
                  addmod(/*column0_row8*/ mload(0x2100), /*column0_row8*/ mload(0x2100), PRIME)),
                PRIME)
              mstore(0x31c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_8 = column0_row8 - (column0_row9 + column0_row9).
              let val := addmod(
                /*column0_row8*/ mload(0x2100),
                sub(
                  PRIME,
                  addmod(/*column0_row9*/ mload(0x2120), /*column0_row9*/ mload(0x2120), PRIME)),
                PRIME)
              mstore(0x31e0, val)
              }


              {
              // npc_reg_0 = column5_row0 + cpu__decode__opcode_rc__bit_2 + 1.
              let val := addmod(
                addmod(
                  /*column5_row0*/ mload(0x2480),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3100),
                  PRIME),
                1,
                PRIME)
              mstore(0x3200, val)
              }


              {
              // cpu/decode/opcode_rc/bit_10 = column0_row10 - (column0_row11 + column0_row11).
              let val := addmod(
                /*column0_row10*/ mload(0x2140),
                sub(
                  PRIME,
                  addmod(/*column0_row11*/ mload(0x2160), /*column0_row11*/ mload(0x2160), PRIME)),
                PRIME)
              mstore(0x3220, val)
              }


              {
              // cpu/decode/opcode_rc/bit_11 = column0_row11 - (column0_row12 + column0_row12).
              let val := addmod(
                /*column0_row11*/ mload(0x2160),
                sub(
                  PRIME,
                  addmod(/*column0_row12*/ mload(0x2180), /*column0_row12*/ mload(0x2180), PRIME)),
                PRIME)
              mstore(0x3240, val)
              }


              {
              // cpu/decode/opcode_rc/bit_12 = column0_row12 - (column0_row13 + column0_row13).
              let val := addmod(
                /*column0_row12*/ mload(0x2180),
                sub(
                  PRIME,
                  addmod(/*column0_row13*/ mload(0x21a0), /*column0_row13*/ mload(0x21a0), PRIME)),
                PRIME)
              mstore(0x3260, val)
              }


              {
              // cpu/decode/opcode_rc/bit_13 = column0_row13 - (column0_row14 + column0_row14).
              let val := addmod(
                /*column0_row13*/ mload(0x21a0),
                sub(
                  PRIME,
                  addmod(/*column0_row14*/ mload(0x21c0), /*column0_row14*/ mload(0x21c0), PRIME)),
                PRIME)
              mstore(0x3280, val)
              }


              {
              // cpu/decode/opcode_rc/bit_14 = column0_row14 - (column0_row15 + column0_row15).
              let val := addmod(
                /*column0_row14*/ mload(0x21c0),
                sub(
                  PRIME,
                  addmod(/*column0_row15*/ mload(0x21e0), /*column0_row15*/ mload(0x21e0), PRIME)),
                PRIME)
              mstore(0x32a0, val)
              }


              {
              // memory/address_diff_0 = column6_row2 - column6_row0.
              let val := addmod(/*column6_row2*/ mload(0x28a0), sub(PRIME, /*column6_row0*/ mload(0x2860)), PRIME)
              mstore(0x32c0, val)
              }


              {
              // rc16/diff_0 = column7_row6 - column7_row2.
              let val := addmod(/*column7_row6*/ mload(0x29a0), sub(PRIME, /*column7_row2*/ mload(0x2920)), PRIME)
              mstore(0x32e0, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_0 = column4_row0 - (column4_row1 + column4_row1).
              let val := addmod(
                /*column4_row0*/ mload(0x2360),
                sub(
                  PRIME,
                  addmod(/*column4_row1*/ mload(0x2380), /*column4_row1*/ mload(0x2380), PRIME)),
                PRIME)
              mstore(0x3300, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash0__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3300)),
                PRIME)
              mstore(0x3320, val)
              }


              {
              // rc_builtin/value0_0 = column7_row12.
              let val := /*column7_row12*/ mload(0x2a40)
              mstore(0x3340, val)
              }


              {
              // rc_builtin/value1_0 = rc_builtin__value0_0 * offset_size + column7_row44.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value0_0*/ mload(0x3340),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column7_row44*/ mload(0x2b40),
                PRIME)
              mstore(0x3360, val)
              }


              {
              // rc_builtin/value2_0 = rc_builtin__value1_0 * offset_size + column7_row76.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value1_0*/ mload(0x3360),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column7_row76*/ mload(0x2be0),
                PRIME)
              mstore(0x3380, val)
              }


              {
              // rc_builtin/value3_0 = rc_builtin__value2_0 * offset_size + column7_row108.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value2_0*/ mload(0x3380),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column7_row108*/ mload(0x2c60),
                PRIME)
              mstore(0x33a0, val)
              }


              {
              // rc_builtin/value4_0 = rc_builtin__value3_0 * offset_size + column7_row140.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value3_0*/ mload(0x33a0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column7_row140*/ mload(0x2ca0),
                PRIME)
              mstore(0x33c0, val)
              }


              {
              // rc_builtin/value5_0 = rc_builtin__value4_0 * offset_size + column7_row172.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value4_0*/ mload(0x33c0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column7_row172*/ mload(0x2cc0),
                PRIME)
              mstore(0x33e0, val)
              }


              {
              // rc_builtin/value6_0 = rc_builtin__value5_0 * offset_size + column7_row204.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value5_0*/ mload(0x33e0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column7_row204*/ mload(0x2ce0),
                PRIME)
              mstore(0x3400, val)
              }


              {
              // rc_builtin/value7_0 = rc_builtin__value6_0 * offset_size + column7_row236.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value6_0*/ mload(0x3400),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column7_row236*/ mload(0x2d00),
                PRIME)
              mstore(0x3420, val)
              }


              {
              // ecdsa/signature0/doubling_key/x_squared = column7_row7 * column7_row7.
              let val := mulmod(/*column7_row7*/ mload(0x29c0), /*column7_row7*/ mload(0x29c0), PRIME)
              mstore(0x3440, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_0 = column8_row96 - (column8_row224 + column8_row224).
              let val := addmod(
                /*column8_row96*/ mload(0x2f20),
                sub(
                  PRIME,
                  addmod(/*column8_row224*/ mload(0x2f80), /*column8_row224*/ mload(0x2f80), PRIME)),
                PRIME)
              mstore(0x3460, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_generator__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x3460)),
                PRIME)
              mstore(0x3480, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_0 = column7_row31 - (column7_row95 + column7_row95).
              let val := addmod(
                /*column7_row31*/ mload(0x2b00),
                sub(
                  PRIME,
                  addmod(/*column7_row95*/ mload(0x2c20), /*column7_row95*/ mload(0x2c20), PRIME)),
                PRIME)
              mstore(0x34a0, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_key__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x34a0)),
                PRIME)
              mstore(0x34c0, val)
              }


              {
              // Constraint expression for cpu/decode/opcode_rc/bit: cpu__decode__opcode_rc__bit_0 * cpu__decode__opcode_rc__bit_0 - cpu__decode__opcode_rc__bit_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x30c0),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x30c0),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x30c0)),
                PRIME)

              // Numerator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= numerators[0].
              val := mulmod(val, mload(0x3d60), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x37a0), PRIME)

              // res += val * (coefficients[0] + coefficients[1] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[0]*/ mload(0x440),
                                       mulmod(/*coefficients[1]*/ mload(0x460),
                                              /*adjustments[0]*/mload(0x3ec0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc/zero: column0_row0.
              let val := /*column0_row0*/ mload(0x2000)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= denominator_invs[1].
              val := mulmod(val, mload(0x37c0), PRIME)

              // res += val * (coefficients[2] + coefficients[3] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[2]*/ mload(0x480),
                                       mulmod(/*coefficients[3]*/ mload(0x4a0),
                                              /*adjustments[1]*/mload(0x3ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc_input: column5_row1 - (((column0_row0 * offset_size + column7_row4) * offset_size + column7_row8) * offset_size + column7_row0).
              let val := addmod(
                /*column5_row1*/ mload(0x24a0),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      addmod(
                        mulmod(
                          addmod(
                            mulmod(/*column0_row0*/ mload(0x2000), /*offset_size*/ mload(0xa0), PRIME),
                            /*column7_row4*/ mload(0x2960),
                            PRIME),
                          /*offset_size*/ mload(0xa0),
                          PRIME),
                        /*column7_row8*/ mload(0x29e0),
                        PRIME),
                      /*offset_size*/ mload(0xa0),
                      PRIME),
                    /*column7_row0*/ mload(0x28e0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[4] + coefficients[5] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[4]*/ mload(0x4c0),
                                       mulmod(/*coefficients[5]*/ mload(0x4e0),
                                              /*adjustments[1]*/mload(0x3ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem_dst_addr: column5_row8 + half_offset_size - (cpu__decode__opcode_rc__bit_0 * column7_row9 + (1 - cpu__decode__opcode_rc__bit_0) * column7_row1 + column7_row0).
              let val := addmod(
                addmod(/*column5_row8*/ mload(0x2580), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x30c0),
                        /*column7_row9*/ mload(0x2a00),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x30c0)),
                          PRIME),
                        /*column7_row1*/ mload(0x2900),
                        PRIME),
                      PRIME),
                    /*column7_row0*/ mload(0x28e0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[6] + coefficients[7] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[6]*/ mload(0x500),
                                       mulmod(/*coefficients[7]*/ mload(0x520),
                                              /*adjustments[2]*/mload(0x3f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem0_addr: column5_row4 + half_offset_size - (cpu__decode__opcode_rc__bit_1 * column7_row9 + (1 - cpu__decode__opcode_rc__bit_1) * column7_row1 + column7_row8).
              let val := addmod(
                addmod(/*column5_row4*/ mload(0x2500), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x30e0),
                        /*column7_row9*/ mload(0x2a00),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x30e0)),
                          PRIME),
                        /*column7_row1*/ mload(0x2900),
                        PRIME),
                      PRIME),
                    /*column7_row8*/ mload(0x29e0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[8] + coefficients[9] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[8]*/ mload(0x540),
                                       mulmod(/*coefficients[9]*/ mload(0x560),
                                              /*adjustments[2]*/mload(0x3f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem1_addr: column5_row12 + half_offset_size - (cpu__decode__opcode_rc__bit_2 * column5_row0 + cpu__decode__opcode_rc__bit_4 * column7_row1 + cpu__decode__opcode_rc__bit_3 * column7_row9 + (1 - (cpu__decode__opcode_rc__bit_2 + cpu__decode__opcode_rc__bit_4 + cpu__decode__opcode_rc__bit_3)) * column5_row5 + column7_row4).
              let val := addmod(
                addmod(/*column5_row12*/ mload(0x25c0), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3100),
                            /*column5_row0*/ mload(0x2480),
                            PRIME),
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x3120),
                            /*column7_row1*/ mload(0x2900),
                            PRIME),
                          PRIME),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x3140),
                          /*column7_row9*/ mload(0x2a00),
                          PRIME),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(
                            PRIME,
                            addmod(
                              addmod(
                                /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3100),
                                /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x3120),
                                PRIME),
                              /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x3140),
                              PRIME)),
                          PRIME),
                        /*column5_row5*/ mload(0x2520),
                        PRIME),
                      PRIME),
                    /*column7_row4*/ mload(0x2960),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[10] + coefficients[11] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[10]*/ mload(0x580),
                                       mulmod(/*coefficients[11]*/ mload(0x5a0),
                                              /*adjustments[2]*/mload(0x3f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/ops_mul: column7_row5 - column5_row5 * column5_row13.
              let val := addmod(
                /*column7_row5*/ mload(0x2980),
                sub(
                  PRIME,
                  mulmod(/*column5_row5*/ mload(0x2520), /*column5_row13*/ mload(0x25e0), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[12] + coefficients[13] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[12]*/ mload(0x5c0),
                                       mulmod(/*coefficients[13]*/ mload(0x5e0),
                                              /*adjustments[2]*/mload(0x3f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/res: (1 - cpu__decode__opcode_rc__bit_9) * column7_row13 - (cpu__decode__opcode_rc__bit_5 * (column5_row5 + column5_row13) + cpu__decode__opcode_rc__bit_6 * column7_row5 + (1 - (cpu__decode__opcode_rc__bit_5 + cpu__decode__opcode_rc__bit_6 + cpu__decode__opcode_rc__bit_9)) * column5_row13).
              let val := addmod(
                mulmod(
                  addmod(
                    1,
                    sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3160)),
                    PRIME),
                  /*column7_row13*/ mload(0x2a60),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x3180),
                        addmod(/*column5_row5*/ mload(0x2520), /*column5_row13*/ mload(0x25e0), PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x31a0),
                        /*column7_row5*/ mload(0x2980),
                        PRIME),
                      PRIME),
                    mulmod(
                      addmod(
                        1,
                        sub(
                          PRIME,
                          addmod(
                            addmod(
                              /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x3180),
                              /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x31a0),
                              PRIME),
                            /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3160),
                            PRIME)),
                        PRIME),
                      /*column5_row13*/ mload(0x25e0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[14] + coefficients[15] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[14]*/ mload(0x600),
                                       mulmod(/*coefficients[15]*/ mload(0x620),
                                              /*adjustments[2]*/mload(0x3f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp0: column7_row3 - cpu__decode__opcode_rc__bit_9 * column5_row9.
              let val := addmod(
                /*column7_row3*/ mload(0x2940),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3160),
                    /*column5_row9*/ mload(0x25a0),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x3d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[16] + coefficients[17] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[16]*/ mload(0x640),
                                       mulmod(/*coefficients[17]*/ mload(0x660),
                                              /*adjustments[3]*/mload(0x3f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp1: column7_row11 - column7_row3 * column7_row13.
              let val := addmod(
                /*column7_row11*/ mload(0x2a20),
                sub(
                  PRIME,
                  mulmod(/*column7_row3*/ mload(0x2940), /*column7_row13*/ mload(0x2a60), PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x3d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[18] + coefficients[19] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[18]*/ mload(0x680),
                                       mulmod(/*coefficients[19]*/ mload(0x6a0),
                                              /*adjustments[3]*/mload(0x3f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_negative: (1 - cpu__decode__opcode_rc__bit_9) * column5_row16 + column7_row3 * (column5_row16 - (column5_row0 + column5_row13)) - ((1 - (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_8 + cpu__decode__opcode_rc__bit_9)) * npc_reg_0 + cpu__decode__opcode_rc__bit_7 * column7_row13 + cpu__decode__opcode_rc__bit_8 * (column5_row0 + column7_row13)).
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      1,
                      sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3160)),
                      PRIME),
                    /*column5_row16*/ mload(0x2600),
                    PRIME),
                  mulmod(
                    /*column7_row3*/ mload(0x2940),
                    addmod(
                      /*column5_row16*/ mload(0x2600),
                      sub(
                        PRIME,
                        addmod(/*column5_row0*/ mload(0x2480), /*column5_row13*/ mload(0x25e0), PRIME)),
                      PRIME),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        addmod(
                          1,
                          sub(
                            PRIME,
                            addmod(
                              addmod(
                                /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x31c0),
                                /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x31e0),
                                PRIME),
                              /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3160),
                              PRIME)),
                          PRIME),
                        /*intermediate_value/npc_reg_0*/ mload(0x3200),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x31c0),
                        /*column7_row13*/ mload(0x2a60),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x31e0),
                      addmod(/*column5_row0*/ mload(0x2480), /*column7_row13*/ mload(0x2a60), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x3d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[20] + coefficients[21] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[20]*/ mload(0x6c0),
                                       mulmod(/*coefficients[21]*/ mload(0x6e0),
                                              /*adjustments[3]*/mload(0x3f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_positive: (column7_row11 - cpu__decode__opcode_rc__bit_9) * (column5_row16 - npc_reg_0).
              let val := mulmod(
                addmod(
                  /*column7_row11*/ mload(0x2a20),
                  sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3160)),
                  PRIME),
                addmod(
                  /*column5_row16*/ mload(0x2600),
                  sub(PRIME, /*intermediate_value/npc_reg_0*/ mload(0x3200)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x3d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[22] + coefficients[23] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[22]*/ mload(0x700),
                                       mulmod(/*coefficients[23]*/ mload(0x720),
                                              /*adjustments[3]*/mload(0x3f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_ap/ap_update: column7_row17 - (column7_row1 + cpu__decode__opcode_rc__bit_10 * column7_row13 + cpu__decode__opcode_rc__bit_11 + cpu__decode__opcode_rc__bit_12 * 2).
              let val := addmod(
                /*column7_row17*/ mload(0x2aa0),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        /*column7_row1*/ mload(0x2900),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_10*/ mload(0x3220),
                          /*column7_row13*/ mload(0x2a60),
                          PRIME),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_11*/ mload(0x3240),
                      PRIME),
                    mulmod(/*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3260), 2, PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x3d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[24] + coefficients[25] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[24]*/ mload(0x740),
                                       mulmod(/*coefficients[25]*/ mload(0x760),
                                              /*adjustments[3]*/mload(0x3f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_fp/fp_update: column7_row25 - ((1 - (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_13)) * column7_row9 + cpu__decode__opcode_rc__bit_13 * column5_row9 + cpu__decode__opcode_rc__bit_12 * (column7_row1 + 2)).
              let val := addmod(
                /*column7_row25*/ mload(0x2ae0),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        addmod(
                          1,
                          sub(
                            PRIME,
                            addmod(
                              /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3260),
                              /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x3280),
                              PRIME)),
                          PRIME),
                        /*column7_row9*/ mload(0x2a00),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x3280),
                        /*column5_row9*/ mload(0x25a0),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3260),
                      addmod(/*column7_row1*/ mload(0x2900), 2, PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x3d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[26] + coefficients[27] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[26]*/ mload(0x780),
                                       mulmod(/*coefficients[27]*/ mload(0x7a0),
                                              /*adjustments[3]*/mload(0x3f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_fp: cpu__decode__opcode_rc__bit_12 * (column5_row9 - column7_row9).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3260),
                addmod(/*column5_row9*/ mload(0x25a0), sub(PRIME, /*column7_row9*/ mload(0x2a00)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[28] + coefficients[29] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[28]*/ mload(0x7c0),
                                       mulmod(/*coefficients[29]*/ mload(0x7e0),
                                              /*adjustments[2]*/mload(0x3f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_pc: cpu__decode__opcode_rc__bit_12 * (column5_row5 - (column5_row0 + cpu__decode__opcode_rc__bit_2 + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3260),
                addmod(
                  /*column5_row5*/ mload(0x2520),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*column5_row0*/ mload(0x2480),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3100),
                        PRIME),
                      1,
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[30] + coefficients[31] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[30]*/ mload(0x800),
                                       mulmod(/*coefficients[31]*/ mload(0x820),
                                              /*adjustments[2]*/mload(0x3f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/assert_eq/assert_eq: cpu__decode__opcode_rc__bit_14 * (column5_row9 - column7_row13).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_14*/ mload(0x32a0),
                addmod(/*column5_row9*/ mload(0x25a0), sub(PRIME, /*column7_row13*/ mload(0x2a60)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x37e0), PRIME)

              // res += val * (coefficients[32] + coefficients[33] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[32]*/ mload(0x840),
                                       mulmod(/*coefficients[33]*/ mload(0x860),
                                              /*adjustments[2]*/mload(0x3f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for initial_ap: column7_row1 - initial_ap.
              let val := addmod(/*column7_row1*/ mload(0x2900), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[34] + coefficients[35] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[34]*/ mload(0x880),
                                       mulmod(/*coefficients[35]*/ mload(0x8a0),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for initial_fp: column7_row9 - initial_ap.
              let val := addmod(/*column7_row9*/ mload(0x2a00), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[36] + coefficients[37] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[36]*/ mload(0x8c0),
                                       mulmod(/*coefficients[37]*/ mload(0x8e0),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for initial_pc: column5_row0 - initial_pc.
              let val := addmod(/*column5_row0*/ mload(0x2480), sub(PRIME, /*initial_pc*/ mload(0x100)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[38] + coefficients[39] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[38]*/ mload(0x900),
                                       mulmod(/*coefficients[39]*/ mload(0x920),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for final_ap: column7_row1 - final_ap.
              let val := addmod(/*column7_row1*/ mload(0x2900), sub(PRIME, /*final_ap*/ mload(0x120)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[4].
              val := mulmod(val, mload(0x3820), PRIME)

              // res += val * (coefficients[40] + coefficients[41] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[40]*/ mload(0x940),
                                       mulmod(/*coefficients[41]*/ mload(0x960),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for final_pc: column5_row0 - final_pc.
              let val := addmod(/*column5_row0*/ mload(0x2480), sub(PRIME, /*final_pc*/ mload(0x140)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[4].
              val := mulmod(val, mload(0x3820), PRIME)

              // res += val * (coefficients[42] + coefficients[43] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[42]*/ mload(0x980),
                                       mulmod(/*coefficients[43]*/ mload(0x9a0),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/init0: (memory/multi_column_perm/perm/interaction_elm - (column6_row0 + memory/multi_column_perm/hash_interaction_elm0 * column6_row1)) * column9_inter1_row0 + column5_row0 + memory/multi_column_perm/hash_interaction_elm0 * column5_row1 - memory/multi_column_perm/perm/interaction_elm.
              let val := addmod(
                addmod(
                  addmod(
                    mulmod(
                      addmod(
                        /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                        sub(
                          PRIME,
                          addmod(
                            /*column6_row0*/ mload(0x2860),
                            mulmod(
                              /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                              /*column6_row1*/ mload(0x2880),
                              PRIME),
                            PRIME)),
                        PRIME),
                      /*column9_inter1_row0*/ mload(0x3020),
                      PRIME),
                    /*column5_row0*/ mload(0x2480),
                    PRIME),
                  mulmod(
                    /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                    /*column5_row1*/ mload(0x24a0),
                    PRIME),
                  PRIME),
                sub(PRIME, /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[44] + coefficients[45] * adjustments[5]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[44]*/ mload(0x9c0),
                                       mulmod(/*coefficients[45]*/ mload(0x9e0),
                                              /*adjustments[5]*/mload(0x3f60),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/step0: (memory/multi_column_perm/perm/interaction_elm - (column6_row2 + memory/multi_column_perm/hash_interaction_elm0 * column6_row3)) * column9_inter1_row2 - (memory/multi_column_perm/perm/interaction_elm - (column5_row2 + memory/multi_column_perm/hash_interaction_elm0 * column5_row3)) * column9_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                    sub(
                      PRIME,
                      addmod(
                        /*column6_row2*/ mload(0x28a0),
                        mulmod(
                          /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                          /*column6_row3*/ mload(0x28c0),
                          PRIME),
                        PRIME)),
                    PRIME),
                  /*column9_inter1_row2*/ mload(0x3060),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                      sub(
                        PRIME,
                        addmod(
                          /*column5_row2*/ mload(0x24c0),
                          mulmod(
                            /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                            /*column5_row3*/ mload(0x24e0),
                            PRIME),
                          PRIME)),
                      PRIME),
                    /*column9_inter1_row0*/ mload(0x3020),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x3da0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x3840), PRIME)

              // res += val * (coefficients[46] + coefficients[47] * adjustments[6]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[46]*/ mload(0xa00),
                                       mulmod(/*coefficients[47]*/ mload(0xa20),
                                              /*adjustments[6]*/mload(0x3f80),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/last: column9_inter1_row0 - memory/multi_column_perm/perm/public_memory_prod.
              let val := addmod(
                /*column9_inter1_row0*/ mload(0x3020),
                sub(PRIME, /*memory/multi_column_perm/perm/public_memory_prod*/ mload(0x1a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, mload(0x3860), PRIME)

              // res += val * (coefficients[48] + coefficients[49] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[48]*/ mload(0xa40),
                                       mulmod(/*coefficients[49]*/ mload(0xa60),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/diff_is_bit: memory__address_diff_0 * memory__address_diff_0 - memory__address_diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/memory/address_diff_0*/ mload(0x32c0),
                  /*intermediate_value/memory/address_diff_0*/ mload(0x32c0),
                  PRIME),
                sub(PRIME, /*intermediate_value/memory/address_diff_0*/ mload(0x32c0)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x3da0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x3840), PRIME)

              // res += val * (coefficients[50] + coefficients[51] * adjustments[6]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[50]*/ mload(0xa80),
                                       mulmod(/*coefficients[51]*/ mload(0xaa0),
                                              /*adjustments[6]*/mload(0x3f80),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/is_func: (memory__address_diff_0 - 1) * (column6_row1 - column6_row3).
              let val := mulmod(
                addmod(/*intermediate_value/memory/address_diff_0*/ mload(0x32c0), sub(PRIME, 1), PRIME),
                addmod(/*column6_row1*/ mload(0x2880), sub(PRIME, /*column6_row3*/ mload(0x28c0)), PRIME),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x3da0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x3840), PRIME)

              // res += val * (coefficients[52] + coefficients[53] * adjustments[6]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[52]*/ mload(0xac0),
                                       mulmod(/*coefficients[53]*/ mload(0xae0),
                                              /*adjustments[6]*/mload(0x3f80),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/initial_addr: column6_row0 - 1.
              let val := addmod(/*column6_row0*/ mload(0x2860), sub(PRIME, 1), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[54] + coefficients[55] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[54]*/ mload(0xb00),
                                       mulmod(/*coefficients[55]*/ mload(0xb20),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for public_memory_addr_zero: column5_row2.
              let val := /*column5_row2*/ mload(0x24c0)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, mload(0x3880), PRIME)

              // res += val * (coefficients[56] + coefficients[57] * adjustments[7]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[56]*/ mload(0xb40),
                                       mulmod(/*coefficients[57]*/ mload(0xb60),
                                              /*adjustments[7]*/mload(0x3fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for public_memory_value_zero: column5_row3.
              let val := /*column5_row3*/ mload(0x24e0)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, mload(0x3880), PRIME)

              // res += val * (coefficients[58] + coefficients[59] * adjustments[7]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[58]*/ mload(0xb80),
                                       mulmod(/*coefficients[59]*/ mload(0xba0),
                                              /*adjustments[7]*/mload(0x3fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/perm/init0: (rc16/perm/interaction_elm - column7_row2) * column9_inter1_row1 + column7_row0 - rc16/perm/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x1c0),
                      sub(PRIME, /*column7_row2*/ mload(0x2920)),
                      PRIME),
                    /*column9_inter1_row1*/ mload(0x3040),
                    PRIME),
                  /*column7_row0*/ mload(0x28e0),
                  PRIME),
                sub(PRIME, /*rc16/perm/interaction_elm*/ mload(0x1c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[60] + coefficients[61] * adjustments[5]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[60]*/ mload(0xbc0),
                                       mulmod(/*coefficients[61]*/ mload(0xbe0),
                                              /*adjustments[5]*/mload(0x3f60),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/perm/step0: (rc16/perm/interaction_elm - column7_row6) * column9_inter1_row5 - (rc16/perm/interaction_elm - column7_row4) * column9_inter1_row1.
              let val := addmod(
                mulmod(
                  addmod(
                    /*rc16/perm/interaction_elm*/ mload(0x1c0),
                    sub(PRIME, /*column7_row6*/ mload(0x29a0)),
                    PRIME),
                  /*column9_inter1_row5*/ mload(0x3080),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x1c0),
                      sub(PRIME, /*column7_row4*/ mload(0x2960)),
                      PRIME),
                    /*column9_inter1_row1*/ mload(0x3040),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= numerators[3].
              val := mulmod(val, mload(0x3dc0), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x38a0), PRIME)

              // res += val * (coefficients[62] + coefficients[63] * adjustments[8]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[62]*/ mload(0xc00),
                                       mulmod(/*coefficients[63]*/ mload(0xc20),
                                              /*adjustments[8]*/mload(0x3fc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/perm/last: column9_inter1_row1 - rc16/perm/public_memory_prod.
              let val := addmod(
                /*column9_inter1_row1*/ mload(0x3040),
                sub(PRIME, /*rc16/perm/public_memory_prod*/ mload(0x1e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x38c0), PRIME)

              // res += val * (coefficients[64] + coefficients[65] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[64]*/ mload(0xc40),
                                       mulmod(/*coefficients[65]*/ mload(0xc60),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/diff_is_bit: rc16__diff_0 * rc16__diff_0 - rc16__diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc16/diff_0*/ mload(0x32e0),
                  /*intermediate_value/rc16/diff_0*/ mload(0x32e0),
                  PRIME),
                sub(PRIME, /*intermediate_value/rc16/diff_0*/ mload(0x32e0)),
                PRIME)

              // Numerator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= numerators[3].
              val := mulmod(val, mload(0x3dc0), PRIME)
              // Denominator: point^(trace_length / 4) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x38a0), PRIME)

              // res += val * (coefficients[66] + coefficients[67] * adjustments[8]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[66]*/ mload(0xc80),
                                       mulmod(/*coefficients[67]*/ mload(0xca0),
                                              /*adjustments[8]*/mload(0x3fc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/minimum: column7_row2 - rc_min.
              let val := addmod(/*column7_row2*/ mload(0x2920), sub(PRIME, /*rc_min*/ mload(0x200)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[68] + coefficients[69] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[68]*/ mload(0xcc0),
                                       mulmod(/*coefficients[69]*/ mload(0xce0),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/maximum: column7_row2 - rc_max.
              let val := addmod(/*column7_row2*/ mload(0x2920), sub(PRIME, /*rc_max*/ mload(0x220)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(4 * (trace_length / 4 - 1)).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x38c0), PRIME)

              // res += val * (coefficients[70] + coefficients[71] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[70]*/ mload(0xd00),
                                       mulmod(/*coefficients[71]*/ mload(0xd20),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero: column8_row80 * (column4_row0 - (column4_row1 + column4_row1)).
              let val := mulmod(
                /*column8_row80*/ mload(0x2f00),
                addmod(
                  /*column4_row0*/ mload(0x2360),
                  sub(
                    PRIME,
                    addmod(/*column4_row1*/ mload(0x2380), /*column4_row1*/ mload(0x2380), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[72] + coefficients[73] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[72]*/ mload(0xd40),
                                       mulmod(/*coefficients[73]*/ mload(0xd60),
                                              /*adjustments[9]*/mload(0x3fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column8_row80 * (column4_row1 - 3138550867693340381917894711603833208051177722232017256448 * column4_row192).
              let val := mulmod(
                /*column8_row80*/ mload(0x2f00),
                addmod(
                  /*column4_row1*/ mload(0x2380),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column4_row192*/ mload(0x23a0),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[74] + coefficients[75] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[74]*/ mload(0xd80),
                                       mulmod(/*coefficients[75]*/ mload(0xda0),
                                              /*adjustments[9]*/mload(0x3fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192: column8_row80 - column3_row255 * (column4_row192 - (column4_row193 + column4_row193)).
              let val := addmod(
                /*column8_row80*/ mload(0x2f00),
                sub(
                  PRIME,
                  mulmod(
                    /*column3_row255*/ mload(0x2340),
                    addmod(
                      /*column4_row192*/ mload(0x23a0),
                      sub(
                        PRIME,
                        addmod(/*column4_row193*/ mload(0x23c0), /*column4_row193*/ mload(0x23c0), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[76] + coefficients[77] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[76]*/ mload(0xdc0),
                                       mulmod(/*coefficients[77]*/ mload(0xde0),
                                              /*adjustments[9]*/mload(0x3fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column3_row255 * (column4_row193 - 8 * column4_row196).
              let val := mulmod(
                /*column3_row255*/ mload(0x2340),
                addmod(
                  /*column4_row193*/ mload(0x23c0),
                  sub(PRIME, mulmod(8, /*column4_row196*/ mload(0x23e0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[78] + coefficients[79] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[78]*/ mload(0xe00),
                                       mulmod(/*coefficients[79]*/ mload(0xe20),
                                              /*adjustments[9]*/mload(0x3fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196: column3_row255 - (column4_row251 - (column4_row252 + column4_row252)) * (column4_row196 - (column4_row197 + column4_row197)).
              let val := addmod(
                /*column3_row255*/ mload(0x2340),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column4_row251*/ mload(0x2420),
                      sub(
                        PRIME,
                        addmod(/*column4_row252*/ mload(0x2440), /*column4_row252*/ mload(0x2440), PRIME)),
                      PRIME),
                    addmod(
                      /*column4_row196*/ mload(0x23e0),
                      sub(
                        PRIME,
                        addmod(/*column4_row197*/ mload(0x2400), /*column4_row197*/ mload(0x2400), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[80] + coefficients[81] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[80]*/ mload(0xe40),
                                       mulmod(/*coefficients[81]*/ mload(0xe60),
                                              /*adjustments[9]*/mload(0x3fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column4_row251 - (column4_row252 + column4_row252)) * (column4_row197 - 18014398509481984 * column4_row251).
              let val := mulmod(
                addmod(
                  /*column4_row251*/ mload(0x2420),
                  sub(
                    PRIME,
                    addmod(/*column4_row252*/ mload(0x2440), /*column4_row252*/ mload(0x2440), PRIME)),
                  PRIME),
                addmod(
                  /*column4_row197*/ mload(0x2400),
                  sub(PRIME, mulmod(18014398509481984, /*column4_row251*/ mload(0x2420), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[82] + coefficients[83] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[82]*/ mload(0xe80),
                                       mulmod(/*coefficients[83]*/ mload(0xea0),
                                              /*adjustments[9]*/mload(0x3fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/booleanity_test: pedersen__hash0__ec_subset_sum__bit_0 * (pedersen__hash0__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3300),
                addmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3300),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x3de0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x37a0), PRIME)

              // res += val * (coefficients[84] + coefficients[85] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[84]*/ mload(0xec0),
                                       mulmod(/*coefficients[85]*/ mload(0xee0),
                                              /*adjustments[10]*/mload(0x4000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_extraction_end: column4_row0.
              let val := /*column4_row0*/ mload(0x2360)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x3900), PRIME)

              // res += val * (coefficients[86] + coefficients[87] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[86]*/ mload(0xf00),
                                       mulmod(/*coefficients[87]*/ mload(0xf20),
                                              /*adjustments[11]*/mload(0x4020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/zeros_tail: column4_row0.
              let val := /*column4_row0*/ mload(0x2360)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x3920), PRIME)

              // res += val * (coefficients[88] + coefficients[89] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[88]*/ mload(0xf40),
                                       mulmod(/*coefficients[89]*/ mload(0xf60),
                                              /*adjustments[11]*/mload(0x4020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/slope: pedersen__hash0__ec_subset_sum__bit_0 * (column2_row0 - pedersen__points__y) - column3_row0 * (column1_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3300),
                  addmod(
                    /*column2_row0*/ mload(0x22a0),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column3_row0*/ mload(0x2320),
                    addmod(
                      /*column1_row0*/ mload(0x2200),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x3de0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x37a0), PRIME)

              // res += val * (coefficients[90] + coefficients[91] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[90]*/ mload(0xf80),
                                       mulmod(/*coefficients[91]*/ mload(0xfa0),
                                              /*adjustments[10]*/mload(0x4000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/x: column3_row0 * column3_row0 - pedersen__hash0__ec_subset_sum__bit_0 * (column1_row0 + pedersen__points__x + column1_row1).
              let val := addmod(
                mulmod(/*column3_row0*/ mload(0x2320), /*column3_row0*/ mload(0x2320), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3300),
                    addmod(
                      addmod(
                        /*column1_row0*/ mload(0x2200),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column1_row1*/ mload(0x2220),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x3de0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x37a0), PRIME)

              // res += val * (coefficients[92] + coefficients[93] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[92]*/ mload(0xfc0),
                                       mulmod(/*coefficients[93]*/ mload(0xfe0),
                                              /*adjustments[10]*/mload(0x4000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/y: pedersen__hash0__ec_subset_sum__bit_0 * (column2_row0 + column2_row1) - column3_row0 * (column1_row0 - column1_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3300),
                  addmod(/*column2_row0*/ mload(0x22a0), /*column2_row1*/ mload(0x22c0), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column3_row0*/ mload(0x2320),
                    addmod(/*column1_row0*/ mload(0x2200), sub(PRIME, /*column1_row1*/ mload(0x2220)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x3de0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x37a0), PRIME)

              // res += val * (coefficients[94] + coefficients[95] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[94]*/ mload(0x1000),
                                       mulmod(/*coefficients[95]*/ mload(0x1020),
                                              /*adjustments[10]*/mload(0x4000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/x: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column1_row1 - column1_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x3320),
                addmod(/*column1_row1*/ mload(0x2220), sub(PRIME, /*column1_row0*/ mload(0x2200)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x3de0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x37a0), PRIME)

              // res += val * (coefficients[96] + coefficients[97] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[96]*/ mload(0x1040),
                                       mulmod(/*coefficients[97]*/ mload(0x1060),
                                              /*adjustments[10]*/mload(0x4000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/y: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column2_row1 - column2_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x3320),
                addmod(/*column2_row1*/ mload(0x22c0), sub(PRIME, /*column2_row0*/ mload(0x22a0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x3de0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x37a0), PRIME)

              // res += val * (coefficients[98] + coefficients[99] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[98]*/ mload(0x1080),
                                       mulmod(/*coefficients[99]*/ mload(0x10a0),
                                              /*adjustments[10]*/mload(0x4000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/x: column1_row256 - column1_row255.
              let val := addmod(
                /*column1_row256*/ mload(0x2260),
                sub(PRIME, /*column1_row255*/ mload(0x2240)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x3e00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[100] + coefficients[101] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[100]*/ mload(0x10c0),
                                       mulmod(/*coefficients[101]*/ mload(0x10e0),
                                              /*adjustments[12]*/mload(0x4040),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/y: column2_row256 - column2_row255.
              let val := addmod(
                /*column2_row256*/ mload(0x2300),
                sub(PRIME, /*column2_row255*/ mload(0x22e0)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x3e00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[102] + coefficients[103] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[102]*/ mload(0x1100),
                                       mulmod(/*coefficients[103]*/ mload(0x1120),
                                              /*adjustments[12]*/mload(0x4040),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/x: column1_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column1_row0*/ mload(0x2200),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x3940), PRIME)

              // res += val * (coefficients[104] + coefficients[105] * adjustments[13]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[104]*/ mload(0x1140),
                                       mulmod(/*coefficients[105]*/ mload(0x1160),
                                              /*adjustments[13]*/mload(0x4060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/y: column2_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column2_row0*/ mload(0x22a0),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x260)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x3940), PRIME)

              // res += val * (coefficients[106] + coefficients[107] * adjustments[13]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[106]*/ mload(0x1180),
                                       mulmod(/*coefficients[107]*/ mload(0x11a0),
                                              /*adjustments[13]*/mload(0x4060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value0: column5_row7 - column4_row0.
              let val := addmod(/*column5_row7*/ mload(0x2560), sub(PRIME, /*column4_row0*/ mload(0x2360)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x3940), PRIME)

              // res += val * (coefficients[108] + coefficients[109] * adjustments[13]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[108]*/ mload(0x11c0),
                                       mulmod(/*coefficients[109]*/ mload(0x11e0),
                                              /*adjustments[13]*/mload(0x4060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input0_addr: column5_row518 - (column5_row134 + 1).
              let val := addmod(
                /*column5_row518*/ mload(0x27e0),
                sub(PRIME, addmod(/*column5_row134*/ mload(0x26a0), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(512 * (trace_length / 512 - 1)).
              // val *= numerators[6].
              val := mulmod(val, mload(0x3e20), PRIME)
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x3940), PRIME)

              // res += val * (coefficients[110] + coefficients[111] * adjustments[14]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[110]*/ mload(0x1200),
                                       mulmod(/*coefficients[111]*/ mload(0x1220),
                                              /*adjustments[14]*/mload(0x4080),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/init_addr: column5_row6 - initial_pedersen_addr.
              let val := addmod(
                /*column5_row6*/ mload(0x2540),
                sub(PRIME, /*initial_pedersen_addr*/ mload(0x280)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[112] + coefficients[113] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[112]*/ mload(0x1240),
                                       mulmod(/*coefficients[113]*/ mload(0x1260),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value0: column5_row263 - column4_row256.
              let val := addmod(
                /*column5_row263*/ mload(0x2740),
                sub(PRIME, /*column4_row256*/ mload(0x2460)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x3940), PRIME)

              // res += val * (coefficients[114] + coefficients[115] * adjustments[13]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[114]*/ mload(0x1280),
                                       mulmod(/*coefficients[115]*/ mload(0x12a0),
                                              /*adjustments[13]*/mload(0x4060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input1_addr: column5_row262 - (column5_row6 + 1).
              let val := addmod(
                /*column5_row262*/ mload(0x2720),
                sub(PRIME, addmod(/*column5_row6*/ mload(0x2540), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x3940), PRIME)

              // res += val * (coefficients[116] + coefficients[117] * adjustments[13]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[116]*/ mload(0x12c0),
                                       mulmod(/*coefficients[117]*/ mload(0x12e0),
                                              /*adjustments[13]*/mload(0x4060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/output_value0: column5_row135 - column1_row511.
              let val := addmod(
                /*column5_row135*/ mload(0x26c0),
                sub(PRIME, /*column1_row511*/ mload(0x2280)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x3940), PRIME)

              // res += val * (coefficients[118] + coefficients[119] * adjustments[13]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[118]*/ mload(0x1300),
                                       mulmod(/*coefficients[119]*/ mload(0x1320),
                                              /*adjustments[13]*/mload(0x4060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/output_addr: column5_row134 - (column5_row262 + 1).
              let val := addmod(
                /*column5_row134*/ mload(0x26a0),
                sub(PRIME, addmod(/*column5_row262*/ mload(0x2720), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x3940), PRIME)

              // res += val * (coefficients[120] + coefficients[121] * adjustments[13]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[120]*/ mload(0x1340),
                                       mulmod(/*coefficients[121]*/ mload(0x1360),
                                              /*adjustments[13]*/mload(0x4060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc_builtin/value: rc_builtin__value7_0 - column5_row71.
              let val := addmod(
                /*intermediate_value/rc_builtin/value7_0*/ mload(0x3420),
                sub(PRIME, /*column5_row71*/ mload(0x2680)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[122] + coefficients[123] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[122]*/ mload(0x1380),
                                       mulmod(/*coefficients[123]*/ mload(0x13a0),
                                              /*adjustments[11]*/mload(0x4020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc_builtin/addr_step: column5_row326 - (column5_row70 + 1).
              let val := addmod(
                /*column5_row326*/ mload(0x2760),
                sub(PRIME, addmod(/*column5_row70*/ mload(0x2660), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= numerators[7].
              val := mulmod(val, mload(0x3e40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[124] + coefficients[125] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[124]*/ mload(0x13c0),
                                       mulmod(/*coefficients[125]*/ mload(0x13e0),
                                              /*adjustments[15]*/mload(0x40a0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc_builtin/init_addr: column5_row70 - initial_rc_addr.
              let val := addmod(
                /*column5_row70*/ mload(0x2660),
                sub(PRIME, /*initial_rc_addr*/ mload(0x2a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[126] + coefficients[127] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[126]*/ mload(0x1400),
                                       mulmod(/*coefficients[127]*/ mload(0x1420),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/slope: ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa/sig_config.alpha - (column7_row39 + column7_row39) * column7_row23.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x3440),
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x3440),
                      PRIME),
                    /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x3440),
                    PRIME),
                  /*ecdsa/sig_config.alpha*/ mload(0x2c0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(/*column7_row39*/ mload(0x2b20), /*column7_row39*/ mload(0x2b20), PRIME),
                    /*column7_row23*/ mload(0x2ac0),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[128] + coefficients[129] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[128]*/ mload(0x1440),
                                       mulmod(/*coefficients[129]*/ mload(0x1460),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/x: column7_row23 * column7_row23 - (column7_row7 + column7_row7 + column7_row71).
              let val := addmod(
                mulmod(/*column7_row23*/ mload(0x2ac0), /*column7_row23*/ mload(0x2ac0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column7_row7*/ mload(0x29c0), /*column7_row7*/ mload(0x29c0), PRIME),
                    /*column7_row71*/ mload(0x2bc0),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[130] + coefficients[131] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[130]*/ mload(0x1480),
                                       mulmod(/*coefficients[131]*/ mload(0x14a0),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/y: column7_row39 + column7_row103 - column7_row23 * (column7_row7 - column7_row71).
              let val := addmod(
                addmod(/*column7_row39*/ mload(0x2b20), /*column7_row103*/ mload(0x2c40), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column7_row23*/ mload(0x2ac0),
                    addmod(/*column7_row7*/ mload(0x29c0), sub(PRIME, /*column7_row71*/ mload(0x2bc0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[132] + coefficients[133] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[132]*/ mload(0x14c0),
                                       mulmod(/*coefficients[133]*/ mload(0x14e0),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/booleanity_test: ecdsa__signature0__exponentiate_generator__bit_0 * (ecdsa__signature0__exponentiate_generator__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x3460),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x3460),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[9].
              val := mulmod(val, mload(0x3e80), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, mload(0x3980), PRIME)

              // res += val * (coefficients[134] + coefficients[135] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[134]*/ mload(0x1500),
                                       mulmod(/*coefficients[135]*/ mload(0x1520),
                                              /*adjustments[17]*/mload(0x40e0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/bit_extraction_end: column8_row96.
              let val := /*column8_row96*/ mload(0x2f20)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[16].
              val := mulmod(val, mload(0x39a0), PRIME)

              // res += val * (coefficients[136] + coefficients[137] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[136]*/ mload(0x1540),
                                       mulmod(/*coefficients[137]*/ mload(0x1560),
                                              /*adjustments[18]*/mload(0x4100),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/zeros_tail: column8_row96.
              let val := /*column8_row96*/ mload(0x2f20)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[17].
              val := mulmod(val, mload(0x39c0), PRIME)

              // res += val * (coefficients[138] + coefficients[139] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[138]*/ mload(0x1580),
                                       mulmod(/*coefficients[139]*/ mload(0x15a0),
                                              /*adjustments[18]*/mload(0x4100),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/slope: ecdsa__signature0__exponentiate_generator__bit_0 * (column8_row64 - ecdsa__generator_points__y) - column8_row32 * (column8_row0 - ecdsa__generator_points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x3460),
                  addmod(
                    /*column8_row64*/ mload(0x2ee0),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/y*/ mload(0x60)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row32*/ mload(0x2ec0),
                    addmod(
                      /*column8_row0*/ mload(0x2e80),
                      sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[9].
              val := mulmod(val, mload(0x3e80), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, mload(0x3980), PRIME)

              // res += val * (coefficients[140] + coefficients[141] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[140]*/ mload(0x15c0),
                                       mulmod(/*coefficients[141]*/ mload(0x15e0),
                                              /*adjustments[17]*/mload(0x40e0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x: column8_row32 * column8_row32 - ecdsa__signature0__exponentiate_generator__bit_0 * (column8_row0 + ecdsa__generator_points__x + column8_row128).
              let val := addmod(
                mulmod(/*column8_row32*/ mload(0x2ec0), /*column8_row32*/ mload(0x2ec0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x3460),
                    addmod(
                      addmod(
                        /*column8_row0*/ mload(0x2e80),
                        /*periodic_column/ecdsa/generator_points/x*/ mload(0x40),
                        PRIME),
                      /*column8_row128*/ mload(0x2f40),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[9].
              val := mulmod(val, mload(0x3e80), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, mload(0x3980), PRIME)

              // res += val * (coefficients[142] + coefficients[143] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[142]*/ mload(0x1600),
                                       mulmod(/*coefficients[143]*/ mload(0x1620),
                                              /*adjustments[17]*/mload(0x40e0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/y: ecdsa__signature0__exponentiate_generator__bit_0 * (column8_row64 + column8_row192) - column8_row32 * (column8_row0 - column8_row128).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x3460),
                  addmod(/*column8_row64*/ mload(0x2ee0), /*column8_row192*/ mload(0x2f60), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row32*/ mload(0x2ec0),
                    addmod(/*column8_row0*/ mload(0x2e80), sub(PRIME, /*column8_row128*/ mload(0x2f40)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[9].
              val := mulmod(val, mload(0x3e80), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, mload(0x3980), PRIME)

              // res += val * (coefficients[144] + coefficients[145] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[144]*/ mload(0x1640),
                                       mulmod(/*coefficients[145]*/ mload(0x1660),
                                              /*adjustments[17]*/mload(0x40e0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv: column8_row16 * (column8_row0 - ecdsa__generator_points__x) - 1.
              let val := addmod(
                mulmod(
                  /*column8_row16*/ mload(0x2ea0),
                  addmod(
                    /*column8_row0*/ mload(0x2e80),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[9].
              val := mulmod(val, mload(0x3e80), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, mload(0x3980), PRIME)

              // res += val * (coefficients[146] + coefficients[147] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[146]*/ mload(0x1680),
                                       mulmod(/*coefficients[147]*/ mload(0x16a0),
                                              /*adjustments[17]*/mload(0x40e0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/x: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column8_row128 - column8_row0).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x3480),
                addmod(/*column8_row128*/ mload(0x2f40), sub(PRIME, /*column8_row0*/ mload(0x2e80)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[9].
              val := mulmod(val, mload(0x3e80), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, mload(0x3980), PRIME)

              // res += val * (coefficients[148] + coefficients[149] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[148]*/ mload(0x16c0),
                                       mulmod(/*coefficients[149]*/ mload(0x16e0),
                                              /*adjustments[17]*/mload(0x40e0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/y: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column8_row192 - column8_row64).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x3480),
                addmod(
                  /*column8_row192*/ mload(0x2f60),
                  sub(PRIME, /*column8_row64*/ mload(0x2ee0)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 32768) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[9].
              val := mulmod(val, mload(0x3e80), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[15].
              val := mulmod(val, mload(0x3980), PRIME)

              // res += val * (coefficients[150] + coefficients[151] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[150]*/ mload(0x1700),
                                       mulmod(/*coefficients[151]*/ mload(0x1720),
                                              /*adjustments[17]*/mload(0x40e0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/booleanity_test: ecdsa__signature0__exponentiate_key__bit_0 * (ecdsa__signature0__exponentiate_key__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x34a0),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x34a0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[152] + coefficients[153] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[152]*/ mload(0x1740),
                                       mulmod(/*coefficients[153]*/ mload(0x1760),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/bit_extraction_end: column7_row31.
              let val := /*column7_row31*/ mload(0x2b00)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16384) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x39e0), PRIME)

              // res += val * (coefficients[154] + coefficients[155] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[154]*/ mload(0x1780),
                                       mulmod(/*coefficients[155]*/ mload(0x17a0),
                                              /*adjustments[19]*/mload(0x4120),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/zeros_tail: column7_row31.
              let val := /*column7_row31*/ mload(0x2b00)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x3a00), PRIME)

              // res += val * (coefficients[156] + coefficients[157] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[156]*/ mload(0x17c0),
                                       mulmod(/*coefficients[157]*/ mload(0x17e0),
                                              /*adjustments[19]*/mload(0x4120),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/slope: ecdsa__signature0__exponentiate_key__bit_0 * (column7_row15 - column7_row39) - column7_row47 * (column7_row55 - column7_row7).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x34a0),
                  addmod(/*column7_row15*/ mload(0x2a80), sub(PRIME, /*column7_row39*/ mload(0x2b20)), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column7_row47*/ mload(0x2b60),
                    addmod(/*column7_row55*/ mload(0x2b80), sub(PRIME, /*column7_row7*/ mload(0x29c0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[158] + coefficients[159] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[158]*/ mload(0x1800),
                                       mulmod(/*coefficients[159]*/ mload(0x1820),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x: column7_row47 * column7_row47 - ecdsa__signature0__exponentiate_key__bit_0 * (column7_row55 + column7_row7 + column7_row119).
              let val := addmod(
                mulmod(/*column7_row47*/ mload(0x2b60), /*column7_row47*/ mload(0x2b60), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x34a0),
                    addmod(
                      addmod(/*column7_row55*/ mload(0x2b80), /*column7_row7*/ mload(0x29c0), PRIME),
                      /*column7_row119*/ mload(0x2c80),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[160] + coefficients[161] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[160]*/ mload(0x1840),
                                       mulmod(/*coefficients[161]*/ mload(0x1860),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/y: ecdsa__signature0__exponentiate_key__bit_0 * (column7_row15 + column7_row79) - column7_row47 * (column7_row55 - column7_row119).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x34a0),
                  addmod(/*column7_row15*/ mload(0x2a80), /*column7_row79*/ mload(0x2c00), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column7_row47*/ mload(0x2b60),
                    addmod(
                      /*column7_row55*/ mload(0x2b80),
                      sub(PRIME, /*column7_row119*/ mload(0x2c80)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[162] + coefficients[163] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[162]*/ mload(0x1880),
                                       mulmod(/*coefficients[163]*/ mload(0x18a0),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x_diff_inv: column7_row63 * (column7_row55 - column7_row7) - 1.
              let val := addmod(
                mulmod(
                  /*column7_row63*/ mload(0x2ba0),
                  addmod(/*column7_row55*/ mload(0x2b80), sub(PRIME, /*column7_row7*/ mload(0x29c0)), PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[164] + coefficients[165] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[164]*/ mload(0x18c0),
                                       mulmod(/*coefficients[165]*/ mload(0x18e0),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/x: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column7_row119 - column7_row55).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x34c0),
                addmod(
                  /*column7_row119*/ mload(0x2c80),
                  sub(PRIME, /*column7_row55*/ mload(0x2b80)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[166] + coefficients[167] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[166]*/ mload(0x1900),
                                       mulmod(/*coefficients[167]*/ mload(0x1920),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/y: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column7_row79 - column7_row15).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x34c0),
                addmod(/*column7_row79*/ mload(0x2c00), sub(PRIME, /*column7_row15*/ mload(0x2a80)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 16384) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x3e60), PRIME)
              // Denominator: point^(trace_length / 64) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x3960), PRIME)

              // res += val * (coefficients[168] + coefficients[169] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[168]*/ mload(0x1940),
                                       mulmod(/*coefficients[169]*/ mload(0x1960),
                                              /*adjustments[16]*/mload(0x40c0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/x: column8_row0 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column8_row0*/ mload(0x2e80),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[170] + coefficients[171] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[170]*/ mload(0x1980),
                                       mulmod(/*coefficients[171]*/ mload(0x19a0),
                                              /*adjustments[18]*/mload(0x4100),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/y: column8_row64 + ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column8_row64*/ mload(0x2ee0),
                /*ecdsa/sig_config.shift_point.y*/ mload(0x300),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[172] + coefficients[173] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[172]*/ mload(0x19c0),
                                       mulmod(/*coefficients[173]*/ mload(0x19e0),
                                              /*adjustments[18]*/mload(0x4100),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/x: column7_row55 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column7_row55*/ mload(0x2b80),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, mload(0x3a40), PRIME)

              // res += val * (coefficients[174] + coefficients[175] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[174]*/ mload(0x1a00),
                                       mulmod(/*coefficients[175]*/ mload(0x1a20),
                                              /*adjustments[19]*/mload(0x4120),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/y: column7_row15 - ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column7_row15*/ mload(0x2a80),
                sub(PRIME, /*ecdsa/sig_config.shift_point.y*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, mload(0x3a40), PRIME)

              // res += val * (coefficients[176] + coefficients[177] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[176]*/ mload(0x1a40),
                                       mulmod(/*coefficients[177]*/ mload(0x1a60),
                                              /*adjustments[19]*/mload(0x4120),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/slope: column8_row32704 - (column7_row16335 + column8_row32656 * (column8_row32640 - column7_row16375)).
              let val := addmod(
                /*column8_row32704*/ mload(0x3000),
                sub(
                  PRIME,
                  addmod(
                    /*column7_row16335*/ mload(0x2d20),
                    mulmod(
                      /*column8_row32656*/ mload(0x2fc0),
                      addmod(
                        /*column8_row32640*/ mload(0x2fa0),
                        sub(PRIME, /*column7_row16375*/ mload(0x2d80)),
                        PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[178] + coefficients[179] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[178]*/ mload(0x1a80),
                                       mulmod(/*coefficients[179]*/ mload(0x1aa0),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x: column8_row32656 * column8_row32656 - (column8_row32640 + column7_row16375 + column7_row16391).
              let val := addmod(
                mulmod(/*column8_row32656*/ mload(0x2fc0), /*column8_row32656*/ mload(0x2fc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column8_row32640*/ mload(0x2fa0), /*column7_row16375*/ mload(0x2d80), PRIME),
                    /*column7_row16391*/ mload(0x2dc0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[180] + coefficients[181] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[180]*/ mload(0x1ac0),
                                       mulmod(/*coefficients[181]*/ mload(0x1ae0),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/y: column8_row32704 + column7_row16423 - column8_row32656 * (column8_row32640 - column7_row16391).
              let val := addmod(
                addmod(/*column8_row32704*/ mload(0x3000), /*column7_row16423*/ mload(0x2de0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column8_row32656*/ mload(0x2fc0),
                    addmod(
                      /*column8_row32640*/ mload(0x2fa0),
                      sub(PRIME, /*column7_row16391*/ mload(0x2dc0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[182] + coefficients[183] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[182]*/ mload(0x1b00),
                                       mulmod(/*coefficients[183]*/ mload(0x1b20),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x_diff_inv: column8_row32672 * (column8_row32640 - column7_row16375) - 1.
              let val := addmod(
                mulmod(
                  /*column8_row32672*/ mload(0x2fe0),
                  addmod(
                    /*column8_row32640*/ mload(0x2fa0),
                    sub(PRIME, /*column7_row16375*/ mload(0x2d80)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[184] + coefficients[185] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[184]*/ mload(0x1b40),
                                       mulmod(/*coefficients[185]*/ mload(0x1b60),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/slope: column7_row32719 + ecdsa/sig_config.shift_point.y - column7_row16367 * (column7_row32759 - ecdsa/sig_config.shift_point.x).
              let val := addmod(
                addmod(
                  /*column7_row32719*/ mload(0x2e00),
                  /*ecdsa/sig_config.shift_point.y*/ mload(0x300),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column7_row16367*/ mload(0x2d60),
                    addmod(
                      /*column7_row32759*/ mload(0x2e60),
                      sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[186] + coefficients[187] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[186]*/ mload(0x1b80),
                                       mulmod(/*coefficients[187]*/ mload(0x1ba0),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x: column7_row16367 * column7_row16367 - (column7_row32759 + ecdsa/sig_config.shift_point.x + column7_row31).
              let val := addmod(
                mulmod(/*column7_row16367*/ mload(0x2d60), /*column7_row16367*/ mload(0x2d60), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*column7_row32759*/ mload(0x2e60),
                      /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0),
                      PRIME),
                    /*column7_row31*/ mload(0x2b00),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[188] + coefficients[189] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[188]*/ mload(0x1bc0),
                                       mulmod(/*coefficients[189]*/ mload(0x1be0),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x_diff_inv: column7_row32751 * (column7_row32759 - ecdsa/sig_config.shift_point.x) - 1.
              let val := addmod(
                mulmod(
                  /*column7_row32751*/ mload(0x2e40),
                  addmod(
                    /*column7_row32759*/ mload(0x2e60),
                    sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[190] + coefficients[191] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[190]*/ mload(0x1c00),
                                       mulmod(/*coefficients[191]*/ mload(0x1c20),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/z_nonzero: column8_row96 * column7_row16343 - 1.
              let val := addmod(
                mulmod(/*column8_row96*/ mload(0x2f20), /*column7_row16343*/ mload(0x2d40), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[192] + coefficients[193] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[192]*/ mload(0x1c40),
                                       mulmod(/*coefficients[193]*/ mload(0x1c60),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/r_and_w_nonzero: column7_row31 * column7_row16383 - 1.
              let val := addmod(
                mulmod(/*column7_row31*/ mload(0x2b00), /*column7_row16383*/ mload(0x2da0), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16384) - 1.
              // val *= denominator_invs[21].
              val := mulmod(val, mload(0x3a40), PRIME)

              // res += val * (coefficients[194] + coefficients[195] * adjustments[21]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[194]*/ mload(0x1c80),
                                       mulmod(/*coefficients[195]*/ mload(0x1ca0),
                                              /*adjustments[21]*/mload(0x4160),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/x_squared: column7_row32727 - column7_row7 * column7_row7.
              let val := addmod(
                /*column7_row32727*/ mload(0x2e20),
                sub(
                  PRIME,
                  mulmod(/*column7_row7*/ mload(0x29c0), /*column7_row7*/ mload(0x29c0), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[196] + coefficients[197] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[196]*/ mload(0x1cc0),
                                       mulmod(/*coefficients[197]*/ mload(0x1ce0),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/on_curve: column7_row39 * column7_row39 - (column7_row7 * column7_row32727 + ecdsa/sig_config.alpha * column7_row7 + ecdsa/sig_config.beta).
              let val := addmod(
                mulmod(/*column7_row39*/ mload(0x2b20), /*column7_row39*/ mload(0x2b20), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(/*column7_row7*/ mload(0x29c0), /*column7_row32727*/ mload(0x2e20), PRIME),
                      mulmod(/*ecdsa/sig_config.alpha*/ mload(0x2c0), /*column7_row7*/ mload(0x29c0), PRIME),
                      PRIME),
                    /*ecdsa/sig_config.beta*/ mload(0x320),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[198] + coefficients[199] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[198]*/ mload(0x1d00),
                                       mulmod(/*coefficients[199]*/ mload(0x1d20),
                                              /*adjustments[20]*/mload(0x4140),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/init_addr: column5_row390 - initial_ecdsa_addr.
              let val := addmod(
                /*column5_row390*/ mload(0x2780),
                sub(PRIME, /*initial_ecdsa_addr*/ mload(0x340)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[200] + coefficients[201] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[200]*/ mload(0x1d40),
                                       mulmod(/*coefficients[201]*/ mload(0x1d60),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/message_addr: column5_row16774 - (column5_row390 + 1).
              let val := addmod(
                /*column5_row16774*/ mload(0x2800),
                sub(PRIME, addmod(/*column5_row390*/ mload(0x2780), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[202] + coefficients[203] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[202]*/ mload(0x1d80),
                                       mulmod(/*coefficients[203]*/ mload(0x1da0),
                                              /*adjustments[18]*/mload(0x4100),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_addr: column5_row33158 - (column5_row16774 + 1).
              let val := addmod(
                /*column5_row33158*/ mload(0x2840),
                sub(PRIME, addmod(/*column5_row16774*/ mload(0x2800), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(32768 * (trace_length / 32768 - 1)).
              // val *= numerators[10].
              val := mulmod(val, mload(0x3ea0), PRIME)
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[204] + coefficients[205] * adjustments[22]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[204]*/ mload(0x1dc0),
                                       mulmod(/*coefficients[205]*/ mload(0x1de0),
                                              /*adjustments[22]*/mload(0x4180),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/message_value0: column5_row16775 - column8_row96.
              let val := addmod(
                /*column5_row16775*/ mload(0x2820),
                sub(PRIME, /*column8_row96*/ mload(0x2f20)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[206] + coefficients[207] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[206]*/ mload(0x1e00),
                                       mulmod(/*coefficients[207]*/ mload(0x1e20),
                                              /*adjustments[18]*/mload(0x4100),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_value0: column5_row391 - column7_row7.
              let val := addmod(/*column5_row391*/ mload(0x27a0), sub(PRIME, /*column7_row7*/ mload(0x29c0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 32768) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x3a20), PRIME)

              // res += val * (coefficients[208] + coefficients[209] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[208]*/ mload(0x1e40),
                                       mulmod(/*coefficients[209]*/ mload(0x1e60),
                                              /*adjustments[18]*/mload(0x4100),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/req_pc_init_addr: column5_row198 - initial_checkpoints_addr.
              let val := addmod(
                /*column5_row198*/ mload(0x26e0),
                sub(PRIME, /*initial_checkpoints_addr*/ mload(0x360)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x3800), PRIME)

              // res += val * (coefficients[210] + coefficients[211] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[210]*/ mload(0x1e80),
                                       mulmod(/*coefficients[211]*/ mload(0x1ea0),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/req_pc_final_addr: column5_row198 - final_checkpoints_addr.
              let val := addmod(
                /*column5_row198*/ mload(0x26e0),
                sub(PRIME, /*final_checkpoints_addr*/ mload(0x380)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= denominator_invs[22].
              val := mulmod(val, mload(0x3a60), PRIME)

              // res += val * (coefficients[212] + coefficients[213] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[212]*/ mload(0x1ec0),
                                       mulmod(/*coefficients[213]*/ mload(0x1ee0),
                                              /*adjustments[4]*/mload(0x3f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/required_fp_addr: column5_row38 - (column5_row198 + 1).
              let val := addmod(
                /*column5_row38*/ mload(0x2620),
                sub(PRIME, addmod(/*column5_row198*/ mload(0x26e0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[214] + coefficients[215] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[214]*/ mload(0x1f00),
                                       mulmod(/*coefficients[215]*/ mload(0x1f20),
                                              /*adjustments[11]*/mload(0x4020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/required_pc_next_addr: (column5_row454 - column5_row198) * (column5_row454 - (column5_row198 + 2)).
              let val := mulmod(
                addmod(
                  /*column5_row454*/ mload(0x27c0),
                  sub(PRIME, /*column5_row198*/ mload(0x26e0)),
                  PRIME),
                addmod(
                  /*column5_row454*/ mload(0x27c0),
                  sub(PRIME, addmod(/*column5_row198*/ mload(0x26e0), 2, PRIME)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= numerators[7].
              val := mulmod(val, mload(0x3e40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[216] + coefficients[217] * adjustments[23]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[216]*/ mload(0x1f40),
                                       mulmod(/*coefficients[217]*/ mload(0x1f60),
                                              /*adjustments[23]*/mload(0x41a0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/req_pc: (column5_row454 - column5_row198) * (column5_row199 - column5_row0).
              let val := mulmod(
                addmod(
                  /*column5_row454*/ mload(0x27c0),
                  sub(PRIME, /*column5_row198*/ mload(0x26e0)),
                  PRIME),
                addmod(/*column5_row199*/ mload(0x2700), sub(PRIME, /*column5_row0*/ mload(0x2480)), PRIME),
                PRIME)

              // Numerator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= numerators[7].
              val := mulmod(val, mload(0x3e40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[218] + coefficients[219] * adjustments[23]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[218]*/ mload(0x1f80),
                                       mulmod(/*coefficients[219]*/ mload(0x1fa0),
                                              /*adjustments[23]*/mload(0x41a0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/req_fp: (column5_row454 - column5_row198) * (column5_row39 - column7_row9).
              let val := mulmod(
                addmod(
                  /*column5_row454*/ mload(0x27c0),
                  sub(PRIME, /*column5_row198*/ mload(0x26e0)),
                  PRIME),
                addmod(/*column5_row39*/ mload(0x2640), sub(PRIME, /*column7_row9*/ mload(0x2a00)), PRIME),
                PRIME)

              // Numerator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= numerators[7].
              val := mulmod(val, mload(0x3e40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x38e0), PRIME)

              // res += val * (coefficients[220] + coefficients[221] * adjustments[23]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[220]*/ mload(0x1fc0),
                                       mulmod(/*coefficients[221]*/ mload(0x1fe0),
                                              /*adjustments[23]*/mload(0x41a0),
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