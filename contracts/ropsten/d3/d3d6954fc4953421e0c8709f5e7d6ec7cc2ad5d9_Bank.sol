/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.10;

contract Bank {

    uint256 public _totalSupply;
    mapping(address => uint256) _balances;

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }

    function withdraw(uint256 amount) public payable {
        require(amount <= _balances[msg.sender], "Not enough money");
        payable(msg.sender).transfer(amount);   //โอนเงินยอด amount เข้าไปที่ msg.sender
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
    }

    function checkBalance() public view returns(uint256 balance) {
        return _balances[msg.sender];
    }

}