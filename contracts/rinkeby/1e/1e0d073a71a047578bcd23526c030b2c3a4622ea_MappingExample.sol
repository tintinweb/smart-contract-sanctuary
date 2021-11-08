/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MappingExample {
    mapping(address => uint256) public balances;

    function setBalance(uint256 newBalance) public {
        balances[msg.sender] += newBalance;
    }
}