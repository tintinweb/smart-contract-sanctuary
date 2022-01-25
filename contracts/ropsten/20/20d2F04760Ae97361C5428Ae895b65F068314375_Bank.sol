/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {

    mapping(address => uint) _balances;
    event Deposit(address indexed owner , uint amount);
    event Withdraw(address indexed owner , uint amount);

    function deposit() public payable {
        require(msg.value > 0 , "amount must be more than 0.");
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender,msg.value);
    }

    function withdraw(uint amount) public {
        require(amount > 0 && amount <= _balances[msg.sender] ,"not enough money");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;

        emit Withdraw(msg.sender,amount);
    }

    function checkBalance() public view returns(uint balance){
        return _balances[msg.sender];
    }

}