/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint) _balances;
    
    function deposit() public payable {
        _balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint amount) public {
        require(_balances[msg.sender] >= amount, "xxxxxxxx");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
    }
    
    function checkBalance() public view returns (uint){
        return _balances[msg.sender];
    }
}