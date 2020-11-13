pragma solidity ^0.5.2;

import "./StarkVerifier.sol";
import "./StarkParameters.sol";
import "./MimcConstraintPoly.sol";
import "./MimcOods.sol";
import "./PublicInputOffsets.sol";
import "./FactRegistry.sol";

contract PeriodicColumnContract {
    function compute(uint256 x) external pure returns (uint256 result);
}

contract MimcVerifier is StarkParameters, StarkVerifier, FactRegistry, PublicInputOffsets{

    MimcConstraintPoly constraintPoly;
    PeriodicColumnContract[20] constantsCols;
    uint256 internal constant PUBLIC_INPUT_SIZE = 5;

    constructor(
        address[] memory auxPolynomials,
        MimcOods oodsContract,
        uint256 numSecurityBits_,
        uint256 minProofOfWorkBits_)
        StarkVerifier(
            numSecurityBits_,
            minProofOfWorkBits_
        )
        public {
        constraintPoly = MimcConstraintPoly(auxPolynomials[0]);
        for (uint256 i = 0; i < 20; i++) {
            constantsCols[i] = PeriodicColumnContract(auxPolynomials[i+1]);
        }
        oodsContractAddress = address(oodsContract);
    }

    function verifyProofAndRegister(
        uint256[] calldata proofParams,
        uint256[] calldata proof,
        uint256[] calldata publicInput
    )
        external
    {
        verifyProof(proofParams, proof, publicInput);
        registerFact(
            keccak256(
                abi.encodePacked(
                    10 * 2**publicInput[OFFSET_LOG_TRACE_LENGTH] - 1,
                    publicInput[OFFSET_VDF_OUTPUT_X],
                    publicInput[OFFSET_VDF_OUTPUT_Y],
                    publicInput[OFFSET_VDF_INPUT_X],
                    publicInput[OFFSET_VDF_INPUT_Y]
                )
            )
        );
    }

    function getNColumnsInTrace() internal pure returns (uint256) {
        return N_COLUMNS_IN_MASK;
    }

    function getNColumnsInComposition() internal pure returns (uint256) {
        return CONSTRAINTS_DEGREE_BOUND;
    }

    function getMmCoefficients() internal pure returns (uint256) {
        return MM_COEFFICIENTS;
    }

    function getMmOodsValues() internal pure returns (uint256) {
        return MM_OODS_VALUES;
    }

    function getMmOodsCoefficients() internal pure returns (uint256) {
        return MM_OODS_COEFFICIENTS;
    }

    function getNCoefficients() internal pure returns (uint256) {
        return N_COEFFICIENTS;
    }

    function getNOodsValues() internal pure returns (uint256) {
        return N_OODS_VALUES;
    }

    function getNOodsCoefficients() internal pure returns (uint256) {
        return N_OODS_COEFFICIENTS;
    }

    function airSpecificInit(uint256[] memory publicInput)
        internal returns (uint256[] memory ctx, uint256 logTraceLength)
    {
        require(publicInput.length == PUBLIC_INPUT_SIZE,
            "INVALID_PUBLIC_INPUT_LENGTH"
        );
        ctx = new uint256[](MM_CONTEXT_SIZE);

        // Note that the prover does the VDF computation the other way around (uses the inverse
        // function), hence vdf_output is the input for its calculation, and vdf_input should be the
        // result of the calculation.
        ctx[MM_INPUT_VALUE_A] = publicInput[OFFSET_VDF_OUTPUT_X];
        ctx[MM_INPUT_VALUE_B] = publicInput[OFFSET_VDF_OUTPUT_Y];
        ctx[MM_OUTPUT_VALUE_A] = publicInput[OFFSET_VDF_INPUT_X];
        ctx[MM_OUTPUT_VALUE_B] = publicInput[OFFSET_VDF_INPUT_Y];

        // Initialize the MDS matrix values with fixed predefined values.
        ctx[MM_MAT00] = 0x109bbc181e07a285856e0d8bde02619;
        ctx[MM_MAT01] = 0x1eb8859b1b789cd8a80927a32fdf41f7;
        ctx[MM_MAT10] = 0xdc8eaac802c8f9cb9dff6ed0728012d;
        ctx[MM_MAT11] = 0x2c18506f35eab63b58143a34181c89e;

        logTraceLength = publicInput[OFFSET_LOG_TRACE_LENGTH];
        require(logTraceLength <= 50, "logTraceLength must not exceed 50.");
    }

    function getPublicInputHash(uint256[] memory publicInput)
        internal pure
        returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                uint64(2 ** publicInput[OFFSET_LOG_TRACE_LENGTH]),
                publicInput[OFFSET_VDF_OUTPUT_X],
                publicInput[OFFSET_VDF_OUTPUT_Y],
                publicInput[OFFSET_VDF_INPUT_X],
                publicInput[OFFSET_VDF_INPUT_Y])
        );
    }

    /*
      Checks that the trace and the composition agree on the Out of Domain Sampling point, assuming
      the prover provided us with the proper evaluations.

      Later, we use boundary constraints to check that those evaluations are actually
      consistent with the committed trace and composition polynomials.
    */
    function oodsConsistencyCheck(uint256[] memory ctx)
        internal {
        uint256 oodsPoint = ctx[MM_OODS_POINT];
        uint256 nRows = 256;
        uint256 zPointPow = fpow(oodsPoint, ctx[MM_TRACE_LENGTH] / nRows);

        ctx[MM_PERIODIC_COLUMN__CONSTS0_A] = constantsCols[0].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS1_A] = constantsCols[1].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS2_A] = constantsCols[2].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS3_A] = constantsCols[3].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS4_A] = constantsCols[4].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS5_A] = constantsCols[5].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS6_A] = constantsCols[6].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS7_A] = constantsCols[7].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS8_A] = constantsCols[8].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS9_A] = constantsCols[9].compute(zPointPow);

        ctx[MM_PERIODIC_COLUMN__CONSTS0_B] = constantsCols[10].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS1_B] = constantsCols[11].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS2_B] = constantsCols[12].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS3_B] = constantsCols[13].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS4_B] = constantsCols[14].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS5_B] = constantsCols[15].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS6_B] = constantsCols[16].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS7_B] = constantsCols[17].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS8_B] = constantsCols[18].compute(zPointPow);
        ctx[MM_PERIODIC_COLUMN__CONSTS9_B] = constantsCols[19].compute(zPointPow);

        uint256 compositionFromTraceValue;
        address lconstraintPoly = address(constraintPoly);
        uint256 offset = 0x20 * (1 + MM_CONSTRAINT_POLY_ARGS_START);
        uint256 size = 0x20 * (MM_CONSTRAINT_POLY_ARGS_END - MM_CONSTRAINT_POLY_ARGS_START);
        assembly {
            // Call MimcConstraintPoly contract.
            let p := mload(0x40)
            if iszero(staticcall(not(0), lconstraintPoly, add(ctx, offset), size, p, 0x20)) {
              returndatacopy(0, 0, returndatasize)
              revert(0, returndatasize)
            }
            compositionFromTraceValue := mload(p)
        }

        uint256 claimedComposition = fadd(
            ctx[MM_OODS_VALUES + MASK_SIZE],
            fmul(oodsPoint, ctx[MM_OODS_VALUES + MASK_SIZE + 1]));

        require(
            compositionFromTraceValue == claimedComposition,
            "claimedComposition does not match trace");
    }
}
