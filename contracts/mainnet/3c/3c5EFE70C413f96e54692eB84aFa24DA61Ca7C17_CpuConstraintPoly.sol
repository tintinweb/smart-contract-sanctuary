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
    // [0x440, 0x2980) - coefficients.
    // [0x2980, 0x3f40) - oods_values.
    // ----------------------- end of input data - -------------------------
    // [0x3f40, 0x3f60) - composition_degree_bound.
    // [0x3f60, 0x3f80) - intermediate_value/cpu/decode/opcode_rc/bit_0.
    // [0x3f80, 0x3fa0) - intermediate_value/cpu/decode/opcode_rc/bit_1.
    // [0x3fa0, 0x3fc0) - intermediate_value/cpu/decode/opcode_rc/bit_2.
    // [0x3fc0, 0x3fe0) - intermediate_value/cpu/decode/opcode_rc/bit_4.
    // [0x3fe0, 0x4000) - intermediate_value/cpu/decode/opcode_rc/bit_3.
    // [0x4000, 0x4020) - intermediate_value/cpu/decode/opcode_rc/bit_9.
    // [0x4020, 0x4040) - intermediate_value/cpu/decode/opcode_rc/bit_5.
    // [0x4040, 0x4060) - intermediate_value/cpu/decode/opcode_rc/bit_6.
    // [0x4060, 0x4080) - intermediate_value/cpu/decode/opcode_rc/bit_7.
    // [0x4080, 0x40a0) - intermediate_value/cpu/decode/opcode_rc/bit_8.
    // [0x40a0, 0x40c0) - intermediate_value/npc_reg_0.
    // [0x40c0, 0x40e0) - intermediate_value/cpu/decode/opcode_rc/bit_10.
    // [0x40e0, 0x4100) - intermediate_value/cpu/decode/opcode_rc/bit_11.
    // [0x4100, 0x4120) - intermediate_value/cpu/decode/opcode_rc/bit_12.
    // [0x4120, 0x4140) - intermediate_value/cpu/decode/opcode_rc/bit_13.
    // [0x4140, 0x4160) - intermediate_value/cpu/decode/opcode_rc/bit_14.
    // [0x4160, 0x4180) - intermediate_value/memory/address_diff_0.
    // [0x4180, 0x41a0) - intermediate_value/rc16/diff_0.
    // [0x41a0, 0x41c0) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_0.
    // [0x41c0, 0x41e0) - intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0.
    // [0x41e0, 0x4200) - intermediate_value/pedersen/hash1/ec_subset_sum/bit_0.
    // [0x4200, 0x4220) - intermediate_value/pedersen/hash1/ec_subset_sum/bit_neg_0.
    // [0x4220, 0x4240) - intermediate_value/pedersen/hash2/ec_subset_sum/bit_0.
    // [0x4240, 0x4260) - intermediate_value/pedersen/hash2/ec_subset_sum/bit_neg_0.
    // [0x4260, 0x4280) - intermediate_value/pedersen/hash3/ec_subset_sum/bit_0.
    // [0x4280, 0x42a0) - intermediate_value/pedersen/hash3/ec_subset_sum/bit_neg_0.
    // [0x42a0, 0x42c0) - intermediate_value/rc_builtin/value0_0.
    // [0x42c0, 0x42e0) - intermediate_value/rc_builtin/value1_0.
    // [0x42e0, 0x4300) - intermediate_value/rc_builtin/value2_0.
    // [0x4300, 0x4320) - intermediate_value/rc_builtin/value3_0.
    // [0x4320, 0x4340) - intermediate_value/rc_builtin/value4_0.
    // [0x4340, 0x4360) - intermediate_value/rc_builtin/value5_0.
    // [0x4360, 0x4380) - intermediate_value/rc_builtin/value6_0.
    // [0x4380, 0x43a0) - intermediate_value/rc_builtin/value7_0.
    // [0x43a0, 0x43c0) - intermediate_value/ecdsa/signature0/doubling_key/x_squared.
    // [0x43c0, 0x43e0) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0.
    // [0x43e0, 0x4400) - intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0.
    // [0x4400, 0x4420) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_0.
    // [0x4420, 0x4440) - intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0.
    // [0x4440, 0x46e0) - expmods.
    // [0x46e0, 0x49a0) - denominator_invs.
    // [0x49a0, 0x4c60) - denominators.
    // [0x4c60, 0x4dc0) - numerators.
    // [0x4dc0, 0x50a0) - adjustments.
    // [0x50a0, 0x5160) - expmod_context.

    function() external {
        uint256 res;
        assembly {
            let PRIME := 0x800000000000011000000000000000000000000000000000000000000000001
            // Copy input from calldata to memory.
            calldatacopy(0x0, 0x0, /*Input data size*/ 0x3f40)
            let point := /*oods_point*/ mload(0x3c0)
            // Initialize composition_degree_bound to 2 * trace_length.
            mstore(0x3f40, mul(2, /*trace_length*/ mload(0x80)))
            function expmod(base, exponent, modulus) -> res {
              let p := /*expmod_context*/ 0x50a0
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
              mstore(0x4440, expmod(point, /*trace_length*/ mload(0x80), PRIME))

              // expmods[1] = point^(trace_length / 16).
              mstore(0x4460, expmod(point, div(/*trace_length*/ mload(0x80), 16), PRIME))

              // expmods[2] = point^(trace_length / 2).
              mstore(0x4480, expmod(point, div(/*trace_length*/ mload(0x80), 2), PRIME))

              // expmods[3] = point^(trace_length / 8).
              mstore(0x44a0, expmod(point, div(/*trace_length*/ mload(0x80), 8), PRIME))

              // expmods[4] = point^(trace_length / 256).
              mstore(0x44c0, expmod(point, div(/*trace_length*/ mload(0x80), 256), PRIME))

              // expmods[5] = point^(trace_length / 512).
              mstore(0x44e0, expmod(point, div(/*trace_length*/ mload(0x80), 512), PRIME))

              // expmods[6] = point^(trace_length / 128).
              mstore(0x4500, expmod(point, div(/*trace_length*/ mload(0x80), 128), PRIME))

              // expmods[7] = point^(trace_length / 4096).
              mstore(0x4520, expmod(point, div(/*trace_length*/ mload(0x80), 4096), PRIME))

              // expmods[8] = point^(trace_length / 32).
              mstore(0x4540, expmod(point, div(/*trace_length*/ mload(0x80), 32), PRIME))

              // expmods[9] = point^(trace_length / 8192).
              mstore(0x4560, expmod(point, div(/*trace_length*/ mload(0x80), 8192), PRIME))

              // expmods[10] = trace_generator^(15 * trace_length / 16).
              mstore(0x4580, expmod(/*trace_generator*/ mload(0x3a0), div(mul(15, /*trace_length*/ mload(0x80)), 16), PRIME))

              // expmods[11] = trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x45a0, expmod(/*trace_generator*/ mload(0x3a0), mul(16, sub(div(/*trace_length*/ mload(0x80), 16), 1)), PRIME))

              // expmods[12] = trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x45c0, expmod(/*trace_generator*/ mload(0x3a0), mul(2, sub(div(/*trace_length*/ mload(0x80), 2), 1)), PRIME))

              // expmods[13] = trace_generator^(trace_length - 1).
              mstore(0x45e0, expmod(/*trace_generator*/ mload(0x3a0), sub(/*trace_length*/ mload(0x80), 1), PRIME))

              // expmods[14] = trace_generator^(255 * trace_length / 256).
              mstore(0x4600, expmod(/*trace_generator*/ mload(0x3a0), div(mul(255, /*trace_length*/ mload(0x80)), 256), PRIME))

              // expmods[15] = trace_generator^(63 * trace_length / 64).
              mstore(0x4620, expmod(/*trace_generator*/ mload(0x3a0), div(mul(63, /*trace_length*/ mload(0x80)), 64), PRIME))

              // expmods[16] = trace_generator^(trace_length / 2).
              mstore(0x4640, expmod(/*trace_generator*/ mload(0x3a0), div(/*trace_length*/ mload(0x80), 2), PRIME))

              // expmods[17] = trace_generator^(128 * (trace_length / 128 - 1)).
              mstore(0x4660, expmod(/*trace_generator*/ mload(0x3a0), mul(128, sub(div(/*trace_length*/ mload(0x80), 128), 1)), PRIME))

              // expmods[18] = trace_generator^(251 * trace_length / 256).
              mstore(0x4680, expmod(/*trace_generator*/ mload(0x3a0), div(mul(251, /*trace_length*/ mload(0x80)), 256), PRIME))

              // expmods[19] = trace_generator^(8192 * (trace_length / 8192 - 1)).
              mstore(0x46a0, expmod(/*trace_generator*/ mload(0x3a0), mul(8192, sub(div(/*trace_length*/ mload(0x80), 8192), 1)), PRIME))

              // expmods[20] = trace_generator^(256 * (trace_length / 256 - 1)).
              mstore(0x46c0, expmod(/*trace_generator*/ mload(0x3a0), mul(256, sub(div(/*trace_length*/ mload(0x80), 256), 1)), PRIME))

            }

            {
              // Prepare denominators for batch inverse.

              // Denominator for constraints: 'cpu/decode/opcode_rc/bit', 'rc16/perm/step0', 'rc16/diff_is_bit', 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y', 'pedersen/hash1/ec_subset_sum/booleanity_test', 'pedersen/hash1/ec_subset_sum/add_points/slope', 'pedersen/hash1/ec_subset_sum/add_points/x', 'pedersen/hash1/ec_subset_sum/add_points/y', 'pedersen/hash1/ec_subset_sum/copy_point/x', 'pedersen/hash1/ec_subset_sum/copy_point/y', 'pedersen/hash2/ec_subset_sum/booleanity_test', 'pedersen/hash2/ec_subset_sum/add_points/slope', 'pedersen/hash2/ec_subset_sum/add_points/x', 'pedersen/hash2/ec_subset_sum/add_points/y', 'pedersen/hash2/ec_subset_sum/copy_point/x', 'pedersen/hash2/ec_subset_sum/copy_point/y', 'pedersen/hash3/ec_subset_sum/booleanity_test', 'pedersen/hash3/ec_subset_sum/add_points/slope', 'pedersen/hash3/ec_subset_sum/add_points/x', 'pedersen/hash3/ec_subset_sum/add_points/y', 'pedersen/hash3/ec_subset_sum/copy_point/x', 'pedersen/hash3/ec_subset_sum/copy_point/y'.
              // denominators[0] = point^trace_length - 1.
              mstore(0x49a0,
                     addmod(/*point^trace_length*/ mload(0x4440), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc/last_bit'.
              // denominators[1] = point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              mstore(0x49c0,
                     addmod(
                       /*point^(trace_length / 16)*/ mload(0x4460),
                       sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x4580)),
                       PRIME))

              // Denominator for constraints: 'cpu/decode/opcode_rc_input', 'cpu/operands/mem_dst_addr', 'cpu/operands/mem0_addr', 'cpu/operands/mem1_addr', 'cpu/operands/ops_mul', 'cpu/operands/res', 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update', 'cpu/opcodes/call/push_fp', 'cpu/opcodes/call/push_pc', 'cpu/opcodes/assert_eq/assert_eq', 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y'.
              // denominators[2] = point^(trace_length / 16) - 1.
              mstore(0x49e0,
                     addmod(/*point^(trace_length / 16)*/ mload(0x4460), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'initial_ap', 'initial_fp', 'initial_pc', 'memory/multi_column_perm/perm/init0', 'rc16/perm/init0', 'rc16/minimum', 'pedersen/init_addr', 'rc_builtin/init_addr', 'ecdsa/init_addr', 'checkpoints/req_pc_init_addr'.
              // denominators[3] = point - 1.
              mstore(0x4a00,
                     addmod(point, sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'final_ap', 'final_pc'.
              // denominators[4] = point - trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x4a20,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16 * (trace_length / 16 - 1))*/ mload(0x45a0)),
                       PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // denominators[5] = point^(trace_length / 2) - 1.
              mstore(0x4a40,
                     addmod(/*point^(trace_length / 2)*/ mload(0x4480), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'memory/multi_column_perm/perm/last'.
              // denominators[6] = point - trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x4a60,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2 * (trace_length / 2 - 1))*/ mload(0x45c0)),
                       PRIME))

              // Denominator for constraints: 'public_memory_addr_zero', 'public_memory_value_zero'.
              // denominators[7] = point^(trace_length / 8) - 1.
              mstore(0x4a80,
                     addmod(/*point^(trace_length / 8)*/ mload(0x44a0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'rc16/perm/last', 'rc16/maximum'.
              // denominators[8] = point - trace_generator^(trace_length - 1).
              mstore(0x4aa0,
                     addmod(point, sub(PRIME, /*trace_generator^(trace_length - 1)*/ mload(0x45e0)), PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/bit_extraction_end', 'pedersen/hash1/ec_subset_sum/bit_extraction_end', 'pedersen/hash2/ec_subset_sum/bit_extraction_end', 'pedersen/hash3/ec_subset_sum/bit_extraction_end'.
              // denominators[9] = point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              mstore(0x4ac0,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x44c0),
                       sub(PRIME, /*trace_generator^(63 * trace_length / 64)*/ mload(0x4620)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/ec_subset_sum/zeros_tail', 'pedersen/hash1/ec_subset_sum/zeros_tail', 'pedersen/hash2/ec_subset_sum/zeros_tail', 'pedersen/hash3/ec_subset_sum/zeros_tail'.
              // denominators[10] = point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              mstore(0x4ae0,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x44c0),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4600)),
                       PRIME))

              // Denominator for constraints: 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y', 'pedersen/hash1/copy_point/x', 'pedersen/hash1/copy_point/y', 'pedersen/hash2/copy_point/x', 'pedersen/hash2/copy_point/y', 'pedersen/hash3/copy_point/x', 'pedersen/hash3/copy_point/y', 'checkpoints/required_fp_addr', 'checkpoints/required_pc_next_addr', 'checkpoints/req_pc', 'checkpoints/req_fp'.
              // denominators[11] = point^(trace_length / 256) - 1.
              mstore(0x4b00,
                     addmod(/*point^(trace_length / 256)*/ mload(0x44c0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/hash0/init/x', 'pedersen/hash0/init/y', 'pedersen/hash1/init/x', 'pedersen/hash1/init/y', 'pedersen/hash2/init/x', 'pedersen/hash2/init/y', 'pedersen/hash3/init/x', 'pedersen/hash3/init/y', 'pedersen/input0_value0', 'pedersen/input0_value1', 'pedersen/input0_value2', 'pedersen/input0_value3', 'pedersen/input1_value0', 'pedersen/input1_value1', 'pedersen/input1_value2', 'pedersen/input1_value3', 'pedersen/output_value0', 'pedersen/output_value1', 'pedersen/output_value2', 'pedersen/output_value3'.
              // denominators[12] = point^(trace_length / 512) - 1.
              mstore(0x4b20,
                     addmod(/*point^(trace_length / 512)*/ mload(0x44e0), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'pedersen/input0_addr', 'pedersen/input1_addr', 'pedersen/output_addr', 'rc_builtin/value', 'rc_builtin/addr_step'.
              // denominators[13] = point^(trace_length / 128) - 1.
              mstore(0x4b40,
                     addmod(/*point^(trace_length / 128)*/ mload(0x4500), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // denominators[14] = point^(trace_length / 32) - 1.
              mstore(0x4b60,
                     addmod(/*point^(trace_length / 32)*/ mload(0x4540), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/bit_extraction_end'.
              // denominators[15] = point^(trace_length / 8192) - trace_generator^(251 * trace_length / 256).
              mstore(0x4b80,
                     addmod(
                       /*point^(trace_length / 8192)*/ mload(0x4560),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x4680)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_generator/zeros_tail'.
              // denominators[16] = point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              mstore(0x4ba0,
                     addmod(
                       /*point^(trace_length / 8192)*/ mload(0x4560),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4600)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/bit_extraction_end'.
              // denominators[17] = point^(trace_length / 4096) - trace_generator^(251 * trace_length / 256).
              mstore(0x4bc0,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4520),
                       sub(PRIME, /*trace_generator^(251 * trace_length / 256)*/ mload(0x4680)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/exponentiate_key/zeros_tail'.
              // denominators[18] = point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              mstore(0x4be0,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4520),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4600)),
                       PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_gen/x', 'ecdsa/signature0/init_gen/y', 'ecdsa/signature0/add_results/slope', 'ecdsa/signature0/add_results/x', 'ecdsa/signature0/add_results/y', 'ecdsa/signature0/add_results/x_diff_inv', 'ecdsa/signature0/extract_r/slope', 'ecdsa/signature0/extract_r/x', 'ecdsa/signature0/extract_r/x_diff_inv', 'ecdsa/signature0/z_nonzero', 'ecdsa/signature0/q_on_curve/x_squared', 'ecdsa/signature0/q_on_curve/on_curve', 'ecdsa/message_addr', 'ecdsa/pubkey_addr', 'ecdsa/message_value0', 'ecdsa/pubkey_value0'.
              // denominators[19] = point^(trace_length / 8192) - 1.
              mstore(0x4c00,
                     addmod(/*point^(trace_length / 8192)*/ mload(0x4560), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'ecdsa/signature0/init_key/x', 'ecdsa/signature0/init_key/y', 'ecdsa/signature0/r_and_w_nonzero'.
              // denominators[20] = point^(trace_length / 4096) - 1.
              mstore(0x4c20,
                     addmod(/*point^(trace_length / 4096)*/ mload(0x4520), sub(PRIME, 1), PRIME))

              // Denominator for constraints: 'checkpoints/req_pc_final_addr'.
              // denominators[21] = point - trace_generator^(256 * (trace_length / 256 - 1)).
              mstore(0x4c40,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(256 * (trace_length / 256 - 1))*/ mload(0x46c0)),
                       PRIME))

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
              let partialProductEndPtr := 0x49a0
              for { let partialProductPtr := 0x46e0 }
                  lt(partialProductPtr, partialProductEndPtr)
                  { partialProductPtr := add(partialProductPtr, 0x20) } {
                  mstore(partialProductPtr, prod)
                  // prod *= d_{i}.
                  prod := mulmod(prod,
                                 mload(add(partialProductPtr, productsToValuesOffset)),
                                 PRIME)
              }

              let firstPartialProductPtr := 0x46e0
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
              let currentPartialProductPtr := 0x49a0
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
              mstore(0x4c60,
                     addmod(
                       /*point^(trace_length / 16)*/ mload(0x4460),
                       sub(PRIME, /*trace_generator^(15 * trace_length / 16)*/ mload(0x4580)),
                       PRIME))

              // Numerator for constraints 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update'.
              // numerators[1] = point - trace_generator^(16 * (trace_length / 16 - 1)).
              mstore(0x4c80,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(16 * (trace_length / 16 - 1))*/ mload(0x45a0)),
                       PRIME))

              // Numerator for constraints 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // numerators[2] = point - trace_generator^(2 * (trace_length / 2 - 1)).
              mstore(0x4ca0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(2 * (trace_length / 2 - 1))*/ mload(0x45c0)),
                       PRIME))

              // Numerator for constraints 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // numerators[3] = point - trace_generator^(trace_length - 1).
              mstore(0x4cc0,
                     addmod(point, sub(PRIME, /*trace_generator^(trace_length - 1)*/ mload(0x45e0)), PRIME))

              // Numerator for constraints 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y', 'pedersen/hash1/ec_subset_sum/booleanity_test', 'pedersen/hash1/ec_subset_sum/add_points/slope', 'pedersen/hash1/ec_subset_sum/add_points/x', 'pedersen/hash1/ec_subset_sum/add_points/y', 'pedersen/hash1/ec_subset_sum/copy_point/x', 'pedersen/hash1/ec_subset_sum/copy_point/y', 'pedersen/hash2/ec_subset_sum/booleanity_test', 'pedersen/hash2/ec_subset_sum/add_points/slope', 'pedersen/hash2/ec_subset_sum/add_points/x', 'pedersen/hash2/ec_subset_sum/add_points/y', 'pedersen/hash2/ec_subset_sum/copy_point/x', 'pedersen/hash2/ec_subset_sum/copy_point/y', 'pedersen/hash3/ec_subset_sum/booleanity_test', 'pedersen/hash3/ec_subset_sum/add_points/slope', 'pedersen/hash3/ec_subset_sum/add_points/x', 'pedersen/hash3/ec_subset_sum/add_points/y', 'pedersen/hash3/ec_subset_sum/copy_point/x', 'pedersen/hash3/ec_subset_sum/copy_point/y'.
              // numerators[4] = point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              mstore(0x4ce0,
                     addmod(
                       /*point^(trace_length / 256)*/ mload(0x44c0),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4600)),
                       PRIME))

              // Numerator for constraints 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y', 'pedersen/hash1/copy_point/x', 'pedersen/hash1/copy_point/y', 'pedersen/hash2/copy_point/x', 'pedersen/hash2/copy_point/y', 'pedersen/hash3/copy_point/x', 'pedersen/hash3/copy_point/y'.
              // numerators[5] = point^(trace_length / 512) - trace_generator^(trace_length / 2).
              mstore(0x4d00,
                     addmod(
                       /*point^(trace_length / 512)*/ mload(0x44e0),
                       sub(PRIME, /*trace_generator^(trace_length / 2)*/ mload(0x4640)),
                       PRIME))

              // Numerator for constraints 'pedersen/input0_addr', 'rc_builtin/addr_step'.
              // numerators[6] = point - trace_generator^(128 * (trace_length / 128 - 1)).
              mstore(0x4d20,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(128 * (trace_length / 128 - 1))*/ mload(0x4660)),
                       PRIME))

              // Numerator for constraints 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y'.
              // numerators[7] = point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              mstore(0x4d40,
                     addmod(
                       /*point^(trace_length / 4096)*/ mload(0x4520),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4600)),
                       PRIME))

              // Numerator for constraints 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // numerators[8] = point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              mstore(0x4d60,
                     addmod(
                       /*point^(trace_length / 8192)*/ mload(0x4560),
                       sub(PRIME, /*trace_generator^(255 * trace_length / 256)*/ mload(0x4600)),
                       PRIME))

              // Numerator for constraints 'ecdsa/pubkey_addr'.
              // numerators[9] = point - trace_generator^(8192 * (trace_length / 8192 - 1)).
              mstore(0x4d80,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(8192 * (trace_length / 8192 - 1))*/ mload(0x46a0)),
                       PRIME))

              // Numerator for constraints 'checkpoints/required_pc_next_addr', 'checkpoints/req_pc', 'checkpoints/req_fp'.
              // numerators[10] = point - trace_generator^(256 * (trace_length / 256 - 1)).
              mstore(0x4da0,
                     addmod(
                       point,
                       sub(PRIME, /*trace_generator^(256 * (trace_length / 256 - 1))*/ mload(0x46c0)),
                       PRIME))

              // Adjustment polynomial for constraints 'cpu/decode/opcode_rc/bit'.
              // adjustments[0] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), trace_length / 16, trace_length).
              mstore(0x4dc0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), div(/*trace_length*/ mload(0x80), 16), /*trace_length*/ mload(0x80)), PRIME))

              // Adjustment polynomial for constraints 'cpu/decode/opcode_rc/last_bit', 'cpu/operands/mem_dst_addr', 'cpu/operands/mem0_addr', 'cpu/operands/mem1_addr', 'cpu/operands/ops_mul', 'cpu/operands/res', 'cpu/opcodes/call/push_fp', 'cpu/opcodes/call/push_pc', 'cpu/opcodes/assert_eq/assert_eq'.
              // adjustments[1] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 0, trace_length / 16).
              mstore(0x4de0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 0, div(/*trace_length*/ mload(0x80), 16)), PRIME))

              // Adjustment polynomial for constraints 'cpu/decode/opcode_rc_input'.
              // adjustments[2] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 16).
              mstore(0x4e00,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 16)), PRIME))

              // Adjustment polynomial for constraints 'cpu/update_registers/update_pc/tmp0', 'cpu/update_registers/update_pc/tmp1', 'cpu/update_registers/update_pc/pc_cond_negative', 'cpu/update_registers/update_pc/pc_cond_positive', 'cpu/update_registers/update_ap/ap_update', 'cpu/update_registers/update_fp/fp_update'.
              // adjustments[3] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 1, trace_length / 16).
              mstore(0x4e20,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 1, div(/*trace_length*/ mload(0x80), 16)), PRIME))

              // Adjustment polynomial for constraints 'initial_ap', 'initial_fp', 'initial_pc', 'final_ap', 'final_pc', 'memory/multi_column_perm/perm/last', 'rc16/perm/last', 'rc16/minimum', 'rc16/maximum', 'pedersen/init_addr', 'rc_builtin/init_addr', 'ecdsa/init_addr', 'checkpoints/req_pc_init_addr', 'checkpoints/req_pc_final_addr'.
              // adjustments[4] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, 1).
              mstore(0x4e40,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 0, 1), PRIME))

              // Adjustment polynomial for constraints 'memory/multi_column_perm/perm/init0', 'rc16/perm/init0'.
              // adjustments[5] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 0, 1).
              mstore(0x4e60,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 0, 1), PRIME))

              // Adjustment polynomial for constraints 'memory/multi_column_perm/perm/step0', 'memory/diff_is_bit', 'memory/is_func'.
              // adjustments[6] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 1, trace_length / 2).
              mstore(0x4e80,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 1, div(/*trace_length*/ mload(0x80), 2)), PRIME))

              // Adjustment polynomial for constraints 'public_memory_addr_zero', 'public_memory_value_zero'.
              // adjustments[7] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 8).
              mstore(0x4ea0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 8)), PRIME))

              // Adjustment polynomial for constraints 'rc16/perm/step0', 'rc16/diff_is_bit'.
              // adjustments[8] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 1, trace_length).
              mstore(0x4ec0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 1, /*trace_length*/ mload(0x80)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/hash0/ec_subset_sum/booleanity_test', 'pedersen/hash0/ec_subset_sum/add_points/slope', 'pedersen/hash0/ec_subset_sum/add_points/x', 'pedersen/hash0/ec_subset_sum/add_points/y', 'pedersen/hash0/ec_subset_sum/copy_point/x', 'pedersen/hash0/ec_subset_sum/copy_point/y', 'pedersen/hash1/ec_subset_sum/booleanity_test', 'pedersen/hash1/ec_subset_sum/add_points/slope', 'pedersen/hash1/ec_subset_sum/add_points/x', 'pedersen/hash1/ec_subset_sum/add_points/y', 'pedersen/hash1/ec_subset_sum/copy_point/x', 'pedersen/hash1/ec_subset_sum/copy_point/y', 'pedersen/hash2/ec_subset_sum/booleanity_test', 'pedersen/hash2/ec_subset_sum/add_points/slope', 'pedersen/hash2/ec_subset_sum/add_points/x', 'pedersen/hash2/ec_subset_sum/add_points/y', 'pedersen/hash2/ec_subset_sum/copy_point/x', 'pedersen/hash2/ec_subset_sum/copy_point/y', 'pedersen/hash3/ec_subset_sum/booleanity_test', 'pedersen/hash3/ec_subset_sum/add_points/slope', 'pedersen/hash3/ec_subset_sum/add_points/x', 'pedersen/hash3/ec_subset_sum/add_points/y', 'pedersen/hash3/ec_subset_sum/copy_point/x', 'pedersen/hash3/ec_subset_sum/copy_point/y'.
              // adjustments[9] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), trace_length / 256, trace_length).
              mstore(0x4ee0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), div(/*trace_length*/ mload(0x80), 256), /*trace_length*/ mload(0x80)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/hash0/ec_subset_sum/bit_extraction_end', 'pedersen/hash0/ec_subset_sum/zeros_tail', 'pedersen/hash1/ec_subset_sum/bit_extraction_end', 'pedersen/hash1/ec_subset_sum/zeros_tail', 'pedersen/hash2/ec_subset_sum/bit_extraction_end', 'pedersen/hash2/ec_subset_sum/zeros_tail', 'pedersen/hash3/ec_subset_sum/bit_extraction_end', 'pedersen/hash3/ec_subset_sum/zeros_tail', 'checkpoints/required_fp_addr'.
              // adjustments[10] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 256).
              mstore(0x4f00,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 256)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/hash0/copy_point/x', 'pedersen/hash0/copy_point/y', 'pedersen/hash1/copy_point/x', 'pedersen/hash1/copy_point/y', 'pedersen/hash2/copy_point/x', 'pedersen/hash2/copy_point/y', 'pedersen/hash3/copy_point/x', 'pedersen/hash3/copy_point/y'.
              // adjustments[11] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, trace_length / 512, trace_length / 256).
              mstore(0x4f20,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), div(/*trace_length*/ mload(0x80), 512), div(/*trace_length*/ mload(0x80), 256)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/hash0/init/x', 'pedersen/hash0/init/y', 'pedersen/hash1/init/x', 'pedersen/hash1/init/y', 'pedersen/hash2/init/x', 'pedersen/hash2/init/y', 'pedersen/hash3/init/x', 'pedersen/hash3/init/y', 'pedersen/input0_value0', 'pedersen/input0_value1', 'pedersen/input0_value2', 'pedersen/input0_value3', 'pedersen/input1_value0', 'pedersen/input1_value1', 'pedersen/input1_value2', 'pedersen/input1_value3', 'pedersen/output_value0', 'pedersen/output_value1', 'pedersen/output_value2', 'pedersen/output_value3'.
              // adjustments[12] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 512).
              mstore(0x4f40,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 512)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/input0_addr', 'rc_builtin/addr_step'.
              // adjustments[13] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 1, trace_length / 128).
              mstore(0x4f60,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 1, div(/*trace_length*/ mload(0x80), 128)), PRIME))

              // Adjustment polynomial for constraints 'pedersen/input1_addr', 'pedersen/output_addr', 'rc_builtin/value'.
              // adjustments[14] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 128).
              mstore(0x4f80,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 128)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/doubling_key/slope', 'ecdsa/signature0/doubling_key/x', 'ecdsa/signature0/doubling_key/y', 'ecdsa/signature0/exponentiate_key/booleanity_test', 'ecdsa/signature0/exponentiate_key/add_points/slope', 'ecdsa/signature0/exponentiate_key/add_points/x', 'ecdsa/signature0/exponentiate_key/add_points/y', 'ecdsa/signature0/exponentiate_key/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_key/copy_point/x', 'ecdsa/signature0/exponentiate_key/copy_point/y'.
              // adjustments[15] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), trace_length / 4096, trace_length / 16).
              mstore(0x4fa0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), div(/*trace_length*/ mload(0x80), 4096), div(/*trace_length*/ mload(0x80), 16)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/exponentiate_generator/booleanity_test', 'ecdsa/signature0/exponentiate_generator/add_points/slope', 'ecdsa/signature0/exponentiate_generator/add_points/x', 'ecdsa/signature0/exponentiate_generator/add_points/y', 'ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv', 'ecdsa/signature0/exponentiate_generator/copy_point/x', 'ecdsa/signature0/exponentiate_generator/copy_point/y'.
              // adjustments[16] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), trace_length / 8192, trace_length / 32).
              mstore(0x4fc0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), div(/*trace_length*/ mload(0x80), 8192), div(/*trace_length*/ mload(0x80), 32)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/exponentiate_generator/bit_extraction_end', 'ecdsa/signature0/exponentiate_generator/zeros_tail', 'ecdsa/signature0/init_gen/x', 'ecdsa/signature0/init_gen/y', 'ecdsa/message_addr', 'ecdsa/message_value0', 'ecdsa/pubkey_value0'.
              // adjustments[17] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 8192).
              mstore(0x4fe0,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 8192)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/exponentiate_key/bit_extraction_end', 'ecdsa/signature0/exponentiate_key/zeros_tail', 'ecdsa/signature0/init_key/x', 'ecdsa/signature0/init_key/y'.
              // adjustments[18] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 0, trace_length / 4096).
              mstore(0x5000,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 0, div(/*trace_length*/ mload(0x80), 4096)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/add_results/slope', 'ecdsa/signature0/add_results/x', 'ecdsa/signature0/add_results/y', 'ecdsa/signature0/add_results/x_diff_inv', 'ecdsa/signature0/extract_r/slope', 'ecdsa/signature0/extract_r/x', 'ecdsa/signature0/extract_r/x_diff_inv', 'ecdsa/signature0/z_nonzero', 'ecdsa/signature0/q_on_curve/x_squared', 'ecdsa/signature0/q_on_curve/on_curve'.
              // adjustments[19] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 0, trace_length / 8192).
              mstore(0x5020,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 0, div(/*trace_length*/ mload(0x80), 8192)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/signature0/r_and_w_nonzero'.
              // adjustments[20] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 0, trace_length / 4096).
              mstore(0x5040,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 0, div(/*trace_length*/ mload(0x80), 4096)), PRIME))

              // Adjustment polynomial for constraints 'ecdsa/pubkey_addr'.
              // adjustments[21] = point^degreeAdjustment(composition_degree_bound, trace_length - 1, 1, trace_length / 8192).
              mstore(0x5060,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), sub(/*trace_length*/ mload(0x80), 1), 1, div(/*trace_length*/ mload(0x80), 8192)), PRIME))

              // Adjustment polynomial for constraints 'checkpoints/required_pc_next_addr', 'checkpoints/req_pc', 'checkpoints/req_fp'.
              // adjustments[22] = point^degreeAdjustment(composition_degree_bound, 2 * (trace_length - 1), 1, trace_length / 256).
              mstore(0x5080,
                     expmod(point, degreeAdjustment(/*composition_degree_bound*/ mload(0x3f40), mul(2, sub(/*trace_length*/ mload(0x80), 1)), 1, div(/*trace_length*/ mload(0x80), 256)), PRIME))

            }

            {
              // Compute the result of the composition polynomial.

              {
              // cpu/decode/opcode_rc/bit_0 = column1_row0 - (column1_row1 + column1_row1).
              let val := addmod(
                /*column1_row0*/ mload(0x2b00),
                sub(
                  PRIME,
                  addmod(/*column1_row1*/ mload(0x2b20), /*column1_row1*/ mload(0x2b20), PRIME)),
                PRIME)
              mstore(0x3f60, val)
              }


              {
              // cpu/decode/opcode_rc/bit_1 = column1_row1 - (column1_row2 + column1_row2).
              let val := addmod(
                /*column1_row1*/ mload(0x2b20),
                sub(
                  PRIME,
                  addmod(/*column1_row2*/ mload(0x2b40), /*column1_row2*/ mload(0x2b40), PRIME)),
                PRIME)
              mstore(0x3f80, val)
              }


              {
              // cpu/decode/opcode_rc/bit_2 = column1_row2 - (column1_row3 + column1_row3).
              let val := addmod(
                /*column1_row2*/ mload(0x2b40),
                sub(
                  PRIME,
                  addmod(/*column1_row3*/ mload(0x2b60), /*column1_row3*/ mload(0x2b60), PRIME)),
                PRIME)
              mstore(0x3fa0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_4 = column1_row4 - (column1_row5 + column1_row5).
              let val := addmod(
                /*column1_row4*/ mload(0x2b80),
                sub(
                  PRIME,
                  addmod(/*column1_row5*/ mload(0x2ba0), /*column1_row5*/ mload(0x2ba0), PRIME)),
                PRIME)
              mstore(0x3fc0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_3 = column1_row3 - (column1_row4 + column1_row4).
              let val := addmod(
                /*column1_row3*/ mload(0x2b60),
                sub(
                  PRIME,
                  addmod(/*column1_row4*/ mload(0x2b80), /*column1_row4*/ mload(0x2b80), PRIME)),
                PRIME)
              mstore(0x3fe0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_9 = column1_row9 - (column1_row10 + column1_row10).
              let val := addmod(
                /*column1_row9*/ mload(0x2c20),
                sub(
                  PRIME,
                  addmod(/*column1_row10*/ mload(0x2c40), /*column1_row10*/ mload(0x2c40), PRIME)),
                PRIME)
              mstore(0x4000, val)
              }


              {
              // cpu/decode/opcode_rc/bit_5 = column1_row5 - (column1_row6 + column1_row6).
              let val := addmod(
                /*column1_row5*/ mload(0x2ba0),
                sub(
                  PRIME,
                  addmod(/*column1_row6*/ mload(0x2bc0), /*column1_row6*/ mload(0x2bc0), PRIME)),
                PRIME)
              mstore(0x4020, val)
              }


              {
              // cpu/decode/opcode_rc/bit_6 = column1_row6 - (column1_row7 + column1_row7).
              let val := addmod(
                /*column1_row6*/ mload(0x2bc0),
                sub(
                  PRIME,
                  addmod(/*column1_row7*/ mload(0x2be0), /*column1_row7*/ mload(0x2be0), PRIME)),
                PRIME)
              mstore(0x4040, val)
              }


              {
              // cpu/decode/opcode_rc/bit_7 = column1_row7 - (column1_row8 + column1_row8).
              let val := addmod(
                /*column1_row7*/ mload(0x2be0),
                sub(
                  PRIME,
                  addmod(/*column1_row8*/ mload(0x2c00), /*column1_row8*/ mload(0x2c00), PRIME)),
                PRIME)
              mstore(0x4060, val)
              }


              {
              // cpu/decode/opcode_rc/bit_8 = column1_row8 - (column1_row9 + column1_row9).
              let val := addmod(
                /*column1_row8*/ mload(0x2c00),
                sub(
                  PRIME,
                  addmod(/*column1_row9*/ mload(0x2c20), /*column1_row9*/ mload(0x2c20), PRIME)),
                PRIME)
              mstore(0x4080, val)
              }


              {
              // npc_reg_0 = column19_row0 + cpu__decode__opcode_rc__bit_2 + 1.
              let val := addmod(
                addmod(
                  /*column19_row0*/ mload(0x33c0),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3fa0),
                  PRIME),
                1,
                PRIME)
              mstore(0x40a0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_10 = column1_row10 - (column1_row11 + column1_row11).
              let val := addmod(
                /*column1_row10*/ mload(0x2c40),
                sub(
                  PRIME,
                  addmod(/*column1_row11*/ mload(0x2c60), /*column1_row11*/ mload(0x2c60), PRIME)),
                PRIME)
              mstore(0x40c0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_11 = column1_row11 - (column1_row12 + column1_row12).
              let val := addmod(
                /*column1_row11*/ mload(0x2c60),
                sub(
                  PRIME,
                  addmod(/*column1_row12*/ mload(0x2c80), /*column1_row12*/ mload(0x2c80), PRIME)),
                PRIME)
              mstore(0x40e0, val)
              }


              {
              // cpu/decode/opcode_rc/bit_12 = column1_row12 - (column1_row13 + column1_row13).
              let val := addmod(
                /*column1_row12*/ mload(0x2c80),
                sub(
                  PRIME,
                  addmod(/*column1_row13*/ mload(0x2ca0), /*column1_row13*/ mload(0x2ca0), PRIME)),
                PRIME)
              mstore(0x4100, val)
              }


              {
              // cpu/decode/opcode_rc/bit_13 = column1_row13 - (column1_row14 + column1_row14).
              let val := addmod(
                /*column1_row13*/ mload(0x2ca0),
                sub(
                  PRIME,
                  addmod(/*column1_row14*/ mload(0x2cc0), /*column1_row14*/ mload(0x2cc0), PRIME)),
                PRIME)
              mstore(0x4120, val)
              }


              {
              // cpu/decode/opcode_rc/bit_14 = column1_row14 - (column1_row15 + column1_row15).
              let val := addmod(
                /*column1_row14*/ mload(0x2cc0),
                sub(
                  PRIME,
                  addmod(/*column1_row15*/ mload(0x2ce0), /*column1_row15*/ mload(0x2ce0), PRIME)),
                PRIME)
              mstore(0x4140, val)
              }


              {
              // memory/address_diff_0 = column20_row2 - column20_row0.
              let val := addmod(/*column20_row2*/ mload(0x3900), sub(PRIME, /*column20_row0*/ mload(0x38c0)), PRIME)
              mstore(0x4160, val)
              }


              {
              // rc16/diff_0 = column2_row1 - column2_row0.
              let val := addmod(/*column2_row1*/ mload(0x2d20), sub(PRIME, /*column2_row0*/ mload(0x2d00)), PRIME)
              mstore(0x4180, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_0 = column6_row0 - (column6_row1 + column6_row1).
              let val := addmod(
                /*column6_row0*/ mload(0x2e80),
                sub(
                  PRIME,
                  addmod(/*column6_row1*/ mload(0x2ea0), /*column6_row1*/ mload(0x2ea0), PRIME)),
                PRIME)
              mstore(0x41a0, val)
              }


              {
              // pedersen/hash0/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash0__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x41a0)),
                PRIME)
              mstore(0x41c0, val)
              }


              {
              // pedersen/hash1/ec_subset_sum/bit_0 = column10_row0 - (column10_row1 + column10_row1).
              let val := addmod(
                /*column10_row0*/ mload(0x3020),
                sub(
                  PRIME,
                  addmod(/*column10_row1*/ mload(0x3040), /*column10_row1*/ mload(0x3040), PRIME)),
                PRIME)
              mstore(0x41e0, val)
              }


              {
              // pedersen/hash1/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash1__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x41e0)),
                PRIME)
              mstore(0x4200, val)
              }


              {
              // pedersen/hash2/ec_subset_sum/bit_0 = column14_row0 - (column14_row1 + column14_row1).
              let val := addmod(
                /*column14_row0*/ mload(0x31c0),
                sub(
                  PRIME,
                  addmod(/*column14_row1*/ mload(0x31e0), /*column14_row1*/ mload(0x31e0), PRIME)),
                PRIME)
              mstore(0x4220, val)
              }


              {
              // pedersen/hash2/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash2__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4220)),
                PRIME)
              mstore(0x4240, val)
              }


              {
              // pedersen/hash3/ec_subset_sum/bit_0 = column18_row0 - (column18_row1 + column18_row1).
              let val := addmod(
                /*column18_row0*/ mload(0x3360),
                sub(
                  PRIME,
                  addmod(/*column18_row1*/ mload(0x3380), /*column18_row1*/ mload(0x3380), PRIME)),
                PRIME)
              mstore(0x4260, val)
              }


              {
              // pedersen/hash3/ec_subset_sum/bit_neg_0 = 1 - pedersen__hash3__ec_subset_sum__bit_0.
              let val := addmod(
                1,
                sub(PRIME, /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4260)),
                PRIME)
              mstore(0x4280, val)
              }


              {
              // rc_builtin/value0_0 = column0_row12.
              let val := /*column0_row12*/ mload(0x2a00)
              mstore(0x42a0, val)
              }


              {
              // rc_builtin/value1_0 = rc_builtin__value0_0 * offset_size + column0_row28.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value0_0*/ mload(0x42a0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column0_row28*/ mload(0x2a20),
                PRIME)
              mstore(0x42c0, val)
              }


              {
              // rc_builtin/value2_0 = rc_builtin__value1_0 * offset_size + column0_row44.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value1_0*/ mload(0x42c0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column0_row44*/ mload(0x2a40),
                PRIME)
              mstore(0x42e0, val)
              }


              {
              // rc_builtin/value3_0 = rc_builtin__value2_0 * offset_size + column0_row60.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value2_0*/ mload(0x42e0),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column0_row60*/ mload(0x2a60),
                PRIME)
              mstore(0x4300, val)
              }


              {
              // rc_builtin/value4_0 = rc_builtin__value3_0 * offset_size + column0_row76.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value3_0*/ mload(0x4300),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column0_row76*/ mload(0x2a80),
                PRIME)
              mstore(0x4320, val)
              }


              {
              // rc_builtin/value5_0 = rc_builtin__value4_0 * offset_size + column0_row92.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value4_0*/ mload(0x4320),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column0_row92*/ mload(0x2aa0),
                PRIME)
              mstore(0x4340, val)
              }


              {
              // rc_builtin/value6_0 = rc_builtin__value5_0 * offset_size + column0_row108.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value5_0*/ mload(0x4340),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column0_row108*/ mload(0x2ac0),
                PRIME)
              mstore(0x4360, val)
              }


              {
              // rc_builtin/value7_0 = rc_builtin__value6_0 * offset_size + column0_row124.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc_builtin/value6_0*/ mload(0x4360),
                  /*offset_size*/ mload(0xa0),
                  PRIME),
                /*column0_row124*/ mload(0x2ae0),
                PRIME)
              mstore(0x4380, val)
              }


              {
              // ecdsa/signature0/doubling_key/x_squared = column21_row6 * column21_row6.
              let val := mulmod(/*column21_row6*/ mload(0x3a00), /*column21_row6*/ mload(0x3a00), PRIME)
              mstore(0x43a0, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_0 = column21_row31 - (column21_row63 + column21_row63).
              let val := addmod(
                /*column21_row31*/ mload(0x3c40),
                sub(
                  PRIME,
                  addmod(/*column21_row63*/ mload(0x3ca0), /*column21_row63*/ mload(0x3ca0), PRIME)),
                PRIME)
              mstore(0x43c0, val)
              }


              {
              // ecdsa/signature0/exponentiate_generator/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_generator__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x43c0)),
                PRIME)
              mstore(0x43e0, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_0 = column21_row3 - (column21_row19 + column21_row19).
              let val := addmod(
                /*column21_row3*/ mload(0x39a0),
                sub(
                  PRIME,
                  addmod(/*column21_row19*/ mload(0x3b60), /*column21_row19*/ mload(0x3b60), PRIME)),
                PRIME)
              mstore(0x4400, val)
              }


              {
              // ecdsa/signature0/exponentiate_key/bit_neg_0 = 1 - ecdsa__signature0__exponentiate_key__bit_0.
              let val := addmod(
                1,
                sub(
                  PRIME,
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4400)),
                PRIME)
              mstore(0x4420, val)
              }


              {
              // Constraint expression for cpu/decode/opcode_rc/bit: cpu__decode__opcode_rc__bit_0 * cpu__decode__opcode_rc__bit_0 - cpu__decode__opcode_rc__bit_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3f60),
                  /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3f60),
                  PRIME),
                sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3f60)),
                PRIME)

              // Numerator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= numerators[0].
              val := mulmod(val, mload(0x4c60), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[0] + coefficients[1] * adjustments[0]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[0]*/ mload(0x440),
                                       mulmod(/*coefficients[1]*/ mload(0x460),
                                              /*adjustments[0]*/mload(0x4dc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc/last_bit: column1_row0 * column1_row0 - column1_row0.
              let val := addmod(
                mulmod(/*column1_row0*/ mload(0x2b00), /*column1_row0*/ mload(0x2b00), PRIME),
                sub(PRIME, /*column1_row0*/ mload(0x2b00)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - trace_generator^(15 * trace_length / 16).
              // val *= denominator_invs[1].
              val := mulmod(val, mload(0x4700), PRIME)

              // res += val * (coefficients[2] + coefficients[3] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[2]*/ mload(0x480),
                                       mulmod(/*coefficients[3]*/ mload(0x4a0),
                                              /*adjustments[1]*/mload(0x4de0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/decode/opcode_rc_input: column19_row1 - (((column1_row0 * offset_size + column0_row4) * offset_size + column0_row8) * offset_size + column0_row0).
              let val := addmod(
                /*column19_row1*/ mload(0x33e0),
                sub(
                  PRIME,
                  addmod(
                    mulmod(
                      addmod(
                        mulmod(
                          addmod(
                            mulmod(/*column1_row0*/ mload(0x2b00), /*offset_size*/ mload(0xa0), PRIME),
                            /*column0_row4*/ mload(0x29c0),
                            PRIME),
                          /*offset_size*/ mload(0xa0),
                          PRIME),
                        /*column0_row8*/ mload(0x29e0),
                        PRIME),
                      /*offset_size*/ mload(0xa0),
                      PRIME),
                    /*column0_row0*/ mload(0x2980),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[4] + coefficients[5] * adjustments[2]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[4]*/ mload(0x4c0),
                                       mulmod(/*coefficients[5]*/ mload(0x4e0),
                                              /*adjustments[2]*/mload(0x4e00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem_dst_addr: column19_row8 + half_offset_size - (cpu__decode__opcode_rc__bit_0 * column21_row8 + (1 - cpu__decode__opcode_rc__bit_0) * column21_row0 + column0_row0).
              let val := addmod(
                addmod(/*column19_row8*/ mload(0x34c0), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3f60),
                        /*column21_row8*/ mload(0x3a40),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_0*/ mload(0x3f60)),
                          PRIME),
                        /*column21_row0*/ mload(0x3940),
                        PRIME),
                      PRIME),
                    /*column0_row0*/ mload(0x2980),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[6] + coefficients[7] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[6]*/ mload(0x500),
                                       mulmod(/*coefficients[7]*/ mload(0x520),
                                              /*adjustments[1]*/mload(0x4de0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem0_addr: column19_row4 + half_offset_size - (cpu__decode__opcode_rc__bit_1 * column21_row8 + (1 - cpu__decode__opcode_rc__bit_1) * column21_row0 + column0_row8).
              let val := addmod(
                addmod(/*column19_row4*/ mload(0x3440), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x3f80),
                        /*column21_row8*/ mload(0x3a40),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_1*/ mload(0x3f80)),
                          PRIME),
                        /*column21_row0*/ mload(0x3940),
                        PRIME),
                      PRIME),
                    /*column0_row8*/ mload(0x29e0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[8] + coefficients[9] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[8]*/ mload(0x540),
                                       mulmod(/*coefficients[9]*/ mload(0x560),
                                              /*adjustments[1]*/mload(0x4de0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/mem1_addr: column19_row12 + half_offset_size - (cpu__decode__opcode_rc__bit_2 * column19_row0 + cpu__decode__opcode_rc__bit_4 * column21_row0 + cpu__decode__opcode_rc__bit_3 * column21_row8 + (1 - (cpu__decode__opcode_rc__bit_2 + cpu__decode__opcode_rc__bit_4 + cpu__decode__opcode_rc__bit_3)) * column19_row5 + column0_row4).
              let val := addmod(
                addmod(/*column19_row12*/ mload(0x3500), /*half_offset_size*/ mload(0xc0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        addmod(
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3fa0),
                            /*column19_row0*/ mload(0x33c0),
                            PRIME),
                          mulmod(
                            /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x3fc0),
                            /*column21_row0*/ mload(0x3940),
                            PRIME),
                          PRIME),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x3fe0),
                          /*column21_row8*/ mload(0x3a40),
                          PRIME),
                        PRIME),
                      mulmod(
                        addmod(
                          1,
                          sub(
                            PRIME,
                            addmod(
                              addmod(
                                /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3fa0),
                                /*intermediate_value/cpu/decode/opcode_rc/bit_4*/ mload(0x3fc0),
                                PRIME),
                              /*intermediate_value/cpu/decode/opcode_rc/bit_3*/ mload(0x3fe0),
                              PRIME)),
                          PRIME),
                        /*column19_row5*/ mload(0x3460),
                        PRIME),
                      PRIME),
                    /*column0_row4*/ mload(0x29c0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[10] + coefficients[11] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[10]*/ mload(0x580),
                                       mulmod(/*coefficients[11]*/ mload(0x5a0),
                                              /*adjustments[1]*/mload(0x4de0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/ops_mul: column21_row4 - column19_row5 * column19_row13.
              let val := addmod(
                /*column21_row4*/ mload(0x39c0),
                sub(
                  PRIME,
                  mulmod(/*column19_row5*/ mload(0x3460), /*column19_row13*/ mload(0x3520), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[12] + coefficients[13] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[12]*/ mload(0x5c0),
                                       mulmod(/*coefficients[13]*/ mload(0x5e0),
                                              /*adjustments[1]*/mload(0x4de0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/operands/res: (1 - cpu__decode__opcode_rc__bit_9) * column21_row12 - (cpu__decode__opcode_rc__bit_5 * (column19_row5 + column19_row13) + cpu__decode__opcode_rc__bit_6 * column21_row4 + (1 - (cpu__decode__opcode_rc__bit_5 + cpu__decode__opcode_rc__bit_6 + cpu__decode__opcode_rc__bit_9)) * column19_row13).
              let val := addmod(
                mulmod(
                  addmod(
                    1,
                    sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4000)),
                    PRIME),
                  /*column21_row12*/ mload(0x3ac0),
                  PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x4020),
                        addmod(/*column19_row5*/ mload(0x3460), /*column19_row13*/ mload(0x3520), PRIME),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x4040),
                        /*column21_row4*/ mload(0x39c0),
                        PRIME),
                      PRIME),
                    mulmod(
                      addmod(
                        1,
                        sub(
                          PRIME,
                          addmod(
                            addmod(
                              /*intermediate_value/cpu/decode/opcode_rc/bit_5*/ mload(0x4020),
                              /*intermediate_value/cpu/decode/opcode_rc/bit_6*/ mload(0x4040),
                              PRIME),
                            /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4000),
                            PRIME)),
                        PRIME),
                      /*column19_row13*/ mload(0x3520),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[14] + coefficients[15] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[14]*/ mload(0x600),
                                       mulmod(/*coefficients[15]*/ mload(0x620),
                                              /*adjustments[1]*/mload(0x4de0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp0: column21_row2 - cpu__decode__opcode_rc__bit_9 * column19_row9.
              let val := addmod(
                /*column21_row2*/ mload(0x3980),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4000),
                    /*column19_row9*/ mload(0x34e0),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4c80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[16] + coefficients[17] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[16]*/ mload(0x640),
                                       mulmod(/*coefficients[17]*/ mload(0x660),
                                              /*adjustments[3]*/mload(0x4e20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/tmp1: column21_row10 - column21_row2 * column21_row12.
              let val := addmod(
                /*column21_row10*/ mload(0x3a80),
                sub(
                  PRIME,
                  mulmod(/*column21_row2*/ mload(0x3980), /*column21_row12*/ mload(0x3ac0), PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4c80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[18] + coefficients[19] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[18]*/ mload(0x680),
                                       mulmod(/*coefficients[19]*/ mload(0x6a0),
                                              /*adjustments[3]*/mload(0x4e20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_negative: (1 - cpu__decode__opcode_rc__bit_9) * column19_row16 + column21_row2 * (column19_row16 - (column19_row0 + column19_row13)) - ((1 - (cpu__decode__opcode_rc__bit_7 + cpu__decode__opcode_rc__bit_8 + cpu__decode__opcode_rc__bit_9)) * npc_reg_0 + cpu__decode__opcode_rc__bit_7 * column21_row12 + cpu__decode__opcode_rc__bit_8 * (column19_row0 + column21_row12)).
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      1,
                      sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4000)),
                      PRIME),
                    /*column19_row16*/ mload(0x3540),
                    PRIME),
                  mulmod(
                    /*column21_row2*/ mload(0x3980),
                    addmod(
                      /*column19_row16*/ mload(0x3540),
                      sub(
                        PRIME,
                        addmod(/*column19_row0*/ mload(0x33c0), /*column19_row13*/ mload(0x3520), PRIME)),
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
                                /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x4060),
                                /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x4080),
                                PRIME),
                              /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4000),
                              PRIME)),
                          PRIME),
                        /*intermediate_value/npc_reg_0*/ mload(0x40a0),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_7*/ mload(0x4060),
                        /*column21_row12*/ mload(0x3ac0),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_8*/ mload(0x4080),
                      addmod(/*column19_row0*/ mload(0x33c0), /*column21_row12*/ mload(0x3ac0), PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4c80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[20] + coefficients[21] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[20]*/ mload(0x6c0),
                                       mulmod(/*coefficients[21]*/ mload(0x6e0),
                                              /*adjustments[3]*/mload(0x4e20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_pc/pc_cond_positive: (column21_row10 - cpu__decode__opcode_rc__bit_9) * (column19_row16 - npc_reg_0).
              let val := mulmod(
                addmod(
                  /*column21_row10*/ mload(0x3a80),
                  sub(PRIME, /*intermediate_value/cpu/decode/opcode_rc/bit_9*/ mload(0x4000)),
                  PRIME),
                addmod(
                  /*column19_row16*/ mload(0x3540),
                  sub(PRIME, /*intermediate_value/npc_reg_0*/ mload(0x40a0)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4c80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[22] + coefficients[23] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[22]*/ mload(0x700),
                                       mulmod(/*coefficients[23]*/ mload(0x720),
                                              /*adjustments[3]*/mload(0x4e20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_ap/ap_update: column21_row16 - (column21_row0 + cpu__decode__opcode_rc__bit_10 * column21_row12 + cpu__decode__opcode_rc__bit_11 + cpu__decode__opcode_rc__bit_12 * 2).
              let val := addmod(
                /*column21_row16*/ mload(0x3b40),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      addmod(
                        /*column21_row0*/ mload(0x3940),
                        mulmod(
                          /*intermediate_value/cpu/decode/opcode_rc/bit_10*/ mload(0x40c0),
                          /*column21_row12*/ mload(0x3ac0),
                          PRIME),
                        PRIME),
                      /*intermediate_value/cpu/decode/opcode_rc/bit_11*/ mload(0x40e0),
                      PRIME),
                    mulmod(/*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4100), 2, PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4c80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[24] + coefficients[25] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[24]*/ mload(0x740),
                                       mulmod(/*coefficients[25]*/ mload(0x760),
                                              /*adjustments[3]*/mload(0x4e20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/update_registers/update_fp/fp_update: column21_row24 - ((1 - (cpu__decode__opcode_rc__bit_12 + cpu__decode__opcode_rc__bit_13)) * column21_row8 + cpu__decode__opcode_rc__bit_13 * column19_row9 + cpu__decode__opcode_rc__bit_12 * (column21_row0 + 2)).
              let val := addmod(
                /*column21_row24*/ mload(0x3be0),
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
                              /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4100),
                              /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x4120),
                              PRIME)),
                          PRIME),
                        /*column21_row8*/ mload(0x3a40),
                        PRIME),
                      mulmod(
                        /*intermediate_value/cpu/decode/opcode_rc/bit_13*/ mload(0x4120),
                        /*column19_row9*/ mload(0x34e0),
                        PRIME),
                      PRIME),
                    mulmod(
                      /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4100),
                      addmod(/*column21_row0*/ mload(0x3940), 2, PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= numerators[1].
              val := mulmod(val, mload(0x4c80), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[26] + coefficients[27] * adjustments[3]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[26]*/ mload(0x780),
                                       mulmod(/*coefficients[27]*/ mload(0x7a0),
                                              /*adjustments[3]*/mload(0x4e20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_fp: cpu__decode__opcode_rc__bit_12 * (column19_row9 - column21_row8).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4100),
                addmod(/*column19_row9*/ mload(0x34e0), sub(PRIME, /*column21_row8*/ mload(0x3a40)), PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[28] + coefficients[29] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[28]*/ mload(0x7c0),
                                       mulmod(/*coefficients[29]*/ mload(0x7e0),
                                              /*adjustments[1]*/mload(0x4de0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/call/push_pc: cpu__decode__opcode_rc__bit_12 * (column19_row5 - (column19_row0 + cpu__decode__opcode_rc__bit_2 + 1)).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_12*/ mload(0x4100),
                addmod(
                  /*column19_row5*/ mload(0x3460),
                  sub(
                    PRIME,
                    addmod(
                      addmod(
                        /*column19_row0*/ mload(0x33c0),
                        /*intermediate_value/cpu/decode/opcode_rc/bit_2*/ mload(0x3fa0),
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
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[30] + coefficients[31] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[30]*/ mload(0x800),
                                       mulmod(/*coefficients[31]*/ mload(0x820),
                                              /*adjustments[1]*/mload(0x4de0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for cpu/opcodes/assert_eq/assert_eq: cpu__decode__opcode_rc__bit_14 * (column19_row9 - column21_row12).
              let val := mulmod(
                /*intermediate_value/cpu/decode/opcode_rc/bit_14*/ mload(0x4140),
                addmod(
                  /*column19_row9*/ mload(0x34e0),
                  sub(PRIME, /*column21_row12*/ mload(0x3ac0)),
                  PRIME),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[32] + coefficients[33] * adjustments[1]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[32]*/ mload(0x840),
                                       mulmod(/*coefficients[33]*/ mload(0x860),
                                              /*adjustments[1]*/mload(0x4de0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for initial_ap: column21_row0 - initial_ap.
              let val := addmod(/*column21_row0*/ mload(0x3940), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[34] + coefficients[35] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[34]*/ mload(0x880),
                                       mulmod(/*coefficients[35]*/ mload(0x8a0),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for initial_fp: column21_row8 - initial_ap.
              let val := addmod(/*column21_row8*/ mload(0x3a40), sub(PRIME, /*initial_ap*/ mload(0xe0)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[36] + coefficients[37] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[36]*/ mload(0x8c0),
                                       mulmod(/*coefficients[37]*/ mload(0x8e0),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for initial_pc: column19_row0 - initial_pc.
              let val := addmod(/*column19_row0*/ mload(0x33c0), sub(PRIME, /*initial_pc*/ mload(0x100)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[38] + coefficients[39] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[38]*/ mload(0x900),
                                       mulmod(/*coefficients[39]*/ mload(0x920),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for final_ap: column21_row0 - final_ap.
              let val := addmod(/*column21_row0*/ mload(0x3940), sub(PRIME, /*final_ap*/ mload(0x120)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[4].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * (coefficients[40] + coefficients[41] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[40]*/ mload(0x940),
                                       mulmod(/*coefficients[41]*/ mload(0x960),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for final_pc: column19_row0 - final_pc.
              let val := addmod(/*column19_row0*/ mload(0x33c0), sub(PRIME, /*final_pc*/ mload(0x140)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(16 * (trace_length / 16 - 1)).
              // val *= denominator_invs[4].
              val := mulmod(val, mload(0x4760), PRIME)

              // res += val * (coefficients[42] + coefficients[43] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[42]*/ mload(0x980),
                                       mulmod(/*coefficients[43]*/ mload(0x9a0),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/init0: (memory/multi_column_perm/perm/interaction_elm - (column20_row0 + memory/multi_column_perm/hash_interaction_elm0 * column20_row1)) * column24_inter1_row0 + column19_row0 + memory/multi_column_perm/hash_interaction_elm0 * column19_row1 - memory/multi_column_perm/perm/interaction_elm.
              let val := addmod(
                addmod(
                  addmod(
                    mulmod(
                      addmod(
                        /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                        sub(
                          PRIME,
                          addmod(
                            /*column20_row0*/ mload(0x38c0),
                            mulmod(
                              /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                              /*column20_row1*/ mload(0x38e0),
                              PRIME),
                            PRIME)),
                        PRIME),
                      /*column24_inter1_row0*/ mload(0x3f00),
                      PRIME),
                    /*column19_row0*/ mload(0x33c0),
                    PRIME),
                  mulmod(
                    /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                    /*column19_row1*/ mload(0x33e0),
                    PRIME),
                  PRIME),
                sub(PRIME, /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[44] + coefficients[45] * adjustments[5]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[44]*/ mload(0x9c0),
                                       mulmod(/*coefficients[45]*/ mload(0x9e0),
                                              /*adjustments[5]*/mload(0x4e60),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/step0: (memory/multi_column_perm/perm/interaction_elm - (column20_row2 + memory/multi_column_perm/hash_interaction_elm0 * column20_row3)) * column24_inter1_row2 - (memory/multi_column_perm/perm/interaction_elm - (column19_row2 + memory/multi_column_perm/hash_interaction_elm0 * column19_row3)) * column24_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                    sub(
                      PRIME,
                      addmod(
                        /*column20_row2*/ mload(0x3900),
                        mulmod(
                          /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                          /*column20_row3*/ mload(0x3920),
                          PRIME),
                        PRIME)),
                    PRIME),
                  /*column24_inter1_row2*/ mload(0x3f20),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*memory/multi_column_perm/perm/interaction_elm*/ mload(0x160),
                      sub(
                        PRIME,
                        addmod(
                          /*column19_row2*/ mload(0x3400),
                          mulmod(
                            /*memory/multi_column_perm/hash_interaction_elm0*/ mload(0x180),
                            /*column19_row3*/ mload(0x3420),
                            PRIME),
                          PRIME)),
                      PRIME),
                    /*column24_inter1_row0*/ mload(0x3f00),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x4ca0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * (coefficients[46] + coefficients[47] * adjustments[6]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[46]*/ mload(0xa00),
                                       mulmod(/*coefficients[47]*/ mload(0xa20),
                                              /*adjustments[6]*/mload(0x4e80),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/multi_column_perm/perm/last: column24_inter1_row0 - memory/multi_column_perm/perm/public_memory_prod.
              let val := addmod(
                /*column24_inter1_row0*/ mload(0x3f00),
                sub(PRIME, /*memory/multi_column_perm/perm/public_memory_prod*/ mload(0x1a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= denominator_invs[6].
              val := mulmod(val, mload(0x47a0), PRIME)

              // res += val * (coefficients[48] + coefficients[49] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[48]*/ mload(0xa40),
                                       mulmod(/*coefficients[49]*/ mload(0xa60),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/diff_is_bit: memory__address_diff_0 * memory__address_diff_0 - memory__address_diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/memory/address_diff_0*/ mload(0x4160),
                  /*intermediate_value/memory/address_diff_0*/ mload(0x4160),
                  PRIME),
                sub(PRIME, /*intermediate_value/memory/address_diff_0*/ mload(0x4160)),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x4ca0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * (coefficients[50] + coefficients[51] * adjustments[6]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[50]*/ mload(0xa80),
                                       mulmod(/*coefficients[51]*/ mload(0xaa0),
                                              /*adjustments[6]*/mload(0x4e80),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for memory/is_func: (memory__address_diff_0 - 1) * (column20_row1 - column20_row3).
              let val := mulmod(
                addmod(/*intermediate_value/memory/address_diff_0*/ mload(0x4160), sub(PRIME, 1), PRIME),
                addmod(/*column20_row1*/ mload(0x38e0), sub(PRIME, /*column20_row3*/ mload(0x3920)), PRIME),
                PRIME)

              // Numerator: point - trace_generator^(2 * (trace_length / 2 - 1)).
              // val *= numerators[2].
              val := mulmod(val, mload(0x4ca0), PRIME)
              // Denominator: point^(trace_length / 2) - 1.
              // val *= denominator_invs[5].
              val := mulmod(val, mload(0x4780), PRIME)

              // res += val * (coefficients[52] + coefficients[53] * adjustments[6]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[52]*/ mload(0xac0),
                                       mulmod(/*coefficients[53]*/ mload(0xae0),
                                              /*adjustments[6]*/mload(0x4e80),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for public_memory_addr_zero: column19_row2.
              let val := /*column19_row2*/ mload(0x3400)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, mload(0x47c0), PRIME)

              // res += val * (coefficients[54] + coefficients[55] * adjustments[7]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[54]*/ mload(0xb00),
                                       mulmod(/*coefficients[55]*/ mload(0xb20),
                                              /*adjustments[7]*/mload(0x4ea0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for public_memory_value_zero: column19_row3.
              let val := /*column19_row3*/ mload(0x3420)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8) - 1.
              // val *= denominator_invs[7].
              val := mulmod(val, mload(0x47c0), PRIME)

              // res += val * (coefficients[56] + coefficients[57] * adjustments[7]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[56]*/ mload(0xb40),
                                       mulmod(/*coefficients[57]*/ mload(0xb60),
                                              /*adjustments[7]*/mload(0x4ea0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/perm/init0: (rc16/perm/interaction_elm - column2_row0) * column23_inter1_row0 + column0_row0 - rc16/perm/interaction_elm.
              let val := addmod(
                addmod(
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x1c0),
                      sub(PRIME, /*column2_row0*/ mload(0x2d00)),
                      PRIME),
                    /*column23_inter1_row0*/ mload(0x3ec0),
                    PRIME),
                  /*column0_row0*/ mload(0x2980),
                  PRIME),
                sub(PRIME, /*rc16/perm/interaction_elm*/ mload(0x1c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[58] + coefficients[59] * adjustments[5]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[58]*/ mload(0xb80),
                                       mulmod(/*coefficients[59]*/ mload(0xba0),
                                              /*adjustments[5]*/mload(0x4e60),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/perm/step0: (rc16/perm/interaction_elm - column2_row1) * column23_inter1_row1 - (rc16/perm/interaction_elm - column0_row1) * column23_inter1_row0.
              let val := addmod(
                mulmod(
                  addmod(
                    /*rc16/perm/interaction_elm*/ mload(0x1c0),
                    sub(PRIME, /*column2_row1*/ mload(0x2d20)),
                    PRIME),
                  /*column23_inter1_row1*/ mload(0x3ee0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(
                      /*rc16/perm/interaction_elm*/ mload(0x1c0),
                      sub(PRIME, /*column0_row1*/ mload(0x29a0)),
                      PRIME),
                    /*column23_inter1_row0*/ mload(0x3ec0),
                    PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= numerators[3].
              val := mulmod(val, mload(0x4cc0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[60] + coefficients[61] * adjustments[8]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[60]*/ mload(0xbc0),
                                       mulmod(/*coefficients[61]*/ mload(0xbe0),
                                              /*adjustments[8]*/mload(0x4ec0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/perm/last: column23_inter1_row0 - rc16/perm/public_memory_prod.
              let val := addmod(
                /*column23_inter1_row0*/ mload(0x3ec0),
                sub(PRIME, /*rc16/perm/public_memory_prod*/ mload(0x1e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x47e0), PRIME)

              // res += val * (coefficients[62] + coefficients[63] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[62]*/ mload(0xc00),
                                       mulmod(/*coefficients[63]*/ mload(0xc20),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/diff_is_bit: rc16__diff_0 * rc16__diff_0 - rc16__diff_0.
              let val := addmod(
                mulmod(
                  /*intermediate_value/rc16/diff_0*/ mload(0x4180),
                  /*intermediate_value/rc16/diff_0*/ mload(0x4180),
                  PRIME),
                sub(PRIME, /*intermediate_value/rc16/diff_0*/ mload(0x4180)),
                PRIME)

              // Numerator: point - trace_generator^(trace_length - 1).
              // val *= numerators[3].
              val := mulmod(val, mload(0x4cc0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[64] + coefficients[65] * adjustments[8]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[64]*/ mload(0xc40),
                                       mulmod(/*coefficients[65]*/ mload(0xc60),
                                              /*adjustments[8]*/mload(0x4ec0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/minimum: column2_row0 - rc_min.
              let val := addmod(/*column2_row0*/ mload(0x2d00), sub(PRIME, /*rc_min*/ mload(0x200)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[66] + coefficients[67] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[66]*/ mload(0xc80),
                                       mulmod(/*coefficients[67]*/ mload(0xca0),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc16/maximum: column2_row0 - rc_max.
              let val := addmod(/*column2_row0*/ mload(0x2d00), sub(PRIME, /*rc_max*/ mload(0x220)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(trace_length - 1).
              // val *= denominator_invs[8].
              val := mulmod(val, mload(0x47e0), PRIME)

              // res += val * (coefficients[68] + coefficients[69] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[68]*/ mload(0xcc0),
                                       mulmod(/*coefficients[69]*/ mload(0xce0),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/booleanity_test: pedersen__hash0__ec_subset_sum__bit_0 * (pedersen__hash0__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x41a0),
                addmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x41a0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[70] + coefficients[71] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[70]*/ mload(0xd00),
                                       mulmod(/*coefficients[71]*/ mload(0xd20),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/bit_extraction_end: column6_row0.
              let val := /*column6_row0*/ mload(0x2e80)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x4800), PRIME)

              // res += val * (coefficients[72] + coefficients[73] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[72]*/ mload(0xd40),
                                       mulmod(/*coefficients[73]*/ mload(0xd60),
                                              /*adjustments[10]*/mload(0x4f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/zeros_tail: column6_row0.
              let val := /*column6_row0*/ mload(0x2e80)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * (coefficients[74] + coefficients[75] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[74]*/ mload(0xd80),
                                       mulmod(/*coefficients[75]*/ mload(0xda0),
                                              /*adjustments[10]*/mload(0x4f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/slope: pedersen__hash0__ec_subset_sum__bit_0 * (column4_row0 - pedersen__points__y) - column5_row0 * (column3_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x41a0),
                  addmod(
                    /*column4_row0*/ mload(0x2de0),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column5_row0*/ mload(0x2e60),
                    addmod(
                      /*column3_row0*/ mload(0x2d40),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[76] + coefficients[77] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[76]*/ mload(0xdc0),
                                       mulmod(/*coefficients[77]*/ mload(0xde0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/x: column5_row0 * column5_row0 - pedersen__hash0__ec_subset_sum__bit_0 * (column3_row0 + pedersen__points__x + column3_row1).
              let val := addmod(
                mulmod(/*column5_row0*/ mload(0x2e60), /*column5_row0*/ mload(0x2e60), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x41a0),
                    addmod(
                      addmod(
                        /*column3_row0*/ mload(0x2d40),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column3_row1*/ mload(0x2d60),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[78] + coefficients[79] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[78]*/ mload(0xe00),
                                       mulmod(/*coefficients[79]*/ mload(0xe20),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/add_points/y: pedersen__hash0__ec_subset_sum__bit_0 * (column4_row0 + column4_row1) - column5_row0 * (column3_row0 - column3_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_0*/ mload(0x41a0),
                  addmod(/*column4_row0*/ mload(0x2de0), /*column4_row1*/ mload(0x2e00), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column5_row0*/ mload(0x2e60),
                    addmod(/*column3_row0*/ mload(0x2d40), sub(PRIME, /*column3_row1*/ mload(0x2d60)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[80] + coefficients[81] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[80]*/ mload(0xe40),
                                       mulmod(/*coefficients[81]*/ mload(0xe60),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/x: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column3_row1 - column3_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x41c0),
                addmod(/*column3_row1*/ mload(0x2d60), sub(PRIME, /*column3_row0*/ mload(0x2d40)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[82] + coefficients[83] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[82]*/ mload(0xe80),
                                       mulmod(/*coefficients[83]*/ mload(0xea0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/ec_subset_sum/copy_point/y: pedersen__hash0__ec_subset_sum__bit_neg_0 * (column4_row1 - column4_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash0/ec_subset_sum/bit_neg_0*/ mload(0x41c0),
                addmod(/*column4_row1*/ mload(0x2e00), sub(PRIME, /*column4_row0*/ mload(0x2de0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[84] + coefficients[85] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[84]*/ mload(0xec0),
                                       mulmod(/*coefficients[85]*/ mload(0xee0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/x: column3_row256 - column3_row255.
              let val := addmod(
                /*column3_row256*/ mload(0x2da0),
                sub(PRIME, /*column3_row255*/ mload(0x2d80)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[86] + coefficients[87] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[86]*/ mload(0xf00),
                                       mulmod(/*coefficients[87]*/ mload(0xf20),
                                              /*adjustments[11]*/mload(0x4f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/copy_point/y: column4_row256 - column4_row255.
              let val := addmod(
                /*column4_row256*/ mload(0x2e40),
                sub(PRIME, /*column4_row255*/ mload(0x2e20)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[88] + coefficients[89] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[88]*/ mload(0xf40),
                                       mulmod(/*coefficients[89]*/ mload(0xf60),
                                              /*adjustments[11]*/mload(0x4f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/x: column3_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column3_row0*/ mload(0x2d40),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[90] + coefficients[91] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[90]*/ mload(0xf80),
                                       mulmod(/*coefficients[91]*/ mload(0xfa0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash0/init/y: column4_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column4_row0*/ mload(0x2de0),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x260)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[92] + coefficients[93] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[92]*/ mload(0xfc0),
                                       mulmod(/*coefficients[93]*/ mload(0xfe0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/booleanity_test: pedersen__hash1__ec_subset_sum__bit_0 * (pedersen__hash1__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x41e0),
                addmod(
                  /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x41e0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[94] + coefficients[95] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[94]*/ mload(0x1000),
                                       mulmod(/*coefficients[95]*/ mload(0x1020),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/bit_extraction_end: column10_row0.
              let val := /*column10_row0*/ mload(0x3020)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x4800), PRIME)

              // res += val * (coefficients[96] + coefficients[97] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[96]*/ mload(0x1040),
                                       mulmod(/*coefficients[97]*/ mload(0x1060),
                                              /*adjustments[10]*/mload(0x4f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/zeros_tail: column10_row0.
              let val := /*column10_row0*/ mload(0x3020)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * (coefficients[98] + coefficients[99] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[98]*/ mload(0x1080),
                                       mulmod(/*coefficients[99]*/ mload(0x10a0),
                                              /*adjustments[10]*/mload(0x4f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/add_points/slope: pedersen__hash1__ec_subset_sum__bit_0 * (column8_row0 - pedersen__points__y) - column9_row0 * (column7_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x41e0),
                  addmod(
                    /*column8_row0*/ mload(0x2f80),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column9_row0*/ mload(0x3000),
                    addmod(
                      /*column7_row0*/ mload(0x2ee0),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[100] + coefficients[101] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[100]*/ mload(0x10c0),
                                       mulmod(/*coefficients[101]*/ mload(0x10e0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/add_points/x: column9_row0 * column9_row0 - pedersen__hash1__ec_subset_sum__bit_0 * (column7_row0 + pedersen__points__x + column7_row1).
              let val := addmod(
                mulmod(/*column9_row0*/ mload(0x3000), /*column9_row0*/ mload(0x3000), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x41e0),
                    addmod(
                      addmod(
                        /*column7_row0*/ mload(0x2ee0),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column7_row1*/ mload(0x2f00),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[102] + coefficients[103] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[102]*/ mload(0x1100),
                                       mulmod(/*coefficients[103]*/ mload(0x1120),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/add_points/y: pedersen__hash1__ec_subset_sum__bit_0 * (column8_row0 + column8_row1) - column9_row0 * (column7_row0 - column7_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_0*/ mload(0x41e0),
                  addmod(/*column8_row0*/ mload(0x2f80), /*column8_row1*/ mload(0x2fa0), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column9_row0*/ mload(0x3000),
                    addmod(/*column7_row0*/ mload(0x2ee0), sub(PRIME, /*column7_row1*/ mload(0x2f00)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[104] + coefficients[105] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[104]*/ mload(0x1140),
                                       mulmod(/*coefficients[105]*/ mload(0x1160),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/copy_point/x: pedersen__hash1__ec_subset_sum__bit_neg_0 * (column7_row1 - column7_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_neg_0*/ mload(0x4200),
                addmod(/*column7_row1*/ mload(0x2f00), sub(PRIME, /*column7_row0*/ mload(0x2ee0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[106] + coefficients[107] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[106]*/ mload(0x1180),
                                       mulmod(/*coefficients[107]*/ mload(0x11a0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/ec_subset_sum/copy_point/y: pedersen__hash1__ec_subset_sum__bit_neg_0 * (column8_row1 - column8_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash1/ec_subset_sum/bit_neg_0*/ mload(0x4200),
                addmod(/*column8_row1*/ mload(0x2fa0), sub(PRIME, /*column8_row0*/ mload(0x2f80)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[108] + coefficients[109] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[108]*/ mload(0x11c0),
                                       mulmod(/*coefficients[109]*/ mload(0x11e0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/copy_point/x: column7_row256 - column7_row255.
              let val := addmod(
                /*column7_row256*/ mload(0x2f40),
                sub(PRIME, /*column7_row255*/ mload(0x2f20)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[110] + coefficients[111] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[110]*/ mload(0x1200),
                                       mulmod(/*coefficients[111]*/ mload(0x1220),
                                              /*adjustments[11]*/mload(0x4f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/copy_point/y: column8_row256 - column8_row255.
              let val := addmod(
                /*column8_row256*/ mload(0x2fe0),
                sub(PRIME, /*column8_row255*/ mload(0x2fc0)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[112] + coefficients[113] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[112]*/ mload(0x1240),
                                       mulmod(/*coefficients[113]*/ mload(0x1260),
                                              /*adjustments[11]*/mload(0x4f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/init/x: column7_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column7_row0*/ mload(0x2ee0),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[114] + coefficients[115] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[114]*/ mload(0x1280),
                                       mulmod(/*coefficients[115]*/ mload(0x12a0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash1/init/y: column8_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column8_row0*/ mload(0x2f80),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x260)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[116] + coefficients[117] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[116]*/ mload(0x12c0),
                                       mulmod(/*coefficients[117]*/ mload(0x12e0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/booleanity_test: pedersen__hash2__ec_subset_sum__bit_0 * (pedersen__hash2__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4220),
                addmod(
                  /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4220),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[118] + coefficients[119] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[118]*/ mload(0x1300),
                                       mulmod(/*coefficients[119]*/ mload(0x1320),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/bit_extraction_end: column14_row0.
              let val := /*column14_row0*/ mload(0x31c0)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x4800), PRIME)

              // res += val * (coefficients[120] + coefficients[121] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[120]*/ mload(0x1340),
                                       mulmod(/*coefficients[121]*/ mload(0x1360),
                                              /*adjustments[10]*/mload(0x4f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/zeros_tail: column14_row0.
              let val := /*column14_row0*/ mload(0x31c0)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * (coefficients[122] + coefficients[123] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[122]*/ mload(0x1380),
                                       mulmod(/*coefficients[123]*/ mload(0x13a0),
                                              /*adjustments[10]*/mload(0x4f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/add_points/slope: pedersen__hash2__ec_subset_sum__bit_0 * (column12_row0 - pedersen__points__y) - column13_row0 * (column11_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4220),
                  addmod(
                    /*column12_row0*/ mload(0x3120),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column13_row0*/ mload(0x31a0),
                    addmod(
                      /*column11_row0*/ mload(0x3080),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[124] + coefficients[125] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[124]*/ mload(0x13c0),
                                       mulmod(/*coefficients[125]*/ mload(0x13e0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/add_points/x: column13_row0 * column13_row0 - pedersen__hash2__ec_subset_sum__bit_0 * (column11_row0 + pedersen__points__x + column11_row1).
              let val := addmod(
                mulmod(/*column13_row0*/ mload(0x31a0), /*column13_row0*/ mload(0x31a0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4220),
                    addmod(
                      addmod(
                        /*column11_row0*/ mload(0x3080),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column11_row1*/ mload(0x30a0),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[126] + coefficients[127] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[126]*/ mload(0x1400),
                                       mulmod(/*coefficients[127]*/ mload(0x1420),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/add_points/y: pedersen__hash2__ec_subset_sum__bit_0 * (column12_row0 + column12_row1) - column13_row0 * (column11_row0 - column11_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_0*/ mload(0x4220),
                  addmod(/*column12_row0*/ mload(0x3120), /*column12_row1*/ mload(0x3140), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column13_row0*/ mload(0x31a0),
                    addmod(/*column11_row0*/ mload(0x3080), sub(PRIME, /*column11_row1*/ mload(0x30a0)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[128] + coefficients[129] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[128]*/ mload(0x1440),
                                       mulmod(/*coefficients[129]*/ mload(0x1460),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/copy_point/x: pedersen__hash2__ec_subset_sum__bit_neg_0 * (column11_row1 - column11_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_neg_0*/ mload(0x4240),
                addmod(/*column11_row1*/ mload(0x30a0), sub(PRIME, /*column11_row0*/ mload(0x3080)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[130] + coefficients[131] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[130]*/ mload(0x1480),
                                       mulmod(/*coefficients[131]*/ mload(0x14a0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/ec_subset_sum/copy_point/y: pedersen__hash2__ec_subset_sum__bit_neg_0 * (column12_row1 - column12_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash2/ec_subset_sum/bit_neg_0*/ mload(0x4240),
                addmod(/*column12_row1*/ mload(0x3140), sub(PRIME, /*column12_row0*/ mload(0x3120)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[132] + coefficients[133] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[132]*/ mload(0x14c0),
                                       mulmod(/*coefficients[133]*/ mload(0x14e0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/copy_point/x: column11_row256 - column11_row255.
              let val := addmod(
                /*column11_row256*/ mload(0x30e0),
                sub(PRIME, /*column11_row255*/ mload(0x30c0)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[134] + coefficients[135] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[134]*/ mload(0x1500),
                                       mulmod(/*coefficients[135]*/ mload(0x1520),
                                              /*adjustments[11]*/mload(0x4f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/copy_point/y: column12_row256 - column12_row255.
              let val := addmod(
                /*column12_row256*/ mload(0x3180),
                sub(PRIME, /*column12_row255*/ mload(0x3160)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[136] + coefficients[137] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[136]*/ mload(0x1540),
                                       mulmod(/*coefficients[137]*/ mload(0x1560),
                                              /*adjustments[11]*/mload(0x4f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/init/x: column11_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column11_row0*/ mload(0x3080),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[138] + coefficients[139] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[138]*/ mload(0x1580),
                                       mulmod(/*coefficients[139]*/ mload(0x15a0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash2/init/y: column12_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column12_row0*/ mload(0x3120),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x260)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[140] + coefficients[141] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[140]*/ mload(0x15c0),
                                       mulmod(/*coefficients[141]*/ mload(0x15e0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/booleanity_test: pedersen__hash3__ec_subset_sum__bit_0 * (pedersen__hash3__ec_subset_sum__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4260),
                addmod(
                  /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4260),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[142] + coefficients[143] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[142]*/ mload(0x1600),
                                       mulmod(/*coefficients[143]*/ mload(0x1620),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/bit_extraction_end: column18_row0.
              let val := /*column18_row0*/ mload(0x3360)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(63 * trace_length / 64).
              // val *= denominator_invs[9].
              val := mulmod(val, mload(0x4800), PRIME)

              // res += val * (coefficients[144] + coefficients[145] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[144]*/ mload(0x1640),
                                       mulmod(/*coefficients[145]*/ mload(0x1660),
                                              /*adjustments[10]*/mload(0x4f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/zeros_tail: column18_row0.
              let val := /*column18_row0*/ mload(0x3360)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[10].
              val := mulmod(val, mload(0x4820), PRIME)

              // res += val * (coefficients[146] + coefficients[147] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[146]*/ mload(0x1680),
                                       mulmod(/*coefficients[147]*/ mload(0x16a0),
                                              /*adjustments[10]*/mload(0x4f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/add_points/slope: pedersen__hash3__ec_subset_sum__bit_0 * (column16_row0 - pedersen__points__y) - column17_row0 * (column15_row0 - pedersen__points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4260),
                  addmod(
                    /*column16_row0*/ mload(0x32c0),
                    sub(PRIME, /*periodic_column/pedersen/points/y*/ mload(0x20)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column17_row0*/ mload(0x3340),
                    addmod(
                      /*column15_row0*/ mload(0x3220),
                      sub(PRIME, /*periodic_column/pedersen/points/x*/ mload(0x0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[148] + coefficients[149] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[148]*/ mload(0x16c0),
                                       mulmod(/*coefficients[149]*/ mload(0x16e0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/add_points/x: column17_row0 * column17_row0 - pedersen__hash3__ec_subset_sum__bit_0 * (column15_row0 + pedersen__points__x + column15_row1).
              let val := addmod(
                mulmod(/*column17_row0*/ mload(0x3340), /*column17_row0*/ mload(0x3340), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4260),
                    addmod(
                      addmod(
                        /*column15_row0*/ mload(0x3220),
                        /*periodic_column/pedersen/points/x*/ mload(0x0),
                        PRIME),
                      /*column15_row1*/ mload(0x3240),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[150] + coefficients[151] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[150]*/ mload(0x1700),
                                       mulmod(/*coefficients[151]*/ mload(0x1720),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/add_points/y: pedersen__hash3__ec_subset_sum__bit_0 * (column16_row0 + column16_row1) - column17_row0 * (column15_row0 - column15_row1).
              let val := addmod(
                mulmod(
                  /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_0*/ mload(0x4260),
                  addmod(/*column16_row0*/ mload(0x32c0), /*column16_row1*/ mload(0x32e0), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column17_row0*/ mload(0x3340),
                    addmod(/*column15_row0*/ mload(0x3220), sub(PRIME, /*column15_row1*/ mload(0x3240)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[152] + coefficients[153] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[152]*/ mload(0x1740),
                                       mulmod(/*coefficients[153]*/ mload(0x1760),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/copy_point/x: pedersen__hash3__ec_subset_sum__bit_neg_0 * (column15_row1 - column15_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_neg_0*/ mload(0x4280),
                addmod(/*column15_row1*/ mload(0x3240), sub(PRIME, /*column15_row0*/ mload(0x3220)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[154] + coefficients[155] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[154]*/ mload(0x1780),
                                       mulmod(/*coefficients[155]*/ mload(0x17a0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/ec_subset_sum/copy_point/y: pedersen__hash3__ec_subset_sum__bit_neg_0 * (column16_row1 - column16_row0).
              let val := mulmod(
                /*intermediate_value/pedersen/hash3/ec_subset_sum/bit_neg_0*/ mload(0x4280),
                addmod(/*column16_row1*/ mload(0x32e0), sub(PRIME, /*column16_row0*/ mload(0x32c0)), PRIME),
                PRIME)

              // Numerator: point^(trace_length / 256) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[4].
              val := mulmod(val, mload(0x4ce0), PRIME)
              // Denominator: point^trace_length - 1.
              // val *= denominator_invs[0].
              val := mulmod(val, mload(0x46e0), PRIME)

              // res += val * (coefficients[156] + coefficients[157] * adjustments[9]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[156]*/ mload(0x17c0),
                                       mulmod(/*coefficients[157]*/ mload(0x17e0),
                                              /*adjustments[9]*/mload(0x4ee0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/copy_point/x: column15_row256 - column15_row255.
              let val := addmod(
                /*column15_row256*/ mload(0x3280),
                sub(PRIME, /*column15_row255*/ mload(0x3260)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[158] + coefficients[159] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[158]*/ mload(0x1800),
                                       mulmod(/*coefficients[159]*/ mload(0x1820),
                                              /*adjustments[11]*/mload(0x4f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/copy_point/y: column16_row256 - column16_row255.
              let val := addmod(
                /*column16_row256*/ mload(0x3320),
                sub(PRIME, /*column16_row255*/ mload(0x3300)),
                PRIME)

              // Numerator: point^(trace_length / 512) - trace_generator^(trace_length / 2).
              // val *= numerators[5].
              val := mulmod(val, mload(0x4d00), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[160] + coefficients[161] * adjustments[11]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[160]*/ mload(0x1840),
                                       mulmod(/*coefficients[161]*/ mload(0x1860),
                                              /*adjustments[11]*/mload(0x4f20),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/init/x: column15_row0 - pedersen/shift_point.x.
              let val := addmod(
                /*column15_row0*/ mload(0x3220),
                sub(PRIME, /*pedersen/shift_point.x*/ mload(0x240)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[162] + coefficients[163] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[162]*/ mload(0x1880),
                                       mulmod(/*coefficients[163]*/ mload(0x18a0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/hash3/init/y: column16_row0 - pedersen/shift_point.y.
              let val := addmod(
                /*column16_row0*/ mload(0x32c0),
                sub(PRIME, /*pedersen/shift_point.y*/ mload(0x260)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[164] + coefficients[165] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[164]*/ mload(0x18c0),
                                       mulmod(/*coefficients[165]*/ mload(0x18e0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value0: column19_row7 - column6_row0.
              let val := addmod(/*column19_row7*/ mload(0x34a0), sub(PRIME, /*column6_row0*/ mload(0x2e80)), PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[166] + coefficients[167] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[166]*/ mload(0x1900),
                                       mulmod(/*coefficients[167]*/ mload(0x1920),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value1: column19_row135 - column10_row0.
              let val := addmod(
                /*column19_row135*/ mload(0x36c0),
                sub(PRIME, /*column10_row0*/ mload(0x3020)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[168] + coefficients[169] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[168]*/ mload(0x1940),
                                       mulmod(/*coefficients[169]*/ mload(0x1960),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value2: column19_row263 - column14_row0.
              let val := addmod(
                /*column19_row263*/ mload(0x3780),
                sub(PRIME, /*column14_row0*/ mload(0x31c0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[170] + coefficients[171] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[170]*/ mload(0x1980),
                                       mulmod(/*coefficients[171]*/ mload(0x19a0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input0_value3: column19_row391 - column18_row0.
              let val := addmod(
                /*column19_row391*/ mload(0x37e0),
                sub(PRIME, /*column18_row0*/ mload(0x3360)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[172] + coefficients[173] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[172]*/ mload(0x19c0),
                                       mulmod(/*coefficients[173]*/ mload(0x19e0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input0_addr: column19_row134 - (column19_row38 + 1).
              let val := addmod(
                /*column19_row134*/ mload(0x36a0),
                sub(PRIME, addmod(/*column19_row38*/ mload(0x35a0), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(128 * (trace_length / 128 - 1)).
              // val *= numerators[6].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * (coefficients[174] + coefficients[175] * adjustments[13]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[174]*/ mload(0x1a00),
                                       mulmod(/*coefficients[175]*/ mload(0x1a20),
                                              /*adjustments[13]*/mload(0x4f60),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/init_addr: column19_row6 - initial_pedersen_addr.
              let val := addmod(
                /*column19_row6*/ mload(0x3480),
                sub(PRIME, /*initial_pedersen_addr*/ mload(0x280)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[176] + coefficients[177] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[176]*/ mload(0x1a40),
                                       mulmod(/*coefficients[177]*/ mload(0x1a60),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value0: column19_row71 - column6_row256.
              let val := addmod(
                /*column19_row71*/ mload(0x3600),
                sub(PRIME, /*column6_row256*/ mload(0x2ec0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[178] + coefficients[179] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[178]*/ mload(0x1a80),
                                       mulmod(/*coefficients[179]*/ mload(0x1aa0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value1: column19_row199 - column10_row256.
              let val := addmod(
                /*column19_row199*/ mload(0x3740),
                sub(PRIME, /*column10_row256*/ mload(0x3060)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[180] + coefficients[181] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[180]*/ mload(0x1ac0),
                                       mulmod(/*coefficients[181]*/ mload(0x1ae0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value2: column19_row327 - column14_row256.
              let val := addmod(
                /*column19_row327*/ mload(0x37c0),
                sub(PRIME, /*column14_row256*/ mload(0x3200)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[182] + coefficients[183] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[182]*/ mload(0x1b00),
                                       mulmod(/*coefficients[183]*/ mload(0x1b20),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input1_value3: column19_row455 - column18_row256.
              let val := addmod(
                /*column19_row455*/ mload(0x3840),
                sub(PRIME, /*column18_row256*/ mload(0x33a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[184] + coefficients[185] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[184]*/ mload(0x1b40),
                                       mulmod(/*coefficients[185]*/ mload(0x1b60),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/input1_addr: column19_row70 - (column19_row6 + 1).
              let val := addmod(
                /*column19_row70*/ mload(0x35e0),
                sub(PRIME, addmod(/*column19_row6*/ mload(0x3480), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * (coefficients[186] + coefficients[187] * adjustments[14]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[186]*/ mload(0x1b80),
                                       mulmod(/*coefficients[187]*/ mload(0x1ba0),
                                              /*adjustments[14]*/mload(0x4f80),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/output_value0: column19_row39 - column3_row511.
              let val := addmod(
                /*column19_row39*/ mload(0x35c0),
                sub(PRIME, /*column3_row511*/ mload(0x2dc0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[188] + coefficients[189] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[188]*/ mload(0x1bc0),
                                       mulmod(/*coefficients[189]*/ mload(0x1be0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/output_value1: column19_row167 - column7_row511.
              let val := addmod(
                /*column19_row167*/ mload(0x3720),
                sub(PRIME, /*column7_row511*/ mload(0x2f60)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[190] + coefficients[191] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[190]*/ mload(0x1c00),
                                       mulmod(/*coefficients[191]*/ mload(0x1c20),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/output_value2: column19_row295 - column11_row511.
              let val := addmod(
                /*column19_row295*/ mload(0x37a0),
                sub(PRIME, /*column11_row511*/ mload(0x3100)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[192] + coefficients[193] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[192]*/ mload(0x1c40),
                                       mulmod(/*coefficients[193]*/ mload(0x1c60),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/output_value3: column19_row423 - column15_row511.
              let val := addmod(
                /*column19_row423*/ mload(0x3820),
                sub(PRIME, /*column15_row511*/ mload(0x32a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 512) - 1.
              // val *= denominator_invs[12].
              val := mulmod(val, mload(0x4860), PRIME)

              // res += val * (coefficients[194] + coefficients[195] * adjustments[12]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[194]*/ mload(0x1c80),
                                       mulmod(/*coefficients[195]*/ mload(0x1ca0),
                                              /*adjustments[12]*/mload(0x4f40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for pedersen/output_addr: column19_row38 - (column19_row70 + 1).
              let val := addmod(
                /*column19_row38*/ mload(0x35a0),
                sub(PRIME, addmod(/*column19_row70*/ mload(0x35e0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * (coefficients[196] + coefficients[197] * adjustments[14]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[196]*/ mload(0x1cc0),
                                       mulmod(/*coefficients[197]*/ mload(0x1ce0),
                                              /*adjustments[14]*/mload(0x4f80),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc_builtin/value: rc_builtin__value7_0 - column19_row103.
              let val := addmod(
                /*intermediate_value/rc_builtin/value7_0*/ mload(0x4380),
                sub(PRIME, /*column19_row103*/ mload(0x3680)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * (coefficients[198] + coefficients[199] * adjustments[14]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[198]*/ mload(0x1d00),
                                       mulmod(/*coefficients[199]*/ mload(0x1d20),
                                              /*adjustments[14]*/mload(0x4f80),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc_builtin/addr_step: column19_row230 - (column19_row102 + 1).
              let val := addmod(
                /*column19_row230*/ mload(0x3760),
                sub(PRIME, addmod(/*column19_row102*/ mload(0x3660), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(128 * (trace_length / 128 - 1)).
              // val *= numerators[6].
              val := mulmod(val, mload(0x4d20), PRIME)
              // Denominator: point^(trace_length / 128) - 1.
              // val *= denominator_invs[13].
              val := mulmod(val, mload(0x4880), PRIME)

              // res += val * (coefficients[200] + coefficients[201] * adjustments[13]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[200]*/ mload(0x1d40),
                                       mulmod(/*coefficients[201]*/ mload(0x1d60),
                                              /*adjustments[13]*/mload(0x4f60),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for rc_builtin/init_addr: column19_row102 - initial_rc_addr.
              let val := addmod(
                /*column19_row102*/ mload(0x3660),
                sub(PRIME, /*initial_rc_addr*/ mload(0x2a0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[202] + coefficients[203] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[202]*/ mload(0x1d80),
                                       mulmod(/*coefficients[203]*/ mload(0x1da0),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/slope: ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa__signature0__doubling_key__x_squared + ecdsa/sig_config.alpha - (column21_row14 + column21_row14) * column21_row1.
              let val := addmod(
                addmod(
                  addmod(
                    addmod(
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x43a0),
                      /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x43a0),
                      PRIME),
                    /*intermediate_value/ecdsa/signature0/doubling_key/x_squared*/ mload(0x43a0),
                    PRIME),
                  /*ecdsa/sig_config.alpha*/ mload(0x2c0),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    addmod(/*column21_row14*/ mload(0x3b00), /*column21_row14*/ mload(0x3b00), PRIME),
                    /*column21_row1*/ mload(0x3960),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[204] + coefficients[205] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[204]*/ mload(0x1dc0),
                                       mulmod(/*coefficients[205]*/ mload(0x1de0),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/x: column21_row1 * column21_row1 - (column21_row6 + column21_row6 + column21_row22).
              let val := addmod(
                mulmod(/*column21_row1*/ mload(0x3960), /*column21_row1*/ mload(0x3960), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column21_row6*/ mload(0x3a00), /*column21_row6*/ mload(0x3a00), PRIME),
                    /*column21_row22*/ mload(0x3ba0),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[206] + coefficients[207] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[206]*/ mload(0x1e00),
                                       mulmod(/*coefficients[207]*/ mload(0x1e20),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/doubling_key/y: column21_row14 + column21_row30 - column21_row1 * (column21_row6 - column21_row22).
              let val := addmod(
                addmod(/*column21_row14*/ mload(0x3b00), /*column21_row30*/ mload(0x3c20), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column21_row1*/ mload(0x3960),
                    addmod(
                      /*column21_row6*/ mload(0x3a00),
                      sub(PRIME, /*column21_row22*/ mload(0x3ba0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[208] + coefficients[209] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[208]*/ mload(0x1e40),
                                       mulmod(/*coefficients[209]*/ mload(0x1e60),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/booleanity_test: ecdsa__signature0__exponentiate_generator__bit_0 * (ecdsa__signature0__exponentiate_generator__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x43c0),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x43c0),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4d60), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * (coefficients[210] + coefficients[211] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[210]*/ mload(0x1e80),
                                       mulmod(/*coefficients[211]*/ mload(0x1ea0),
                                              /*adjustments[16]*/mload(0x4fc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/bit_extraction_end: column21_row31.
              let val := /*column21_row31*/ mload(0x3c40)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[15].
              val := mulmod(val, mload(0x48c0), PRIME)

              // res += val * (coefficients[212] + coefficients[213] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[212]*/ mload(0x1ec0),
                                       mulmod(/*coefficients[213]*/ mload(0x1ee0),
                                              /*adjustments[17]*/mload(0x4fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/zeros_tail: column21_row31.
              let val := /*column21_row31*/ mload(0x3c40)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[16].
              val := mulmod(val, mload(0x48e0), PRIME)

              // res += val * (coefficients[214] + coefficients[215] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[214]*/ mload(0x1f00),
                                       mulmod(/*coefficients[215]*/ mload(0x1f20),
                                              /*adjustments[17]*/mload(0x4fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/slope: ecdsa__signature0__exponentiate_generator__bit_0 * (column21_row23 - ecdsa__generator_points__y) - column21_row15 * (column21_row7 - ecdsa__generator_points__x).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x43c0),
                  addmod(
                    /*column21_row23*/ mload(0x3bc0),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/y*/ mload(0x60)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column21_row15*/ mload(0x3b20),
                    addmod(
                      /*column21_row7*/ mload(0x3a20),
                      sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4d60), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * (coefficients[216] + coefficients[217] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[216]*/ mload(0x1f40),
                                       mulmod(/*coefficients[217]*/ mload(0x1f60),
                                              /*adjustments[16]*/mload(0x4fc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x: column21_row15 * column21_row15 - ecdsa__signature0__exponentiate_generator__bit_0 * (column21_row7 + ecdsa__generator_points__x + column21_row39).
              let val := addmod(
                mulmod(/*column21_row15*/ mload(0x3b20), /*column21_row15*/ mload(0x3b20), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x43c0),
                    addmod(
                      addmod(
                        /*column21_row7*/ mload(0x3a20),
                        /*periodic_column/ecdsa/generator_points/x*/ mload(0x40),
                        PRIME),
                      /*column21_row39*/ mload(0x3c60),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4d60), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * (coefficients[218] + coefficients[219] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[218]*/ mload(0x1f80),
                                       mulmod(/*coefficients[219]*/ mload(0x1fa0),
                                              /*adjustments[16]*/mload(0x4fc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/y: ecdsa__signature0__exponentiate_generator__bit_0 * (column21_row23 + column21_row55) - column21_row15 * (column21_row7 - column21_row39).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_0*/ mload(0x43c0),
                  addmod(/*column21_row23*/ mload(0x3bc0), /*column21_row55*/ mload(0x3c80), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column21_row15*/ mload(0x3b20),
                    addmod(
                      /*column21_row7*/ mload(0x3a20),
                      sub(PRIME, /*column21_row39*/ mload(0x3c60)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4d60), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * (coefficients[220] + coefficients[221] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[220]*/ mload(0x1fc0),
                                       mulmod(/*coefficients[221]*/ mload(0x1fe0),
                                              /*adjustments[16]*/mload(0x4fc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/add_points/x_diff_inv: column22_row0 * (column21_row7 - ecdsa__generator_points__x) - 1.
              let val := addmod(
                mulmod(
                  /*column22_row0*/ mload(0x3e80),
                  addmod(
                    /*column21_row7*/ mload(0x3a20),
                    sub(PRIME, /*periodic_column/ecdsa/generator_points/x*/ mload(0x40)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4d60), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * (coefficients[222] + coefficients[223] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[222]*/ mload(0x2000),
                                       mulmod(/*coefficients[223]*/ mload(0x2020),
                                              /*adjustments[16]*/mload(0x4fc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/x: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column21_row39 - column21_row7).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x43e0),
                addmod(
                  /*column21_row39*/ mload(0x3c60),
                  sub(PRIME, /*column21_row7*/ mload(0x3a20)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4d60), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * (coefficients[224] + coefficients[225] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[224]*/ mload(0x2040),
                                       mulmod(/*coefficients[225]*/ mload(0x2060),
                                              /*adjustments[16]*/mload(0x4fc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_generator/copy_point/y: ecdsa__signature0__exponentiate_generator__bit_neg_0 * (column21_row55 - column21_row23).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_generator/bit_neg_0*/ mload(0x43e0),
                addmod(
                  /*column21_row55*/ mload(0x3c80),
                  sub(PRIME, /*column21_row23*/ mload(0x3bc0)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 8192) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[8].
              val := mulmod(val, mload(0x4d60), PRIME)
              // Denominator: point^(trace_length / 32) - 1.
              // val *= denominator_invs[14].
              val := mulmod(val, mload(0x48a0), PRIME)

              // res += val * (coefficients[226] + coefficients[227] * adjustments[16]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[226]*/ mload(0x2080),
                                       mulmod(/*coefficients[227]*/ mload(0x20a0),
                                              /*adjustments[16]*/mload(0x4fc0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/booleanity_test: ecdsa__signature0__exponentiate_key__bit_0 * (ecdsa__signature0__exponentiate_key__bit_0 - 1).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4400),
                addmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4400),
                  sub(PRIME, 1),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[228] + coefficients[229] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[228]*/ mload(0x20c0),
                                       mulmod(/*coefficients[229]*/ mload(0x20e0),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/bit_extraction_end: column21_row3.
              let val := /*column21_row3*/ mload(0x39a0)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - trace_generator^(251 * trace_length / 256).
              // val *= denominator_invs[17].
              val := mulmod(val, mload(0x4900), PRIME)

              // res += val * (coefficients[230] + coefficients[231] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[230]*/ mload(0x2100),
                                       mulmod(/*coefficients[231]*/ mload(0x2120),
                                              /*adjustments[18]*/mload(0x5000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/zeros_tail: column21_row3.
              let val := /*column21_row3*/ mload(0x39a0)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= denominator_invs[18].
              val := mulmod(val, mload(0x4920), PRIME)

              // res += val * (coefficients[232] + coefficients[233] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[232]*/ mload(0x2140),
                                       mulmod(/*coefficients[233]*/ mload(0x2160),
                                              /*adjustments[18]*/mload(0x5000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/slope: ecdsa__signature0__exponentiate_key__bit_0 * (column21_row5 - column21_row14) - column21_row13 * (column21_row9 - column21_row6).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4400),
                  addmod(
                    /*column21_row5*/ mload(0x39e0),
                    sub(PRIME, /*column21_row14*/ mload(0x3b00)),
                    PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column21_row13*/ mload(0x3ae0),
                    addmod(/*column21_row9*/ mload(0x3a60), sub(PRIME, /*column21_row6*/ mload(0x3a00)), PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[234] + coefficients[235] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[234]*/ mload(0x2180),
                                       mulmod(/*coefficients[235]*/ mload(0x21a0),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x: column21_row13 * column21_row13 - ecdsa__signature0__exponentiate_key__bit_0 * (column21_row9 + column21_row6 + column21_row25).
              let val := addmod(
                mulmod(/*column21_row13*/ mload(0x3ae0), /*column21_row13*/ mload(0x3ae0), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4400),
                    addmod(
                      addmod(/*column21_row9*/ mload(0x3a60), /*column21_row6*/ mload(0x3a00), PRIME),
                      /*column21_row25*/ mload(0x3c00),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[236] + coefficients[237] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[236]*/ mload(0x21c0),
                                       mulmod(/*coefficients[237]*/ mload(0x21e0),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/y: ecdsa__signature0__exponentiate_key__bit_0 * (column21_row5 + column21_row21) - column21_row13 * (column21_row9 - column21_row25).
              let val := addmod(
                mulmod(
                  /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_0*/ mload(0x4400),
                  addmod(/*column21_row5*/ mload(0x39e0), /*column21_row21*/ mload(0x3b80), PRIME),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column21_row13*/ mload(0x3ae0),
                    addmod(
                      /*column21_row9*/ mload(0x3a60),
                      sub(PRIME, /*column21_row25*/ mload(0x3c00)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[238] + coefficients[239] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[238]*/ mload(0x2200),
                                       mulmod(/*coefficients[239]*/ mload(0x2220),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/add_points/x_diff_inv: column21_row11 * (column21_row9 - column21_row6) - 1.
              let val := addmod(
                mulmod(
                  /*column21_row11*/ mload(0x3aa0),
                  addmod(/*column21_row9*/ mload(0x3a60), sub(PRIME, /*column21_row6*/ mload(0x3a00)), PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[240] + coefficients[241] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[240]*/ mload(0x2240),
                                       mulmod(/*coefficients[241]*/ mload(0x2260),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/x: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column21_row25 - column21_row9).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x4420),
                addmod(
                  /*column21_row25*/ mload(0x3c00),
                  sub(PRIME, /*column21_row9*/ mload(0x3a60)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[242] + coefficients[243] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[242]*/ mload(0x2280),
                                       mulmod(/*coefficients[243]*/ mload(0x22a0),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/exponentiate_key/copy_point/y: ecdsa__signature0__exponentiate_key__bit_neg_0 * (column21_row21 - column21_row5).
              let val := mulmod(
                /*intermediate_value/ecdsa/signature0/exponentiate_key/bit_neg_0*/ mload(0x4420),
                addmod(
                  /*column21_row21*/ mload(0x3b80),
                  sub(PRIME, /*column21_row5*/ mload(0x39e0)),
                  PRIME),
                PRIME)

              // Numerator: point^(trace_length / 4096) - trace_generator^(255 * trace_length / 256).
              // val *= numerators[7].
              val := mulmod(val, mload(0x4d40), PRIME)
              // Denominator: point^(trace_length / 16) - 1.
              // val *= denominator_invs[2].
              val := mulmod(val, mload(0x4720), PRIME)

              // res += val * (coefficients[244] + coefficients[245] * adjustments[15]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[244]*/ mload(0x22c0),
                                       mulmod(/*coefficients[245]*/ mload(0x22e0),
                                              /*adjustments[15]*/mload(0x4fa0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/x: column21_row7 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column21_row7*/ mload(0x3a20),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[246] + coefficients[247] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[246]*/ mload(0x2300),
                                       mulmod(/*coefficients[247]*/ mload(0x2320),
                                              /*adjustments[17]*/mload(0x4fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_gen/y: column21_row23 + ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column21_row23*/ mload(0x3bc0),
                /*ecdsa/sig_config.shift_point.y*/ mload(0x300),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[248] + coefficients[249] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[248]*/ mload(0x2340),
                                       mulmod(/*coefficients[249]*/ mload(0x2360),
                                              /*adjustments[17]*/mload(0x4fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/x: column21_row9 - ecdsa/sig_config.shift_point.x.
              let val := addmod(
                /*column21_row9*/ mload(0x3a60),
                sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * (coefficients[250] + coefficients[251] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[250]*/ mload(0x2380),
                                       mulmod(/*coefficients[251]*/ mload(0x23a0),
                                              /*adjustments[18]*/mload(0x5000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/init_key/y: column21_row5 - ecdsa/sig_config.shift_point.y.
              let val := addmod(
                /*column21_row5*/ mload(0x39e0),
                sub(PRIME, /*ecdsa/sig_config.shift_point.y*/ mload(0x300)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * (coefficients[252] + coefficients[253] * adjustments[18]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[252]*/ mload(0x23c0),
                                       mulmod(/*coefficients[253]*/ mload(0x23e0),
                                              /*adjustments[18]*/mload(0x5000),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/slope: column21_row8183 - (column21_row4085 + column22_row8160 * (column21_row8167 - column21_row4089)).
              let val := addmod(
                /*column21_row8183*/ mload(0x3e20),
                sub(
                  PRIME,
                  addmod(
                    /*column21_row4085*/ mload(0x3ce0),
                    mulmod(
                      /*column22_row8160*/ mload(0x3ea0),
                      addmod(
                        /*column21_row8167*/ mload(0x3da0),
                        sub(PRIME, /*column21_row4089*/ mload(0x3d00)),
                        PRIME),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[254] + coefficients[255] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[254]*/ mload(0x2400),
                                       mulmod(/*coefficients[255]*/ mload(0x2420),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x: column22_row8160 * column22_row8160 - (column21_row8167 + column21_row4089 + column21_row4102).
              let val := addmod(
                mulmod(/*column22_row8160*/ mload(0x3ea0), /*column22_row8160*/ mload(0x3ea0), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(/*column21_row8167*/ mload(0x3da0), /*column21_row4089*/ mload(0x3d00), PRIME),
                    /*column21_row4102*/ mload(0x3d60),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[256] + coefficients[257] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[256]*/ mload(0x2440),
                                       mulmod(/*coefficients[257]*/ mload(0x2460),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/y: column21_row8183 + column21_row4110 - column22_row8160 * (column21_row8167 - column21_row4102).
              let val := addmod(
                addmod(/*column21_row8183*/ mload(0x3e20), /*column21_row4110*/ mload(0x3d80), PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column22_row8160*/ mload(0x3ea0),
                    addmod(
                      /*column21_row8167*/ mload(0x3da0),
                      sub(PRIME, /*column21_row4102*/ mload(0x3d60)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[258] + coefficients[259] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[258]*/ mload(0x2480),
                                       mulmod(/*coefficients[259]*/ mload(0x24a0),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/add_results/x_diff_inv: column21_row8175 * (column21_row8167 - column21_row4089) - 1.
              let val := addmod(
                mulmod(
                  /*column21_row8175*/ mload(0x3dc0),
                  addmod(
                    /*column21_row8167*/ mload(0x3da0),
                    sub(PRIME, /*column21_row4089*/ mload(0x3d00)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[260] + coefficients[261] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[260]*/ mload(0x24c0),
                                       mulmod(/*coefficients[261]*/ mload(0x24e0),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/slope: column21_row8181 + ecdsa/sig_config.shift_point.y - column21_row4093 * (column21_row8185 - ecdsa/sig_config.shift_point.x).
              let val := addmod(
                addmod(
                  /*column21_row8181*/ mload(0x3e00),
                  /*ecdsa/sig_config.shift_point.y*/ mload(0x300),
                  PRIME),
                sub(
                  PRIME,
                  mulmod(
                    /*column21_row4093*/ mload(0x3d40),
                    addmod(
                      /*column21_row8185*/ mload(0x3e40),
                      sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0)),
                      PRIME),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[262] + coefficients[263] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[262]*/ mload(0x2500),
                                       mulmod(/*coefficients[263]*/ mload(0x2520),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x: column21_row4093 * column21_row4093 - (column21_row8185 + ecdsa/sig_config.shift_point.x + column21_row3).
              let val := addmod(
                mulmod(/*column21_row4093*/ mload(0x3d40), /*column21_row4093*/ mload(0x3d40), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      /*column21_row8185*/ mload(0x3e40),
                      /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0),
                      PRIME),
                    /*column21_row3*/ mload(0x39a0),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[264] + coefficients[265] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[264]*/ mload(0x2540),
                                       mulmod(/*coefficients[265]*/ mload(0x2560),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/extract_r/x_diff_inv: column21_row8189 * (column21_row8185 - ecdsa/sig_config.shift_point.x) - 1.
              let val := addmod(
                mulmod(
                  /*column21_row8189*/ mload(0x3e60),
                  addmod(
                    /*column21_row8185*/ mload(0x3e40),
                    sub(PRIME, /*ecdsa/sig_config.shift_point.x*/ mload(0x2e0)),
                    PRIME),
                  PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[266] + coefficients[267] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[266]*/ mload(0x2580),
                                       mulmod(/*coefficients[267]*/ mload(0x25a0),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/z_nonzero: column21_row31 * column21_row4081 - 1.
              let val := addmod(
                mulmod(/*column21_row31*/ mload(0x3c40), /*column21_row4081*/ mload(0x3cc0), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[268] + coefficients[269] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[268]*/ mload(0x25c0),
                                       mulmod(/*coefficients[269]*/ mload(0x25e0),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/r_and_w_nonzero: column21_row3 * column21_row4091 - 1.
              let val := addmod(
                mulmod(/*column21_row3*/ mload(0x39a0), /*column21_row4091*/ mload(0x3d20), PRIME),
                sub(PRIME, 1),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 4096) - 1.
              // val *= denominator_invs[20].
              val := mulmod(val, mload(0x4960), PRIME)

              // res += val * (coefficients[270] + coefficients[271] * adjustments[20]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[270]*/ mload(0x2600),
                                       mulmod(/*coefficients[271]*/ mload(0x2620),
                                              /*adjustments[20]*/mload(0x5040),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/x_squared: column21_row8177 - column21_row6 * column21_row6.
              let val := addmod(
                /*column21_row8177*/ mload(0x3de0),
                sub(
                  PRIME,
                  mulmod(/*column21_row6*/ mload(0x3a00), /*column21_row6*/ mload(0x3a00), PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[272] + coefficients[273] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[272]*/ mload(0x2640),
                                       mulmod(/*coefficients[273]*/ mload(0x2660),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/signature0/q_on_curve/on_curve: column21_row14 * column21_row14 - (column21_row6 * column21_row8177 + ecdsa/sig_config.alpha * column21_row6 + ecdsa/sig_config.beta).
              let val := addmod(
                mulmod(/*column21_row14*/ mload(0x3b00), /*column21_row14*/ mload(0x3b00), PRIME),
                sub(
                  PRIME,
                  addmod(
                    addmod(
                      mulmod(/*column21_row6*/ mload(0x3a00), /*column21_row8177*/ mload(0x3de0), PRIME),
                      mulmod(/*ecdsa/sig_config.alpha*/ mload(0x2c0), /*column21_row6*/ mload(0x3a00), PRIME),
                      PRIME),
                    /*ecdsa/sig_config.beta*/ mload(0x320),
                    PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[274] + coefficients[275] * adjustments[19]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[274]*/ mload(0x2680),
                                       mulmod(/*coefficients[275]*/ mload(0x26a0),
                                              /*adjustments[19]*/mload(0x5020),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/init_addr: column19_row22 - initial_ecdsa_addr.
              let val := addmod(
                /*column19_row22*/ mload(0x3560),
                sub(PRIME, /*initial_ecdsa_addr*/ mload(0x340)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[276] + coefficients[277] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[276]*/ mload(0x26c0),
                                       mulmod(/*coefficients[277]*/ mload(0x26e0),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/message_addr: column19_row4118 - (column19_row22 + 1).
              let val := addmod(
                /*column19_row4118*/ mload(0x3860),
                sub(PRIME, addmod(/*column19_row22*/ mload(0x3560), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[278] + coefficients[279] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[278]*/ mload(0x2700),
                                       mulmod(/*coefficients[279]*/ mload(0x2720),
                                              /*adjustments[17]*/mload(0x4fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_addr: column19_row8214 - (column19_row4118 + 1).
              let val := addmod(
                /*column19_row8214*/ mload(0x38a0),
                sub(PRIME, addmod(/*column19_row4118*/ mload(0x3860), 1, PRIME)),
                PRIME)

              // Numerator: point - trace_generator^(8192 * (trace_length / 8192 - 1)).
              // val *= numerators[9].
              val := mulmod(val, mload(0x4d80), PRIME)
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[280] + coefficients[281] * adjustments[21]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[280]*/ mload(0x2740),
                                       mulmod(/*coefficients[281]*/ mload(0x2760),
                                              /*adjustments[21]*/mload(0x5060),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/message_value0: column19_row4119 - column21_row31.
              let val := addmod(
                /*column19_row4119*/ mload(0x3880),
                sub(PRIME, /*column21_row31*/ mload(0x3c40)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[282] + coefficients[283] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[282]*/ mload(0x2780),
                                       mulmod(/*coefficients[283]*/ mload(0x27a0),
                                              /*adjustments[17]*/mload(0x4fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for ecdsa/pubkey_value0: column19_row23 - column21_row6.
              let val := addmod(
                /*column19_row23*/ mload(0x3580),
                sub(PRIME, /*column21_row6*/ mload(0x3a00)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 8192) - 1.
              // val *= denominator_invs[19].
              val := mulmod(val, mload(0x4940), PRIME)

              // res += val * (coefficients[284] + coefficients[285] * adjustments[17]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[284]*/ mload(0x27c0),
                                       mulmod(/*coefficients[285]*/ mload(0x27e0),
                                              /*adjustments[17]*/mload(0x4fe0),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/req_pc_init_addr: column19_row150 - initial_checkpoints_addr.
              let val := addmod(
                /*column19_row150*/ mload(0x36e0),
                sub(PRIME, /*initial_checkpoints_addr*/ mload(0x360)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - 1.
              // val *= denominator_invs[3].
              val := mulmod(val, mload(0x4740), PRIME)

              // res += val * (coefficients[286] + coefficients[287] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[286]*/ mload(0x2800),
                                       mulmod(/*coefficients[287]*/ mload(0x2820),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/req_pc_final_addr: column19_row150 - final_checkpoints_addr.
              let val := addmod(
                /*column19_row150*/ mload(0x36e0),
                sub(PRIME, /*final_checkpoints_addr*/ mload(0x380)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= denominator_invs[21].
              val := mulmod(val, mload(0x4980), PRIME)

              // res += val * (coefficients[288] + coefficients[289] * adjustments[4]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[288]*/ mload(0x2840),
                                       mulmod(/*coefficients[289]*/ mload(0x2860),
                                              /*adjustments[4]*/mload(0x4e40),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/required_fp_addr: column19_row86 - (column19_row150 + 1).
              let val := addmod(
                /*column19_row86*/ mload(0x3620),
                sub(PRIME, addmod(/*column19_row150*/ mload(0x36e0), 1, PRIME)),
                PRIME)

              // Numerator: 1.
              // val *= 1.
              // val := mulmod(val, 1, PRIME).
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[290] + coefficients[291] * adjustments[10]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[290]*/ mload(0x2880),
                                       mulmod(/*coefficients[291]*/ mload(0x28a0),
                                              /*adjustments[10]*/mload(0x4f00),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/required_pc_next_addr: (column19_row406 - column19_row150) * (column19_row406 - (column19_row150 + 2)).
              let val := mulmod(
                addmod(
                  /*column19_row406*/ mload(0x3800),
                  sub(PRIME, /*column19_row150*/ mload(0x36e0)),
                  PRIME),
                addmod(
                  /*column19_row406*/ mload(0x3800),
                  sub(PRIME, addmod(/*column19_row150*/ mload(0x36e0), 2, PRIME)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= numerators[10].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[292] + coefficients[293] * adjustments[22]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[292]*/ mload(0x28c0),
                                       mulmod(/*coefficients[293]*/ mload(0x28e0),
                                              /*adjustments[22]*/mload(0x5080),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/req_pc: (column19_row406 - column19_row150) * (column19_row151 - column19_row0).
              let val := mulmod(
                addmod(
                  /*column19_row406*/ mload(0x3800),
                  sub(PRIME, /*column19_row150*/ mload(0x36e0)),
                  PRIME),
                addmod(
                  /*column19_row151*/ mload(0x3700),
                  sub(PRIME, /*column19_row0*/ mload(0x33c0)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= numerators[10].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[294] + coefficients[295] * adjustments[22]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[294]*/ mload(0x2900),
                                       mulmod(/*coefficients[295]*/ mload(0x2920),
                                              /*adjustments[22]*/mload(0x5080),
                      PRIME)),
                      PRIME),
                      PRIME)
              }

              {
              // Constraint expression for checkpoints/req_fp: (column19_row406 - column19_row150) * (column19_row87 - column21_row8).
              let val := mulmod(
                addmod(
                  /*column19_row406*/ mload(0x3800),
                  sub(PRIME, /*column19_row150*/ mload(0x36e0)),
                  PRIME),
                addmod(
                  /*column19_row87*/ mload(0x3640),
                  sub(PRIME, /*column21_row8*/ mload(0x3a40)),
                  PRIME),
                PRIME)

              // Numerator: point - trace_generator^(256 * (trace_length / 256 - 1)).
              // val *= numerators[10].
              val := mulmod(val, mload(0x4da0), PRIME)
              // Denominator: point^(trace_length / 256) - 1.
              // val *= denominator_invs[11].
              val := mulmod(val, mload(0x4840), PRIME)

              // res += val * (coefficients[296] + coefficients[297] * adjustments[22]).
              res := addmod(res,
                            mulmod(val,
                                   add(/*coefficients[296]*/ mload(0x2940),
                                       mulmod(/*coefficients[297]*/ mload(0x2960),
                                              /*adjustments[22]*/mload(0x5080),
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