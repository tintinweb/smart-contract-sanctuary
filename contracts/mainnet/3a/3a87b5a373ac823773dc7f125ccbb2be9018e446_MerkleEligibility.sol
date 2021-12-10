/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IEligibility {

//    function getGate(uint) external view returns (struct Gate)
//    function addGate(uint...) external

    function isEligible(uint, address, bytes32[] memory) external view returns (bool eligible);

    function passThruGate(uint, address, bytes32[] memory) external;
}

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

contract MerkleEligibility is IEligibility {
    using MerkleLib for bytes32;
    
    address public management;
    address public gateMaster;

    struct Gate {
        bytes32 root;
        uint maxWithdrawalsAddress;
        uint maxWithdrawalsTotal;
        uint totalWithdrawals;
    }

    mapping (uint => Gate) public gates;
    mapping(uint => mapping(address => uint)) public timesWithdrawn;
    uint public numGates = 0;

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address _mgmt, address _gateMaster) {
        management = _mgmt;
        gateMaster = _gateMaster;
    }

    function addGate(bytes32 merkleRoot, uint maxWithdrawalsAddress, uint maxWithdrawalsTotal) external managementOnly returns (uint index) {
        // increment the number of roots
        numGates += 1;

        gates[numGates] = Gate(merkleRoot, maxWithdrawalsAddress, maxWithdrawalsTotal, 0);
        return numGates;
    }

    function getGate(uint index) external view returns (bytes32, uint, uint, uint) {
        Gate memory gate = gates[index];
        return (gate.root, gate.maxWithdrawalsAddress, gate.maxWithdrawalsTotal, gate.totalWithdrawals);
    }

    function isEligible(uint index, address recipient, bytes32[] memory proof) public override view returns (bool eligible) {
        Gate memory gate = gates[index];
        // We need to pack the 20 bytes address to the 32 bytes value
        bytes32 leaf = keccak256(abi.encode(recipient));
        bool countValid = timesWithdrawn[index][recipient] < gate.maxWithdrawalsAddress;
        return countValid && gate.totalWithdrawals < gate.maxWithdrawalsTotal && gate.root.verifyProof(leaf, proof);
    }

    function passThruGate(uint index, address recipient, bytes32[] memory proof) external override {
        require(msg.sender == gateMaster, "Only gatemaster may call this.");

        // close re-entrance gate, prevent double withdrawals
        require(isEligible(index, recipient, proof), "Address is not eligible");

        timesWithdrawn[index][recipient] += 1;
        Gate storage gate = gates[index];
        gate.totalWithdrawals += 1;
    }
}