/**
 *Submitted for verification at polygonscan.com on 2021-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 { function balanceOf(address account) external view returns (uint256); }

contract MultiBalance {
    
    function multiBalance(address token, address[] calldata holders) external view returns (uint[] memory balances) {
        
        balances = new uint[](holders.length);
        
        for (uint i; i < holders.length; i++) {
            balances[i] = IERC20(token).balanceOf(holders[i]);
        }
    }

    function totalBalance(address token, address[] calldata holders) external view returns (uint total) {
        
        for (uint i; i < holders.length; i++) {
            total += IERC20(token).balanceOf(holders[i]);
        }
    }

}