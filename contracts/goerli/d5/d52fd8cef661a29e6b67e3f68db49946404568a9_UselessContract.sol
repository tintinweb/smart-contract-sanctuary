/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: GPL-3.0
// Code by Harshil Jain
// Email: - [email protected]
// Telegram: - @OreGaZembuTouchiSuru

pragma solidity >=0.7.0 <0.9.0;

contract UselessContract {
    function caller1() external pure {
        
    }
    
    uint256 temp;
    event Bullshit(uint256 amount1, uint256 amount2);
    
    function caller2(uint256 a, uint256 b) external returns(uint256) {
        require(a < b, "Bad Parameter Values");
        temp = a;
        
        emit Bullshit(a, b);
        
        return (a + b);
    }
}