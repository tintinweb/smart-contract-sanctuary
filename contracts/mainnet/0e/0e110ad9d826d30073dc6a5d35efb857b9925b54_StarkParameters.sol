// ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------
pragma solidity ^0.5.2;

import "./PrimeFieldElement6.sol";

contract StarkParameters is PrimeFieldElement6 {
    uint256 constant internal N_COEFFICIENTS = 48;
    uint256 constant internal MASK_SIZE = 22;
    uint256 constant internal N_ROWS_IN_MASK = 2;
    uint256 constant internal N_COLUMNS_IN_MASK = 20;
    uint256 constant internal CONSTRAINTS_DEGREE_BOUND = 2;
    uint256 constant internal N_OODS_VALUES = MASK_SIZE + CONSTRAINTS_DEGREE_BOUND;
    uint256 constant internal N_OODS_COEFFICIENTS = N_OODS_VALUES;
    uint256 constant internal MAX_FRI_STEP = 3;
}
// ---------- End of auto-generated code. ----------
