/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Garbage {
    event ProfitGenerated(uint256 _amount);
    
    uint256 amount;
    
    function caller(uint256 _amount) external {
        amount = _amount;
        emit ProfitGenerated(_amount);
    }
}