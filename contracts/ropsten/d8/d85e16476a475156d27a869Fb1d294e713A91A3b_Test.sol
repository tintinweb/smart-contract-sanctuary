// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "MerkleLib.sol";

contract Test {
    using MerkleLib for bytes32;

    address public management;
    address public gateMaster;
    struct MerkleRoot {
        bytes32 root;
        uint maxWithdrawals;
    }
    mapping (uint => MerkleRoot) public merkleRoots;
    mapping(uint => mapping(address => uint)) public timesWithdrawn;
    uint public numMerkleRoots = 0;

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor() {

    }

    function addMerkleRoot(bytes32 _merkleRoot, uint _maxWithdrawals) external managementOnly returns (uint index) {
        // increment the number of roots
        numMerkleRoots += 1;

        merkleRoots[numMerkleRoots] = MerkleRoot(_merkleRoot, _maxWithdrawals);
        return numMerkleRoots;
    }

    function isEligible(uint rootIndex, address recipient, bytes32[] memory proof) public view returns (bool eligible) {
        // We need to pack the 20 bytes address to the 32 bytes value
//        bytes32 leaf = keccak256(abi.encode(recipient));
//        bool countValid = timesWithdrawn[rootIndex][recipient] < merkleRoots[rootIndex].maxWithdrawals;
//        return countValid && merkleRoots[rootIndex].root.verifyProof(leaf, proof);
        return true;
    }

    function passThruGate(uint rootIndex, address recipient, bytes32[] memory proof) external {
        require(msg.sender == gateMaster, "Only gatemaster may call this.");

        // close re-entrance gate, prevent double withdrawals
        require(isEligible(rootIndex, recipient, proof), "Address is not eligible");

        timesWithdrawn[rootIndex][recipient] += 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

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