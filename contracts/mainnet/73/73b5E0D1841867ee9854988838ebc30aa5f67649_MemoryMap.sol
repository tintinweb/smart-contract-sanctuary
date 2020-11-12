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

contract MemoryMap {
    /*
      We store the state of the verifer in a contiguous chunk of memory.
      The offsets of the different fields are listed below.
      E.g. The offset of the i'th hash is [mm_hashes + i].
    */
    uint256 constant internal CHANNEL_STATE_SIZE = 3;
    uint256 constant internal MAX_N_QUERIES =  48;
    uint256 constant internal FRI_QUEUE_SIZE = MAX_N_QUERIES;

    uint256 constant internal MAX_SUPPORTED_MAX_FRI_STEP = 4;

    uint256 constant internal MM_EVAL_DOMAIN_SIZE =                          0x0;
    uint256 constant internal MM_BLOW_UP_FACTOR =                            0x1;
    uint256 constant internal MM_LOG_EVAL_DOMAIN_SIZE =                      0x2;
    uint256 constant internal MM_PROOF_OF_WORK_BITS =                        0x3;
    uint256 constant internal MM_EVAL_DOMAIN_GENERATOR =                     0x4;
    uint256 constant internal MM_PUBLIC_INPUT_PTR =                          0x5;
    uint256 constant internal MM_TRACE_COMMITMENT =                          0x6; // uint256[2]
    uint256 constant internal MM_OODS_COMMITMENT =                           0x8;
    uint256 constant internal MM_N_UNIQUE_QUERIES =                          0x9;
    uint256 constant internal MM_CHANNEL =                                   0xa; // uint256[3]
    uint256 constant internal MM_MERKLE_QUEUE =                              0xd; // uint256[96]
    uint256 constant internal MM_FRI_QUEUE =                                0x6d; // uint256[144]
    uint256 constant internal MM_FRI_QUERIES_DELIMITER =                    0xfd;
    uint256 constant internal MM_FRI_CTX =                                  0xfe; // uint256[40]
    uint256 constant internal MM_FRI_STEPS_PTR =                           0x126;
    uint256 constant internal MM_FRI_EVAL_POINTS =                         0x127; // uint256[10]
    uint256 constant internal MM_FRI_COMMITMENTS =                         0x131; // uint256[10]
    uint256 constant internal MM_FRI_LAST_LAYER_DEG_BOUND =                0x13b;
    uint256 constant internal MM_FRI_LAST_LAYER_PTR =                      0x13c;
    uint256 constant internal MM_CONSTRAINT_POLY_ARGS_START =              0x13d;
    uint256 constant internal MM_PERIODIC_COLUMN__PEDERSEN__POINTS__X =    0x13d;
    uint256 constant internal MM_PERIODIC_COLUMN__PEDERSEN__POINTS__Y =    0x13e;
    uint256 constant internal MM_PERIODIC_COLUMN__ECDSA__GENERATOR_POINTS__X = 0x13f;
    uint256 constant internal MM_PERIODIC_COLUMN__ECDSA__GENERATOR_POINTS__Y = 0x140;
    uint256 constant internal MM_TRACE_LENGTH =                            0x141;
    uint256 constant internal MM_OFFSET_SIZE =                             0x142;
    uint256 constant internal MM_HALF_OFFSET_SIZE =                        0x143;
    uint256 constant internal MM_INITIAL_AP =                              0x144;
    uint256 constant internal MM_INITIAL_PC =                              0x145;
    uint256 constant internal MM_FINAL_AP =                                0x146;
    uint256 constant internal MM_FINAL_PC =                                0x147;
    uint256 constant internal MM_MEMORY__MULTI_COLUMN_PERM__PERM__INTERACTION_ELM = 0x148;
    uint256 constant internal MM_MEMORY__MULTI_COLUMN_PERM__HASH_INTERACTION_ELM0 = 0x149;
    uint256 constant internal MM_MEMORY__MULTI_COLUMN_PERM__PERM__PUBLIC_MEMORY_PROD = 0x14a;
    uint256 constant internal MM_RC16__PERM__INTERACTION_ELM =             0x14b;
    uint256 constant internal MM_RC16__PERM__PUBLIC_MEMORY_PROD =          0x14c;
    uint256 constant internal MM_RC_MIN =                                  0x14d;
    uint256 constant internal MM_RC_MAX =                                  0x14e;
    uint256 constant internal MM_PEDERSEN__SHIFT_POINT_X =                 0x14f;
    uint256 constant internal MM_PEDERSEN__SHIFT_POINT_Y =                 0x150;
    uint256 constant internal MM_INITIAL_PEDERSEN_ADDR =                   0x151;
    uint256 constant internal MM_INITIAL_RC_ADDR =                         0x152;
    uint256 constant internal MM_ECDSA__SIG_CONFIG_ALPHA =                 0x153;
    uint256 constant internal MM_ECDSA__SIG_CONFIG_SHIFT_POINT_X =         0x154;
    uint256 constant internal MM_ECDSA__SIG_CONFIG_SHIFT_POINT_Y =         0x155;
    uint256 constant internal MM_ECDSA__SIG_CONFIG_BETA =                  0x156;
    uint256 constant internal MM_INITIAL_ECDSA_ADDR =                      0x157;
    uint256 constant internal MM_INITIAL_CHECKPOINTS_ADDR =                0x158;
    uint256 constant internal MM_FINAL_CHECKPOINTS_ADDR =                  0x159;
    uint256 constant internal MM_TRACE_GENERATOR =                         0x15a;
    uint256 constant internal MM_OODS_POINT =                              0x15b;
    uint256 constant internal MM_INTERACTION_ELEMENTS =                    0x15c; // uint256[3]
    uint256 constant internal MM_COEFFICIENTS =                            0x15f; // uint256[298]
    uint256 constant internal MM_OODS_VALUES =                             0x289; // uint256[173]
    uint256 constant internal MM_CONSTRAINT_POLY_ARGS_END =                0x336;
    uint256 constant internal MM_COMPOSITION_OODS_VALUES =                 0x336; // uint256[2]
    uint256 constant internal MM_OODS_EVAL_POINTS =                        0x338; // uint256[48]
    uint256 constant internal MM_OODS_COEFFICIENTS =                       0x368; // uint256[175]
    uint256 constant internal MM_TRACE_QUERY_RESPONSES =                   0x417; // uint256[1056]
    uint256 constant internal MM_COMPOSITION_QUERY_RESPONSES =             0x837; // uint256[96]
    uint256 constant internal MM_LOG_N_STEPS =                             0x897;
    uint256 constant internal MM_N_PUBLIC_MEM_ENTRIES =                    0x898;
    uint256 constant internal MM_N_PUBLIC_MEM_PAGES =                      0x899;
    uint256 constant internal MM_CONTEXT_SIZE =                            0x89a;
}
