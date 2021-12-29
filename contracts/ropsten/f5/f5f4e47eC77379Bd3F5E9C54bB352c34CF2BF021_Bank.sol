/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {     
    mapping(address  => uint) _balances;
    uint _TotalSupply;

    function deposit() public payable {    
        _balances[msg.sender] +=  msg.value ; 
        _TotalSupply += msg.value;   
    }

    function withdraw(uint amount) public payable {
       require(amount <= _balances[msg.sender], "not enough money");

        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount; 
        _TotalSupply -= amount; 
    }

    function checkbalance() public view returns(uint _balance) {
        return _balances[msg.sender];
    }

    function checkTotalSupply() public view returns(uint totalsupply) {
        return _TotalSupply;
    }
}