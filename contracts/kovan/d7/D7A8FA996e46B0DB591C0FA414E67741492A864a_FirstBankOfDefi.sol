// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FirstBankOfDefi {

    uint256 number;
    uint256 number2;

    mapping (address => uint256) balances;

    function deposit(uint256 amount) public returns (uint256) {
        uint256 balance = balances[msg.sender];
        balance += amount;
        balances[msg.sender] = balance;
        return balance;
    }

    function withdraw(uint256 amount) public returns (uint256) {
        uint256 balance = balances[msg.sender];
        balance -= amount;
        balances[msg.sender] = balance;
        return balance;
    }

    function getCurrent() public view returns (uint256) {
        return balances[msg.sender];
    }


}