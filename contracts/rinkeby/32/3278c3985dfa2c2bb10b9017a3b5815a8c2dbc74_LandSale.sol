/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.9;

contract LandSale {
    
    address addr;
    uint256[] u256Array;
    bytes32 b32;
    bytes32[] b32Array;
    bytes b1;
    
    function buyLandWithSand(
        address buyer, 
        address to, 
        address reserved, 
        uint256[] memory info, 
        bytes32 salt,
        uint256[] memory assetIds,
        bytes32[] memory proof,
        bytes memory referral,
        bytes memory signature
    ) public returns (bool success) {
        addr = buyer;
        addr = to;
        addr = reserved;
        u256Array = info;
        b32 = salt;
        u256Array = assetIds;
        b32Array = proof;
        b1 = referral;
        b1 = signature;
        return true;
    }
    
}