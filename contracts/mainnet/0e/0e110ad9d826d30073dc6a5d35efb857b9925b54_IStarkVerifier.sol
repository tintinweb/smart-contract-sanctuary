pragma solidity ^0.5.2;

contract IStarkVerifier {

    function verifyProof(
        uint256[] memory proofParams,
        uint256[] memory proof,
        uint256[] memory publicInput
    )
        internal;
}
