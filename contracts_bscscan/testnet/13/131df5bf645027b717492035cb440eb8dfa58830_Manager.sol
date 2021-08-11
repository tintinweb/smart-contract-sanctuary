/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT
// File: IManagableObject.sol

pragma solidity ^0.7.6;

contract Manager {
    uint256 dividePercentage = 10000;
    
    function divPercent() external view returns (uint256) {
        return dividePercentage;
    }
}