/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.9;

contract SimpleAuction {
    
    address addr;
    uint256[] u256Array;
    bytes32 b32;
    bytes32[] b32Array;
    bytes b1;
    
    function buyLandWithSand(
        address addr1, 
        address addr2, 
        address reserved, 
        uint256[] memory landMetaData, 
        bytes32 salt,
        uint256[] memory assetIds,
        bytes32[] memory proof,
        bytes memory referral,
        bytes memory signature
    ) public returns (bool success) {
        addr = addr1;
        addr = addr2;
        addr = reserved;
        u256Array = landMetaData;
        b32 = salt;
        u256Array = assetIds;
        b32Array = proof;
        b1 = referral;
        b1 = signature;
        return true;
    }
    
}