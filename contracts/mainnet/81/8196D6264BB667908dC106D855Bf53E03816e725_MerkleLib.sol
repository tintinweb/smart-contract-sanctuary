// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

library MerkleLib {

    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        bytes32 currentHash = leaf;

        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) public pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}