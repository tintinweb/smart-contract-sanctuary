/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract SimpleAuction {
    
    address p1;
    uint256[] p2;
    bytes32 p3;
    
    function buyLandWithSand(address param1, uint256[] calldata param2, bytes32 param3) public returns (bool success) {
        p1 = param1;
        p2 = param2;
        p3 = param3;
        return true;
    }
    
}