/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

contract Bank {
    
    mapping(address => uint) _balances;
    uint _totalsupply;
    
    function deposit() public payable  {
        _balances[msg.sender] += msg.value;
        _totalsupply += msg.value;
    }
    
    function  withdraw(uint amount) public payable {
        require(amount <= _balances[msg.sender], "Money not enough");
        
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalsupply -= amount;
    }
    
    function checkbalance() public view returns(uint balance){
        return _balances[msg.sender];
    }
    
    function CheckTotalSupply()public view returns(uint totalsupply){
        return _totalsupply;
    }
    
    
    
}