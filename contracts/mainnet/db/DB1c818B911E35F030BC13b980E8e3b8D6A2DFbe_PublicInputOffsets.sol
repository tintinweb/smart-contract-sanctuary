pragma solidity ^0.5.2;

contract PublicInputOffsets {
    // The following constants are offsets of data expected in the public input.
    uint256 internal constant OFFSET_LOG_TRACE_LENGTH = 0;
    uint256 internal constant OFFSET_VDF_OUTPUT_X = 1;
    uint256 internal constant OFFSET_VDF_OUTPUT_Y = 2;
    uint256 internal constant OFFSET_VDF_INPUT_X = 3;
    uint256 internal constant OFFSET_VDF_INPUT_Y = 4;
    // The Verifier derives the number of iterations from the log of the trace length.
    // The Vending contract uses the number of iterations.
    uint256 internal constant OFFSET_N_ITER = 0;
}
