// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./MerkleProof.sol";
import "./IMerkleProofVerifier.sol";

contract MerkleProofVerifier is IMerkleProofVerifier {
    bytes32 public immutable root;

    constructor(bytes32 _root) {
        root = _root;
    }

    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function verify(address _account, bytes32[] memory _proof)
        public
        view
        override
        returns (bool)
    {
        return MerkleProof.verify(_proof, root, _leaf(_account));
    }
}