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
    uint256 constant internal MM_TRACE_COMMITMENT =                          0x6;
    uint256 constant internal MM_OODS_COMMITMENT =                           0x7;
    uint256 constant internal MM_N_UNIQUE_QUERIES =                          0x8;
    uint256 constant internal MM_CHANNEL =                                   0x9; // uint256[3]
    uint256 constant internal MM_MERKLE_QUEUE =                              0xc; // uint256[96]
    uint256 constant internal MM_FRI_QUEUE =                                0x6c; // uint256[144]
    uint256 constant internal MM_FRI_QUERIES_DELIMITER =                    0xfc;
    uint256 constant internal MM_FRI_CTX =                                  0xfd; // uint256[40]
    uint256 constant internal MM_FRI_STEPS_PTR =                           0x125;
    uint256 constant internal MM_FRI_EVAL_POINTS =                         0x126; // uint256[10]
    uint256 constant internal MM_FRI_COMMITMENTS =                         0x130; // uint256[10]
    uint256 constant internal MM_FRI_LAST_LAYER_DEG_BOUND =                0x13a;
    uint256 constant internal MM_FRI_LAST_LAYER_PTR =                      0x13b;
    uint256 constant internal MM_CONSTRAINT_POLY_ARGS_START =              0x13c;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS0_A =              0x13c;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS1_A =              0x13d;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS2_A =              0x13e;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS3_A =              0x13f;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS4_A =              0x140;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS5_A =              0x141;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS6_A =              0x142;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS7_A =              0x143;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS8_A =              0x144;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS9_A =              0x145;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS0_B =              0x146;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS1_B =              0x147;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS2_B =              0x148;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS3_B =              0x149;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS4_B =              0x14a;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS5_B =              0x14b;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS6_B =              0x14c;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS7_B =              0x14d;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS8_B =              0x14e;
    uint256 constant internal MM_PERIODIC_COLUMN__CONSTS9_B =              0x14f;
    uint256 constant internal MM_MAT00 =                                   0x150;
    uint256 constant internal MM_MAT01 =                                   0x151;
    uint256 constant internal MM_TRACE_LENGTH =                            0x152;
    uint256 constant internal MM_MAT10 =                                   0x153;
    uint256 constant internal MM_MAT11 =                                   0x154;
    uint256 constant internal MM_INPUT_VALUE_A =                           0x155;
    uint256 constant internal MM_OUTPUT_VALUE_A =                          0x156;
    uint256 constant internal MM_INPUT_VALUE_B =                           0x157;
    uint256 constant internal MM_OUTPUT_VALUE_B =                          0x158;
    uint256 constant internal MM_TRACE_GENERATOR =                         0x159;
    uint256 constant internal MM_OODS_POINT =                              0x15a;
    uint256 constant internal MM_COEFFICIENTS =                            0x15b; // uint256[48]
    uint256 constant internal MM_OODS_VALUES =                             0x18b; // uint256[22]
    uint256 constant internal MM_CONSTRAINT_POLY_ARGS_END =                0x1a1;
    uint256 constant internal MM_COMPOSITION_OODS_VALUES =                 0x1a1; // uint256[2]
    uint256 constant internal MM_OODS_EVAL_POINTS =                        0x1a3; // uint256[48]
    uint256 constant internal MM_OODS_COEFFICIENTS =                       0x1d3; // uint256[24]
    uint256 constant internal MM_TRACE_QUERY_RESPONSES =                   0x1eb; // uint256[960]
    uint256 constant internal MM_COMPOSITION_QUERY_RESPONSES =             0x5ab; // uint256[96]
    uint256 constant internal MM_CONTEXT_SIZE =                            0x60b;
}
