/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FeeCollector {

    address public owner;
    uint256 public balance;
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
       
    }

    receive() payable external {
        balance += msg.value;
    }

}