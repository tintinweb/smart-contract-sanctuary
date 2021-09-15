/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    
    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    mapping(address => uint) _balances;
    uint _totalSupply;
    
    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }
    
    function withdraw(uint amount) public payable {
        require(amount <= _balances[msg.sender], "Not enough money");
        
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
    }
    
    function checkBalance() public view returns(uint balance) {
        return _balances[msg.sender];
    }
    
    function checkTotalSupply() public view returns(uint totalSupply) {
        return _totalSupply;
    }
}