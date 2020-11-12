pragma solidity ^0.5.2;

contract IMerkleVerifier {
    uint256 constant internal MAX_N_MERKLE_VERIFIER_QUERIES =  128;

    function verify(
        uint256 channelPtr,
        uint256 queuePtr,
        bytes32 root,
        uint256 n)
        internal view
        returns (bytes32 hash);
}
