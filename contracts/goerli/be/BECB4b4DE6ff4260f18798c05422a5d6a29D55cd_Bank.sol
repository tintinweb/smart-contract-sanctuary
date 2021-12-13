/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint) _balance;
    uint TBD; // TotalBankDeposit

    event Deposit(address indexed owner, uint amount);
    event Withdraw(address indexed owner, uint amount);

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount can't be zero");

        _balance[msg.sender] += msg.value;
        TBD += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public {
        require(amount > 0 && amount <= _balance[msg.sender], "Withdraw amount can't be zero");
        payable(msg.sender).transfer(amount);
        _balance[msg.sender] -= amount;
        TBD -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function balance() public view returns(uint) {
        return _balance[msg.sender];
    }

    function balanceOf(address x) public view returns(uint) {
        return _balance[x];
    }
    
    function TotalDeposit() public view returns(uint TotalBankDeposit) {
        return TBD;
    }
}