/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.7.3;

abstract contract IFactRegistry {
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact) external view virtual returns(bool);
}

/*
  AMM demo contract.
  Maintains the AMM system state hash.
*/
contract AmmDemo {
    // Off-chain state attributes.
    uint256 accountTreeRoot_;

    // On-chain tokens balances.
    uint256 amountTokenA_;
    uint256 amountTokenB_;

    // The Cairo program hash.
    uint256 cairoProgramHash_;

    // The Cairo verifier.
    IFactRegistry cairoVerifier_;

    /*
      Initializes the contract state.
    */
    constructor(
        uint256 accountTreeRoot,
        uint256 amountTokenA,
        uint256 amountTokenB,
        uint256 cairoProgramHash,
        address cairoVerifier)
        public
    {
        accountTreeRoot_ = accountTreeRoot;
        amountTokenA_ = amountTokenA;
        amountTokenB_ = amountTokenB;
        cairoProgramHash_ = cairoProgramHash;
        cairoVerifier_ = IFactRegistry(cairoVerifier);
    }

    function updateState(uint256[] memory programOutput)
        public
    {
        // Ensure that a corresponding proof was verified.
        bytes32 outputHash = keccak256(abi.encodePacked(programOutput));
        bytes32 fact = keccak256(abi.encodePacked(cairoProgramHash_, outputHash));
        require(cairoVerifier_.isValid(fact), "MISSING_CAIRO_PROOF");

        // Ensure the output consistency with current system state.
        require(programOutput.length == 6, "INVALID_PROGRAM_OUTPUT");
        require(accountTreeRoot_ == programOutput[4], "ACCOUNT_TREE_ROOT_MISMATCH");
        require(amountTokenA_ == programOutput[0], "TOKEN_A_MISMATCH");
        require(amountTokenB_ == programOutput[1], "TOKEN_B_MISMATCH");

        // Update system state.
        accountTreeRoot_ = programOutput[5];
        amountTokenA_ = programOutput[2];
        amountTokenB_ = programOutput[3];
    }
}