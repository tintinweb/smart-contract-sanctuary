/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint256) _balances;
    uint _totalSupply;

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount <= _balances[msg.sender], "not enough money");

        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply += amount;
    }

    function checkBalance() public view returns (uint256 balance) {
        return _balances[msg.sender];
    }
    
    function checkTotalSupply() public view returns(uint totalSupply) {
        return _totalSupply;   
    }
}