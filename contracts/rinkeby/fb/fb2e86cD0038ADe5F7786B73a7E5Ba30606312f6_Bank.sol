/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {

    mapping(address => uint) _balances;    
    uint _totolsupply;

    function deposite() public payable{
        _balances[msg.sender] += msg.value;
        _totolsupply += msg.value;
    }

    function withdraw(uint amount) public payable{
        require(amount <= _balances[msg.sender],"not enough money");
        payable(msg.sender).transfer(amount);          
        _balances[msg.sender] -= amount;
        _totolsupply -= amount;
    }

    function checkBalance()  public view returns(uint balance){
        return _balances[msg.sender]; 
    }            

    function checktotalsupply() public view returns(uint totolsupply){
        return _totolsupply;
    }      
}