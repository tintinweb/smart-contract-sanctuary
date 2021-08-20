/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.4;

contract Staking {
    mapping(address => uint8) private _balance;

    constructor() public {}

    function stake(uint8 amount) public {
        _balance[msg.sender] += amount;
    }

    function withdraw(uint8 amount) public {
        _balance[msg.sender] -= amount;
    }

    function balance() public view returns (uint8) {
        return _balance[msg.sender];
    }
}