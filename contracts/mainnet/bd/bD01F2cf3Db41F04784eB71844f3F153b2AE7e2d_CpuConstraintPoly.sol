/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

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
pragma solidity ^0.6.12;

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
    // [0x240, 0x260) - diluted_check/permutation/interaction_elm.
    // [0x260, 0x280) - diluted_check/permutation/public_memory_prod.
    // [0x280, 0x2a0) - diluted_check/first_elm.
    // [0x2a0, 0x2c0) - diluted_check/interaction_z.
    // [0x2c0, 0x2e0) - diluted_check/interaction_alpha.
    // [0x2e0, 0x300) - diluted_check/final_cum_val.
    // [0x300, 0x320) - pedersen/shift_point.x.
    // [0x320, 0x340) - pedersen/shift_point.y.
    // [0x340, 0x360) - initial_pedersen_addr.
    // [0x360, 0x380) - initial_rc_addr.
    // [0x380, 0x3a0) - ecdsa/sig_config.alpha.
    // [0x3a0, 0x3c0) - ecdsa/sig_config.shift_point.x.
    // [0x3c0, 0x3e0) - ecdsa/sig_config.shift_point.y.
    // [0x3e0, 0x400) - ecdsa/sig_config.beta.
    // [0x400, 0x420) - initial_ecdsa_addr.
    // [0x420, 0x440) - initial_bitwise_addr.
    // [0x440, 0x460) - trace_generator.
    // [0x460, 0x480) - oods_point.
    // [0x480, 0x540) - interaction_elements.
    // [0x540, 0x1de0) - coefficients.
    // [0x1de0, 0x3ce0) - oods_values.
    // ----------------------- end of input data - -------------------------
    // [0x3ce0, 0x3d00) - intermediate_value/cpu/decode/opcode_rc/bit_0.
    // [0x3d00, 0x3d20) - intermediate_value/cpu/decode/opcode_rc/bit_2.
    // [0x3d20, 0x3d40) - intermediate_value/cpu/decode/opcode_rc/bit_4.
    // [0x3d40, 0x3d60) - intermediate_value/cpu/decode/opcode_rc/bit_3.
    // [0x3d60, 0x3d80) - intermediate_value/cpu/decode/flag_op1_base_op0_0.
    // [0x3d80, 0x3da0) - intermediate_value/cpu/decode/opcode_rc/bit_5.
    // [0x3da0, 0x3dc0) - intermediate_value/cpu/decode/opcode_rc/bit_6.
    // [0x3dc0, 0x3de0) - intermediate_value/cpu/decode/opcode_rc/bit_9.
    // [0x3de0, 0x3e00) - intermediate_value/cpu/decode/flag_res_op1_0.
    // [0x3e00, 0x3e20) - intermediate_value/cpu/decode/opcode_rc/bit_7.
    // [0x3e20, 0x3e40) - intermediate_value/cpu/decode/opcode_rc/bit_8.
    // [0x3e40, 0x3e60) - intermediate_value/cpu/decode/flag_pc_update_regular_0.
    // [0x3e60, 0x3e80) - intermediate_value/cpu/decode/opcode_rc/bit_12.
    // [0x3e80, 0x3ea0) - intermediate_value/cpu/decode/opcode_rc/bit_13.
    // [0x3ea0, 0x3ec0) - intermediate_value/cpu/decode/fp_update_regular_0.
    // [0x3ec0, 0x3ee0) - intermediate_value/cpu/decode/opcode_rc/bit_1.
    // [0x3ee0, 0x3f00) - intermediate_value/npc_reg_0.
    // [0x3f00, 0x3f20) - intermediate_value/cpu/decode/opcode_rc/bit_10.
    // [0x3f20, 0x3f40) - intermediate_value/cpu/decode/opcode_rc/bit_11.
    // [0x3f40, 0x3f60) - intermediate_value/cpu/decode/opcode_rc/bit_14.
    // [0x3f60, 0x3f80) - intermediate_value/memory/address_diff_0.
    // [0x3f80, 0x3fa0) - intermediate_value/rc16/diff_0.
    // [0x3fa0, 0x3fc0) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_0.
    // [0x3fc0, 0x3fe0) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0.
    // [0x3fe0, 0x4000) - intermediate_value/pedersen/hash1/ec_subset_sum/bit_0.
    // [0x4000, 0x4020) - intermediate_value/pedersen/hash1/ec_subset_sum/bit_neg_0.
    // [0x4020, 0x4040) - intermediate_value/pedersen/hash2/ec_subset_sum/bit_0.
    // [0x4040, 0x4060) - intermediate_value/pedersen/hash2/ec_subset_sum/bit_neg_0.
    // [0x4060, 0x4080) - intermediate_value/pedersen/hash3/ec_subset_sum/bit_0.
    // [0x4080, 0x40a0) - intermediate_value/pedersen/hash3/ec_subset_sum/bit_neg_0.
    // [0x40a0, 0x40c0) - intermediate_value/rc_builtin/value0_0.
    // [0x40c0, 0x40e0) - intermediate_value/rc_builtin/value1_0.
    // [0x40e0, 0x4100) - intermediate_value/rc_builtin/value2_0.
    // [0x4100, 0x4120) - intermediate_value/rc_builtin/value3_0.
    // [0x4120, 0x4140) - intermediate_value/rc_builtin/value4_0.
    // [0x4140, 0x4160) - intermediate_value/rc_builtin/value5_0.
    // [0x4160, 0x4180) - intermediate_value/rc_builtin/value6_0.
    // [0x4180, 0x41a0) - intermediate_value/rc_builtin/value7_0.
    // [0x41a0, 0x41c0) - intermediate_value/ecdsa/signature0/doubling_key/x_squared.
    // [0x41c0, 0x41e0) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0.
    // [0x41e0, 0x4200) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0.
    // [0x4200, 0x4220) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_0.
    // [0x4220, 0x4240) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0.
    // [0x4240, 0x4260) - intermediate_value/bitwise/sum_var_0_0.
    // [0x4260, 0x4280) - intermediate_value/bitwise/sum_var_8_0.
    // [0x4280, 0x4720) - expmods.
    // [0x4720, 0x49e0) - denominator_invs.
    // [0x49e0, 0x4ca0) - denominators.
    // [0x4ca0, 0x4e20) - numerators.
    // [0x4e20, 0x4ee0) - expmod_context.

    fallback() external {
        uint256 res;
        assembly {
            let PRIME := 0x800000000000011000000000000000000000000000000000000000000000001
            // Copy input from calldata to memory.
            calldatacopy(0x0, 0x0, /*Input data size*/ 0x3ce0)
            let point := /*oods_point*/ mload(0x460)
            function expmod(base, exponent, modulus) -> result {
              let p := /*expmod_context*/ 0x4e20
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
            {
              // Prepare expmods for denominators and numerators.

              // expmods[0] = point^trace_length.
              mstore(0x4280, expmod(point, /*trace_length*/ mload(0x80), PRIME))

              // expmods[1] = point^(trace_length / 16).
              mstore(0x42a0, expmod(point, div(/*trace_length*/ mload(0x80), 16), PRIME))

              // expmods[2] = point^(trace_length / 2).
              mstore(0x42c0, expmod(point, div(/*trace_length*/ mload(0x80), 2), PRIME))

              // expmods[3] = point^(trace_length / 256).
              mstore(0x42e0, expmod(point, div(/*trace_length*/ mload(0x80), 256), PRIME))

              // expmods[4] = point^(trace_length / 512).
              mstore(0x4300, expmod(point, div(/*trace_length*/ mload(0x80), 512), PRIME))

              // expmods[5] = point^(trace_length / 128).
              mstore(0x4320, expmod(point, div(/*trace_length*/ mload(0x80), 128), PRIME))

              // expmods[6] = point^(trace_length / 4096).
              mstore(0x4340, expmod(point, div(/*trace_length*/ mload(0x80), 4096), PRIME))

              // expmods[7] = point^(trace_length / 32).
              mstore(0x4360, expmod(point, div(/*trace_length*/ mload(0x80), 32), PRIME))

              // expmods[8] = point^(trace_length / 8192).
              mstore(0x4380, expmod(point, div(/*trace_length*/ mload(0x80), 8192), PRIME))

              // expmods[9] = point^(trace_length / 1024).
              mstore(0x43a0, expmod(point, div(/*trace_length*/ mload(0x80), 1024), PRIME))

              // expmods[10] = trace_generator^(15 * trace_length / 16).
              mstore(0x43c0, expmod(/*trace_generator*/ mload(0x440), div(mul(15, /*trace_length*/ mload(0x80)), 16), PRIME))

              // expmods[11] = trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x43e0, expmod(/*trace_generator*/ mload(0x440), mul(16, sub(div(/*trace_length*/ mload(0x80), 16), 1)), PRIME))

              // expmods[12] = trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x4400, expmod(/*trace_generator*/ mload(0x440), mul(2, sub(div(/*trace_length*/ mload(0x80), 2), 1)), PRIME))

              // expmods[13] = trace_generator^(trace_length - 1).
              mstore(0x4420, expmod(/*trace_generator*/ mload(0x440), sub(/*trace_length*/ mload(0x80), 1), PRIME))

              // expmods[14] = trace_generator^(255 * trace_length / 256).
              mstore(0x4440, expmod(/*trace_generator*/ mload(0x440), div(mul(255, /*trace_length*/ mload(0x80)), 256), PRIME))

              // expmods[15] = trace_generator^(63 * trace_length / 64).
              mstore(0x4460, expmod(/*trace_generator*/ mload(0x440), div(mul(63, /*trace_length*/ mload(0x80)), 64), PRIME))

              // expmods[16] = trace_generator^(trace_length / 2).
              mstore(0x4480, expmod(/*trace_generator*/ mload(0x440), div(/*trace_length*/ mload(0x80), 2), PRIME))

              // expmods[17] = trace_generator^(128 * (trace_length / 128 - 1)).
              mstore(0x44a0, expmod(/*trace_generator*/ mload(0x440), mul(128, sub(div(/*trace_length*/ mload(0x80), 128), 1)), PRIME))

              // expmods[18] = trace_generator^(251 * trace_length / 256).
              mstore(0x44c0, expmod(/*trace_generator*/ mload(0x440), div(mul(251, /*trace_length*/ mload(0x80)), 256), PRIME))

              // expmods[19] = trace_generator^(8192 * (trace_length / 8192 - 1)).
              mstore(0x44e0, expmod(/*trace_generator*/ mload(0x440), mul(8192, sub(div(/*trace_length*/ mload(0x80), 8192), 1)), PRIME))

              // expmods[20] = trace_generator^(3 * trace_length / 4).
              mstore(0x4500, expmod(/*trace_generator*/ mload(0x440), div(mul(3, /*trace_length*/ mload(0x80)), 4), PRIME))

              // expmods[21] = trace_generator^(4096 * (trace_length / 4096 - 1)).
              mstore(0x4520, expmod(/*trace_generator*/ mload(0x440), mul(4096, sub(div(/*trace_length*/ mload(0x80), 4096), 1)), PRIME))

              // expmods[22] = trace_generator^(trace_length / 64).
              mstore(0x4540, expmod(/*trace_generator*/ mload(0x440), div(/*trace_length*/ mload(0x80), 64), PRIME))

              // expmods[23] = trace_generator^(trace_length / 32).
              mstore(0x4560, expmod(/*trace_generator*/ mload(0x440), div(/*trace_length*/ mload(0x80), 32), PRIME))

              // expmods[24] = trace_generator^(3 * trace_length / 64).
              mstore(0x4580, expmod(/*trace_generator*/ mload(0x440), div(mul(3, /*trace_length*/ mload(0x80)), 64), PRIME))

              // expmods[25] = trace_generator^(trace_length / 16).
              mstore(0x45a0, expmod(/*trace_generator*/ mload(0x440), div(/*trace_length*/ mload(0x80), 16), PRIME))

              // expmods[26] = trace_generator^(5 * trace_length / 64).
              mstore(0x45c0, expmod(/*trace_generator*/ mload(0x440), div(mul(5, /*trace_length*/ mload(0x80)), 64), PRIME))

              // expmods[27] = trace_generator^(3 * trace_length / 32).
              mstore(0x45e0, expmod(/*trace_generator*/ mload(0x440), div(mul(3, /*trace_length*/ mload(0x80)), 32), PRIME))

              // expmods[28] = trace_generator^(7 * trace_length / 64).
              mstore(0x4600, expmod(/*trace_generator*/ mload(0x440), div(mul(7, /*trace_length*/ mload(0x80)), 64), PRIME))

              // expmods[29] = trace_generator^(trace_length / 8).
              mstore(0x4620, expmod(/*trace_generator*/ mload(0x440), div(/*trace_length*/ mload(0x80), 8), PRIME))

              // expmods[30] = trace_generator^(9 * trace_length / 64).
              mstore(0x4640, expmod(/*trace_generator*/ mload(0x440), div(mul(9, /*trace_length*/ mload(0x80)), 64), PRIME))

              // expmods[31] = trace_generator^(5 * trace_length / 32).
              mstore(0x4660, expmod(/*trace_generator*/ mload(0x440), div(mul(5, /*trace_length*/ mload(0x80)), 32), PRIME))

              // expmods[32] = trace_generator^(11 * trace_length / 64).
              mstore(0x4680, expmod(/*trace_generator*/ mload(0x440), div(mul(11, /*trace_length*/ mload(0x80)), 64), PRIME))

              // expmods[33] = trace_generator^(3 * trace_length / 16).
              mstore(0x46a0, expmod(/*trace_generator*/ mload(0x440), div(mul(3, /*trace_length*/ mload(0x80)), 16), PRIME))

              // expmods[34] = trace_generator^(13 * trace_length / 64).
              mstore(0x46c0, expmod(/*trace_generator*/ mload(0x440), div(mul(13, /*trace_length*/ mload(0x80)), 64), PRIME))

              // expmods[35] = trace_generator^(7 * trace_length / 32).
              mstore(0x46e0, expmod(/*trace_generator*/ mload(0x440), div(mul(7, /*trace_length*/ mload(0x80)), 32), PRIME))

              // expmods[36] = trace_generator^(15 * trace_length / 64).
              mstore(0x4700, expmod(/*trace_generator*/ mload(0x440), div(mul(15, /*trace_length*/ mload(0x80)), 64), PRIME))

            }

            {
              // Prepare denominators for batch inverse.

              // Denominator for constraints: 'cpu/decode/opcode_rc/bit', 'diluted_check/permutation/step0', 'diluted_check/step', 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y', 'pedersen/hash1/ec_subset_sum/booleanity_test', 'pedersen/hash1/ec_subset_sum/add_points/slope', 'pedersen/hash1/ec_subset_sum/add_points/x', 'pedersen/hash1/ec_subset_sum/add_points/y', 'pedersen/hash1/ec_subset_sum/copy_point/x', 'pedersen/hash1/ec_subset_sum/copy_point/y', 'pedersen/hash2/ec_subset_sum/booleanity_test', 'pedersen/hash2/ec_subset_sum/add_points/slope', 'pedersen/hash2/ec_subset_sum/add_points/x', 'pedersen/hash2/ec_subset_sum/add_points/y', 'pedersen/hash2/ec_subset_sum/copy_point/x', 'pedersen/hash2/ec_subset_sum/copy_point/y', 'pedersen/hash3/ec_subset_sum/booleanity_test', 'pedersen/hash3/ec_subset_sum/add_points/slope', 'pedersen/hash3/ec_subset_sum/add_points/x', 'pedersen/hash3/ec_subset_sum/add_points/y', 'pedersen/hash3/ec_subset_sum/copy_point/x', 'pedersen/hash3/ec_subset_sum/copy_point/y'.
              // denominators[0] = point^trace_length - 1.
              mstore(0x49e0,
                     addmod(/*point^trace_length*/ mload(0x4280), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc/zero'.
              // denominators[1] = point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              mstore(0x4a00,
                     addmod(
                       /*point^(trace_length / 16)*/ mload(0x42a0),
                       sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x43c0)),
                       PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc_input', 'cpu/decode/flag_op1_base_op0_bit', 'cpu/decode/flag_res_op1_bit', 'cpu/decode/flag_pc_update_regular_bit', 'cpu/decode/fp_update_regular_bit', 'cpu/operands/mem_dst_addr', 'cpu/operands/mem0_addr', 'cpu/operands/mem1_addr', 'cpu/operands/ops_mul', 'cpu/operands/res', 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update', 'cpu/opcodes/call/push_fp', 'cpu/opcodes/call/push_pc', 'cpu/opcodes/call/off0', 'cpu/opcodes/call/off1', 'cpu/opcodes/call/flags', 'cpu/opcodes/ret/off0', 'cpu/opcodes/ret/off2', 'cpu/opcodes/ret/flags', 'cpu/opcodes/assert_eq/assert_eq', 'public_memory_addr_zero', 'public_memory_value_zero', 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y'.
              // denominators[2] = point^(trace_length / 16) - 1.
              mstore(0x4a20,
                     addmod(/*point^(trace_length / 16)*/ mload(0x42a0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'initial_ap', 'initial_fp', 'initial_pc', 'memory/multi_column_perm/perm/init0', 'memory/initial_addr', 'rc16/perm/init0', 'rc16/minimum', 'diluted_check/permutation/init0', 'diluted_check/init', 'diluted_check/first_element', 'pedersen/init_addr', 'rc_builtin/init_addr', 'ecdsa/init_addr', 'bitwise/init_var_pool_addr'.
              // denominators[3] = point - 1.
              mstore(0x4a40,
                     addmod(point, sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'final_ap', 'final_fp', 'final_pc'.
              // denominators[4] = point - trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x4a60,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16 * (trace_length / 16 - 1))*/ mload(0x43e0)),
                       PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func', 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // denominators[5] = point^(trace_length / 2) - 1.
              mstore(0x4a80,
                     addmod(/*point^(trace_length / 2)*/ mload(0x42c0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/last', 'rc16/perm/last', 'rc16/maximum'.
              // denominators[6] = point - trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x4aa0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2 * (trace_length / 2 - 1))*/ mload(0x4400)),
                       PRIME))

              // Denominator for constraints: 'diluted_check/permutation/last', 'diluted_check/last'.
              // denominators[7] = point - trace_generator^(trace_length - 1).
              mstore(0x4ac0,
                     addmod(point, sub(PRIME, /*trace_generator^(trace_length - 1)*/ mload(0x4420)), PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y', 'pedersen/hash1/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash1/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash1/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash1/copy_point/x', 'pedersen/hash1/copy_point/y', 'pedersen/hash2/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash2/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash2/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash2/copy_point/x', 'pedersen/hash2/copy_point/y', 'pedersen/hash3/ec_subset_sum/bit_unpacking/last_one_is_zero', 'pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones0', 'pedersen/hash3/ec_subset_sum/bit_unpacking/cumulative_bit192', 'pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones192', 'pedersen/hash3/ec_subset_sum/bit_unpacking/cumulative_bit196', 'pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones196', 'pedersen/hash3/copy_point/x', 'pedersen/hash3/copy_point/y'.
              // denominators[8] = point^(trace_length / 256) - 1.
              mstore(0x4ae0,
                     addmod(/*point^(trace_length / 256)*/ mload(0x42e0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_extraction_end', 'pedersen/hash1/ec_subset_sum/bit_extraction_end', 'pedersen/hash2/ec_subset_sum/bit_extraction_end', 'pedersen/hash3/ec_subset_sum/bit_extraction_end'.
              // denominators[9] = point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              mstore(0x4b00,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x42e0),
                       sub(PRIME, /*trace_generator^(63 * trace_length / 64)*/ mload(0x4460)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/zeros_tail', 'pedersen/hash1/ec_subset_sum/zeros_tail', 'pedersen/hash2/ec_subset_sum/zeros_tail', 'pedersen/hash3/ec_subset_sum/zeros_tail'.
              // denominators[10] = point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              mstore(0x4b20,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x42e0),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4440)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/init/x', 'pedersen/hash0/init/y', 'pedersen/hash1/init/x', 'pedersen/hash1/init/y', 'pedersen/hash2/init/x', 'pedersen/hash2/init/y', 'pedersen/hash3/init/x', 'pedersen/hash3/init/y', 'pedersen/input0_value0', 'pedersen/input0_value1', 'pedersen/input0_value2', 'pedersen/input0_value3', 'pedersen/input1_value0', 'pedersen/input1_value1', 'pedersen/input1_value2', 'pedersen/input1_value3', 'pedersen/output_value0', 'pedersen/output_value1', 'pedersen/output_value2', 'pedersen/output_value3'.
              // denominators[11] = point^(trace_length / 512) - 1.
              mstore(0x4b40,
                     addmod(/*point^(trace_length / 512)*/ mload(0x4300), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/input0_addr', 'pedersen/input1_addr', 'pedersen/output_addr', 'rc_builtin/value', 'rc_builtin/addr_step'.
              // denominators[12] = point^(trace_length / 128) - 1.
              mstore(0x4b60,
                     addmod(/*point^(trace_length / 128)*/ mload(0x4320), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // denominators[13] = point^(trace_length / 32) - 1.
              mstore(0x4b80,
                     addmod(/*point^(trace_length / 32)*/ mload(0x4360), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/bit_extraction_end'.
              // denominators[14] = point^(trace_length / 8192) - trace_generator^(251 * trace_length / 256).
              mstore(0x4ba0,
                     addmod(
                       /*point^(trace_length / 8192)*/ mload(0x4380),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x44c0)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/zeros_tail'.
              // denominators[15] = point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              mstore(0x4bc0,
                     addmod(
                       /*point^(trace_length / 8192)*/ mload(0x4380),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4440)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/bit_extraction_end'.
              // denominators[16] = point^(trace_length / 4096) - trace_generator^(251 * trace_length / 256).
              mstore(0x4be0,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4340),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x44c0)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/zeros_tail'.
              // denominators[17] = point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              mstore(0x4c00,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4340),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4440)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_gen/x', 'ecdsa/signature0/init_gen/y', 'ecdsa/signature0/add_results/slope', 'ecdsa/signature0/add_results/x', 'ecdsa/signature0/add_results/y', 'ecdsa/signature0/add_results/x_diff_inv', 'ecdsa/signature0/extract_r/slope', 'ecdsa/signature0/extract_r/x', 'ecdsa/signature0/extract_r/x_diff_inv', 'ecdsa/signature0/z_nonzero', 'ecdsa/signature0/q_on_curve/x_squared', 'ecdsa/signature0/q_on_curve/on_curve', 'ecdsa/message_addr', 'ecdsa/pubkey_addr', 'ecdsa/message_value0', 'ecdsa/pubkey_value0'.
              // denominators[18] = point^(trace_length / 8192) - 1.
              mstore(0x4c20,
                     addmod(/*point^(trace_length / 8192)*/ mload(0x4380), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_key/x', 'ecdsa/signature0/init_key/y', 'ecdsa/signature0/r_and_w_nonzero', 'bitwise/x_or_y_addr', 'bitwise/next_var_pool_addr', 'bitwise/or_is_and_plus_xor', 'bitwise/unique_unpacking192', 'bitwise/unique_unpacking193', 'bitwise/unique_unpacking194', 'bitwise/unique_unpacking195'.
              // denominators[19] = point^(trace_length / 4096) - 1.
              mstore(0x4c40,
                     addmod(/*point^(trace_length / 4096)*/ mload(0x4340), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'bitwise/step_var_pool_addr', 'bitwise/partition'.
              // denominators[20] = point^(trace_length / 1024) - 1.
              mstore(0x4c60,
                     addmod(/*point^(trace_length / 1024)*/ mload(0x43a0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'bitwise/addition_is_xor_with_and'.
              // denominators[21] = (point^(trace_length / 4096) - 1) * (point^(trace_length / 4096) - trace_generator^(trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 16)) * (point^(trace_length / 4096) - trace_generator^(5 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(7 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 8)) * (point^(trace_length / 4096) - trace_generator^(9 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(5 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(11 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 16)) * (point^(trace_length / 4096) - trace_generator^(13 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(7 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(15 * trace_length / 64)).
              {
                let denominator := mulmod(
                    mulmod(
                      mulmod(
                        addmod(/*point^(trace_length / 4096)*/ mload(0x4340), sub(PRIME, 1), PRIME),
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4340),
                          sub(PRIME, /*trace_generator^(trace_length / 64)*/ mload(0x4540)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 4096)*/ mload(0x4340),
                        sub(PRIME, /*trace_generator^(trace_length / 32)*/ mload(0x4560)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 4096)*/ mload(0x4340),
                      sub(PRIME, /*trace_generator^(3 * trace_length / 64)*/ mload(0x4580)),
                      PRIME),
                    PRIME)
                denominator := mulmod(
                  denominator,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4340),
                          sub(PRIME, /*trace_generator^(trace_length / 16)*/ mload(0x45a0)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4340),
                          sub(PRIME, /*trace_generator^(5 * trace_length / 64)*/ mload(0x45c0)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 4096)*/ mload(0x4340),
                        sub(PRIME, /*trace_generator^(3 * trace_length / 32)*/ mload(0x45e0)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 4096)*/ mload(0x4340),
                      sub(PRIME, /*trace_generator^(7 * trace_length / 64)*/ mload(0x4600)),
                      PRIME),
                    PRIME),
                  PRIME)
                denominator := mulmod(
                  denominator,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4340),
                          sub(PRIME, /*trace_generator^(trace_length / 8)*/ mload(0x4620)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4340),
                          sub(PRIME, /*trace_generator^(9 * trace_length / 64)*/ mload(0x4640)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 4096)*/ mload(0x4340),
                        sub(PRIME, /*trace_generator^(5 * trace_length / 32)*/ mload(0x4660)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 4096)*/ mload(0x4340),
                      sub(PRIME, /*trace_generator^(11 * trace_length / 64)*/ mload(0x4680)),
                      PRIME),
                    PRIME),
                  PRIME)
                denominator := mulmod(
                  denominator,
                  mulmod(
                    mulmod(
                      mulmod(
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4340),
                          sub(PRIME, /*trace_generator^(3 * trace_length / 16)*/ mload(0x46a0)),
                          PRIME),
                        addmod(
                          /*point^(trace_length / 4096)*/ mload(0x4340),
                          sub(PRIME, /*trace_generator^(13 * trace_length / 64)*/ mload(0x46c0)),
                          PRIME),
                        PRIME),
                      addmod(
                        /*point^(trace_length / 4096)*/ mload(0x4340),
                        sub(PRIME, /*trace_generator^(7 * trace_length / 32)*/ mload(0x46e0)),
                        PRIME),
                      PRIME),
                    addmod(
                      /*point^(trace_length / 4096)*/ mload(0x4340),
                      sub(PRIME, /*trace_generator^(15 * trace_length / 64)*/ mload(0x4700)),
                      PRIME),
                    PRIME),
                  PRIME)
                mstore(0x4c80, denominator)
              }

            }

            {
              // Compute the inverses of the denominators into denominatorInvs using batch inverse.

              // Start by computing the cumulative product.
              // Let (d_0, d_1, d_2, ..., d_{n-1}) be the values in denominators. After this loop
              // denominatorInvs will be (1, d_0, d_0 * d_1, ...) and prod will contain the value of
              // d_0 * ... * d_{n-1}.
              // Compute the offset between the partialProducts array and the input values array.
              let productsToValuesOffset := 0x2c0
              let prod := 1
              let partialProductEndPtr := 0x49e0
              for { let partialProductPtr := 0x4720 }
                  lt(partialProductPtr, partialProductEndPtr)
                  { partialProductPtr := add(partialProductPtr, 0x20) } {
                  mstore(partialProductPtr, prod)
                  // prod *= d_{i}.
                  prod := mulmod(prod,
                                 mload(add(partialProductPtr, productsToValuesOffset)),
                                 PRIME)
              }

              let firstPartialProductPtr := 0x4720
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
              let currentPartialProductPtr := 0x49e0
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
              // Compute numerators.

              // Numerator for constraints 'cpu/decode/opcode_rc/bit'.
              // numerators[0] = point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              mstore(0x4ca0,
                     addmod(
                       /*point^(trace_length / 16)*/ mload(0x42a0),
                       sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x43c0)),
                       PRIME))

              // Numerator for constraints 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update'.
              // numerators[1] = point - trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x4cc0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16 * (trace_length / 16 - 1))*/ mload(0x43e0)),
                       PRIME))

              // Numerator for constraints 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func', 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // numerators[2] = point - trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x4ce0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2 * (trace_length / 2 - 1))*/ mload(0x4400)),
                       PRIME))

              // Numerator for constraints 'diluted_check/permutation/step0', 'diluted_check/step'.
              // numerators[3] = point - trace_generator^(trace_length - 1).
              mstore(0x4d00,
                     addmod(point, sub(PRIME, /*trace_generator^(trace_length - 1)*/ mload(0x4420)), PRIME))

              // Numerator for constraints 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y', 'pedersen/hash1/ec_subset_sum/booleanity_test', 'pedersen/hash1/ec_subset_sum/add_points/slope', 'pedersen/hash1/ec_subset_sum/add_points/x', 'pedersen/hash1/ec_subset_sum/add_points/y', 'pedersen/hash1/ec_subset_sum/copy_point/x', 'pedersen/hash1/ec_subset_sum/copy_point/y', 'pedersen/hash2/ec_subset_sum/booleanity_test', 'pedersen/hash2/ec_subset_sum/add_points/slope', 'pedersen/hash2/ec_subset_sum/add_points/x', 'pedersen/hash2/ec_subset_sum/add_points/y', 'pedersen/hash2/ec_subset_sum/copy_point/x', 'pedersen/hash2/ec_subset_sum/copy_point/y', 'pedersen/hash3/ec_subset_sum/booleanity_test', 'pedersen/hash3/ec_subset_sum/add_points/slope', 'pedersen/hash3/ec_subset_sum/add_points/x', 'pedersen/hash3/ec_subset_sum/add_points/y', 'pedersen/hash3/ec_subset_sum/copy_point/x', 'pedersen/hash3/ec_subset_sum/copy_point/y'.
              // numerators[4] = point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              mstore(0x4d20,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x42e0),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4440)),
                       PRIME))

              // Numerator for constraints 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y', 'pedersen/hash1/copy_point/x', 'pedersen/hash1/copy_point/y', 'pedersen/hash2/copy_point/x', 'pedersen/hash2/copy_point/y', 'pedersen/hash3/copy_point/x', 'pedersen/hash3/copy_point/y'.
              // numerators[5] = point^(trace_length / 512) - trace_generator^(trace_length / 2).
              mstore(0x4d40,
                     addmod(
                       /*point^(trace_length / 512)*/ mload(0x4300),
                       sub(PRIME, /*trace_generator^(trace_length / 2)*/ mload(0x4480)),
                       PRIME))

              // Numerator for constraints 'pedersen/input0_addr', 'rc_builtin/addr_step'.
              // numerators[6] = point - trace_generator^(128 * (trace_length / 128 - 1)).
              mstore(0x4d60,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(128 * (trace_length / 128 - 1))*/ mload(0x44a0)),
                       PRIME))

              // Numerator for constraints 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y'.
              // numerators[7] = point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              mstore(0x4d80,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4340),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4440)),
                       PRIME))

              // Numerator for constraints 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // numerators[8] = point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              mstore(0x4da0,
                     addmod(
                       /*point^(trace_length / 8192)*/ mload(0x4380),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4440)),
                       PRIME))

              // Numerator for constraints 'ecdsa/pubkey_addr'.
              // numerators[9] = point - trace_generator^(8192 * (trace_length / 8192 - 1)).
              mstore(0x4dc0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(8192 * (trace_length / 8192 - 1))*/ mload(0x44e0)),
                       PRIME))

              // Numerator for constraints 'bitwise/step_var_pool_addr'.
              // numerators[10] = point^(trace_length / 4096) - trace_generator^(3 * trace_length / 4).
              mstore(0x4de0,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4340),
                       sub(PRIME, /*trace_generator^(3 * trace_length / 4)*/ mload(0x4500)),
                       PRIME))

              // Numerator for constraints 'bitwise/next_var_pool_addr'.
              // numerators[11] = point - trace_generator^(4096 * (trace_length / 4096 - 1)).
              mstore(0x4e00,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(4096 * (trace_length / 4096 - 1))*/ mload(0x4520)),
                       PRIME))

            }

            {
              // Compute the result of the composition polynomial.

              {
              // cpu/decode/opcode_rc/bit_0 = column0_row0 - (column0_row1 + column0_row1).
              let val := addmod(
                /*column0_row0*/ mload(0x1de0),
                sub(
                  PRIME,
                  addmod(/*column0_row1*/ mload(0x1e00), /*column0_row1*/ mload(0x1e00), PRIME)),
                PRIME)
              mstore(0x3ce0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_2 = column0_row2 - (column0_row3 + column0_row3).
              let val := addmod(
                /*column0_row2*/ mload(0x1e20),
                sub(
                  PRIME,
                  addmod(/*column0_row3*/ mload(0x1e40), /*column0_row3*/ mload(0x1e40), PRIME)),
                PRIME)
              mstore(0x3d00, val)
              }


              {
              // cpu/decode/opcode_rc/bit_4 = column0_row4 - (column0_row5 + column0_row5).
              let val := addmod(
                /*column0_row4*/ mload(0x1e60),
                sub(
                  PRIME,
                  addmod(/*column0_row5*/ mload(0x1e80), /*column0_row5*/ mload(0x1e80), PRIME)),
                PRIME)
              mstore(0x3d20, val)
              }


              {
              // cpu/decode/opcode_rc/bit_3 = column0_row3 - (column0_row4 + column0_row4).
              let val := addmod(
                /*column0_row3*/ mload(0x1e40),
                sub(
                  PRIME,
                  addmod(/*column0_row4*/ mload(0x1e60), /*column0_row4*/ mload(0x1e60), PRIME)),
                PRIME)
              mstore(0x3d40, val)
              }


              {
              // cpu/decode/flag_op1_base_op0_0 = 1 - (cpu__decode__opcode_rc__bit_2 + cpu__decode__opcode_rc__bit_4 + cpu__decode__opcode_rc__bit_3).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3d00),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x3d20),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x3d40),
                    PRIME)),
                PRIME)
              mstore(0x3d60, val)
              }


              {
              // cpu/decode/opcode_rc/bit_5 = column0_row5 - (column0_row6 + column0_row6).
              let val := addmod(
                /*column0_row5*/ mload(0x1e80),
                sub(
                  PRIME,
                  addmod(/*column0_row6*/ mload(0x1ea0), /*column0_row6*/ mload(0x1ea0), PRIME)),
                PRIME)
              mstore(0x3d80, val)
              }


              {
              // cpu/decode/opcode_rc/bit_6 = column0_row6 - (column0_row7 + column0_row7).
              let val := addmod(
                /*column0_row6*/ mload(0x1ea0),
                sub(
                  PRIME,
                  addmod(/*column0_row7*/ mload(0x1ec0), /*column0_row7*/ mload(0x1ec0), PRIME)),
                PRIME)
              mstore(0x3da0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_9 = column0_row9 - (column0_row10 + column0_row10).
              let val := addmod(
                /*column0_row9*/ mload(0x1f00),
                sub(
                  PRIME,
                  addmod(/*column0_row10*/ mload(0x1f20), /*column0_row10*/ mload(0x1f20), PRIME)),
                PRIME)
              mstore(0x3dc0, val)
              }


              {
              // cpu/decode/flag_res_op1_0 = 1 - (cpu__decode__opcode_rc__bit_5 + cpu__decode__opcode_rc__bit_6 + cpu__decode__opcode_rc__bit_9).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x3d80),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x3da0),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3dc0),
                    PRIME)),
                PRIME)
              mstore(0x3de0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_7 = column0_row7 - (column0_row8 + column0_row8).
              let val := addmod(
                /*column0_row7*/ mload(0x1ec0),
                sub(
                  PRIME,
                  addmod(/*column0_row8*/ mload(0x1ee0), /*column0_row8*/ mload(0x1ee0), PRIME)),
                PRIME)
              mstore(0x3e00, val)
              }


              {
              // cpu/decode/opcode_rc/bit_8 = column0_row8 - (column0_row9 + column0_row9).
              let val := addmod(
                /*column0_row8*/ mload(0x1ee0),
                sub(
                  PRIME,
                  addmod(/*column0_row9*/ mload(0x1f00), /*column0_row9*/ mload(0x1f00), PRIME)),
                PRIME)
              mstore(0x3e20, val)
              }


              {
              // cpu/decode/flag_pc_update_regular_0 = 1 - (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_8 + cpu__decode__opcode_rc__bit_9).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x3e00),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x3e20),
                      PRIME),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3dc0),
                    PRIME)),
                PRIME)
              mstore(0x3e40, val)
              }


              {
              // cpu/decode/opcode_rc/bit_12 = column0_row12 - (column0_row13 + column0_row13).
              let val := addmod(
                /*column0_row12*/ mload(0x1f60),
                sub(
                  PRIME,
                  addmod(/*column0_row13*/ mload(0x1f80), /*column0_row13*/ mload(0x1f80), PRIME)),
                PRIME)
              mstore(0x3e60, val)
              }


              {
              // cpu/decode/opcode_rc/bit_13 = column0_row13 - (column0_row14 + column0_row14).
              let val := addmod(
                /*column0_row13*/ mload(0x1f80),
                sub(
                  PRIME,
                  addmod(/*column0_row14*/ mload(0x1fa0), /*column0_row14*/ mload(0x1fa0), PRIME)),
                PRIME)
              mstore(0x3e80, val)
              }


              {
              // cpu/decode/fp_update_regular_0 = 1 - (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_13).
              let val := addmod(
                1,
                sub(
                  PRIME,
                  addmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60),
                    /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x3e80),
                    PRIME)),
                PRIME)
              mstore(0x3ea0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_1 = column0_row1 - (column0_row2 + column0_row2).
              let val := addmod(
                /*column0_row1*/ mload(0x1e00),
                sub(
                  PRIME,
                  addmod(/*column0_row2*/ mload(0x1e20), /*column0_row2*/ mload(0x1e20), PRIME)),
                PRIME)
              mstore(0x3ec0, val)
              }


              {
              // npc_reg_0 = column19_row0 + cpu__decode__opcode_rc__bit_2 + 1.
              let val := addmod(
                addmod(
                  /*column19_row0*/ mload(0x2e20),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3d00),
                  PRIME),
                1,
                PRIME)
              mstore(0x3ee0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_10 = column0_row10 - (column0_row11 + column0_row11).
              let val := addmod(
                /*column0_row10*/ mload(0x1f20),
                sub(
                  PRIME,
                  addmod(/*column0_row11*/ mload(0x1f40), /*column0_row11*/ mload(0x1f40), PRIME)),
                PRIME)
              mstore(0x3f00, val)
              }


              {
              // cpu/decode/opcode_rc/bit_11 = column0_row11 - (column0_row12 + column0_row12).
              let val := addmod(
                /*column0_row11*/ mload(0x1f40),
                sub(
                  PRIME,
                  addmod(/*column0_row12*/ mload(0x1f60), /*column0_row12*/ mload(0x1f60), PRIME)),
                PRIME)
              mstore(0x3f20, val)
              }


              {
              // cpu/decode/opcode_rc/bit_14 = column0_row14 - (column0_row15 + column0_row15).
              let val := addmod(
                /*column0_row14*/ mload(0x1fa0),
                sub(
                  PRIME,
                  addmod(/*column0_row15*/ mload(0x1fc0), /*column0_row15*/ mload(0x1fc0), PRIME)),
                PRIME)
              mstore(0x3f40, val)
              }


              {
              // memory/address_diff_0 = column20_row3 - column20_row1.
              let val := addmod(/*column20_row3*/ mload(0x3400), sub(PRIME, /*column20_row1*/ mload(0x33c0)), PRIME)
              mstore(0x3f60, val)
              }


              {
              // rc16/diff_0 = column21_row3 - column21_row1.
              let val := addmod(/*column21_row3*/ mload(0x35c0), sub(PRIME, /*column21_row1*/ mload(0x3580)), PRIME)
              mstore(0x3f80, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_0 = column6_row0 - (column6_row1 + column6_row1).
              let val := addmod(
                /*column6_row0*/ mload(0x2580),
                sub(
                  PRIME,
                  addmod(/*column6_row1*/ mload(0x25a0), /*column6_row1*/ mload(0x25a0), PRIME)),
                PRIME)
              mstore(0x3fa0, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash0__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3fa0)),
                PRIME)
              mstore(0x3fc0, val)
              }


              {
              // pedersen/hash1/ec_subset_sum/bit_0 = column10_row0 - (column10_row1 + column10_row1).
              let val := addmod(
                /*column10_row0*/ mload(0x2800),
                sub(
                  PRIME,
                  addmod(/*column10_row1*/ mload(0x2820), /*column10_row1*/ mload(0x2820), PRIME)),
                PRIME)
              mstore(0x3fe0, val)
              }


              {
              // pedersen/hash1/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash1__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x3fe0)),
                PRIME)
              mstore(0x4000, val)
              }


              {
              // pedersen/hash2/ec_subset_sum/bit_0 = column14_row0 - (column14_row1 + column14_row1).
              let val := addmod(
                /*column14_row0*/ mload(0x2a80),
                sub(
                  PRIME,
                  addmod(/*column14_row1*/ mload(0x2aa0), /*column14_row1*/ mload(0x2aa0), PRIME)),
                PRIME)
              mstore(0x4020, val)
              }


              {
              // pedersen/hash2/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash2__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4020)),
                PRIME)
              mstore(0x4040, val)
              }


              {
              // pedersen/hash3/ec_subset_sum/bit_0 = column18_row0 - (column18_row1 + column18_row1).
              let val := addmod(
                /*column18_row0*/ mload(0x2d00),
                sub(
                  PRIME,
                  addmod(/*column18_row1*/ mload(0x2d20), /*column18_row1*/ mload(0x2d20), PRIME)),
                PRIME)
              mstore(0x4060, val)
              }


              {
              // pedersen/hash3/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash3__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4060)),
                PRIME)
              mstore(0x4080, val)
              }


              {
              // rc_builtin/value0_0 = column20_row12.
              let val := /*column20_row12*/ mload(0x3460)
              mstore(0x40a0, val)
              }


              {
              // rc_builtin/value1_0 = rc_builtin__value0_0 * offset_size + column20_row28.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value0_0*/ mload(0x40a0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row28*/ mload(0x3480),
                PRIME)
              mstore(0x40c0, val)
              }


              {
              // rc_builtin/value2_0 = rc_builtin__value1_0 * offset_size + column20_row44.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value1_0*/ mload(0x40c0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row44*/ mload(0x34a0),
                PRIME)
              mstore(0x40e0, val)
              }


              {
              // rc_builtin/value3_0 = rc_builtin__value2_0 * offset_size + column20_row60.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value2_0*/ mload(0x40e0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row60*/ mload(0x34c0),
                PRIME)
              mstore(0x4100, val)
              }


              {
              // rc_builtin/value4_0 = rc_builtin__value3_0 * offset_size + column20_row76.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value3_0*/ mload(0x4100),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row76*/ mload(0x34e0),
                PRIME)
              mstore(0x4120, val)
              }


              {
              // rc_builtin/value5_0 = rc_builtin__value4_0 * offset_size + column20_row92.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value4_0*/ mload(0x4120),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row92*/ mload(0x3500),
                PRIME)
              mstore(0x4140, val)
              }


              {
              // rc_builtin/value6_0 = rc_builtin__value5_0 * offset_size + column20_row108.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value5_0*/ mload(0x4140),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row108*/ mload(0x3520),
                PRIME)
              mstore(0x4160, val)
              }


              {
              // rc_builtin/value7_0 = rc_builtin__value6_0 * offset_size + column20_row124.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value6_0*/ mload(0x4160),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column20_row124*/ mload(0x3540),
                PRIME)
              mstore(0x4180, val)
              }


              {
              // ecdsa/signature0/doubling_key/x_squared = column22_row6 * column22_row6.
              let val := mulmod(/*column22_row6*/ mload(0x36a0), /*column22_row6*/ mload(0x36a0), PRIME)
              mstore(0x41a0, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_0 = column22_row31 - (column22_row63 + column22_row63).
              let val := addmod(
                /*column22_row31*/ mload(0x38e0),
                sub(
                  PRIME,
                  addmod(/*column22_row63*/ mload(0x3940), /*column22_row63*/ mload(0x3940), PRIME)),
                PRIME)
              mstore(0x41c0, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_generator__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x41c0)),
                PRIME)
              mstore(0x41e0, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_0 = column22_row3 - (column22_row19 + column22_row19).
              let val := addmod(
                /*column22_row3*/ mload(0x3640),
                sub(
                  PRIME,
                  addmod(/*column22_row19*/ mload(0x3800), /*column22_row19*/ mload(0x3800), PRIME)),
                PRIME)
              mstore(0x4200, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_key__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4200)),
                PRIME)
              mstore(0x4220, val)
              }


              {
              // bitwise/sum_var_0_0 = column1_row0 + column1_row64 * 2 + column1_row128 * 4 + column1_row192 * 8 + column1_row256 * 18446744073709551616 + column1_row320 * 36893488147419103232 + column1_row384 * 73786976294838206464 + column1_row448 * 147573952589676412928.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            /*column1_row0*/ mload(0x1fe0),
                            mulmod(/*column1_row64*/ mload(0x2040), 2, PRIME),
                            PRIME),
                          mulmod(/*column1_row128*/ mload(0x2060), 4, PRIME),
                          PRIME),
                        mulmod(/*column1_row192*/ mload(0x2080), 8, PRIME),
                        PRIME),
                      mulmod(/*column1_row256*/ mload(0x20a0), 18446744073709551616, PRIME),
                      PRIME),
                    mulmod(/*column1_row320*/ mload(0x20c0), 36893488147419103232, PRIME),
                    PRIME),
                  mulmod(/*column1_row384*/ mload(0x20e0), 73786976294838206464, PRIME),
                  PRIME),
                mulmod(/*column1_row448*/ mload(0x2100), 147573952589676412928, PRIME),
                PRIME)
              mstore(0x4240, val)
              }


              {
              // bitwise/sum_var_8_0 = column1_row512 * 340282366920938463463374607431768211456 + column1_row576 * 680564733841876926926749214863536422912 + column1_row640 * 1361129467683753853853498429727072845824 + column1_row704 * 2722258935367507707706996859454145691648 + column1_row768 * 6277101735386680763835789423207666416102355444464034512896 + column1_row832 * 12554203470773361527671578846415332832204710888928069025792 + column1_row896 * 25108406941546723055343157692830665664409421777856138051584 + column1_row960 * 50216813883093446110686315385661331328818843555712276103168.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          addmod(
                            mulmod(/*column1_row512*/ mload(0x2120), 340282366920938463463374607431768211456, PRIME),
                            mulmod(/*column1_row576*/ mload(0x2140), 680564733841876926926749214863536422912, PRIME),
                            PRIME),
                          mulmod(/*column1_row640*/ mload(0x2160), 1361129467683753853853498429727072845824, PRIME),
                          PRIME),
                        mulmod(/*column1_row704*/ mload(0x2180), 2722258935367507707706996859454145691648, PRIME),
                        PRIME),
                      mulmod(
                        /*column1_row768*/ mload(0x21a0),
                        6277101735386680763835789423207666416102355444464034512896,
                        PRIME),
                      PRIME),
                    mulmod(
                      /*column1_row832*/ mload(0x21c0),
                      12554203470773361527671578846415332832204710888928069025792,
                      PRIME),
                    PRIME),
                  mulmod(
                    /*column1_row896*/ mload(0x21e0),
                    25108406941546723055343157692830665664409421777856138051584,
                    PRIME),
                  PRIME),
                mulmod(
                  /*column1_row960*/ mload(0x2200),
                  50216813883093446110686315385661331328818843555712276103168,
                  PRIME),
                PRIME)
              mstore(0x4260, val)
              }


              {
              // Constraint expression for cpu/decode/opcode_rc/bit: cpu__decode__opcode_rc__bit_0 * cpu__decode__opcode_rc__bit_0 - cpu__decode__opcode_rc__bit_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3ce0),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3ce0),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3ce0)),
                PRIME)

              // Numerator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= numerators[0].
              val := mulmod(val, mload(0x4ca0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[0].
              res := addmod(res,
                            mulmod(val, /*coefficients[0]*/ mload(0x540), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc/zero: column0_row0.
              let val := /*column0_row0*/ mload(0x1de0)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= denominator_invs[1].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * coefficients[1].
              res := addmod(res,
                            mulmod(val, /*coefficients[1]*/ mload(0x560), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc_input: column19_row1 - (((column0_row0 * offset_size + column20_row4) * offset_size + column20_row8) * offset_size + column20_row0).
              let val := addmod(
                /*column19_row1*/ mload(0x2e40),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      addmod(
                        mulmod(
                          addmod(
                            mulmod(/*column0_row0*/ mload(0x1de0), /*offset_size*/ mload(0xa0), PRIME),
                            /*column20_row4*/ mload(0x3420),
                            PRIME),
                          /*offset_size*/ mload(0xa0),
                          PRIME),
                        /*column20_row8*/ mload(0x3440),
                        PRIME),
                      /*offset_size*/ mload(0xa0),
                      PRIME),
                    /*column20_row0*/ mload(0x33a0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[2].
              res := addmod(res,
                            mulmod(val, /*coefficients[2]*/ mload(0x580), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_op1_base_op0_bit: cpu__decode__flag_op1_base_op0_0 * cpu__decode__flag_op1_base_op0_0 - cpu__decode__flag_op1_base_op0_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x3d60),
                  /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x3d60),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x3d60)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[3].
              res := addmod(res,
                            mulmod(val, /*coefficients[3]*/ mload(0x5a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_res_op1_bit: cpu__decode__flag_res_op1_0 * cpu__decode__flag_res_op1_0 - cpu__decode__flag_res_op1_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x3de0),
                  /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x3de0),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x3de0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[4].
              res := addmod(res,
                            mulmod(val, /*coefficients[4]*/ mload(0x5c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/flag_pc_update_regular_bit: cpu__decode__flag_pc_update_regular_0 * cpu__decode__flag_pc_update_regular_0 - cpu__decode__flag_pc_update_regular_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x3e40),
                  /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x3e40),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x3e40)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[5].
              res := addmod(res,
                            mulmod(val, /*coefficients[5]*/ mload(0x5e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/decode/fp_update_regular_bit: cpu__decode__fp_update_regular_0 * cpu__decode__fp_update_regular_0 - cpu__decode__fp_update_regular_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x3ea0),
                  /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x3ea0),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x3ea0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[6].
              res := addmod(res,
                            mulmod(val, /*coefficients[6]*/ mload(0x600), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem_dst_addr: column19_row8 + half_offset_size - (cpu__decode__opcode_rc__bit_0 * column22_row8 + (1 - cpu__decode__opcode_rc__bit_0) * column22_row0 + column20_row0).
              let val := addmod(
                addmod(/*column19_row8*/ mload(0x2ee0), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3ce0),
                        /*column22_row8*/ mload(0x36e0),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3ce0)),
                          PRIME),
                        /*column22_row0*/ mload(0x35e0),
                        PRIME),
                      PRIME),
                    /*column20_row0*/ mload(0x33a0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[7].
              res := addmod(res,
                            mulmod(val, /*coefficients[7]*/ mload(0x620), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem0_addr: column19_row4 + half_offset_size - (cpu__decode__opcode_rc__bit_1 * column22_row8 + (1 - cpu__decode__opcode_rc__bit_1) * column22_row0 + column20_row8).
              let val := addmod(
                addmod(/*column19_row4*/ mload(0x2ea0), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x3ec0),
                        /*column22_row8*/ mload(0x36e0),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x3ec0)),
                          PRIME),
                        /*column22_row0*/ mload(0x35e0),
                        PRIME),
                      PRIME),
                    /*column20_row8*/ mload(0x3440),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[8].
              res := addmod(res,
                            mulmod(val, /*coefficients[8]*/ mload(0x640), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem1_addr: column19_row12 + half_offset_size - (cpu__decode__opcode_rc__bit_2 * column19_row0 + cpu__decode__opcode_rc__bit_4 * column22_row0 + cpu__decode__opcode_rc__bit_3 * column22_row8 + cpu__decode__flag_op1_base_op0_0 * column19_row5 + column20_row4).
              let val := addmod(
                addmod(/*column19_row12*/ mload(0x2f60), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3d00),
                            /*column19_row0*/ mload(0x2e20),
                            PRIME),
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x3d20),
                            /*column22_row0*/ mload(0x35e0),
                            PRIME),
                          PRIME),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x3d40),
                          /*column22_row8*/ mload(0x36e0),
                          PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/flag_op1_base_op0_0*/ mload(0x3d60),
                        /*column19_row5*/ mload(0x2ec0),
                        PRIME),
                      PRIME),
                    /*column20_row4*/ mload(0x3420),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[9].
              res := addmod(res,
                            mulmod(val, /*coefficients[9]*/ mload(0x660), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/ops_mul: column22_row4 - column19_row5 * column19_row13.
              let val := addmod(
                /*column22_row4*/ mload(0x3660),
                sub(
                  PRIME,
                  mulmod(/*column19_row5*/ mload(0x2ec0), /*column19_row13*/ mload(0x2f80), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[10].
              res := addmod(res,
                            mulmod(val, /*coefficients[10]*/ mload(0x680), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/operands/res: (1 - cpu__decode__opcode_rc__bit_9) * column22_row12 - (cpu__decode__opcode_rc__bit_5 * (column19_row5 + column19_row13) + cpu__decode__opcode_rc__bit_6 * column22_row4 + cpu__decode__flag_res_op1_0 * column19_row13).
              let val := addmod(
                mulmod(
                  addmod(
                    1,
                    sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3dc0)),
                    PRIME),
                  /*column22_row12*/ mload(0x3760),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x3d80),
                        addmod(/*column19_row5*/ mload(0x2ec0), /*column19_row13*/ mload(0x2f80), PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x3da0),
                        /*column22_row4*/ mload(0x3660),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x3de0),
                      /*column19_row13*/ mload(0x2f80),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[11].
              res := addmod(res,
                            mulmod(val, /*coefficients[11]*/ mload(0x6a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp0: column22_row2 - cpu__decode__opcode_rc__bit_9 * column19_row9.
              let val := addmod(
                /*column22_row2*/ mload(0x3620),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3dc0),
                    /*column19_row9*/ mload(0x2f00),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4cc0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[12].
              res := addmod(res,
                            mulmod(val, /*coefficients[12]*/ mload(0x6c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp1: column22_row10 - column22_row2 * column22_row12.
              let val := addmod(
                /*column22_row10*/ mload(0x3720),
                sub(
                  PRIME,
                  mulmod(/*column22_row2*/ mload(0x3620), /*column22_row12*/ mload(0x3760), PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4cc0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[13].
              res := addmod(res,
                            mulmod(val, /*coefficients[13]*/ mload(0x6e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_negative: (1 - cpu__decode__opcode_rc__bit_9) * column19_row16 + column22_row2 * (column19_row16 - (column19_row0 + column19_row13)) - (cpu__decode__flag_pc_update_regular_0 * npc_reg_0 + cpu__decode__opcode_rc__bit_7 * column22_row12 + cpu__decode__opcode_rc__bit_8 * (column19_row0 + column22_row12)).
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      1,
                      sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3dc0)),
                      PRIME),
                    /*column19_row16*/ mload(0x2fa0),
                    PRIME),
                  mulmod(
                    /*column22_row2*/ mload(0x3620),
                    addmod(
                      /*column19_row16*/ mload(0x2fa0),
                      sub(
                        PRIME,
                        addmod(/*column19_row0*/ mload(0x2e20), /*column19_row13*/ mload(0x2f80), PRIME)),
                      PRIME),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/flag_pc_update_regular_0*/ mload(0x3e40),
                        /*intermediate_value/npc_reg_0*/ mload(0x3ee0),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x3e00),
                        /*column22_row12*/ mload(0x3760),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x3e20),
                      addmod(/*column19_row0*/ mload(0x2e20), /*column22_row12*/ mload(0x3760), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4cc0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[14].
              res := addmod(res,
                            mulmod(val, /*coefficients[14]*/ mload(0x700), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_positive: (column22_row10 - cpu__decode__opcode_rc__bit_9) * (column19_row16 - npc_reg_0).
              let val := mulmod(
                addmod(
                  /*column22_row10*/ mload(0x3720),
                  sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x3dc0)),
                  PRIME),
                addmod(
                  /*column19_row16*/ mload(0x2fa0),
                  sub(PRIME, /*intermediate_value/npc_reg_0*/ mload(0x3ee0)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4cc0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[15].
              res := addmod(res,
                            mulmod(val, /*coefficients[15]*/ mload(0x720), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_ap/ap_update: column22_row16 - (column22_row0 + cpu__decode__opcode_rc__bit_10 * column22_row12 + cpu__decode__opcode_rc__bit_11 + cpu__decode__opcode_rc__bit_12 * 2).
              let val := addmod(
                /*column22_row16*/ mload(0x37e0),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        /*column22_row0*/ mload(0x35e0),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_10*/ mload(0x3f00),
                          /*column22_row12*/ mload(0x3760),
                          PRIME),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_11*/ mload(0x3f20),
                      PRIME),
                    mulmod(/*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60), 2, PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4cc0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[16].
              res := addmod(res,
                            mulmod(val, /*coefficients[16]*/ mload(0x740), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_fp/fp_update: column22_row24 - (cpu__decode__fp_update_regular_0 * column22_row8 + cpu__decode__opcode_rc__bit_13 * column19_row9 + cpu__decode__opcode_rc__bit_12 * (column22_row0 + 2)).
              let val := addmod(
                /*column22_row24*/ mload(0x3880),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/fp_update_regular_0*/ mload(0x3ea0),
                        /*column22_row8*/ mload(0x36e0),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x3e80),
                        /*column19_row9*/ mload(0x2f00),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60),
                      addmod(/*column22_row0*/ mload(0x35e0), 2, PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4cc0), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[17].
              res := addmod(res,
                            mulmod(val, /*coefficients[17]*/ mload(0x760), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_fp: cpu__decode__opcode_rc__bit_12 * (column19_row9 - column22_row8).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60),
                addmod(/*column19_row9*/ mload(0x2f00), sub(PRIME, /*column22_row8*/ mload(0x36e0)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[18].
              res := addmod(res,
                            mulmod(val, /*coefficients[18]*/ mload(0x780), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_pc: cpu__decode__opcode_rc__bit_12 * (column19_row5 - (column19_row0 + cpu__decode__opcode_rc__bit_2 + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60),
                addmod(
                  /*column19_row5*/ mload(0x2ec0),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*column19_row0*/ mload(0x2e20),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3d00),
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
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[19].
              res := addmod(res,
                            mulmod(val, /*coefficients[19]*/ mload(0x7a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/off0: cpu__decode__opcode_rc__bit_12 * (column20_row0 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60),
                addmod(
                  /*column20_row0*/ mload(0x33a0),
                  sub(PRIME, /*half_offset_size*/ mload(0xc0)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[20].
              res := addmod(res,
                            mulmod(val, /*coefficients[20]*/ mload(0x7c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/off1: cpu__decode__opcode_rc__bit_12 * (column20_row8 - (half_offset_size + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60),
                addmod(
                  /*column20_row8*/ mload(0x3440),
                  sub(PRIME, addmod(/*half_offset_size*/ mload(0xc0), 1, PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[21].
              res := addmod(res,
                            mulmod(val, /*coefficients[21]*/ mload(0x7e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/flags: cpu__decode__opcode_rc__bit_12 * (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_12 + 1 + 1 - (cpu__decode__opcode_rc__bit_0 + cpu__decode__opcode_rc__bit_1 + 4)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60),
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x3e60),
                        PRIME),
                      1,
                      PRIME),
                    1,
                    PRIME),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3ce0),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x3ec0),
                        PRIME),
                      4,
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[22].
              res := addmod(res,
                            mulmod(val, /*coefficients[22]*/ mload(0x800), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/off0: cpu__decode__opcode_rc__bit_13 * (column20_row0 + 2 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x3e80),
                addmod(
                  addmod(/*column20_row0*/ mload(0x33a0), 2, PRIME),
                  sub(PRIME, /*half_offset_size*/ mload(0xc0)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[23].
              res := addmod(res,
                            mulmod(val, /*coefficients[23]*/ mload(0x820), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/off2: cpu__decode__opcode_rc__bit_13 * (column20_row4 + 1 - half_offset_size).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x3e80),
                addmod(
                  addmod(/*column20_row4*/ mload(0x3420), 1, PRIME),
                  sub(PRIME, /*half_offset_size*/ mload(0xc0)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[24].
              res := addmod(res,
                            mulmod(val, /*coefficients[24]*/ mload(0x840), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/ret/flags: cpu__decode__opcode_rc__bit_13 * (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_0 + cpu__decode__opcode_rc__bit_3 + cpu__decode__flag_res_op1_0 - 4).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x3e80),
                addmod(
                  addmod(
                    addmod(
                      addmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x3e00),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3ce0),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x3d40),
                      PRIME),
                    /*intermediate_value/cpu/decode/flag_res_op1_0*/ mload(0x3de0),
                    PRIME),
                  sub(PRIME, 4),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[25].
              res := addmod(res,
                            mulmod(val, /*coefficients[25]*/ mload(0x860), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/assert_eq/assert_eq: cpu__decode__opcode_rc__bit_14 * (column19_row9 - column22_row12).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_14*/ mload(0x3f40),
                addmod(
                  /*column19_row9*/ mload(0x2f00),
                  sub(PRIME, /*column22_row12*/ mload(0x3760)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[26].
              res := addmod(res,
                            mulmod(val, /*coefficients[26]*/ mload(0x880), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_ap: column22_row0 - initial_ap.
              let val := addmod(/*column22_row0*/ mload(0x35e0), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[27].
              res := addmod(res,
                            mulmod(val, /*coefficients[27]*/ mload(0x8a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_fp: column22_row8 - initial_ap.
              let val := addmod(/*column22_row8*/ mload(0x36e0), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[28].
              res := addmod(res,
                            mulmod(val, /*coefficients[28]*/ mload(0x8c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for initial_pc: column19_row0 - initial_pc.
              let val := addmod(/*column19_row0*/ mload(0x2e20), sub(PRIME, /*initial_pc*/ mload(0x100)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[29].
              res := addmod(res,
                            mulmod(val, /*coefficients[29]*/ mload(0x8e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_ap: column22_row0 - final_ap.
              let val := addmod(/*column22_row0*/ mload(0x35e0), sub(PRIME, /*final_ap*/ mload(0x120)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[4].
              val := mulmod(val, mload(0x47a0), PRIME)

              // res += val * coefficients[30].
              res := addmod(res,
                            mulmod(val, /*coefficients[30]*/ mload(0x900), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_fp: column22_row8 - initial_ap.
              let val := addmod(/*column22_row8*/ mload(0x36e0), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[4].
              val := mulmod(val, mload(0x47a0), PRIME)

              // res += val * coefficients[31].
              res := addmod(res,
                            mulmod(val, /*coefficients[31]*/ mload(0x920), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for final_pc: column19_row0 - final_pc.
              let val := addmod(/*column19_row0*/ mload(0x2e20), sub(PRIME, /*final_pc*/ mload(0x140)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[4].
              val := mulmod(val, mload(0x47a0), PRIME)

              // res += val * coefficients[32].
              res := addmod(res,
                            mulmod(val, /*coefficients[32]*/ mload(0x940), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/init0: (memory/multi_column_perm/perm/interaction_elm - (column20_row1 + memory/multi_column_perm/hash_interaction_elm0 * column21_row0)) * column26_inter1_row0 + column19_row0 + memory/multi_column_perm/hash_interaction_elm0 * column19_row1 - memory/multi_column_perm/perm/interaction_elm.
              let val := addmod(
                addmod(
                  addmod(
                    mulmod(
                      addmod(
                        /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                        sub(
                          PRIME,
                          addmod(
                            /*column20_row1*/ mload(0x33c0),
                            mulmod(
                              /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                              /*column21_row0*/ mload(0x3560),
                              PRIME),
                            PRIME)),
                        PRIME),
                      /*column26_inter1_row0*/ mload(0x3c60),
                      PRIME),
                    /*column19_row0*/ mload(0x2e20),
                    PRIME),
                  mulmod(
                    /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                    /*column19_row1*/ mload(0x2e40),
                    PRIME),
                  PRIME),
                sub(PRIME, /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[33].
              res := addmod(res,
                            mulmod(val, /*coefficients[33]*/ mload(0x960), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/step0: (memory/multi_column_perm/perm/interaction_elm - (column20_row3 + memory/multi_column_perm/hash_interaction_elm0 * column21_row2)) * column26_inter1_row2 - (memory/multi_column_perm/perm/interaction_elm - (column19_row2 + memory/multi_column_perm/hash_interaction_elm0 * column19_row3)) * column26_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                    sub(
                      PRIME,
                      addmod(
                        /*column20_row3*/ mload(0x3400),
                        mulmod(
                          /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                          /*column21_row2*/ mload(0x35a0),
                          PRIME),
                        PRIME)),
                    PRIME),
                  /*column26_inter1_row2*/ mload(0x3ca0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                      sub(
                        PRIME,
                        addmod(
                          /*column19_row2*/ mload(0x2e60),
                          mulmod(
                            /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                            /*column19_row3*/ mload(0x2e80),
                            PRIME),
                          PRIME)),
                      PRIME),
                    /*column26_inter1_row0*/ mload(0x3c60),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x47c0), PRIME)

              // res += val * coefficients[34].
              res := addmod(res,
                            mulmod(val, /*coefficients[34]*/ mload(0x980), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/last: column26_inter1_row0 - memory/multi_column_perm/perm/public_memory_prod.
              let val := addmod(
                /*column26_inter1_row0*/ mload(0x3c60),
                sub(PRIME, /*memory/multi_column_perm/perm/public_memory_prod*/ mload(0x1a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, mload(0x47e0), PRIME)

              // res += val * coefficients[35].
              res := addmod(res,
                            mulmod(val, /*coefficients[35]*/ mload(0x9a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/diff_is_bit: memory__address_diff_0 * memory__address_diff_0 - memory__address_diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/memory/address_diff_0*/ mload(0x3f60),
                  /*intermediate_value/memory/address_diff_0*/ mload(0x3f60),
                  PRIME),
                sub(PRIME, /*intermediate_value/memory/address_diff_0*/ mload(0x3f60)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x47c0), PRIME)

              // res += val * coefficients[36].
              res := addmod(res,
                            mulmod(val, /*coefficients[36]*/ mload(0x9c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/is_func: (memory__address_diff_0 - 1) * (column21_row0 - column21_row2).
              let val := mulmod(
                addmod(/*intermediate_value/memory/address_diff_0*/ mload(0x3f60), sub(PRIME, 1), PRIME),
                addmod(/*column21_row0*/ mload(0x3560), sub(PRIME, /*column21_row2*/ mload(0x35a0)), PRIME),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x47c0), PRIME)

              // res += val * coefficients[37].
              res := addmod(res,
                            mulmod(val, /*coefficients[37]*/ mload(0x9e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for memory/initial_addr: column20_row1 - 1.
              let val := addmod(/*column20_row1*/ mload(0x33c0), sub(PRIME, 1), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[38].
              res := addmod(res,
                            mulmod(val, /*coefficients[38]*/ mload(0xa00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for public_memory_addr_zero: column19_row2.
              let val := /*column19_row2*/ mload(0x2e60)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[39].
              res := addmod(res,
                            mulmod(val, /*coefficients[39]*/ mload(0xa20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for public_memory_value_zero: column19_row3.
              let val := /*column19_row3*/ mload(0x2e80)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[40].
              res := addmod(res,
                            mulmod(val, /*coefficients[40]*/ mload(0xa40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/init0: (rc16/perm/interaction_elm - column21_row1) * column26_inter1_row1 + column20_row0 - rc16/perm/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x1c0),
                      sub(PRIME, /*column21_row1*/ mload(0x3580)),
                      PRIME),
                    /*column26_inter1_row1*/ mload(0x3c80),
                    PRIME),
                  /*column20_row0*/ mload(0x33a0),
                  PRIME),
                sub(PRIME, /*rc16/perm/interaction_elm*/ mload(0x1c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[41].
              res := addmod(res,
                            mulmod(val, /*coefficients[41]*/ mload(0xa60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/step0: (rc16/perm/interaction_elm - column21_row3) * column26_inter1_row3 - (rc16/perm/interaction_elm - column20_row2) * column26_inter1_row1.
              let val := addmod(
                mulmod(
                  addmod(
                    /*rc16/perm/interaction_elm*/ mload(0x1c0),
                    sub(PRIME, /*column21_row3*/ mload(0x35c0)),
                    PRIME),
                  /*column26_inter1_row3*/ mload(0x3cc0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x1c0),
                      sub(PRIME, /*column20_row2*/ mload(0x33e0)),
                      PRIME),
                    /*column26_inter1_row1*/ mload(0x3c80),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x47c0), PRIME)

              // res += val * coefficients[42].
              res := addmod(res,
                            mulmod(val, /*coefficients[42]*/ mload(0xa80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/perm/last: column26_inter1_row1 - rc16/perm/public_memory_prod.
              let val := addmod(
                /*column26_inter1_row1*/ mload(0x3c80),
                sub(PRIME, /*rc16/perm/public_memory_prod*/ mload(0x1e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, mload(0x47e0), PRIME)

              // res += val * coefficients[43].
              res := addmod(res,
                            mulmod(val, /*coefficients[43]*/ mload(0xaa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/diff_is_bit: rc16__diff_0 * rc16__diff_0 - rc16__diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc16/diff_0*/ mload(0x3f80),
                  /*intermediate_value/rc16/diff_0*/ mload(0x3f80),
                  PRIME),
                sub(PRIME, /*intermediate_value/rc16/diff_0*/ mload(0x3f80)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x47c0), PRIME)

              // res += val * coefficients[44].
              res := addmod(res,
                            mulmod(val, /*coefficients[44]*/ mload(0xac0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/minimum: column21_row1 - rc_min.
              let val := addmod(/*column21_row1*/ mload(0x3580), sub(PRIME, /*rc_min*/ mload(0x200)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[45].
              res := addmod(res,
                            mulmod(val, /*coefficients[45]*/ mload(0xae0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc16/maximum: column21_row1 - rc_max.
              let val := addmod(/*column21_row1*/ mload(0x3580), sub(PRIME, /*rc_max*/ mload(0x220)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, mload(0x47e0), PRIME)

              // res += val * coefficients[46].
              res := addmod(res,
                            mulmod(val, /*coefficients[46]*/ mload(0xb00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/init0: (diluted_check/permutation/interaction_elm - column2_row0) * column25_inter1_row0 + column1_row0 - diluted_check/permutation/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*diluted_check/permutation/interaction_elm*/ mload(0x240),
                      sub(PRIME, /*column2_row0*/ mload(0x23e0)),
                      PRIME),
                    /*column25_inter1_row0*/ mload(0x3c20),
                    PRIME),
                  /*column1_row0*/ mload(0x1fe0),
                  PRIME),
                sub(PRIME, /*diluted_check/permutation/interaction_elm*/ mload(0x240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[47].
              res := addmod(res,
                            mulmod(val, /*coefficients[47]*/ mload(0xb20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/step0: (diluted_check/permutation/interaction_elm - column2_row1) * column25_inter1_row1 - (diluted_check/permutation/interaction_elm - column1_row1) * column25_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*diluted_check/permutation/interaction_elm*/ mload(0x240),
                    sub(PRIME, /*column2_row1*/ mload(0x2400)),
                    PRIME),
                  /*column25_inter1_row1*/ mload(0x3c40),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*diluted_check/permutation/interaction_elm*/ mload(0x240),
                      sub(PRIME, /*column1_row1*/ mload(0x2000)),
                      PRIME),
                    /*column25_inter1_row0*/ mload(0x3c20),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= numerators[3].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[48].
              res := addmod(res,
                            mulmod(val, /*coefficients[48]*/ mload(0xb40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/permutation/last: column25_inter1_row0 - diluted_check/permutation/public_memory_prod.
              let val := addmod(
                /*column25_inter1_row0*/ mload(0x3c20),
                sub(PRIME, /*diluted_check/permutation/public_memory_prod*/ mload(0x260)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[7].
              val := mulmod(val, mload(0x4800), PRIME)

              // res += val * coefficients[49].
              res := addmod(res,
                            mulmod(val, /*coefficients[49]*/ mload(0xb60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/init: column24_inter1_row0 - 1.
              let val := addmod(/*column24_inter1_row0*/ mload(0x3be0), sub(PRIME, 1), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[50].
              res := addmod(res,
                            mulmod(val, /*coefficients[50]*/ mload(0xb80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/first_element: column2_row0 - diluted_check/first_elm.
              let val := addmod(
                /*column2_row0*/ mload(0x23e0),
                sub(PRIME, /*diluted_check/first_elm*/ mload(0x280)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[51].
              res := addmod(res,
                            mulmod(val, /*coefficients[51]*/ mload(0xba0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/step: column24_inter1_row1 - (column24_inter1_row0 * (1 + diluted_check/interaction_z * (column2_row1 - column2_row0)) + diluted_check/interaction_alpha * (column2_row1 - column2_row0) * (column2_row1 - column2_row0)).
              let val := addmod(
                /*column24_inter1_row1*/ mload(0x3c00),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      /*column24_inter1_row0*/ mload(0x3be0),
                      addmod(
                        1,
                        mulmod(
                          /*diluted_check/interaction_z*/ mload(0x2a0),
                          addmod(/*column2_row1*/ mload(0x2400), sub(PRIME, /*column2_row0*/ mload(0x23e0)), PRIME),
                          PRIME),
                        PRIME),
                      PRIME),
                    mulmod(
                      mulmod(
                        /*diluted_check/interaction_alpha*/ mload(0x2c0),
                        addmod(/*column2_row1*/ mload(0x2400), sub(PRIME, /*column2_row0*/ mload(0x23e0)), PRIME),
                        PRIME),
                      addmod(/*column2_row1*/ mload(0x2400), sub(PRIME, /*column2_row0*/ mload(0x23e0)), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= numerators[3].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[52].
              res := addmod(res,
                            mulmod(val, /*coefficients[52]*/ mload(0xbc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for diluted_check/last: column24_inter1_row0 - diluted_check/final_cum_val.
              let val := addmod(
                /*column24_inter1_row0*/ mload(0x3be0),
                sub(PRIME, /*diluted_check/final_cum_val*/ mload(0x2e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[7].
              val := mulmod(val, mload(0x4800), PRIME)

              // res += val * coefficients[53].
              res := addmod(res,
                            mulmod(val, /*coefficients[53]*/ mload(0xbe0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/last_one_is_zero: column9_row255 * (column6_row0 - (column6_row1 + column6_row1)).
              let val := mulmod(
                /*column9_row255*/ mload(0x27e0),
                addmod(
                  /*column6_row0*/ mload(0x2580),
                  sub(
                    PRIME,
                    addmod(/*column6_row1*/ mload(0x25a0), /*column6_row1*/ mload(0x25a0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[54].
              res := addmod(res,
                            mulmod(val, /*coefficients[54]*/ mload(0xc00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column9_row255 * (column6_row1 - 3138550867693340381917894711603833208051177722232017256448 * column6_row192).
              let val := mulmod(
                /*column9_row255*/ mload(0x27e0),
                addmod(
                  /*column6_row1*/ mload(0x25a0),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column6_row192*/ mload(0x25c0),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[55].
              res := addmod(res,
                            mulmod(val, /*coefficients[55]*/ mload(0xc20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit192: column9_row255 - column5_row255 * (column6_row192 - (column6_row193 + column6_row193)).
              let val := addmod(
                /*column9_row255*/ mload(0x27e0),
                sub(
                  PRIME,
                  mulmod(
                    /*column5_row255*/ mload(0x2560),
                    addmod(
                      /*column6_row192*/ mload(0x25c0),
                      sub(
                        PRIME,
                        addmod(/*column6_row193*/ mload(0x25e0), /*column6_row193*/ mload(0x25e0), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[56].
              res := addmod(res,
                            mulmod(val, /*coefficients[56]*/ mload(0xc40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column5_row255 * (column6_row193 - 8 * column6_row196).
              let val := mulmod(
                /*column5_row255*/ mload(0x2560),
                addmod(
                  /*column6_row193*/ mload(0x25e0),
                  sub(PRIME, mulmod(8, /*column6_row196*/ mload(0x2600), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[57].
              res := addmod(res,
                            mulmod(val, /*coefficients[57]*/ mload(0xc60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/cumulative_bit196: column5_row255 - (column6_row251 - (column6_row252 + column6_row252)) * (column6_row196 - (column6_row197 + column6_row197)).
              let val := addmod(
                /*column5_row255*/ mload(0x2560),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column6_row251*/ mload(0x2640),
                      sub(
                        PRIME,
                        addmod(/*column6_row252*/ mload(0x2660), /*column6_row252*/ mload(0x2660), PRIME)),
                      PRIME),
                    addmod(
                      /*column6_row196*/ mload(0x2600),
                      sub(
                        PRIME,
                        addmod(/*column6_row197*/ mload(0x2620), /*column6_row197*/ mload(0x2620), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[58].
              res := addmod(res,
                            mulmod(val, /*coefficients[58]*/ mload(0xc80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column6_row251 - (column6_row252 + column6_row252)) * (column6_row197 - 18014398509481984 * column6_row251).
              let val := mulmod(
                addmod(
                  /*column6_row251*/ mload(0x2640),
                  sub(
                    PRIME,
                    addmod(/*column6_row252*/ mload(0x2660), /*column6_row252*/ mload(0x2660), PRIME)),
                  PRIME),
                addmod(
                  /*column6_row197*/ mload(0x2620),
                  sub(PRIME, mulmod(18014398509481984, /*column6_row251*/ mload(0x2640), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[59].
              res := addmod(res,
                            mulmod(val, /*coefficients[59]*/ mload(0xca0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/booleanity_test: pedersen__hash0__ec_subset_sum__bit_0 * (pedersen__hash0__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3fa0),
                addmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3fa0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[60].
              res := addmod(res,
                            mulmod(val, /*coefficients[60]*/ mload(0xcc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_extraction_end: column6_row0.
              let val := /*column6_row0*/ mload(0x2580)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * coefficients[61].
              res := addmod(res,
                            mulmod(val, /*coefficients[61]*/ mload(0xce0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/zeros_tail: column6_row0.
              let val := /*column6_row0*/ mload(0x2580)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * coefficients[62].
              res := addmod(res,
                            mulmod(val, /*coefficients[62]*/ mload(0xd00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/slope: pedersen__hash0__ec_subset_sum__bit_0 * (column4_row0 - pedersen__points__y) - column5_row0 * (column3_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3fa0),
                  addmod(
                    /*column4_row0*/ mload(0x24c0),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column5_row0*/ mload(0x2540),
                    addmod(
                      /*column3_row0*/ mload(0x2420),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[63].
              res := addmod(res,
                            mulmod(val, /*coefficients[63]*/ mload(0xd20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/x: column5_row0 * column5_row0 - pedersen__hash0__ec_subset_sum__bit_0 * (column3_row0 + pedersen__points__x + column3_row1).
              let val := addmod(
                mulmod(/*column5_row0*/ mload(0x2540), /*column5_row0*/ mload(0x2540), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3fa0),
                    addmod(
                      addmod(
                        /*column3_row0*/ mload(0x2420),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column3_row1*/ mload(0x2440),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[64].
              res := addmod(res,
                            mulmod(val, /*coefficients[64]*/ mload(0xd40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/y: pedersen__hash0__ec_subset_sum__bit_0 * (column4_row0 + column4_row1) - column5_row0 * (column3_row0 - column3_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x3fa0),
                  addmod(/*column4_row0*/ mload(0x24c0), /*column4_row1*/ mload(0x24e0), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column5_row0*/ mload(0x2540),
                    addmod(/*column3_row0*/ mload(0x2420), sub(PRIME, /*column3_row1*/ mload(0x2440)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[65].
              res := addmod(res,
                            mulmod(val, /*coefficients[65]*/ mload(0xd60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/x: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column3_row1 - column3_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x3fc0),
                addmod(/*column3_row1*/ mload(0x2440), sub(PRIME, /*column3_row0*/ mload(0x2420)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[66].
              res := addmod(res,
                            mulmod(val, /*coefficients[66]*/ mload(0xd80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/y: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column4_row1 - column4_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x3fc0),
                addmod(/*column4_row1*/ mload(0x24e0), sub(PRIME, /*column4_row0*/ mload(0x24c0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[67].
              res := addmod(res,
                            mulmod(val, /*coefficients[67]*/ mload(0xda0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/x: column3_row256 - column3_row255.
              let val := addmod(
                /*column3_row256*/ mload(0x2480),
                sub(PRIME, /*column3_row255*/ mload(0x2460)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[68].
              res := addmod(res,
                            mulmod(val, /*coefficients[68]*/ mload(0xdc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/y: column4_row256 - column4_row255.
              let val := addmod(
                /*column4_row256*/ mload(0x2520),
                sub(PRIME, /*column4_row255*/ mload(0x2500)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[69].
              res := addmod(res,
                            mulmod(val, /*coefficients[69]*/ mload(0xde0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/x: column3_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column3_row0*/ mload(0x2420),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[70].
              res := addmod(res,
                            mulmod(val, /*coefficients[70]*/ mload(0xe00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/y: column4_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column4_row0*/ mload(0x24c0),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[71].
              res := addmod(res,
                            mulmod(val, /*coefficients[71]*/ mload(0xe20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/last_one_is_zero: column17_row255 * (column10_row0 - (column10_row1 + column10_row1)).
              let val := mulmod(
                /*column17_row255*/ mload(0x2ce0),
                addmod(
                  /*column10_row0*/ mload(0x2800),
                  sub(
                    PRIME,
                    addmod(/*column10_row1*/ mload(0x2820), /*column10_row1*/ mload(0x2820), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[72].
              res := addmod(res,
                            mulmod(val, /*coefficients[72]*/ mload(0xe40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column17_row255 * (column10_row1 - 3138550867693340381917894711603833208051177722232017256448 * column10_row192).
              let val := mulmod(
                /*column17_row255*/ mload(0x2ce0),
                addmod(
                  /*column10_row1*/ mload(0x2820),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column10_row192*/ mload(0x2840),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[73].
              res := addmod(res,
                            mulmod(val, /*coefficients[73]*/ mload(0xe60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/cumulative_bit192: column17_row255 - column13_row255 * (column10_row192 - (column10_row193 + column10_row193)).
              let val := addmod(
                /*column17_row255*/ mload(0x2ce0),
                sub(
                  PRIME,
                  mulmod(
                    /*column13_row255*/ mload(0x2a60),
                    addmod(
                      /*column10_row192*/ mload(0x2840),
                      sub(
                        PRIME,
                        addmod(/*column10_row193*/ mload(0x2860), /*column10_row193*/ mload(0x2860), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[74].
              res := addmod(res,
                            mulmod(val, /*coefficients[74]*/ mload(0xe80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column13_row255 * (column10_row193 - 8 * column10_row196).
              let val := mulmod(
                /*column13_row255*/ mload(0x2a60),
                addmod(
                  /*column10_row193*/ mload(0x2860),
                  sub(PRIME, mulmod(8, /*column10_row196*/ mload(0x2880), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[75].
              res := addmod(res,
                            mulmod(val, /*coefficients[75]*/ mload(0xea0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/cumulative_bit196: column13_row255 - (column10_row251 - (column10_row252 + column10_row252)) * (column10_row196 - (column10_row197 + column10_row197)).
              let val := addmod(
                /*column13_row255*/ mload(0x2a60),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column10_row251*/ mload(0x28c0),
                      sub(
                        PRIME,
                        addmod(/*column10_row252*/ mload(0x28e0), /*column10_row252*/ mload(0x28e0), PRIME)),
                      PRIME),
                    addmod(
                      /*column10_row196*/ mload(0x2880),
                      sub(
                        PRIME,
                        addmod(/*column10_row197*/ mload(0x28a0), /*column10_row197*/ mload(0x28a0), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[76].
              res := addmod(res,
                            mulmod(val, /*coefficients[76]*/ mload(0xec0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column10_row251 - (column10_row252 + column10_row252)) * (column10_row197 - 18014398509481984 * column10_row251).
              let val := mulmod(
                addmod(
                  /*column10_row251*/ mload(0x28c0),
                  sub(
                    PRIME,
                    addmod(/*column10_row252*/ mload(0x28e0), /*column10_row252*/ mload(0x28e0), PRIME)),
                  PRIME),
                addmod(
                  /*column10_row197*/ mload(0x28a0),
                  sub(PRIME, mulmod(18014398509481984, /*column10_row251*/ mload(0x28c0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[77].
              res := addmod(res,
                            mulmod(val, /*coefficients[77]*/ mload(0xee0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/booleanity_test: pedersen__hash1__ec_subset_sum__bit_0 * (pedersen__hash1__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x3fe0),
                addmod(
                  /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x3fe0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[78].
              res := addmod(res,
                            mulmod(val, /*coefficients[78]*/ mload(0xf00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_extraction_end: column10_row0.
              let val := /*column10_row0*/ mload(0x2800)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * coefficients[79].
              res := addmod(res,
                            mulmod(val, /*coefficients[79]*/ mload(0xf20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/zeros_tail: column10_row0.
              let val := /*column10_row0*/ mload(0x2800)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * coefficients[80].
              res := addmod(res,
                            mulmod(val, /*coefficients[80]*/ mload(0xf40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/add_points/slope: pedersen__hash1__ec_subset_sum__bit_0 * (column8_row0 - pedersen__points__y) - column9_row0 * (column7_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x3fe0),
                  addmod(
                    /*column8_row0*/ mload(0x2740),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column9_row0*/ mload(0x27c0),
                    addmod(
                      /*column7_row0*/ mload(0x26a0),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[81].
              res := addmod(res,
                            mulmod(val, /*coefficients[81]*/ mload(0xf60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/add_points/x: column9_row0 * column9_row0 - pedersen__hash1__ec_subset_sum__bit_0 * (column7_row0 + pedersen__points__x + column7_row1).
              let val := addmod(
                mulmod(/*column9_row0*/ mload(0x27c0), /*column9_row0*/ mload(0x27c0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x3fe0),
                    addmod(
                      addmod(
                        /*column7_row0*/ mload(0x26a0),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column7_row1*/ mload(0x26c0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[82].
              res := addmod(res,
                            mulmod(val, /*coefficients[82]*/ mload(0xf80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/add_points/y: pedersen__hash1__ec_subset_sum__bit_0 * (column8_row0 + column8_row1) - column9_row0 * (column7_row0 - column7_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x3fe0),
                  addmod(/*column8_row0*/ mload(0x2740), /*column8_row1*/ mload(0x2760), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column9_row0*/ mload(0x27c0),
                    addmod(/*column7_row0*/ mload(0x26a0), sub(PRIME, /*column7_row1*/ mload(0x26c0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[83].
              res := addmod(res,
                            mulmod(val, /*coefficients[83]*/ mload(0xfa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/copy_point/x: pedersen__hash1__ec_subset_sum__bit_neg_0 * (column7_row1 - column7_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_neg_0*/ mload(0x4000),
                addmod(/*column7_row1*/ mload(0x26c0), sub(PRIME, /*column7_row0*/ mload(0x26a0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[84].
              res := addmod(res,
                            mulmod(val, /*coefficients[84]*/ mload(0xfc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/copy_point/y: pedersen__hash1__ec_subset_sum__bit_neg_0 * (column8_row1 - column8_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_neg_0*/ mload(0x4000),
                addmod(/*column8_row1*/ mload(0x2760), sub(PRIME, /*column8_row0*/ mload(0x2740)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[85].
              res := addmod(res,
                            mulmod(val, /*coefficients[85]*/ mload(0xfe0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/copy_point/x: column7_row256 - column7_row255.
              let val := addmod(
                /*column7_row256*/ mload(0x2700),
                sub(PRIME, /*column7_row255*/ mload(0x26e0)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[86].
              res := addmod(res,
                            mulmod(val, /*coefficients[86]*/ mload(0x1000), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/copy_point/y: column8_row256 - column8_row255.
              let val := addmod(
                /*column8_row256*/ mload(0x27a0),
                sub(PRIME, /*column8_row255*/ mload(0x2780)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[87].
              res := addmod(res,
                            mulmod(val, /*coefficients[87]*/ mload(0x1020), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/init/x: column7_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column7_row0*/ mload(0x26a0),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[88].
              res := addmod(res,
                            mulmod(val, /*coefficients[88]*/ mload(0x1040), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/init/y: column8_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column8_row0*/ mload(0x2740),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[89].
              res := addmod(res,
                            mulmod(val, /*coefficients[89]*/ mload(0x1060), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/last_one_is_zero: column23_row144 * (column14_row0 - (column14_row1 + column14_row1)).
              let val := mulmod(
                /*column23_row144*/ mload(0x3b80),
                addmod(
                  /*column14_row0*/ mload(0x2a80),
                  sub(
                    PRIME,
                    addmod(/*column14_row1*/ mload(0x2aa0), /*column14_row1*/ mload(0x2aa0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[90].
              res := addmod(res,
                            mulmod(val, /*coefficients[90]*/ mload(0x1080), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column23_row144 * (column14_row1 - 3138550867693340381917894711603833208051177722232017256448 * column14_row192).
              let val := mulmod(
                /*column23_row144*/ mload(0x3b80),
                addmod(
                  /*column14_row1*/ mload(0x2aa0),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column14_row192*/ mload(0x2ac0),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[91].
              res := addmod(res,
                            mulmod(val, /*coefficients[91]*/ mload(0x10a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/cumulative_bit192: column23_row144 - column23_row16 * (column14_row192 - (column14_row193 + column14_row193)).
              let val := addmod(
                /*column23_row144*/ mload(0x3b80),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row16*/ mload(0x3b40),
                    addmod(
                      /*column14_row192*/ mload(0x2ac0),
                      sub(
                        PRIME,
                        addmod(/*column14_row193*/ mload(0x2ae0), /*column14_row193*/ mload(0x2ae0), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[92].
              res := addmod(res,
                            mulmod(val, /*coefficients[92]*/ mload(0x10c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column23_row16 * (column14_row193 - 8 * column14_row196).
              let val := mulmod(
                /*column23_row16*/ mload(0x3b40),
                addmod(
                  /*column14_row193*/ mload(0x2ae0),
                  sub(PRIME, mulmod(8, /*column14_row196*/ mload(0x2b00), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[93].
              res := addmod(res,
                            mulmod(val, /*coefficients[93]*/ mload(0x10e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/cumulative_bit196: column23_row16 - (column14_row251 - (column14_row252 + column14_row252)) * (column14_row196 - (column14_row197 + column14_row197)).
              let val := addmod(
                /*column23_row16*/ mload(0x3b40),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column14_row251*/ mload(0x2b40),
                      sub(
                        PRIME,
                        addmod(/*column14_row252*/ mload(0x2b60), /*column14_row252*/ mload(0x2b60), PRIME)),
                      PRIME),
                    addmod(
                      /*column14_row196*/ mload(0x2b00),
                      sub(
                        PRIME,
                        addmod(/*column14_row197*/ mload(0x2b20), /*column14_row197*/ mload(0x2b20), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[94].
              res := addmod(res,
                            mulmod(val, /*coefficients[94]*/ mload(0x1100), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column14_row251 - (column14_row252 + column14_row252)) * (column14_row197 - 18014398509481984 * column14_row251).
              let val := mulmod(
                addmod(
                  /*column14_row251*/ mload(0x2b40),
                  sub(
                    PRIME,
                    addmod(/*column14_row252*/ mload(0x2b60), /*column14_row252*/ mload(0x2b60), PRIME)),
                  PRIME),
                addmod(
                  /*column14_row197*/ mload(0x2b20),
                  sub(PRIME, mulmod(18014398509481984, /*column14_row251*/ mload(0x2b40), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[95].
              res := addmod(res,
                            mulmod(val, /*coefficients[95]*/ mload(0x1120), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/booleanity_test: pedersen__hash2__ec_subset_sum__bit_0 * (pedersen__hash2__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4020),
                addmod(
                  /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4020),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[96].
              res := addmod(res,
                            mulmod(val, /*coefficients[96]*/ mload(0x1140), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_extraction_end: column14_row0.
              let val := /*column14_row0*/ mload(0x2a80)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * coefficients[97].
              res := addmod(res,
                            mulmod(val, /*coefficients[97]*/ mload(0x1160), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/zeros_tail: column14_row0.
              let val := /*column14_row0*/ mload(0x2a80)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * coefficients[98].
              res := addmod(res,
                            mulmod(val, /*coefficients[98]*/ mload(0x1180), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/add_points/slope: pedersen__hash2__ec_subset_sum__bit_0 * (column12_row0 - pedersen__points__y) - column13_row0 * (column11_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4020),
                  addmod(
                    /*column12_row0*/ mload(0x29c0),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column13_row0*/ mload(0x2a40),
                    addmod(
                      /*column11_row0*/ mload(0x2920),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[99].
              res := addmod(res,
                            mulmod(val, /*coefficients[99]*/ mload(0x11a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/add_points/x: column13_row0 * column13_row0 - pedersen__hash2__ec_subset_sum__bit_0 * (column11_row0 + pedersen__points__x + column11_row1).
              let val := addmod(
                mulmod(/*column13_row0*/ mload(0x2a40), /*column13_row0*/ mload(0x2a40), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4020),
                    addmod(
                      addmod(
                        /*column11_row0*/ mload(0x2920),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column11_row1*/ mload(0x2940),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[100].
              res := addmod(res,
                            mulmod(val, /*coefficients[100]*/ mload(0x11c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/add_points/y: pedersen__hash2__ec_subset_sum__bit_0 * (column12_row0 + column12_row1) - column13_row0 * (column11_row0 - column11_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4020),
                  addmod(/*column12_row0*/ mload(0x29c0), /*column12_row1*/ mload(0x29e0), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column13_row0*/ mload(0x2a40),
                    addmod(/*column11_row0*/ mload(0x2920), sub(PRIME, /*column11_row1*/ mload(0x2940)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[101].
              res := addmod(res,
                            mulmod(val, /*coefficients[101]*/ mload(0x11e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/copy_point/x: pedersen__hash2__ec_subset_sum__bit_neg_0 * (column11_row1 - column11_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_neg_0*/ mload(0x4040),
                addmod(/*column11_row1*/ mload(0x2940), sub(PRIME, /*column11_row0*/ mload(0x2920)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[102].
              res := addmod(res,
                            mulmod(val, /*coefficients[102]*/ mload(0x1200), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/copy_point/y: pedersen__hash2__ec_subset_sum__bit_neg_0 * (column12_row1 - column12_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_neg_0*/ mload(0x4040),
                addmod(/*column12_row1*/ mload(0x29e0), sub(PRIME, /*column12_row0*/ mload(0x29c0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[103].
              res := addmod(res,
                            mulmod(val, /*coefficients[103]*/ mload(0x1220), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/copy_point/x: column11_row256 - column11_row255.
              let val := addmod(
                /*column11_row256*/ mload(0x2980),
                sub(PRIME, /*column11_row255*/ mload(0x2960)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[104].
              res := addmod(res,
                            mulmod(val, /*coefficients[104]*/ mload(0x1240), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/copy_point/y: column12_row256 - column12_row255.
              let val := addmod(
                /*column12_row256*/ mload(0x2a20),
                sub(PRIME, /*column12_row255*/ mload(0x2a00)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[105].
              res := addmod(res,
                            mulmod(val, /*coefficients[105]*/ mload(0x1260), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/init/x: column11_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column11_row0*/ mload(0x2920),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[106].
              res := addmod(res,
                            mulmod(val, /*coefficients[106]*/ mload(0x1280), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/init/y: column12_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column12_row0*/ mload(0x29c0),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[107].
              res := addmod(res,
                            mulmod(val, /*coefficients[107]*/ mload(0x12a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/last_one_is_zero: column23_row208 * (column18_row0 - (column18_row1 + column18_row1)).
              let val := mulmod(
                /*column23_row208*/ mload(0x3ba0),
                addmod(
                  /*column18_row0*/ mload(0x2d00),
                  sub(
                    PRIME,
                    addmod(/*column18_row1*/ mload(0x2d20), /*column18_row1*/ mload(0x2d20), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[108].
              res := addmod(res,
                            mulmod(val, /*coefficients[108]*/ mload(0x12c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones0: column23_row208 * (column18_row1 - 3138550867693340381917894711603833208051177722232017256448 * column18_row192).
              let val := mulmod(
                /*column23_row208*/ mload(0x3ba0),
                addmod(
                  /*column18_row1*/ mload(0x2d20),
                  sub(
                    PRIME,
                    mulmod(
                      3138550867693340381917894711603833208051177722232017256448,
                      /*column18_row192*/ mload(0x2d40),
                      PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[109].
              res := addmod(res,
                            mulmod(val, /*coefficients[109]*/ mload(0x12e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/cumulative_bit192: column23_row208 - column23_row80 * (column18_row192 - (column18_row193 + column18_row193)).
              let val := addmod(
                /*column23_row208*/ mload(0x3ba0),
                sub(
                  PRIME,
                  mulmod(
                    /*column23_row80*/ mload(0x3b60),
                    addmod(
                      /*column18_row192*/ mload(0x2d40),
                      sub(
                        PRIME,
                        addmod(/*column18_row193*/ mload(0x2d60), /*column18_row193*/ mload(0x2d60), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[110].
              res := addmod(res,
                            mulmod(val, /*coefficients[110]*/ mload(0x1300), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones192: column23_row80 * (column18_row193 - 8 * column18_row196).
              let val := mulmod(
                /*column23_row80*/ mload(0x3b60),
                addmod(
                  /*column18_row193*/ mload(0x2d60),
                  sub(PRIME, mulmod(8, /*column18_row196*/ mload(0x2d80), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[111].
              res := addmod(res,
                            mulmod(val, /*coefficients[111]*/ mload(0x1320), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/cumulative_bit196: column23_row80 - (column18_row251 - (column18_row252 + column18_row252)) * (column18_row196 - (column18_row197 + column18_row197)).
              let val := addmod(
                /*column23_row80*/ mload(0x3b60),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*column18_row251*/ mload(0x2dc0),
                      sub(
                        PRIME,
                        addmod(/*column18_row252*/ mload(0x2de0), /*column18_row252*/ mload(0x2de0), PRIME)),
                      PRIME),
                    addmod(
                      /*column18_row196*/ mload(0x2d80),
                      sub(
                        PRIME,
                        addmod(/*column18_row197*/ mload(0x2da0), /*column18_row197*/ mload(0x2da0), PRIME)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[112].
              res := addmod(res,
                            mulmod(val, /*coefficients[112]*/ mload(0x1340), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_unpacking/zeroes_between_ones196: (column18_row251 - (column18_row252 + column18_row252)) * (column18_row197 - 18014398509481984 * column18_row251).
              let val := mulmod(
                addmod(
                  /*column18_row251*/ mload(0x2dc0),
                  sub(
                    PRIME,
                    addmod(/*column18_row252*/ mload(0x2de0), /*column18_row252*/ mload(0x2de0), PRIME)),
                  PRIME),
                addmod(
                  /*column18_row197*/ mload(0x2da0),
                  sub(PRIME, mulmod(18014398509481984, /*column18_row251*/ mload(0x2dc0), PRIME)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[113].
              res := addmod(res,
                            mulmod(val, /*coefficients[113]*/ mload(0x1360), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/booleanity_test: pedersen__hash3__ec_subset_sum__bit_0 * (pedersen__hash3__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4060),
                addmod(
                  /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4060),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[114].
              res := addmod(res,
                            mulmod(val, /*coefficients[114]*/ mload(0x1380), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_extraction_end: column18_row0.
              let val := /*column18_row0*/ mload(0x2d00)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * coefficients[115].
              res := addmod(res,
                            mulmod(val, /*coefficients[115]*/ mload(0x13a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/zeros_tail: column18_row0.
              let val := /*column18_row0*/ mload(0x2d00)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * coefficients[116].
              res := addmod(res,
                            mulmod(val, /*coefficients[116]*/ mload(0x13c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/add_points/slope: pedersen__hash3__ec_subset_sum__bit_0 * (column16_row0 - pedersen__points__y) - column17_row0 * (column15_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4060),
                  addmod(
                    /*column16_row0*/ mload(0x2c40),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column17_row0*/ mload(0x2cc0),
                    addmod(
                      /*column15_row0*/ mload(0x2ba0),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[117].
              res := addmod(res,
                            mulmod(val, /*coefficients[117]*/ mload(0x13e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/add_points/x: column17_row0 * column17_row0 - pedersen__hash3__ec_subset_sum__bit_0 * (column15_row0 + pedersen__points__x + column15_row1).
              let val := addmod(
                mulmod(/*column17_row0*/ mload(0x2cc0), /*column17_row0*/ mload(0x2cc0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4060),
                    addmod(
                      addmod(
                        /*column15_row0*/ mload(0x2ba0),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column15_row1*/ mload(0x2bc0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[118].
              res := addmod(res,
                            mulmod(val, /*coefficients[118]*/ mload(0x1400), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/add_points/y: pedersen__hash3__ec_subset_sum__bit_0 * (column16_row0 + column16_row1) - column17_row0 * (column15_row0 - column15_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4060),
                  addmod(/*column16_row0*/ mload(0x2c40), /*column16_row1*/ mload(0x2c60), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column17_row0*/ mload(0x2cc0),
                    addmod(/*column15_row0*/ mload(0x2ba0), sub(PRIME, /*column15_row1*/ mload(0x2bc0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[119].
              res := addmod(res,
                            mulmod(val, /*coefficients[119]*/ mload(0x1420), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/copy_point/x: pedersen__hash3__ec_subset_sum__bit_neg_0 * (column15_row1 - column15_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_neg_0*/ mload(0x4080),
                addmod(/*column15_row1*/ mload(0x2bc0), sub(PRIME, /*column15_row0*/ mload(0x2ba0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[120].
              res := addmod(res,
                            mulmod(val, /*coefficients[120]*/ mload(0x1440), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/copy_point/y: pedersen__hash3__ec_subset_sum__bit_neg_0 * (column16_row1 - column16_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_neg_0*/ mload(0x4080),
                addmod(/*column16_row1*/ mload(0x2c60), sub(PRIME, /*column16_row0*/ mload(0x2c40)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * coefficients[121].
              res := addmod(res,
                            mulmod(val, /*coefficients[121]*/ mload(0x1460), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/copy_point/x: column15_row256 - column15_row255.
              let val := addmod(
                /*column15_row256*/ mload(0x2c00),
                sub(PRIME, /*column15_row255*/ mload(0x2be0)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[122].
              res := addmod(res,
                            mulmod(val, /*coefficients[122]*/ mload(0x1480), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/copy_point/y: column16_row256 - column16_row255.
              let val := addmod(
                /*column16_row256*/ mload(0x2ca0),
                sub(PRIME, /*column16_row255*/ mload(0x2c80)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * coefficients[123].
              res := addmod(res,
                            mulmod(val, /*coefficients[123]*/ mload(0x14a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/init/x: column15_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column15_row0*/ mload(0x2ba0),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[124].
              res := addmod(res,
                            mulmod(val, /*coefficients[124]*/ mload(0x14c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/init/y: column16_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column16_row0*/ mload(0x2c40),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x320)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[125].
              res := addmod(res,
                            mulmod(val, /*coefficients[125]*/ mload(0x14e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value0: column19_row11 - column6_row0.
              let val := addmod(/*column19_row11*/ mload(0x2f40), sub(PRIME, /*column6_row0*/ mload(0x2580)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[126].
              res := addmod(res,
                            mulmod(val, /*coefficients[126]*/ mload(0x1500), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value1: column19_row139 - column10_row0.
              let val := addmod(
                /*column19_row139*/ mload(0x30e0),
                sub(PRIME, /*column10_row0*/ mload(0x2800)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[127].
              res := addmod(res,
                            mulmod(val, /*coefficients[127]*/ mload(0x1520), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value2: column19_row267 - column14_row0.
              let val := addmod(
                /*column19_row267*/ mload(0x3160),
                sub(PRIME, /*column14_row0*/ mload(0x2a80)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[128].
              res := addmod(res,
                            mulmod(val, /*coefficients[128]*/ mload(0x1540), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value3: column19_row395 - column18_row0.
              let val := addmod(
                /*column19_row395*/ mload(0x31c0),
                sub(PRIME, /*column18_row0*/ mload(0x2d00)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[129].
              res := addmod(res,
                            mulmod(val, /*coefficients[129]*/ mload(0x1560), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input0_addr: column19_row138 - (column19_row42 + 1).
              let val := addmod(
                /*column19_row138*/ mload(0x30c0),
                sub(PRIME, addmod(/*column19_row42*/ mload(0x3000), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(128 * (trace_length / 128 - 1)).
              // val *= numerators[6].
              val := mulmod(val, mload(0x4d60), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * coefficients[130].
              res := addmod(res,
                            mulmod(val, /*coefficients[130]*/ mload(0x1580), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/init_addr: column19_row10 - initial_pedersen_addr.
              let val := addmod(
                /*column19_row10*/ mload(0x2f20),
                sub(PRIME, /*initial_pedersen_addr*/ mload(0x340)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[131].
              res := addmod(res,
                            mulmod(val, /*coefficients[131]*/ mload(0x15a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value0: column19_row75 - column6_row256.
              let val := addmod(
                /*column19_row75*/ mload(0x3060),
                sub(PRIME, /*column6_row256*/ mload(0x2680)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[132].
              res := addmod(res,
                            mulmod(val, /*coefficients[132]*/ mload(0x15c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value1: column19_row203 - column10_row256.
              let val := addmod(
                /*column19_row203*/ mload(0x3120),
                sub(PRIME, /*column10_row256*/ mload(0x2900)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[133].
              res := addmod(res,
                            mulmod(val, /*coefficients[133]*/ mload(0x15e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value2: column19_row331 - column14_row256.
              let val := addmod(
                /*column19_row331*/ mload(0x31a0),
                sub(PRIME, /*column14_row256*/ mload(0x2b80)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[134].
              res := addmod(res,
                            mulmod(val, /*coefficients[134]*/ mload(0x1600), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value3: column19_row459 - column18_row256.
              let val := addmod(
                /*column19_row459*/ mload(0x3200),
                sub(PRIME, /*column18_row256*/ mload(0x2e00)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[135].
              res := addmod(res,
                            mulmod(val, /*coefficients[135]*/ mload(0x1620), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/input1_addr: column19_row74 - (column19_row10 + 1).
              let val := addmod(
                /*column19_row74*/ mload(0x3040),
                sub(PRIME, addmod(/*column19_row10*/ mload(0x2f20), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * coefficients[136].
              res := addmod(res,
                            mulmod(val, /*coefficients[136]*/ mload(0x1640), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value0: column19_row43 - column3_row511.
              let val := addmod(
                /*column19_row43*/ mload(0x3020),
                sub(PRIME, /*column3_row511*/ mload(0x24a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[137].
              res := addmod(res,
                            mulmod(val, /*coefficients[137]*/ mload(0x1660), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value1: column19_row171 - column7_row511.
              let val := addmod(
                /*column19_row171*/ mload(0x3100),
                sub(PRIME, /*column7_row511*/ mload(0x2720)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[138].
              res := addmod(res,
                            mulmod(val, /*coefficients[138]*/ mload(0x1680), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value2: column19_row299 - column11_row511.
              let val := addmod(
                /*column19_row299*/ mload(0x3180),
                sub(PRIME, /*column11_row511*/ mload(0x29a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[139].
              res := addmod(res,
                            mulmod(val, /*coefficients[139]*/ mload(0x16a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_value3: column19_row427 - column15_row511.
              let val := addmod(
                /*column19_row427*/ mload(0x31e0),
                sub(PRIME, /*column15_row511*/ mload(0x2c20)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * coefficients[140].
              res := addmod(res,
                            mulmod(val, /*coefficients[140]*/ mload(0x16c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for pedersen/output_addr: column19_row42 - (column19_row74 + 1).
              let val := addmod(
                /*column19_row42*/ mload(0x3000),
                sub(PRIME, addmod(/*column19_row74*/ mload(0x3040), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * coefficients[141].
              res := addmod(res,
                            mulmod(val, /*coefficients[141]*/ mload(0x16e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/value: rc_builtin__value7_0 - column19_row107.
              let val := addmod(
                /*intermediate_value/rc_builtin/value7_0*/ mload(0x4180),
                sub(PRIME, /*column19_row107*/ mload(0x30a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * coefficients[142].
              res := addmod(res,
                            mulmod(val, /*coefficients[142]*/ mload(0x1700), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/addr_step: column19_row234 - (column19_row106 + 1).
              let val := addmod(
                /*column19_row234*/ mload(0x3140),
                sub(PRIME, addmod(/*column19_row106*/ mload(0x3080), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(128 * (trace_length / 128 - 1)).
              // val *= numerators[6].
              val := mulmod(val, mload(0x4d60), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * coefficients[143].
              res := addmod(res,
                            mulmod(val, /*coefficients[143]*/ mload(0x1720), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for rc_builtin/init_addr: column19_row106 - initial_rc_addr.
              let val := addmod(
                /*column19_row106*/ mload(0x3080),
                sub(PRIME, /*initial_rc_addr*/ mload(0x360)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[144].
              res := addmod(res,
                            mulmod(val, /*coefficients[144]*/ mload(0x1740), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/slope: ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa/sig_config.alpha - (column22_row14 + column22_row14) * column22_row1.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x41a0),
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x41a0),
                      PRIME),
                    /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x41a0),
                    PRIME),
                  /*ecdsa/sig_config.alpha*/ mload(0x380),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(/*column22_row14*/ mload(0x37a0), /*column22_row14*/ mload(0x37a0), PRIME),
                    /*column22_row1*/ mload(0x3600),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[145].
              res := addmod(res,
                            mulmod(val, /*coefficients[145]*/ mload(0x1760), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/x: column22_row1 * column22_row1 - (column22_row6 + column22_row6 + column22_row22).
              let val := addmod(
                mulmod(/*column22_row1*/ mload(0x3600), /*column22_row1*/ mload(0x3600), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column22_row6*/ mload(0x36a0), /*column22_row6*/ mload(0x36a0), PRIME),
                    /*column22_row22*/ mload(0x3840),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[146].
              res := addmod(res,
                            mulmod(val, /*coefficients[146]*/ mload(0x1780), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/y: column22_row14 + column22_row30 - column22_row1 * (column22_row6 - column22_row22).
              let val := addmod(
                addmod(/*column22_row14*/ mload(0x37a0), /*column22_row30*/ mload(0x38c0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column22_row1*/ mload(0x3600),
                    addmod(
                      /*column22_row6*/ mload(0x36a0),
                      sub(PRIME, /*column22_row22*/ mload(0x3840)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[147].
              res := addmod(res,
                            mulmod(val, /*coefficients[147]*/ mload(0x17a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/booleanity_test: ecdsa__signature0__exponentiate_generator__bit_0 * (ecdsa__signature0__exponentiate_generator__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x41c0),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x41c0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x48c0), PRIME)

              // res += val * coefficients[148].
              res := addmod(res,
                            mulmod(val, /*coefficients[148]*/ mload(0x17c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/bit_extraction_end: column22_row31.
              let val := /*column22_row31*/ mload(0x38e0)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x48e0), PRIME)

              // res += val * coefficients[149].
              res := addmod(res,
                            mulmod(val, /*coefficients[149]*/ mload(0x17e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/zeros_tail: column22_row31.
              let val := /*column22_row31*/ mload(0x38e0)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[15].
              val := mulmod(val, mload(0x4900), PRIME)

              // res += val * coefficients[150].
              res := addmod(res,
                            mulmod(val, /*coefficients[150]*/ mload(0x1800), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/slope: ecdsa__signature0__exponentiate_generator__bit_0 * (column22_row23 - ecdsa__generator_points__y) - column22_row15 * (column22_row7 - ecdsa__generator_points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x41c0),
                  addmod(
                    /*column22_row23*/ mload(0x3860),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/y*/ mload(0x60)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column22_row15*/ mload(0x37c0),
                    addmod(
                      /*column22_row7*/ mload(0x36c0),
                      sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x48c0), PRIME)

              // res += val * coefficients[151].
              res := addmod(res,
                            mulmod(val, /*coefficients[151]*/ mload(0x1820), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x: column22_row15 * column22_row15 - ecdsa__signature0__exponentiate_generator__bit_0 * (column22_row7 + ecdsa__generator_points__x + column22_row39).
              let val := addmod(
                mulmod(/*column22_row15*/ mload(0x37c0), /*column22_row15*/ mload(0x37c0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x41c0),
                    addmod(
                      addmod(
                        /*column22_row7*/ mload(0x36c0),
                        /*periodic_column/ecdsa/generator_points/x*/ mload(0x40),
                        PRIME),
                      /*column22_row39*/ mload(0x3900),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x48c0), PRIME)

              // res += val * coefficients[152].
              res := addmod(res,
                            mulmod(val, /*coefficients[152]*/ mload(0x1840), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/y: ecdsa__signature0__exponentiate_generator__bit_0 * (column22_row23 + column22_row55) - column22_row15 * (column22_row7 - column22_row39).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x41c0),
                  addmod(/*column22_row23*/ mload(0x3860), /*column22_row55*/ mload(0x3920), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column22_row15*/ mload(0x37c0),
                    addmod(
                      /*column22_row7*/ mload(0x36c0),
                      sub(PRIME, /*column22_row39*/ mload(0x3900)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x48c0), PRIME)

              // res += val * coefficients[153].
              res := addmod(res,
                            mulmod(val, /*coefficients[153]*/ mload(0x1860), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv: column23_row0 * (column22_row7 - ecdsa__generator_points__x) - 1.
              let val := addmod(
                mulmod(
                  /*column23_row0*/ mload(0x3b20),
                  addmod(
                    /*column22_row7*/ mload(0x36c0),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x48c0), PRIME)

              // res += val * coefficients[154].
              res := addmod(res,
                            mulmod(val, /*coefficients[154]*/ mload(0x1880), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/x: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column22_row39 - column22_row7).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x41e0),
                addmod(
                  /*column22_row39*/ mload(0x3900),
                  sub(PRIME, /*column22_row7*/ mload(0x36c0)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x48c0), PRIME)

              // res += val * coefficients[155].
              res := addmod(res,
                            mulmod(val, /*coefficients[155]*/ mload(0x18a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/y: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column22_row55 - column22_row23).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x41e0),
                addmod(
                  /*column22_row55*/ mload(0x3920),
                  sub(PRIME, /*column22_row23*/ mload(0x3860)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x48c0), PRIME)

              // res += val * coefficients[156].
              res := addmod(res,
                            mulmod(val, /*coefficients[156]*/ mload(0x18c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/booleanity_test: ecdsa__signature0__exponentiate_key__bit_0 * (ecdsa__signature0__exponentiate_key__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4200),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4200),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[157].
              res := addmod(res,
                            mulmod(val, /*coefficients[157]*/ mload(0x18e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/bit_extraction_end: column22_row3.
              let val := /*column22_row3*/ mload(0x3640)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[16].
              val := mulmod(val, mload(0x4920), PRIME)

              // res += val * coefficients[158].
              res := addmod(res,
                            mulmod(val, /*coefficients[158]*/ mload(0x1900), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/zeros_tail: column22_row3.
              let val := /*column22_row3*/ mload(0x3640)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[17].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * coefficients[159].
              res := addmod(res,
                            mulmod(val, /*coefficients[159]*/ mload(0x1920), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/slope: ecdsa__signature0__exponentiate_key__bit_0 * (column22_row5 - column22_row14) - column22_row13 * (column22_row9 - column22_row6).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4200),
                  addmod(
                    /*column22_row5*/ mload(0x3680),
                    sub(PRIME, /*column22_row14*/ mload(0x37a0)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column22_row13*/ mload(0x3780),
                    addmod(/*column22_row9*/ mload(0x3700), sub(PRIME, /*column22_row6*/ mload(0x36a0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[160].
              res := addmod(res,
                            mulmod(val, /*coefficients[160]*/ mload(0x1940), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x: column22_row13 * column22_row13 - ecdsa__signature0__exponentiate_key__bit_0 * (column22_row9 + column22_row6 + column22_row25).
              let val := addmod(
                mulmod(/*column22_row13*/ mload(0x3780), /*column22_row13*/ mload(0x3780), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4200),
                    addmod(
                      addmod(/*column22_row9*/ mload(0x3700), /*column22_row6*/ mload(0x36a0), PRIME),
                      /*column22_row25*/ mload(0x38a0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[161].
              res := addmod(res,
                            mulmod(val, /*coefficients[161]*/ mload(0x1960), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/y: ecdsa__signature0__exponentiate_key__bit_0 * (column22_row5 + column22_row21) - column22_row13 * (column22_row9 - column22_row25).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4200),
                  addmod(/*column22_row5*/ mload(0x3680), /*column22_row21*/ mload(0x3820), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column22_row13*/ mload(0x3780),
                    addmod(
                      /*column22_row9*/ mload(0x3700),
                      sub(PRIME, /*column22_row25*/ mload(0x38a0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[162].
              res := addmod(res,
                            mulmod(val, /*coefficients[162]*/ mload(0x1980), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x_diff_inv: column22_row11 * (column22_row9 - column22_row6) - 1.
              let val := addmod(
                mulmod(
                  /*column22_row11*/ mload(0x3740),
                  addmod(/*column22_row9*/ mload(0x3700), sub(PRIME, /*column22_row6*/ mload(0x36a0)), PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[163].
              res := addmod(res,
                            mulmod(val, /*coefficients[163]*/ mload(0x19a0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/x: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column22_row25 - column22_row9).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x4220),
                addmod(
                  /*column22_row25*/ mload(0x38a0),
                  sub(PRIME, /*column22_row9*/ mload(0x3700)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[164].
              res := addmod(res,
                            mulmod(val, /*coefficients[164]*/ mload(0x19c0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/y: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column22_row21 - column22_row5).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x4220),
                addmod(
                  /*column22_row21*/ mload(0x3820),
                  sub(PRIME, /*column22_row5*/ mload(0x3680)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * coefficients[165].
              res := addmod(res,
                            mulmod(val, /*coefficients[165]*/ mload(0x19e0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/x: column22_row7 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column22_row7*/ mload(0x36c0),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[166].
              res := addmod(res,
                            mulmod(val, /*coefficients[166]*/ mload(0x1a00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/y: column22_row23 + ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column22_row23*/ mload(0x3860),
                /*ecdsa/sig_config.shift_point.y*/ mload(0x3c0),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[167].
              res := addmod(res,
                            mulmod(val, /*coefficients[167]*/ mload(0x1a20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/x: column22_row9 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column22_row9*/ mload(0x3700),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[168].
              res := addmod(res,
                            mulmod(val, /*coefficients[168]*/ mload(0x1a40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/y: column22_row5 - ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column22_row5*/ mload(0x3680),
                sub(PRIME, /*ecdsa/sig_config.shift_point.y*/ mload(0x3c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[169].
              res := addmod(res,
                            mulmod(val, /*coefficients[169]*/ mload(0x1a60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/slope: column22_row8183 - (column22_row4085 + column22_row8175 * (column22_row8167 - column22_row4089)).
              let val := addmod(
                /*column22_row8183*/ mload(0x3aa0),
                sub(
                  PRIME,
                  addmod(
                    /*column22_row4085*/ mload(0x3980),
                    mulmod(
                      /*column22_row8175*/ mload(0x3a60),
                      addmod(
                        /*column22_row8167*/ mload(0x3a40),
                        sub(PRIME, /*column22_row4089*/ mload(0x39a0)),
                        PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[170].
              res := addmod(res,
                            mulmod(val, /*coefficients[170]*/ mload(0x1a80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x: column22_row8175 * column22_row8175 - (column22_row8167 + column22_row4089 + column22_row4102).
              let val := addmod(
                mulmod(/*column22_row8175*/ mload(0x3a60), /*column22_row8175*/ mload(0x3a60), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column22_row8167*/ mload(0x3a40), /*column22_row4089*/ mload(0x39a0), PRIME),
                    /*column22_row4102*/ mload(0x3a00),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[171].
              res := addmod(res,
                            mulmod(val, /*coefficients[171]*/ mload(0x1aa0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/y: column22_row8183 + column22_row4110 - column22_row8175 * (column22_row8167 - column22_row4102).
              let val := addmod(
                addmod(/*column22_row8183*/ mload(0x3aa0), /*column22_row4110*/ mload(0x3a20), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column22_row8175*/ mload(0x3a60),
                    addmod(
                      /*column22_row8167*/ mload(0x3a40),
                      sub(PRIME, /*column22_row4102*/ mload(0x3a00)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[172].
              res := addmod(res,
                            mulmod(val, /*coefficients[172]*/ mload(0x1ac0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x_diff_inv: column23_row8160 * (column22_row8167 - column22_row4089) - 1.
              let val := addmod(
                mulmod(
                  /*column23_row8160*/ mload(0x3bc0),
                  addmod(
                    /*column22_row8167*/ mload(0x3a40),
                    sub(PRIME, /*column22_row4089*/ mload(0x39a0)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[173].
              res := addmod(res,
                            mulmod(val, /*coefficients[173]*/ mload(0x1ae0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/slope: column22_row8181 + ecdsa/sig_config.shift_point.y - column22_row4093 * (column22_row8185 - ecdsa/sig_config.shift_point.x).
              let val := addmod(
                addmod(
                  /*column22_row8181*/ mload(0x3a80),
                  /*ecdsa/sig_config.shift_point.y*/ mload(0x3c0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column22_row4093*/ mload(0x39e0),
                    addmod(
                      /*column22_row8185*/ mload(0x3ac0),
                      sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[174].
              res := addmod(res,
                            mulmod(val, /*coefficients[174]*/ mload(0x1b00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x: column22_row4093 * column22_row4093 - (column22_row8185 + ecdsa/sig_config.shift_point.x + column22_row3).
              let val := addmod(
                mulmod(/*column22_row4093*/ mload(0x39e0), /*column22_row4093*/ mload(0x39e0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*column22_row8185*/ mload(0x3ac0),
                      /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0),
                      PRIME),
                    /*column22_row3*/ mload(0x3640),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[175].
              res := addmod(res,
                            mulmod(val, /*coefficients[175]*/ mload(0x1b20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x_diff_inv: column22_row8189 * (column22_row8185 - ecdsa/sig_config.shift_point.x) - 1.
              let val := addmod(
                mulmod(
                  /*column22_row8189*/ mload(0x3b00),
                  addmod(
                    /*column22_row8185*/ mload(0x3ac0),
                    sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x3a0)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[176].
              res := addmod(res,
                            mulmod(val, /*coefficients[176]*/ mload(0x1b40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/z_nonzero: column22_row31 * column22_row4091 - 1.
              let val := addmod(
                mulmod(/*column22_row31*/ mload(0x38e0), /*column22_row4091*/ mload(0x39c0), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[177].
              res := addmod(res,
                            mulmod(val, /*coefficients[177]*/ mload(0x1b60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/r_and_w_nonzero: column22_row3 * column22_row4081 - 1.
              let val := addmod(
                mulmod(/*column22_row3*/ mload(0x3640), /*column22_row4081*/ mload(0x3960), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[178].
              res := addmod(res,
                            mulmod(val, /*coefficients[178]*/ mload(0x1b80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/x_squared: column22_row8187 - column22_row6 * column22_row6.
              let val := addmod(
                /*column22_row8187*/ mload(0x3ae0),
                sub(
                  PRIME,
                  mulmod(/*column22_row6*/ mload(0x36a0), /*column22_row6*/ mload(0x36a0), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[179].
              res := addmod(res,
                            mulmod(val, /*coefficients[179]*/ mload(0x1ba0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/on_curve: column22_row14 * column22_row14 - (column22_row6 * column22_row8187 + ecdsa/sig_config.alpha * column22_row6 + ecdsa/sig_config.beta).
              let val := addmod(
                mulmod(/*column22_row14*/ mload(0x37a0), /*column22_row14*/ mload(0x37a0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(/*column22_row6*/ mload(0x36a0), /*column22_row8187*/ mload(0x3ae0), PRIME),
                      mulmod(/*ecdsa/sig_config.alpha*/ mload(0x380), /*column22_row6*/ mload(0x36a0), PRIME),
                      PRIME),
                    /*ecdsa/sig_config.beta*/ mload(0x3e0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[180].
              res := addmod(res,
                            mulmod(val, /*coefficients[180]*/ mload(0x1bc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/init_addr: column19_row26 - initial_ecdsa_addr.
              let val := addmod(
                /*column19_row26*/ mload(0x2fc0),
                sub(PRIME, /*initial_ecdsa_addr*/ mload(0x400)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[181].
              res := addmod(res,
                            mulmod(val, /*coefficients[181]*/ mload(0x1be0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/message_addr: column19_row4122 - (column19_row26 + 1).
              let val := addmod(
                /*column19_row4122*/ mload(0x3320),
                sub(PRIME, addmod(/*column19_row26*/ mload(0x2fc0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[182].
              res := addmod(res,
                            mulmod(val, /*coefficients[182]*/ mload(0x1c00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_addr: column19_row8218 - (column19_row4122 + 1).
              let val := addmod(
                /*column19_row8218*/ mload(0x3380),
                sub(PRIME, addmod(/*column19_row4122*/ mload(0x3320), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(8192 * (trace_length / 8192 - 1)).
              // val *= numerators[9].
              val := mulmod(val, mload(0x4dc0), PRIME)
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[183].
              res := addmod(res,
                            mulmod(val, /*coefficients[183]*/ mload(0x1c20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/message_value0: column19_row4123 - column22_row31.
              let val := addmod(
                /*column19_row4123*/ mload(0x3340),
                sub(PRIME, /*column22_row31*/ mload(0x38e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[184].
              res := addmod(res,
                            mulmod(val, /*coefficients[184]*/ mload(0x1c40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_value0: column19_row27 - column22_row6.
              let val := addmod(
                /*column19_row27*/ mload(0x2fe0),
                sub(PRIME, /*column22_row6*/ mload(0x36a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * coefficients[185].
              res := addmod(res,
                            mulmod(val, /*coefficients[185]*/ mload(0x1c60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/init_var_pool_addr: column19_row538 - initial_bitwise_addr.
              let val := addmod(
                /*column19_row538*/ mload(0x3220),
                sub(PRIME, /*initial_bitwise_addr*/ mload(0x420)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * coefficients[186].
              res := addmod(res,
                            mulmod(val, /*coefficients[186]*/ mload(0x1c80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/step_var_pool_addr: column19_row1562 - (column19_row538 + 1).
              let val := addmod(
                /*column19_row1562*/ mload(0x3260),
                sub(PRIME, addmod(/*column19_row538*/ mload(0x3220), 1, PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(3 * trace_length / 4).
              // val *= numerators[10].
              val := mulmod(val, mload(0x4de0), PRIME)
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x49a0), PRIME)

              // res += val * coefficients[187].
              res := addmod(res,
                            mulmod(val, /*coefficients[187]*/ mload(0x1ca0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/x_or_y_addr: column19_row2074 - (column19_row3610 + 1).
              let val := addmod(
                /*column19_row2074*/ mload(0x3280),
                sub(PRIME, addmod(/*column19_row3610*/ mload(0x32e0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[188].
              res := addmod(res,
                            mulmod(val, /*coefficients[188]*/ mload(0x1cc0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/next_var_pool_addr: column19_row4634 - (column19_row2074 + 1).
              let val := addmod(
                /*column19_row4634*/ mload(0x3360),
                sub(PRIME, addmod(/*column19_row2074*/ mload(0x3280), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(4096 * (trace_length / 4096 - 1)).
              // val *= numerators[11].
              val := mulmod(val, mload(0x4e00), PRIME)
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[189].
              res := addmod(res,
                            mulmod(val, /*coefficients[189]*/ mload(0x1ce0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/partition: bitwise__sum_var_0_0 + bitwise__sum_var_8_0 - column19_row539.
              let val := addmod(
                addmod(
                  /*intermediate_value/bitwise/sum_var_0_0*/ mload(0x4240),
                  /*intermediate_value/bitwise/sum_var_8_0*/ mload(0x4260),
                  PRIME),
                sub(PRIME, /*column19_row539*/ mload(0x3240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 1024) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x49a0), PRIME)

              // res += val * coefficients[190].
              res := addmod(res,
                            mulmod(val, /*coefficients[190]*/ mload(0x1d00), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/or_is_and_plus_xor: column19_row2075 - (column19_row2587 + column19_row3611).
              let val := addmod(
                /*column19_row2075*/ mload(0x32a0),
                sub(
                  PRIME,
                  addmod(/*column19_row2587*/ mload(0x32c0), /*column19_row3611*/ mload(0x3300), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[191].
              res := addmod(res,
                            mulmod(val, /*coefficients[191]*/ mload(0x1d20), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/addition_is_xor_with_and: column1_row0 + column1_row1024 - (column1_row3072 + column1_row2048 + column1_row2048).
              let val := addmod(
                addmod(/*column1_row0*/ mload(0x1fe0), /*column1_row1024*/ mload(0x2220), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column1_row3072*/ mload(0x2320), /*column1_row2048*/ mload(0x2260), PRIME),
                    /*column1_row2048*/ mload(0x2260),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: (point^(trace_length / 4096) - 1) * (point^(trace_length / 4096) - trace_generator^(trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 16)) * (point^(trace_length / 4096) - trace_generator^(5 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(7 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(trace_length / 8)) * (point^(trace_length / 4096) - trace_generator^(9 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(5 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(11 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(3 * trace_length / 16)) * (point^(trace_length / 4096) - trace_generator^(13 * trace_length / 64)) * (point^(trace_length / 4096) - trace_generator^(7 * trace_length / 32)) * (point^(trace_length / 4096) - trace_generator^(15 * trace_length / 64)).
              // val *= denominator_invs[21].
              val := mulmod(val, mload(0x49c0), PRIME)

              // res += val * coefficients[192].
              res := addmod(res,
                            mulmod(val, /*coefficients[192]*/ mload(0x1d40), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking192: (column1_row2816 + column1_row3840) * 16 - column1_row32.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row2816*/ mload(0x22a0), /*column1_row3840*/ mload(0x2360), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column1_row32*/ mload(0x2020)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[193].
              res := addmod(res,
                            mulmod(val, /*coefficients[193]*/ mload(0x1d60), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking193: (column1_row2880 + column1_row3904) * 16 - column1_row2080.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row2880*/ mload(0x22c0), /*column1_row3904*/ mload(0x2380), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column1_row2080*/ mload(0x2280)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[194].
              res := addmod(res,
                            mulmod(val, /*coefficients[194]*/ mload(0x1d80), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking194: (column1_row2944 + column1_row3968) * 16 - column1_row1056.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row2944*/ mload(0x22e0), /*column1_row3968*/ mload(0x23a0), PRIME),
                  16,
                  PRIME),
                sub(PRIME, /*column1_row1056*/ mload(0x2240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[195].
              res := addmod(res,
                            mulmod(val, /*coefficients[195]*/ mload(0x1da0), PRIME),
                            PRIME)
              }

              {
              // Constraint expression for bitwise/unique_unpacking195: (column1_row3008 + column1_row4032) * 256 - column1_row3104.
              let val := addmod(
                mulmod(
                  addmod(/*column1_row3008*/ mload(0x2300), /*column1_row4032*/ mload(0x23c0), PRIME),
                  256,
                  PRIME),
                sub(PRIME, /*column1_row3104*/ mload(0x2340)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * coefficients[196].
              res := addmod(res,
                            mulmod(val, /*coefficients[196]*/ mload(0x1dc0), PRIME),
                            PRIME)
              }

            mstore(0, res)
            return(0, 0x20)
            }
        }
    }
}
// ---------- End of auto-generated code. ----------