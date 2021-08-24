/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;


contract Deposit{
    event Deposit(address from, uint256 value);
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

}