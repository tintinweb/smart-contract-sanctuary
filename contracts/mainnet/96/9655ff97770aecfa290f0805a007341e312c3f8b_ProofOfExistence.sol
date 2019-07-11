/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.5.8;
contract ProofOfExistence {
    event Attestation(bytes32 indexed hash);
    function attest(bytes32 hash) public {
        emit Attestation(hash);
    }
}