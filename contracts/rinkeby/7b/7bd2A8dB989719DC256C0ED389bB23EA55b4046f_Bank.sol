/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    
    mapping(address => uint) _balances;
    event Deposit(address indexed owner,uint amount);
    event Withdraw(address indexed owner,uint amount);
    
    uint _totalSupply;
    
    function deposit() public payable{
        require(msg.value > 0,"deposit money is zero");
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender,msg.value);
        //_totalSupply += msg.value;
    }
    
    function withdraw(uint amount) public {
        require(amount <= _balances[msg.sender],"not enough money" );
        
        payable(msg.sender).transfer(amount);
        
        _balances[msg.sender] -= amount;
        emit Withdraw(msg.sender,amount);
        //_totalSupply -= amount;
        
    }
    
    function balance() public view returns(uint) {
        return _balances[msg.sender];
    }
    
    function balanceOf(address owner) public view returns(uint){
        return _balances[owner];
    }
    
}