/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank{
    uint _balance;
    mapping(address=>uint) _balances;
    uint _totalSupply;
    
    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }
    function withdraw(uint amount) public payable{
        require(amount <= _balances[msg.sender],"balance is not enough");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

    }
    function balance() public view returns(uint balance_){
        return _balances[msg.sender];
    }
    function totalSupply() public view returns(uint totalSupply_){
        return _totalSupply;
    }
  
}