/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract QBPlasma {
    mapping(address => uint) private balances;
    event Deposit(address _addr, uint _value);

    constructor() {}

    function deposit() external payable {
        require(msg.value > 0);

        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}