/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SaraleMachains {

    bytes public brideSignature;
    bytes public groomSignature;
    bytes public witnessOneSignature;
    bytes public witnessTwoSignature;

    bytes public brideVowsHash;
    bytes public groomVowsHash;
    
    address public officiant;
    bool public executed;

    constructor() {
        officiant = msg.sender;
        executed = false;
    }

    // Add all relevant signatures and execute the contract
    function officiate(
        bytes memory _brideSignature,
        bytes memory _groomSignature,
        bytes memory _witnessOneSignature,
        bytes memory _witnessTwoSignature,
        bytes memory _brideVowsHash,
        bytes memory _groomVowsHash
    ) public {
        require(msg.sender == officiant, "Only the officiant can officiate");
        require(executed == false, "SaraleMachains has already been executed");
        // Set the signatures
        brideSignature = _brideSignature;
        groomSignature = _groomSignature;
        witnessOneSignature = _witnessOneSignature;
        witnessTwoSignature = _witnessTwoSignature;
        // Set the vows hashes
        brideVowsHash = _brideVowsHash;
        groomVowsHash = _groomVowsHash;
        // Execute the contract
        executed = true;
    }

    // Export ordered state for hashing
    function exportState() public view returns (
        bytes memory _brideSignature,
        bytes memory _groomSignature,
        bytes memory _witnessOneSignature,
        bytes memory _witnessTwoSignature,
        bytes memory _brideVowsHash,
        bytes memory _groomVowsHash,
        address _officiant,
        bool _executed
    ) {
        return (
            brideSignature, 
            groomSignature,
            witnessOneSignature,
            witnessTwoSignature,
            brideVowsHash,
            groomVowsHash,
            officiant,
            executed
        );
    }
}